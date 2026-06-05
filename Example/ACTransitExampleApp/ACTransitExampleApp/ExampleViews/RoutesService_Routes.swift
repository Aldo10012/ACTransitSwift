import ACTransitSwift
import SwiftUI

struct RoutesService_Routes: View {
    @State private var booking: String = ""
    @State private var sortType: RouteSortType?
    @State private var results: [RouteDivision] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let client = ACTransitClient()

    var body: some View {
        Form {
            Section("Parameters") {
                HStack {
                    TextField("booking (e.g. Current)", text: $booking)
                    FieldBadge(requirement: .optional)
                }
                HStack {
                    Picker("sortType", selection: $sortType) {
                        Text("none").tag(RouteSortType?.none)
                        Text("Alphabetical").tag(RouteSortType?.some(.alphabetical))
                        Text("Natural").tag(RouteSortType?.some(.natural))
                    }
                    FieldBadge(requirement: .optional)
                }
            }

            SearchButton(isLoading: isLoading) {
                await fetchRoutes()
            }

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
                    ForEach(results, id: \.routeId) { route in
                        VStack(alignment: .leading) {
                            Text(route.name)
                                .fontWeight(.medium)
                            Text(route.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.routes")
    }

    private func fetchRoutes() async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await client.routes.routes(
                booking: booking.isEmpty ? nil : booking,
                sortType: sortType
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
