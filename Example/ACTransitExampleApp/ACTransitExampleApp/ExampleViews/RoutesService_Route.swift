import SwiftUI
import ACTransitSwift

struct RoutesService_Route: View {
    @State private var routeName: String = ""
    @State private var booking: String = ""
    @State private var result: Route? = nil
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
                    TextField("booking (e.g. Current)", text: $booking)
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

            if let result {
                Section("Result") {
                    VStack(alignment: .leading) {
                        Text(result.name)
                            .fontWeight(.medium)
                        Text(result.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("RoutesService.route")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            result = try await client.routes.route(
                routeName: routeName,
                booking: booking.isEmpty ? nil : booking
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
