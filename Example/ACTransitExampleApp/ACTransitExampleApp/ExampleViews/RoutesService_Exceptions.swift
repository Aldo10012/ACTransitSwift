import SwiftUI
import ACTransitSwift

struct RoutesService_Exceptions: View {
    @State private var routes: String = ""
    @State private var booking: String = ""
    @State private var result: RouteExceptions? = nil
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

            if let result {
                Section("Results (\(result.dateExceptions.count) exceptions)") {
                    ForEach(result.dateExceptions, id: \.routeId) { exception in
                        VStack(alignment: .leading) {
                            Text(exception.routeId)
                                .fontWeight(.medium)
                            Text("\(exception.serviceExceptions.count) service exception(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("RoutesService.exceptions")
    }

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        do {
            result = try await client.routes.exceptions(
                routes: routes,
                booking: booking.isEmpty ? nil : booking
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
