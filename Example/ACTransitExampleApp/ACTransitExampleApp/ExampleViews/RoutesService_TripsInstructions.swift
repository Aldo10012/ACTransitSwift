import ACTransitSwift
import MapKit
import SwiftUI

struct RoutesService_TripsInstructions: View {
    @State private var routeName: String = ""
    @State private var direction: String = ""
    @State private var scheduleType: TripScheduleType = .weekday
    @State private var results: [TripInstruction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let client = ACTransitClient()

    private struct MapPin: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }

    private var mapPins: [MapPin] {
        results.flatMap { trip in
            (trip.timePoints ?? []).map { tp in
                MapPin(coordinate: CLLocationCoordinate2D(latitude: tp.latitude, longitude: tp.longitude))
            }
        }
    }

    var body: some View {
        Form {
            Section("Parameters") {
                HStack {
                    TextField("routeName (e.g. 72)", text: $routeName)
                    FieldBadge(requirement: .required)
                }
                HStack {
                    TextField("direction (e.g. Southbound)", text: $direction)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    Picker("scheduleType", selection: $scheduleType) {
                        Text("Weekday").tag(TripScheduleType.weekday)
                        Text("Saturday").tag(TripScheduleType.saturday)
                        Text("Sunday").tag(TripScheduleType.sunday)
                    }
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
                    if !mapPins.isEmpty {
                        Map(coordinateRegion: $region, annotationItems: mapPins) { pin in
                            MapMarker(coordinate: pin.coordinate)
                        }
                        .frame(height: 300)
                        .listRowInsets(EdgeInsets())
                    } else {
                        Text("No coordinate data included in response")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(results, id: \.tripId) { item in
                        VStack(alignment: .leading) {
                            Text(item.direction)
                                .fontWeight(.medium)
                            Text(item.instructionsText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.tripsInstructions")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.tripsInstructions(
                routeName: routeName,
                direction: direction.isEmpty ? nil : direction,
                scheduleType: scheduleType
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
