import ACTransitSwift
import MapKit
import SwiftUI

struct RoutesService_TripStopsToday: View {
    @State private var routes: String = ""
    @State private var direction: String = ""
    @State private var results: [TripStopToday] = []
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
                    TextField("direction (e.g. Northbound)", text: $direction)
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
                Section("Results (\(results.count))") {
                    Map(position: $position) {
                        ForEach(results, id: \.tripId) { trip in
                            Marker(trip.stopDescription, coordinate: CLLocationCoordinate2D(
                                latitude: trip.stopLatitude,
                                longitude: trip.stopLongitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(results, id: \.tripId) { trip in
                        VStack(alignment: .leading) {
                            Text(trip.stopDescription)
                                .fontWeight(.medium)
                            Text(trip.direction)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.tripStopsToday")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.tripStopsToday(
                routes: routes,
                direction: direction.isEmpty ? nil : direction
            )
            guard let minLat = results.map(\.stopLatitude).min(),
                  let maxLat = results.map(\.stopLatitude).max(),
                  let minLon = results.map(\.stopLongitude).min(),
                  let maxLon = results.map(\.stopLongitude).max() else { return }
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
