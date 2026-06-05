import SwiftUI
import MapKit
import ACTransitSwift

struct RoutesService_Waypoints: View {
    @State private var routes: String = ""
    @State private var booking: String = ""
    @State private var scheduleType: TripScheduleType? = nil
    @State private var results: [RouteWaypoints] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    private let client = ACTransitClient()

    private var allWaypoints: [RouteWaypoint] {
        results.flatMap { $0.patterns }.flatMap { $0.waypoints }
    }

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
                    Picker("scheduleType", selection: $scheduleType) {
                        Text("none").tag(TripScheduleType?.none)
                        Text("Weekday").tag(TripScheduleType?.some(.weekday))
                        Text("Saturday").tag(TripScheduleType?.some(.saturday))
                        Text("Sunday").tag(TripScheduleType?.some(.sunday))
                    }
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
                Section("Results (\(allWaypoints.count) waypoints)") {
                    Map(position: $position) {
                        ForEach(allWaypoints, id: \.orderId) { waypoint in
                            Marker("Waypoint \(waypoint.orderId)", coordinate: CLLocationCoordinate2D(
                                latitude: waypoint.latitude,
                                longitude: waypoint.longitude
                            ))
                        }
                    }
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
                    ForEach(allWaypoints, id: \.orderId) { waypoint in
                        VStack(alignment: .leading) {
                            Text("Waypoint \(waypoint.orderId)")
                                .fontWeight(.medium)
                            Text("\(waypoint.latitude), \(waypoint.longitude)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.waypoints")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.waypoints(
                routes: routes,
                booking: booking.isEmpty ? nil : booking,
                scheduleType: scheduleType
            )
            let lats = allWaypoints.map(\.latitude)
            let lons = allWaypoints.map(\.longitude)
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
