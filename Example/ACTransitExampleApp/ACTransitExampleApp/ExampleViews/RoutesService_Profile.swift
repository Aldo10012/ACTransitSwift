import SwiftUI
import ACTransitSwift

struct RoutesService_Profile: View {
    @State private var routes: String = ""
    @State private var results: [RouteProfile] = []
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
                    ForEach(results, id: \.routeId) { profile in
                        VStack(alignment: .leading) {
                            Text(profile.routeId)
                                .fontWeight(.medium)
                            Text(profile.profile)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.profile")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.profile(routes: routes)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
