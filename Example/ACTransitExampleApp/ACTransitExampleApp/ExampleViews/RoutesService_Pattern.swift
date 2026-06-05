import SwiftUI
import MapKit
import ACTransitSwift

struct RoutesService_Pattern: View {
    @State private var routeName: String = ""
    @State private var tripId: String = ""
    @State private var results: [TimePoint] = []
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
                        ForEach(results, id: \.sequence) { point in
                            Marker("Stop \(point.sequence)", coordinate: CLLocationCoordinate2D(
                                latitude: point.latitude,
                                longitude: point.longitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(results, id: \.sequence) { point in
                        VStack(alignment: .leading) {
                            Text("Stop \(point.sequence)")
                                .fontWeight(.medium)
                            Text("\(point.latitude), \(point.longitude)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.pattern")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.pattern(
                routeName: routeName,
                tripId: Int(tripId)!
            )
            if !results.isEmpty {
                let minLat = results.map(\.latitude).min()!
                let maxLat = results.map(\.latitude).max()!
                let minLon = results.map(\.longitude).min()!
                let maxLon = results.map(\.longitude).max()!
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
