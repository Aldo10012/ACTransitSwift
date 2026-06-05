import ACTransitSwift
import SwiftUI

struct RoutesService_TripEstimate: View {
    @State private var routeName: String = ""
    @State private var fromStopId: String = ""
    @State private var toStopId: String = ""
    @State private var results: [TripEstimate] = []
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
                    TextField("fromStopId (e.g. 55888)", text: $fromStopId)
                        .keyboardType(.numberPad)
                    FieldBadge(requirement: .required)
                }
                HStack {
                    TextField("toStopId (e.g. 51632)", text: $toStopId)
                        .keyboardType(.numberPad)
                    FieldBadge(requirement: .required)
                }
            }

            SearchButton(isLoading: isLoading) {
                await fetch()
            }
            .disabled(isLoading || routeName.isEmpty || fromStopId.isEmpty || toStopId.isEmpty)

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
                    ForEach(results, id: \.expectedDepartureTime) { estimate in
                        VStack(alignment: .leading) {
                            Text(estimate.expectedDepartureTime)
                                .fontWeight(.medium)
                            Text(estimate.tripDuration)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.tripEstimate")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let parsedFromStopId = Int(fromStopId),
                  let parsedToStopId = Int(toStopId) else { return }
            results = try await client.routes.tripEstimate(
                routeName: routeName,
                fromStopId: parsedFromStopId,
                toStopId: parsedToStopId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
