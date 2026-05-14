
import Foundation
import TJLabsCommon
import TJLabsJupiter

protocol JupiterNavigationServiceManaging: AnyObject {
    var delegate: (any NavigationManagerDelegate)? { get set }
    func startService(mode: TJLabsCommon.UserMode)
    func stopService(completion: @escaping (Bool, String) -> Void)
    func setNaviDestination(dest: TJLabsJupiter.Point, isVehicle: Bool)
    func setNaviWaypoints(waypoints: [[Double]])
    func requestRouting(start: TJLabsJupiter.RoutingStart, end: TJLabsJupiter.Point, waypoints: [TJLabsJupiter.Point], is_vehicle: Bool, completion: @escaping (RoutingResult?, [NavigationLevelRoute]) -> Void)
    func setSimulationMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String)
    func setSimulationModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String)
    func setMockingMode()
}

extension NavigationManager: JupiterNavigationServiceManaging {}

private extension NSLock {
    func sync<T>(_ work: () -> T) -> T {
        lock()
        defer { unlock() }
        return work()
    }
}

public class JupiterServiceManager: NavigationManagerDelegate {
    private enum ServiceState {
        case stopped
        case starting
        case started
        case stopping
    }

    private enum LifecycleAction {
        case start(UserMode)
        case stop
    }
    
    public static let sdkVersion = "2.0.1"
    private let lifecycleLock = NSLock()
    private var serviceState: ServiceState = .stopped
    private var activeMode: UserMode?
    private var desiredMode: UserMode?
    private var pendingStopCompletions: [(Bool, String) -> Void] = []
    
    public func onInitSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.InitErrorCode?) {
        if !isSuccess {
            handleStartFailure()
        }
        delegate?.onInitSuccess(isSuccess, code?.toWrap())
    }
    
    public func onJupiterSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.JupiterErrorCode?) {
        if isSuccess {
            handleStartSuccess()
        } else {
            handleStartFailure()
        }
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
    
    public func isUserArrived() {
        delegate?.isUserArrived()
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
    let serviceManager: JupiterNavigationServiceManaging
    public weak var delegate: JupiterServiceManagerDelegate?
    
    public init(id: String, region: String, sectorId: Int, debugOption: Bool) {
        let navigationManager = NavigationManager(id: id, region: region, sectorId: sectorId, debugOption: debugOption)
        self.id = id
        self.serviceManager = navigationManager
        self.serviceManager.delegate = self
    }
    
    init(id: String, serviceManager: JupiterNavigationServiceManaging) {
        self.id = id
        self.serviceManager = serviceManager
        self.serviceManager.delegate = self
    }
    
    deinit {
        TJJupiterLogger.i(tag: "JupiterServiceManager", message: "deinit")
        serviceManager.delegate = nil
        delegate = nil

        serviceManager.stopService(completion: { _, _ in })
    }
    
    public func startService(mode: UserMode) {
        lifecycleLock.sync {
            desiredMode = mode
        }

        processLifecycleIfNeeded()
    }
    
    public func stopService(completion: @escaping (Bool, String) -> Void) {
        let shouldCompleteImmediately = lifecycleLock.sync { () -> Bool in
            desiredMode = nil

            switch serviceState {
            case .stopped:
                return true
            case .starting, .started, .stopping:
                pendingStopCompletions.append(completion)
                return false
            }
        }

        if shouldCompleteImmediately {
            completion(true, "Service already stopped")
            return
        }

        processLifecycleIfNeeded()
    }
    
    public func setNaviDestination(dest: Point) {
        let naviDest = dest.toJupiter()
        serviceManager.setNaviDestination(dest: naviDest, isVehicle: isVehicleMode)
    }
    
    public func setNaviWaypoints(waypoints: [[Double]]) {
        serviceManager.setNaviWaypoints(waypoints: waypoints)
    }
    
    public func requestRouting(start: RoutingStart, end: Point, waypoints: [Point] = [], completion: @escaping (RoutingResult?) -> Void) {
        let startPoint = start.toJupiter()
        let endPoint = end.toJupiter()
        let naviWaypoints = waypoints.map { $0.toJupiter() }
        serviceManager.requestRouting(start: startPoint, end: endPoint, waypoints: naviWaypoints, is_vehicle: isVehicleMode) { result, _ in
            completion(result)
        }
    }
    
    //MARK: - Simulation Mode
    public func setSimulationMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String) {
        serviceManager.setSimulationMode(flag: flag, rfdFileName: rfdFileName, uvdFileName: uvdFileName, eventFileName: eventFileName)
    }
    
    public func setSimulationModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String) {
        serviceManager.setSimulationModeLegacy(flag: flag, bleFileName: bleFileName, sensorFileName: sensorFileName)
    }
    
    public func setMockingMode() {
        serviceManager.setMockingMode()
    }
    
    private func handleStartSuccess() {
        lifecycleLock.sync {
            guard serviceState == .starting else { return }
            serviceState = .started
        }

        processLifecycleIfNeeded()
    }
    
    private func handleStartFailure() {
        let stopCompletions = lifecycleLock.sync { () -> [(Bool, String) -> Void] in
            guard serviceState == .starting else { return [] }

            serviceState = .stopped
            activeMode = nil

            guard desiredMode == nil else { return [] }

            let completions = pendingStopCompletions
            pendingStopCompletions.removeAll()
            return completions
        }

        stopCompletions.forEach { $0(true, "Service already stopped") }
        processLifecycleIfNeeded()
    }

    private func handleStopCompletion(success: Bool, message: String) {
        let completions = lifecycleLock.sync { () -> [(Bool, String) -> Void] in
            guard serviceState == .stopping else { return [] }

            let completions = pendingStopCompletions
            pendingStopCompletions.removeAll()

            if success {
                serviceState = .stopped
                activeMode = nil
            } else if let activeMode {
                serviceState = .started
                desiredMode = activeMode
            } else {
                serviceState = .stopped
                desiredMode = nil
            }

            return completions
        }

        completions.forEach { $0(success, message) }
        processLifecycleIfNeeded()
    }
    
    private var isVehicleMode: Bool {
        lifecycleLock.sync {
            (desiredMode ?? activeMode) == .MODE_VEHICLE
        }
    }

    private func processLifecycleIfNeeded() {
        let action = lifecycleLock.sync {
            nextLifecycleAction()
        }

        switch action {
        case .start(let mode):
            serviceManager.startService(mode: mode.toJupiter())
        case .stop:
            serviceManager.stopService { [weak self] success, message in
                self?.handleStopCompletion(success: success, message: message)
            }
        case nil:
            break
        }
    }

    private func nextLifecycleAction() -> LifecycleAction? {
        switch serviceState {
        case .stopped:
            guard let desiredMode else { return nil }
            serviceState = .starting
            activeMode = desiredMode
            return .start(desiredMode)
        case .starting:
            return nil
        case .started:
            guard desiredMode != activeMode else { return nil }
            serviceState = .stopping
            return .stop
        case .stopping:
            return nil
        }
    }
}
