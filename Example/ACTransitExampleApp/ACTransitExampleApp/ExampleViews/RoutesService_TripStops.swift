import ACTransitSwift
import MapKit
import SwiftUI

struct RoutesService_TripStops: View {
    @State private var routeName: String = ""
    @State private var tripId: String = ""
    @State private var results: [Stop] = []
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
                    TextField("routeName (e.g. 72)", text: $routeName)
                    FieldBadge(requirement: .required)
                }
                HStack {
                    TextField("tripId (e.g. 11861464)", text: $tripId)
                        .keyboardType(.numberPad)
                    FieldBadge(requirement: .required)
                }
            }

            SearchButton(isLoading: isLoading) {
                await fetch()
            }
            .disabled(isLoading || routeName.isEmpty || tripId.isEmpty)

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
                        ForEach(results, id: \.stopId) { stop in
                            Marker(stop.name, coordinate: CLLocationCoordinate2D(
                                latitude: stop.latitude,
                                longitude: stop.longitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(results, id: \.stopId) { stop in
                        VStack(alignment: .leading) {
                            Text(stop.name)
                                .fontWeight(.medium)
                            Text(stop.city ?? "\(stop.latitude), \(stop.longitude)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.tripStops")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let parsedTripId = Int(tripId) else { return }
            results = try await client.routes.tripStops(
                routeName: routeName,
                tripId: parsedTripId
            )
            guard let minLat = results.map(\.latitude).min(),
                  let maxLat = results.map(\.latitude).max(),
                  let minLon = results.map(\.longitude).min(),
                  let maxLon = results.map(\.longitude).max() else { return }
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
