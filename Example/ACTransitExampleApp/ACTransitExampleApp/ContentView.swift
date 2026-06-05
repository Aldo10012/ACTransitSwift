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
                    cell(title: "tripStops") { RoutesService_TripStops() }
                    cell(title: "vehicles") { RoutesService_Vehicles() }
                    cell(title: "tripEstimate") { RoutesService_TripEstimate() }
                    cell(title: "waypoints") { RoutesService_Waypoints() }
                    cell(title: "waypointsFast") { RoutesService_WaypointsFast() }
                    cell(title: "tripsToday") { RoutesService_TripsToday() }
                    cell(title: "tripStopsToday") { RoutesService_TripStopsToday() }
                    cell(title: "timetable") { RoutesService_Timetable() }
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
