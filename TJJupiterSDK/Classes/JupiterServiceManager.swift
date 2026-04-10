
import Foundation
import TJLabsCommon
import TJLabsJupiter

public class JupiterServiceManager: NavigationManagerDelegate {
    public func onJupiterSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.JupiterErrorCode?) {
        delegate?.onJupiterSuccess(isSuccess, code?.toWrap())
    }
    
    public func onJupiterResult(_ result: TJLabsJupiter.JupiterResult) {
        delegate?.onJupiterResult(result.toWrap())
    }
    
    public func onJupiterReport(_ code: TJLabsJupiter.JupiterServiceCode, _ msg: String) {
        delegate?.onJupiterReport(code.toWrap(), msg)
    }
    
    public func isJupiterInOutStateChanged(_ state: TJLabsJupiter.InOutState) {
        delegate?.isJupiterInOutStateChanged(state.toWrap())
    }
    
    public func isUserGuidanceOut() {
        delegate?.isUserGuidanceOut()
    }
    
    public func isNavigationRouteChanged(_ routes: [(String, String, Int, Float, Float)]) {
        delegate?.isNavigationRouteChanged(routes)
    }
    
    public func isNavigationRouteFailed() {
        delegate?.isNavigationRouteFailed()
    }
    
    public func isWaypointChanged(_ waypoints: [[Double]]) {
        delegate?.isWaypointChanged(waypoints)
    }
    
    
    var id: String = ""
    var serviceManager: NavigationManager?
    public weak var delegate: JupiterServiceManagerDelegate?
    
    public init(id: String) {
        self.id = id
        self.serviceManager = NavigationManager(id: id)
        self.serviceManager?.delegate = self
    }
    
    deinit {
        TJJupiterLogger.i(tag: "JupiterServiceManager", message: "deinit")
        serviceManager?.delegate = nil
        delegate = nil

        serviceManager?.stopService(completion: { _, _ in })
    }
    
    public func startService(region: String = JupiterRegion.KOREA.rawValue, sectorId: Int, mode: UserMode, debugOption: Bool = false) {
        let userMode = mode.toJupiter()
        serviceManager?.startService(region: region, sectorId: sectorId, mode: userMode, debugOption: debugOption)
    }
    
    public func stopService(completion: @escaping (Bool, String) -> Void) {
        serviceManager?.stopService(completion: { _, _ in})
    }
    
    public func setNaviDestination(dest: Point) {
        let naviDest = dest.toJupiter()
        serviceManager?.setNaviDestination(dest: naviDest)
    }
    
    public func setNaviWaypoints(waypoints: [[Double]]) {
        serviceManager?.setNaviWaypoints(waypoints: waypoints)
    }
    
    public func requestRouting(start: RoutingStart, end: Point, waypoints: [Point] = [], completion: @escaping (RoutingResult?) -> Void) {
        let startPoint = start.toJupiter()
        let endPoint = end.toJupiter()
        let naviWaypoints = waypoints.map { $0.toJupiter() }
        serviceManager?.requestRouting(start: startPoint, end: endPoint, waypoints: naviWaypoints, completion: completion)
    }
    
    //MARK: - Simulation Mode
    public func setSimulationMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String) {
        serviceManager?.setSimulationMode(flag: flag, rfdFileName: rfdFileName, uvdFileName: uvdFileName, eventFileName: eventFileName)
    }
    
    public func setSimulationModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String) {
        serviceManager?.setSimulationModeLegacy(flag: flag, bleFileName: bleFileName, sensorFileName: sensorFileName)
    }
    
    public func setMockingMode() {
        serviceManager?.setMockingMode()
    }
}
