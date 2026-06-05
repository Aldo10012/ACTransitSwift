import ACTransitSwift
import SwiftUI

struct RoutesService_WaypointsFast: View {
    @State private var routes: String = ""
    @State private var booking: String = ""
    @State private var scheduleType: TripScheduleType?
    @State private var results: [RouteWaypointsFast] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                Section("Results (\(results.count))") {
                    ForEach(results, id: \.routeAlpha) { route in
                        VStack(alignment: .leading) {
                            Text(route.routeAlpha)
                                .fontWeight(.medium)
                            Text(route.booking)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.waypointsFast")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.waypointsFast(
                routes: routes,
                booking: booking.isEmpty ? nil : booking,
                scheduleType: scheduleType
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
