import SwiftUI

struct SearchButton: View {
    let isLoading: Bool
    let action: () async -> Void

    var body: some View {
        Section {
            Button("Search") {
                Task { await action() }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .disabled(isLoading)
            .listRowBackground(isLoading ? Color.accentColor.opacity(0.5) : Color.accentColor)
        }
    }
}
