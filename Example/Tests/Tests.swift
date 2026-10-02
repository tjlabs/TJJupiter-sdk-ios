import XCTest
@testable import TJJupiterSDK
import TJLabsCommon
import TJLabsJupiter

private func makeMockServiceResult(isSuccess: Bool = true) -> TJLabsJupiter.JupiterServiceResult {
    JupiterServiceResult(eventCode: nil, isSuccess: isSuccess, input: .stop)
}

private final class MockNavigationManager: JupiterNavigationServiceManaging {

    var delegate: (any NavigationManagerDelegate)?
    private(set) var initializeCallCount = 0
    private(set) var startModes: [TJLabsCommon.UserMode] = []
    private(set) var startSectorIds: [Int?] = []
    private(set) var stopCallCount = 0
    private var stopCompletion: ((Bool, String, JupiterServiceResult) -> Void)?
    var mockModeResult = true

    func initialize() {
        initializeCallCount += 1
    }

    func startService(mode: TJLabsCommon.UserMode, sectorId: Int?) {
        startModes.append(mode)
        startSectorIds.append(sectorId)
    }

    func stopService(completion: @escaping (Bool, String, JupiterServiceResult) -> Void) {
        stopCallCount += 1
        stopCompletion = completion
    }
    
    func setNaviDestination(dest: TJLabsJupiter.Point, isVehicle: Bool) {}
    
    func setNaviWaypoints(waypoints: [[Double]]) {}
    
    func requestRouting(start: TJLabsJupiter.RoutingStart, end: TJLabsJupiter.Point, waypoints: [TJLabsJupiter.Point], is_vehicle: Bool, completion: @escaping (RoutingResult?, [NavigationLevelRoute], TJLabsJupiter.NavigationRouteFailureReason?) -> Void) {}
    
    func setReplayMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String) {}
    
    func setReplayModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String) {}
    
    func setMockMode(mode: TJLabsJupiter.JupiterMockMode, sectorId: Int, completion: @escaping (Bool) -> Void) {
        completion(mockModeResult)
    }
    
    func setLSEAppName(name: String) {
        
    }
    
    func completeStop(success: Bool = true, message: String = "stopped") {
        let completion = stopCompletion
        stopCompletion = nil
        completion?(success, message, makeMockServiceResult(isSuccess: success))
    }
}

final class Tests: XCTestCase {
    func testRepeatedStartDoesNotForwardDuplicateRequest() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        
        serviceManager.startService(mode: .MODE_AUTO)
        serviceManager.startService(mode: .MODE_AUTO)
        
        XCTAssertEqual(navigationManager.startModes, [.MODE_AUTO])
    }
    
    func testRepeatedStopMergesIntoSingleFrameworkStop() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        let firstCompletion = expectation(description: "first stop completion")
        let secondCompletion = expectation(description: "second stop completion")
        
        serviceManager.startService(mode: .MODE_AUTO)
        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        serviceManager.stopService { success, message in
            XCTAssertTrue(success)
            XCTAssertEqual(message, "stopped")
            firstCompletion.fulfill()
        }
        serviceManager.stopService { success, message in
            XCTAssertTrue(success)
            XCTAssertEqual(message, "stopped")
            secondCompletion.fulfill()
        }
        
        XCTAssertEqual(navigationManager.stopCallCount, 1)
        
        navigationManager.completeStop()
        
        wait(for: [firstCompletion, secondCompletion], timeout: 1.0)
    }
    
    func testStartDuringStopRestartsAfterStopCompletion() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        
        serviceManager.startService(mode: .MODE_PEDESTRIAN)
        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        serviceManager.stopService { _, _ in }
        serviceManager.startService(mode: .MODE_VEHICLE)
        
        XCTAssertEqual(navigationManager.startModes, [.MODE_PEDESTRIAN])
        XCTAssertEqual(navigationManager.stopCallCount, 1)
        
        navigationManager.completeStop()
        
        XCTAssertEqual(navigationManager.startModes, [.MODE_PEDESTRIAN, .MODE_VEHICLE])
    }
    
    func testFailedStartAllowsRetry() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        
        serviceManager.startService(mode: .MODE_AUTO)
        serviceManager.onJupiterSuccess(false, TJLabsJupiter.JupiterErrorCode.NOT_INITIALIZED, makeMockServiceResult(isSuccess: false))
        serviceManager.startService(mode: .MODE_AUTO)
        
        XCTAssertEqual(navigationManager.startModes, [.MODE_AUTO, .MODE_AUTO])
    }

    func testStopDuringStartWaitsForJupiterSuccessBeforeForwardingStop() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        let stopCompletion = expectation(description: "stop completion")

        serviceManager.startService(mode: .MODE_AUTO)
        serviceManager.stopService { success, message in
            XCTAssertTrue(success)
            XCTAssertEqual(message, "stopped")
            stopCompletion.fulfill()
        }

        XCTAssertEqual(navigationManager.stopCallCount, 0)

        serviceManager.onInitSuccess(true, nil, makeMockServiceResult())
        XCTAssertEqual(navigationManager.stopCallCount, 0)

        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        XCTAssertEqual(navigationManager.stopCallCount, 1)

        navigationManager.completeStop()

        wait(for: [stopCompletion], timeout: 1.0)
    }

    func testStopFailureDoesNotAutoRestartQueuedModeChange() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        let stopCompletion = expectation(description: "stop failure completion")

        serviceManager.startService(mode: .MODE_PEDESTRIAN)
        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        serviceManager.stopService { success, message in
            XCTAssertFalse(success)
            XCTAssertEqual(message, "stop failed")
            stopCompletion.fulfill()
        }
        serviceManager.startService(mode: .MODE_VEHICLE)

        XCTAssertEqual(navigationManager.stopCallCount, 1)

        navigationManager.completeStop(success: false, message: "stop failed")

        XCTAssertEqual(navigationManager.startModes, [.MODE_PEDESTRIAN])
        wait(for: [stopCompletion], timeout: 1.0)
    }

    // MARK: - Multi sector

    func testStartWithoutSectorUsesFirstLoadedSector() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager, sectorIds: [10, 20])

        serviceManager.startService(mode: .MODE_AUTO)

        XCTAssertEqual(navigationManager.startSectorIds, [10])
    }

    func testStartWithDifferentSectorRestartsWithThatSector() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager, sectorIds: [10, 20])

        serviceManager.startService(mode: .MODE_AUTO, sectorId: 10)
        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        serviceManager.startService(mode: .MODE_AUTO, sectorId: 20)

        XCTAssertEqual(navigationManager.stopCallCount, 1)

        navigationManager.completeStop()

        XCTAssertEqual(navigationManager.startSectorIds, [10, 20])
    }

    func testStartWithoutSectorKeepsCurrentActiveSector() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager, sectorIds: [10, 20])

        serviceManager.startService(mode: .MODE_AUTO, sectorId: 20)
        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        serviceManager.startService(mode: .MODE_AUTO)

        XCTAssertEqual(navigationManager.stopCallCount, 0)

        // stop 후 섹터 없이 다시 시작하면 마지막으로 시작한 섹터(20)로 시작한다.
        serviceManager.stopService { _, _ in }
        navigationManager.completeStop()
        serviceManager.startService(mode: .MODE_AUTO)

        XCTAssertEqual(navigationManager.startSectorIds, [20, 20])
    }

    func testStartWithoutSectorUsesMockSectorInMockMode() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager, sectorIds: [10, 20])

        serviceManager.setMockMode(mode: .VEHICLE_INDOOR_OUTDOOR, sectorId: 20) { _ in }
        serviceManager.startService(mode: .MODE_VEHICLE)
        serviceManager.onJupiterSuccess(true, nil, makeMockServiceResult())
        serviceManager.stopService { _, _ in }
        navigationManager.completeStop()

        // 목업 해제 후에는 현재 활성 섹터(목업으로 시작한 20)를 그대로 쓴다.
        serviceManager.setMockMode(mode: .NONE, sectorId: 20) { _ in }
        serviceManager.startService(mode: .MODE_VEHICLE)

        XCTAssertEqual(navigationManager.startSectorIds, [20, 20])
    }

    func testFailedMockModeDoesNotChangeStartSector() {
        let navigationManager = MockNavigationManager()
        navigationManager.mockModeResult = false
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager, sectorIds: [10, 20])

        serviceManager.setMockMode(mode: .VEHICLE_INDOOR_OUTDOOR, sectorId: 30) { isSuccess in
            XCTAssertFalse(isSuccess)
        }
        serviceManager.startService(mode: .MODE_VEHICLE)

        XCTAssertEqual(navigationManager.startSectorIds, [10])
    }

    func testInvalidSectorStartFailureAllowsRetry() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager, sectorIds: [10, 20])

        serviceManager.startService(mode: .MODE_AUTO, sectorId: 99)
        serviceManager.onJupiterSuccess(false, TJLabsJupiter.JupiterErrorCode.INVALID_SECTOR, makeMockServiceResult(isSuccess: false))
        serviceManager.startService(mode: .MODE_AUTO, sectorId: 20)

        XCTAssertEqual(navigationManager.startSectorIds, [99, 20])
    }

    func testWrapperConvertsNewJupiterValues() {
        XCTAssertEqual(TJLabsJupiter.JupiterErrorCode.INVALID_SECTOR.toWrap(), .INVALID_SECTOR)
        XCTAssertEqual(TJLabsJupiter.JupiterServiceCode.UVD_STOPPED.toWrap(), .UVD_STOPPED)
        XCTAssertEqual(TJLabsJupiter.JupiterServiceCode.BUILDING_LEVEL_CHANGING.toWrap(), .BUILDING_LEVEL_CHANGING)
        XCTAssertEqual(TJLabsJupiter.NavigationRouteFailureReason.networkError.toWrap(), .networkError)
        XCTAssertEqual(JupiterRegion.SAUDI.toJupiter(), .SAUDI)

        let result = TJLabsJupiter.JupiterResult(
            mobile_time: 1, index: 2, building_name: "B", level_name: "L",
            jupiter_pos: TJLabsJupiter.Position(x: 1, y: 2, heading: 3),
            remaining_distance: 365,
            velocity: 0, is_vehicle: true, is_indoor: true, validity_flag: 1
        )
        XCTAssertEqual(result.toWrap().remaining_distance, 365)
        XCTAssertEqual(result.toWrap().toJupiter().remaining_distance, 365)
    }
}
