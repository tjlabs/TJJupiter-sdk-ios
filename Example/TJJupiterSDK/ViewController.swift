
import UIKit
import TJJupiterSDK

class ViewController: UIViewController, JupiterServiceManagerDelegate {
    
    func onInitSuccess(_ isSuccess: Bool, _ code: TJJupiterSDK.InitErrorCode?) {
        // TODO
    }
    
    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?) {
        // TODD
    }
    
    func onJupiterReport(_ code: JupiterServiceCode, _ msg: String) {
        // TODD
    }
    
    func onJupiterResult(_ result: JupiterResult) {
        // TODD
    }
    
    func isJupiterInOutStateChanged(_ state: InOutState) {
        // TODD
    }
    
    func isUserGuidanceOut() {
        // TODD
    }
    
    func isUserArrived() {
        // TODO
    }
    
    func isNavigationRouteChanged(_ routes: [(String, String, Int, Float, Float)]) {
        // TODO
    }
    
    func isNavigationRouteFailed() {
        // TODO
    }
    
    func isWaypointChanged(_ waypoints: [[Double]]) {
        // TODO
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    var serviceManager: JupiterServiceManager?
    
    func initialize() {
        let userId = "TJJupiterExample"
        serviceManager = JupiterServiceManager(id: userId, region: JupiterRegion.KOREA.rawValue, sectorId: 20, debugOption: false)
        serviceManager?.delegate = self
    }
    
    func start() {
        serviceManager?.startService(mode: .MODE_VEHICLE)
    }
}

