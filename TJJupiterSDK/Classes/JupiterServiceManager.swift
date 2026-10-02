import Foundation
import TJLabsCommon
import TJLabsJupiter

protocol JupiterNavigationServiceManaging: AnyObject {
    var delegate: (any NavigationManagerDelegate)? { get set }
    func initialize()
    func startService(mode: TJLabsCommon.UserMode, sectorId: Int?)
    func stopService(completion: @escaping (Bool, String, JupiterServiceResult) -> Void)
    func setNaviDestination(dest: TJLabsJupiter.Point, isVehicle: Bool)
    func setNaviWaypoints(waypoints: [[Double]])
    func requestRouting(start: TJLabsJupiter.RoutingStart, end: TJLabsJupiter.Point, waypoints: [TJLabsJupiter.Point], is_vehicle: Bool, completion: @escaping (RoutingResult?, [NavigationLevelRoute], TJLabsJupiter.NavigationRouteFailureReason?) -> Void)
    func setReplayMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String)
    func setReplayModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String)
    func setMockMode(mode: TJLabsJupiter.JupiterMockMode, sectorId: Int, completion: @escaping (Bool) -> Void)
    func setLSEAppName(name: String)
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

    // 서비스 요청 단위. mode 나 sectorId 가 바뀌면 다른 요청으로 보고 stop → start 로 전환한다.
    private struct ServiceRequest: Equatable {
        let mode: UserMode
        let sectorId: Int?
    }

    private enum LifecycleAction {
        case start(ServiceRequest)
        case stop
    }

    public static let sdkVersion = "2.0.20"
    private let lifecycleLock = NSLock()
    private var serviceState: ServiceState = .stopped
    private var activeRequest: ServiceRequest?
    private var desiredRequest: ServiceRequest?
    private var pendingStopCompletions: [(Bool, String) -> Void] = []
    private var didSetLSEAppName = false
    // Jupiter 의 활성 섹터. init 직후에는 첫 번째 섹터이며, start 성공 시 그 요청의 섹터로 바뀐다.
    private var currentSectorId: Int?
    // setMockMode 로 지정한 목업 데이터 섹터. 목업 모드에서는 Jupiter 와 같이 이 섹터가 start 의 기본 섹터다.
    private var mockSectorId: Int?
    
    public func onInitSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.InitErrorCode?, _ result: TJLabsJupiter.JupiterServiceResult) {
        if !isSuccess {
            handleStartFailure()
        }
        delegate?.onInitSuccess(isSuccess, code?.toWrap())
    }

    public func onJupiterSuccess(_ isSuccess: Bool, _ code: TJLabsJupiter.JupiterErrorCode?, _ result: TJLabsJupiter.JupiterServiceResult) {
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
    
    public func isNavigationRouteChanged(_ routes: [(String, String, Float, Float)]) {
        delegate?.isNavigationRouteChanged(routes)
    }
    
    public func isNavigationRouteFailed(_ reason: TJLabsJupiter.NavigationRouteFailureReason) {
        delegate?.isNavigationRouteFailed(reason.toWrap())
    }
    
    public func isWaypointChanged(_ waypoints: [[Double]]) {
        delegate?.isWaypointChanged(waypoints)
    }
    
    var id: String = ""
    let serviceManager: JupiterNavigationServiceManaging
    var isDev: Bool = false
    public weak var delegate: JupiterServiceManagerDelegate?
    
    /// 단일 섹터 초기화. `init(sectorIds: [sectorId])` 와 같다.
    public convenience init(id: String, region: String, sectorId: Int, debugOption: Bool = false) {
        self.init(id: id, region: region, sectorIds: [sectorId], debugOption: debugOption)
    }

    /// 멀티 섹터 초기화. `sectorIds` 의 리소스를 한 번에 로드하고, 첫 번째 섹터가 활성 섹터가 된다.
    /// 하나라도 로드에 실패하면 init 실패(`onInitSuccess(false, .LOAD_RESOURCE_FAIL)`)다.
    public init(id: String, region: String, sectorIds: [Int], debugOption: Bool = false) {
        let dev = tjBranch == .DEV
        self.isDev = tjBranch == .DEV

        JupiterLogger.setDebugOption(set: false)
        let navigationManager = NavigationManager(id: id, region: region, sectorIds: sectorIds, debugOption: debugOption, dev: dev)
        self.id = id
        self.serviceManager = navigationManager
        self.currentSectorId = sectorIds.first
        // 인증/네트워크 실패는 initialize() 안에서 동기적으로 통지되므로 delegate 를 먼저 연결한다.
        self.serviceManager.delegate = self
        self.serviceManager.initialize()
    }

    init(id: String, serviceManager: JupiterNavigationServiceManaging, sectorIds: [Int] = []) {
        self.id = id
        self.serviceManager = serviceManager
        self.currentSectorId = sectorIds.first
        self.serviceManager.delegate = self
    }
    
    deinit {
        TJJupiterLogger.i(tag: "JupiterServiceManager", message: "deinit")
        serviceManager.delegate = nil
        delegate = nil

        serviceManager.stopService(completion: { _, _, _ in })
    }
    
    /// 서비스를 시작한다. `sectorId` 가 nil 이면 현재 활성 섹터(목업 모드면 목업 데이터 섹터)로 시작한다.
    /// 실행 중에 다른 mode 나 다른 섹터로 호출하면 stop 후 그 요청으로 다시 시작한다.
    /// init 때 로드하지 않은 섹터면 `onJupiterSuccess(false, .INVALID_SECTOR)` 로 실패한다.
    public func startService(mode: UserMode, sectorId: Int? = nil) {
        lifecycleLock.sync {
            desiredRequest = ServiceRequest(mode: mode, sectorId: sectorId ?? mockSectorId ?? currentSectorId)
        }

        processLifecycleIfNeeded()
    }

    public func stopService(completion: @escaping (Bool, String) -> Void) {
        let shouldCompleteImmediately = lifecycleLock.sync { () -> Bool in
            desiredRequest = nil

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
        serviceManager.requestRouting(start: startPoint, end: endPoint, waypoints: naviWaypoints, is_vehicle: isVehicleMode) { result, _, _ in
            completion(result)
        }
    }
    
    public func setReplayMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String) {
        serviceManager.setReplayMode(flag: flag, rfdFileName: rfdFileName, uvdFileName: uvdFileName, eventFileName: eventFileName)
    }
    
    public func setReplayModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String) {
        serviceManager.setReplayModeLegacy(flag: flag, bleFileName: bleFileName, sensorFileName: sensorFileName)
    }
    
    /// 목업 시뮬레이션 데이터를 가져올 섹터를 지정한다. init 때 로드하지 않은 섹터면 `completion(false)`.
    /// `.NONE`(해제)이면 섹터를 쓰지 않는다.
    public func setMockMode(mode: JupiterMockMode, sectorId: Int, completion: @escaping (Bool) -> Void) {
        serviceManager.setMockMode(mode: mode.toJupiter(), sectorId: sectorId, completion: { [weak self] isSuccess in
            if isSuccess {
                self?.lifecycleLock.sync {
                    self?.mockSectorId = mode == .NONE ? nil : sectorId
                }
            }
            completion(isSuccess)
        })
    }

    private func handleStartSuccess() {
        lifecycleLock.sync {
            guard serviceState == .starting else { return }
            serviceState = .started
            if let sectorId = activeRequest?.sectorId {
                currentSectorId = sectorId
            }
        }

        processLifecycleIfNeeded()
    }
    
    private func handleStartFailure() {
        let stopCompletions = lifecycleLock.sync { () -> [(Bool, String) -> Void] in
            guard serviceState == .starting else { return [] }

            serviceState = .stopped
            activeRequest = nil
            desiredRequest = nil
            didSetLSEAppName = false

            let completions = pendingStopCompletions
            pendingStopCompletions.removeAll()
            return completions
        }

        stopCompletions.forEach { $0(true, "Service already stopped") }
    }

    private func handleStopCompletion(success: Bool, message: String) {
        let completions = lifecycleLock.sync { () -> [(Bool, String) -> Void] in
            guard serviceState == .stopping else { return [] }

            let completions = pendingStopCompletions
            pendingStopCompletions.removeAll()

            if success {
                serviceState = .stopped
                activeRequest = nil
                didSetLSEAppName = false
            } else if let activeRequest {
                serviceState = .started
                desiredRequest = activeRequest
            } else {
                serviceState = .stopped
                desiredRequest = nil
            }

            return completions
        }

        completions.forEach { $0(success, message) }
        processLifecycleIfNeeded()
    }
    
    private var isVehicleMode: Bool {
        lifecycleLock.sync {
            (desiredRequest ?? activeRequest)?.mode == .MODE_VEHICLE
        }
    }

    private func processLifecycleIfNeeded() {
        let action = lifecycleLock.sync {
            nextLifecycleAction()
        }
        
        switch action {
        case .start(let request):
            if !didSetLSEAppName {
                let suffix = self.isDev ? "dev" : "prod"
                let appName = JupiterReplayer.shared.replayMode ? "ios_jupiter_replay" : "ios_jupiter_\(suffix)"
                self.serviceManager.setLSEAppName(name: appName)
                didSetLSEAppName = true
            }
            serviceManager.startService(mode: request.mode.toJupiter(), sectorId: request.sectorId)
        case .stop:
            serviceManager.stopService { [weak self] success, message, _ in
                self?.handleStopCompletion(success: success, message: message)
            }
        case nil:
            break
        }
    }

    private func nextLifecycleAction() -> LifecycleAction? {
        switch serviceState {
        case .stopped:
            guard let desiredRequest else { return nil }
            serviceState = .starting
            activeRequest = desiredRequest
            return .start(desiredRequest)
        case .starting:
            return nil
        case .started:
            guard desiredRequest != activeRequest else { return nil }
            serviceState = .stopping
            return .stop
        case .stopping:
            return nil
        }
    }
}
