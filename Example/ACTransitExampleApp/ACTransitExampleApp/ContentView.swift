import SwiftUI

struct ContentView: View {
    @State var path = [NavigationPath]()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    cell(title: "routes") { RoutesService_Routes() }
                    cell(title: "route") { RoutesService_Route() }
                    cell(title: "trips") { RoutesService_Trips() }
                    cell(title: "tripsInstructions") { RoutesService_TripsInstructions() }
                    cell(title: "directions") { RoutesService_Directions() }
                    cell(title: "stops") { RoutesService_Stops() }
                    cell(title: "pattern") { RoutesService_Pattern() }
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
