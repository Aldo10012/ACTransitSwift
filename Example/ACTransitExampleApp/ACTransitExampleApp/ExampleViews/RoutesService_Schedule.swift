import ACTransitSwift
import MapKit
import SwiftUI

struct RoutesService_Schedule: View {
    @State private var routes: String = ""
    @State private var booking: String = ""
    @State private var direction: String = ""
    @State private var destination: String = ""
    @State private var dayCode: String = ""
    @State private var hasAllStops: Bool = false
    @State private var stopId: String = ""
    @State private var result: TripScheduleInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    private let client = ACTransitClient()

    var body: some View {
        Form {
            Section("Parameters") {
                HStack {
                    TextField("routes (e.g. 72)", text: $routes)
                    FieldBadge(requirement: .required)
                }
                HStack {
                    TextField("booking (e.g. Current)", text: $booking)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    TextField("direction (e.g. Northbound)", text: $direction)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    TextField("destination (e.g. To Downtown Oakland)", text: $destination)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    TextField("dayCode (e.g. Weekday)", text: $dayCode)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    Toggle("hasAllStops", isOn: $hasAllStops)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    TextField("stopId (e.g. 55888)", text: $stopId)
                    FieldBadge(requirement: .optional)
                }
            }

            SearchButton(isLoading: isLoading) {
                await fetch()
            }
            .disabled(isLoading || routes.isEmpty)

            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if let result {
                Section("Results (\(result.stops.count) stops)") {
                    Map(position: $position) {
                        ForEach(result.stops, id: \.stopId) { stop in
                            Marker(stop.stopDescription, coordinate: CLLocationCoordinate2D(
                                latitude: stop.latitude,
                                longitude: stop.longitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(result.stops, id: \.stopId) { stop in
                        VStack(alignment: .leading) {
                            Text(stop.stopDescription)
                                .fontWeight(.medium)
                            Text(stop.city)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.schedule")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            result = try await client.routes.schedule(
                routes: routes,
                booking: booking.isEmpty ? nil : booking,
                direction: direction.isEmpty ? nil : direction,
                destination: destination.isEmpty ? nil : destination,
                dayCode: dayCode.isEmpty ? nil : dayCode,
                hasAllStops: hasAllStops,
                stopId: stopId.isEmpty ? nil : stopId
            )
            if let result {
                guard let minLat = result.stops.map(\.latitude).min(),
                      let maxLat = result.stops.map(\.latitude).max(),
                      let minLon = result.stops.map(\.longitude).min(),
                      let maxLon = result.stops.map(\.longitude).max() else { return }
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: max(maxLat - minLat, 0.01) * 1.3,
                        longitudeDelta: max(maxLon - minLon, 0.01) * 1.3
                    )
                ))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
