import EZNetworking
import Foundation

public struct RoutesService {
    private let token: String
    private let performer: RequestPerformable

    init(token: String, performer: RequestPerformable) {
        self.token = token
        self.performer = performer
    }

    /// Retrieves all AC Transit routes for a given booking period.
    /// - Parameters:
    ///   - booking: Unique id representing a specific schedule. Use `Current` or `nil` for the current schedule, `Next` for the next schedule, or a specific BookingId.
    ///   - sortType: Indicates how the routes should be sorted. Default is natural sort. Options: `Alphabetical` or `Natural`.
    public func routes(booking: String? = nil, sortType: RouteSortType? = nil) async throws -> [RouteDivision] {
        try await performer.perform(
            request: RoutesEndpoint.routes(booking: booking, sortType: sortType).getRequest(token: token),
            decodeTo: [RouteDivision].self
        )
    }

    /// Retrieves details for a specific route in a given booking period.
    /// - Parameters:
    ///   - routeName: The route to be retrieved.
    ///   - booking: Schedule identifier. Use `Current` or `nil` for the current schedule, `Next` for the next, or a specific BookingId.
    public func route(routeName: String, booking: String? = nil) async throws -> Route {
        try await performer.perform(
            request: RoutesEndpoint.route(routeName: routeName, booking: booking).getRequest(token: token),
            decodeTo: Route.self
        )
    }

    /// Retrieves all trips for a given route, optionally filtered by direction and schedule type.
    /// - Parameters:
    ///   - routeName: The route identifier.
    ///   - direction: Filter results by direction of travel.
    ///   - scheduleType: Filter by schedule type: `Weekday`, `Saturday`, or `Sunday`.
    public func trips(routeName: String, direction: String? = nil, scheduleType: TripScheduleType? = nil) async throws -> [Trip] {
        try await performer.perform(
            request: RoutesEndpoint.trips(routeName: routeName, direction: direction, scheduleType: scheduleType).getRequest(token: token),
            decodeTo: [Trip].self
        )
    }

    /// Retrieves trips with operator driving instructions for a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    ///   - direction: Filter by direction of travel.
    ///   - scheduleType: Required. The schedule type: `Weekday`, `Saturday`, or `Sunday`.
    public func tripsInstructions(routeName: String, direction: String? = nil, scheduleType: TripScheduleType) async throws -> [TripInstruction] {
        try await performer.perform(
            request: RoutesEndpoint.tripsInstructions(routeName: routeName, direction: direction, scheduleType: scheduleType).getRequest(token: token),
            decodeTo: [TripInstruction].self
        )
    }

    /// Retrieves all directions serviced by a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    public func directions(routeName: String) async throws -> [String] {
        try await performer.perform(
            request: RoutesEndpoint.directions(routeName: routeName).getRequest(token: token),
            decodeTo: [String].self
        )
    }

    /// Retrieves all stops for a given route, organized by direction or stop pattern.
    /// - Parameters:
    ///   - routeName: The route identifier.
    ///   - booking: Schedule identifier. Use `Current` or `nil` for the current schedule, `Next` for the next, or a specific BookingId.
    ///   - direction: Filter by direction.
    ///   - destination: Filter by destination; should match actrealtime API values.
    ///   - scheduleType: Filter by schedule type: `Today`, `Saturday`, `Sunday`, or `Weekday`.
    ///   - byPattern: If true, return stops per stop pattern. Default false.
    public func stops(routeName: String, booking: String? = nil, direction: String? = nil, destination: String? = nil, scheduleType: TripScheduleType? = nil, byPattern: Bool? = nil) async throws -> [RouteStopOrder] {
        try await performer.perform(
            request: RoutesEndpoint.stops(routeName: routeName, booking: booking, direction: direction, destination: destination, scheduleType: scheduleType, byPattern: byPattern).getRequest(token: token),
            decodeTo: [RouteStopOrder].self
        )
    }

    /// Retrieves the timepoint pattern for a specific trip on a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    ///   - tripId: The trip identifier.
    public func pattern(routeName: String, tripId: Int) async throws -> [TimePoint] {
        try await performer.perform(
            request: RoutesEndpoint.pattern(routeName: routeName, tripId: tripId).getRequest(token: token),
            decodeTo: [TimePoint].self
        )
    }

    /// Retrieves a list of bus stops for a specific trip on a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    ///   - tripId: The trip identifier.
    public func tripStops(routeName: String, tripId: Int) async throws -> [Stop] {
        try await performer.perform(
            request: RoutesEndpoint.tripStops(routeName: routeName, tripId: tripId).getRequest(token: token),
            decodeTo: [Stop].self
        )
    }

    /// Retrieves all vehicles currently servicing a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    public func vehicles(routeName: String) async throws -> [Vehicle] {
        try await performer.perform(
            request: RoutesEndpoint.vehicles(routeName: routeName).getRequest(token: token),
            decodeTo: [Vehicle].self
        )
    }

    /// Retrieves future trip estimates between two stops on a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    ///   - fromStopId: The origin stop identifier.
    ///   - toStopId: The destination stop identifier.
    public func tripEstimate(routeName: String, fromStopId: Int, toStopId: Int) async throws -> [TripEstimate] {
        try await performer.perform(
            request: RoutesEndpoint.tripEstimate(routeName: routeName, fromStopId: fromStopId, toStopId: toStopId).getRequest(token: token),
            decodeTo: [TripEstimate].self
        )
    }

    /// Retrieves all waypoints currently servicing the specified route.
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers, or `all`.
    ///   - booking: Schedule identifier. Use `Current` or `nil` for the current schedule, `Next` for the next, or a specific BookingId.
    ///   - scheduleType: Filter by schedule type: `Weekday`, `Saturday`, or `Sunday`.
    public func waypoints(routes: String, booking: String? = nil, scheduleType: TripScheduleType? = nil) async throws -> [RouteWaypoints] {
        try await performer.perform(
            request: RoutesEndpoint.waypoints(routes: routes, booking: booking, scheduleType: scheduleType).getRequest(token: token),
            decodeTo: [RouteWaypoints].self
        )
    }

    /// Retrieves all waypoints for the specified route, optimized for speed (waypoints as coordinate strings).
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers, or `all`.
    ///   - booking: Schedule identifier. Use `Current` or `nil` for the current schedule, `Next` for the next, or a specific BookingId.
    ///   - scheduleType: Filter by schedule type: `Weekday`, `Saturday`, or `Sunday`.
    public func waypointsFast(routes: String, booking: String? = nil, scheduleType: TripScheduleType? = nil) async throws -> [RouteWaypointsFast] {
        try await performer.perform(
            request: RoutesEndpoint.waypointsFast(routes: routes, booking: booking, scheduleType: scheduleType).getRequest(token: token),
            decodeTo: [RouteWaypointsFast].self
        )
    }

    /// Retrieves all trips traveling along one or more routes today.
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers.
    ///   - direction: Optional direction or destination to filter by (comma delimited).
    public func tripsToday(routes: String, direction: String? = nil) async throws -> [TripStopToday] {
        try await performer.perform(
            request: RoutesEndpoint.tripsToday(routes: routes, direction: direction).getRequest(token: token),
            decodeTo: [TripStopToday].self
        )
    }

    /// Retrieves all stops and trips traveling along one or more routes today.
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers.
    ///   - direction: Optional direction or destination to filter by (comma delimited).
    public func tripStopsToday(routes: String, direction: String? = nil) async throws -> [TripStopToday] {
        try await performer.perform(
            request: RoutesEndpoint.tripStopsToday(routes: routes, direction: direction).getRequest(token: token),
            decodeTo: [TripStopToday].self
        )
    }

    /// Retrieves the timetable for a given route.
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers.
    ///   - direction: Direction or destination designation.
    ///   - dayCode: Day type: `Weekday`, `Saturday`, or `Sunday`. Defaults to current day.
    ///   - hasAllStops: If true, include all stops rather than major locations only. Default false.
    public func timetable(routes: String, direction: String? = nil, dayCode: String? = nil, hasAllStops: Bool? = nil) async throws -> [TimeTable] {
        try await performer.perform(
            request: RoutesEndpoint.timetable(routes: routes, direction: direction, dayCode: dayCode, hasAllStops: hasAllStops).getRequest(token: token),
            decodeTo: [TimeTable].self
        )
    }

    /// Retrieves stops and schedules for a given route.
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers.
    ///   - booking: Schedule identifier. Use `Current` or `nil` for the current schedule, `Next` for the next, or a specific BookingId.
    ///   - direction: Optional route direction.
    ///   - destination: Optional route destination.
    ///   - dayCode: Day type: `Weekday`, `Saturday`, or `Sunday`. Defaults to today.
    ///   - hasAllStops: If true, include waypoints. Default false.
    ///   - stopId: Filter results to a specific stop by ID511 code.
    public func schedule(routes: String, booking: String? = nil, direction: String? = nil, destination: String? = nil, dayCode: String? = nil, hasAllStops: Bool? = nil, stopId: String? = nil) async throws -> TripScheduleInfo {
        try await performer.perform(
            request: RoutesEndpoint.schedule(routes: routes, booking: booking, direction: direction, destination: destination, dayCode: dayCode, hasAllStops: hasAllStops, stopId: stopId).getRequest(token: token),
            decodeTo: TripScheduleInfo.self
        )
    }

    /// Retrieves all destinations for a given route.
    /// - Parameters:
    ///   - routeName: The route identifier.
    public func destinations(routeName: String) async throws -> [RouteDestination] {
        try await performer.perform(
            request: RoutesEndpoint.destinations(routeName: routeName).getRequest(token: token),
            decodeTo: [RouteDestination].self
        )
    }

    /// Retrieves all service exceptions for the given route(s).
    /// - Parameters:
    ///   - routes: Comma-delimited route identifiers, or `all`.
    ///   - booking: Schedule identifier. Use `Current` or `nil` for the current schedule, `Next` for the next, or a specific BookingId.
    public func exceptions(routes: String, booking: String? = nil) async throws -> RouteExceptions {
        try await performer.perform(
            request: RoutesEndpoint.exceptions(routes: routes, booking: booking).getRequest(token: token),
            decodeTo: RouteExceptions.self
        )
    }

    /// Retrieves profile descriptions for the given route(s).
    /// - Parameters:
    ///   - routes: Comma-separated list of route identifiers, or `all`.
    public func profile(routes: String) async throws -> [RouteProfile] {
        try await performer.perform(
            request: RoutesEndpoint.profile(routes: routes).getRequest(token: token),
            decodeTo: [RouteProfile].self
        )
    }
}
