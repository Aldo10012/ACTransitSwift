import ACTransitSwift
import MapKit
import SwiftUI

struct RoutesService_Stops: View {
    @State private var routeName: String = ""
    @State private var booking: String = ""
    @State private var direction: String = ""
    @State private var destination: String = ""
    @State private var scheduleType: TripScheduleType?
    @State private var byPattern: Bool = false
    @State private var results: [RouteStopOrder] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    private let client = ACTransitClient()

    private var allStops: [StopOrder] {
        results.flatMap { $0.stops }
    }

    var body: some View {
        Form {
            Section("Parameters") {
                HStack {
                    TextField("routeName (e.g. 72)", text: $routeName)
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
                    Picker("scheduleType", selection: $scheduleType) {
                        Text("none").tag(TripScheduleType?.none)
                        Text("Weekday").tag(TripScheduleType?.some(.weekday))
                        Text("Saturday").tag(TripScheduleType?.some(.saturday))
                        Text("Sunday").tag(TripScheduleType?.some(.sunday))
                    }
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    Toggle("byPattern", isOn: $byPattern)
                    FieldBadge(requirement: .optional)
                }
            }

            SearchButton(isLoading: isLoading) {
                await fetch()
            }
            .disabled(isLoading || routeName.isEmpty)

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

            if !results.isEmpty {
                Section("Results (\(results.count))") {
                    Map(position: $position) {
                        ForEach(allStops, id: \.stopId) { stop in
                            Marker(stop.name, coordinate: CLLocationCoordinate2D(
                                latitude: stop.latitude,
                                longitude: stop.longitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .navigationTitle("RoutesService.stops")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.stops(
                routeName: routeName,
                booking: booking.isEmpty ? nil : booking,
                direction: direction.isEmpty ? nil : direction,
                destination: destination.isEmpty ? nil : destination,
                scheduleType: scheduleType,
                byPattern: byPattern
            )
            if let first = allStops.first {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
