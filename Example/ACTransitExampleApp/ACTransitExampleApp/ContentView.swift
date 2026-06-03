import SwiftUI

struct ContentView: View {
    @State var path = [NavigationPath]()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    cell(title: "routes") { RoutesService_Routes() }
                } header: {
                    Text("RoutesService")
                }
            }
        }
    }

    @ViewBuilder
    private func cell<Destination: View>(title: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            Text(title)
        }
    }
}

#Preview {
    ContentView()
}
