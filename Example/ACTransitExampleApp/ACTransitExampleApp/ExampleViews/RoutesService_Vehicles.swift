import SwiftUI
import MapKit
import ACTransitSwift

struct RoutesService_Vehicles: View {
    @State private var routeName: String = ""
    @State private var results: [Vehicle] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    private let client = ACTransitClient()

    private var locatedVehicles: [Vehicle] {
        results.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        Form {
            Section("Parameters") {
                HStack {
                    TextField("routeName (e.g. 72)", text: $routeName)
                    FieldBadge(requirement: .required)
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
                        ForEach(locatedVehicles, id: \.vehicleId) { vehicle in
                            if let lat = vehicle.latitude, let lon = vehicle.longitude {
                                Marker("Vehicle \(vehicle.vehicleId)", coordinate: CLLocationCoordinate2D(
                                    latitude: lat,
                                    longitude: lon
                                ))
                            }
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(results, id: \.vehicleId) { vehicle in
                        VStack(alignment: .leading) {
                            Text("Vehicle \(vehicle.vehicleId)")
                                .fontWeight(.medium)
                            Text(vehicle.timeLastReported ?? "No time reported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.vehicles")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.vehicles(routeName: routeName)
            let lats = results.compactMap(\.latitude)
            let lons = results.compactMap(\.longitude)
            guard let minLat = lats.min(),
                  let maxLat = lats.max(),
                  let minLon = lons.min(),
                  let maxLon = lons.max() else { return }
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
