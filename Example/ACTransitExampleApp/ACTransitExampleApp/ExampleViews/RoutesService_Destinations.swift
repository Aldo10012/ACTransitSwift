import SwiftUI
import ACTransitSwift

struct RoutesService_Destinations: View {
    @State private var routeName: String = ""
    @State private var results: [RouteDestination] = []
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
                    ForEach(results, id: \.directionId) { destination in
                        VStack(alignment: .leading) {
                            Text(destination.destination)
                                .fontWeight(.medium)
                            Text(destination.direction)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.destinations")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.destinations(routeName: routeName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
