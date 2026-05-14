import XCTest
@testable import TJJupiterSDK
import TJLabsCommon
import TJLabsJupiter

private final class MockNavigationManager: JupiterNavigationServiceManaging {
    var delegate: (any NavigationManagerDelegate)?
    private(set) var startModes: [TJLabsCommon.UserMode] = []
    private(set) var stopCallCount = 0
    private var stopCompletion: ((Bool, String) -> Void)?
    
    func startService(mode: TJLabsCommon.UserMode) {
        startModes.append(mode)
    }
    
    func stopService(completion: @escaping (Bool, String) -> Void) {
        stopCallCount += 1
        stopCompletion = completion
    }
    
    func setNaviDestination(dest: TJLabsJupiter.Point, isVehicle: Bool) {}
    
    func setNaviWaypoints(waypoints: [[Double]]) {}
    
    func requestRouting(start: TJLabsJupiter.RoutingStart, end: TJLabsJupiter.Point, waypoints: [TJLabsJupiter.Point], is_vehicle: Bool, completion: @escaping (RoutingResult?, [NavigationLevelRoute]) -> Void) {}
    
    func setSimulationMode(flag: Bool, rfdFileName: String, uvdFileName: String, eventFileName: String) {}
    
    func setSimulationModeLegacy(flag: Bool, bleFileName: String, sensorFileName: String) {}
    
    func setMockingMode() {}
    
    func completeStop(success: Bool = true, message: String = "stopped") {
        let completion = stopCompletion
        stopCompletion = nil
        completion?(success, message)
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
        serviceManager.onJupiterSuccess(true, nil)
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
        serviceManager.onJupiterSuccess(true, nil)
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
        serviceManager.onJupiterSuccess(false, TJLabsJupiter.JupiterErrorCode.NOT_INITIALIZED)
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

        serviceManager.onInitSuccess(true, nil)
        XCTAssertEqual(navigationManager.stopCallCount, 0)

        serviceManager.onJupiterSuccess(true, nil)
        XCTAssertEqual(navigationManager.stopCallCount, 1)

        navigationManager.completeStop()

        wait(for: [stopCompletion], timeout: 1.0)
    }

    func testStopFailureDoesNotAutoRestartQueuedModeChange() {
        let navigationManager = MockNavigationManager()
        let serviceManager = JupiterServiceManager(id: "user", serviceManager: navigationManager)
        let stopCompletion = expectation(description: "stop failure completion")

        serviceManager.startService(mode: .MODE_PEDESTRIAN)
        serviceManager.onJupiterSuccess(true, nil)
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
}
