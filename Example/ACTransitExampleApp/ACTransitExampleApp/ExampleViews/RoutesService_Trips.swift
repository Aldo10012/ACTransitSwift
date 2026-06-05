import ACTransitSwift
import SwiftUI

struct RoutesService_Trips: View {
    @State private var routeName: String = ""
    @State private var direction: String = ""
    @State private var scheduleType: TripScheduleType?
    @State private var results: [Trip] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let client = ACTransitClient()

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
                    ForEach(results, id: \.tripId) { trip in
                        VStack(alignment: .leading) {
                            Text(trip.direction)
                                .fontWeight(.medium)
                            Text(trip.routeName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(trip.startTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.trips")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.trips(
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
