import SwiftUI
import MapKit
import ACTransitSwift

struct RoutesService_Timetable: View {
    @State private var routes: String = ""
    @State private var direction: String = ""
    @State private var dayCode: String = ""
    @State private var hasAllStops: Bool = false
    @State private var results: [TimeTable] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    private let client = ACTransitClient()

    private var allStops: [TimeTableStop] {
        results.flatMap { $0.stops }
    }

    var body: some View {
        Form {
            Section("Parameters") {
                HStack {
                    TextField("routes (e.g. 72)", text: $routes)
                    FieldBadge(requirement: .required)
                }
                HStack {
                    TextField("direction (e.g. Northbound)", text: $direction)
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

            if !results.isEmpty {
                Section("Results (\(allStops.count) stops)") {
                    Map(position: $position) {
                        ForEach(allStops, id: \.stopId) { stop in
                            Marker(stop.stopDescription, coordinate: CLLocationCoordinate2D(
                                latitude: stop.stopLatitude,
                                longitude: stop.stopLongitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(allStops, id: \.stopId) { stop in
                        VStack(alignment: .leading) {
                            Text(stop.stopDescription)
                                .fontWeight(.medium)
                            Text(stop.placeId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.timetable")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.timetable(
                routes: routes,
                direction: direction.isEmpty ? nil : direction,
                dayCode: dayCode.isEmpty ? nil : dayCode,
                hasAllStops: hasAllStops
            )
            guard let minLat = allStops.map(\.stopLatitude).min(),
                  let maxLat = allStops.map(\.stopLatitude).max(),
                  let minLon = allStops.map(\.stopLongitude).min(),
                  let maxLon = allStops.map(\.stopLongitude).max() else { return }
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
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
