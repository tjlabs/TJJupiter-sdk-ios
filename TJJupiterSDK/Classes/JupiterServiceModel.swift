
import TJLabsCommon
import TJLabsJupiter

public protocol JupiterServiceManagerDelegate: AnyObject {
    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?)
    func onJupiterReport(_ code: JupiterServiceCode, _ msg: String)
    func onJupiterResult(_ result: JupiterResult)
    func isJupiterInOutStateChanged(_ state: InOutState)
    func isUserGuidanceOut()
    func isNavigationRouteChanged(_ routes: [(String, String, Int, Float, Float)])
    func isNavigationRouteFailed()
    func isWaypointChanged(_ waypoints: [[Double]])
}

public enum JupiterRegion: String {
    case KOREA = "KOREA"
    case US_EAST = "US_EAST"
    case CANADA = "CANADA"
}

public enum UserMode: String {
    case MODE_PEDESTRIAN = "PDR"
    case MODE_VEHICLE = "DR"
    case MODE_AUTO = "AUTO"
}

public enum InOutState: Int {
    case OUT_TO_IN = 0
    case INDOOR = 1
    case IN_TO_OUT = 2
    case OUTDOOR = 3
    case UNKNOWN = -1
}

public enum JupiterErrorCode: Int {
    case INVALID_ID = 0
    case INVALID_MODE = 1
    case NETWORK_DISCONNECT = 2
    case DUPLICATED_SERVICE = 3
    case LOGIN_FAIL = 4
    case GENERATOR_FAIL = 5
    case CALC_INIT_FAIL = 6
}

public enum JupiterServiceCode: Int {
    case SERVICE_FAIL = 0
    case SERVICE_SUCCESS = 1
    case BECOME_BACKGROUND = 2
    case BECOME_FOREGROUND = 3
    case BLUETOOTH_UNAVAILABLE = 4
    case BLUETOOTH_OFF = 5
    case BLUETOOTH_SCAN_STOP = 6
    case NETWORK_DISCONNECT = 7
}

public struct JupiterResult: Codable {
    public var mobile_time: Int
    public var index: Int
    public var building_name: String
    public var level_name: String
    public var jupiter_pos: Position
    public var navi_pos: Position?
    public var llh: LLH?
    public var velocity: Float
    public var is_vehicle: Bool
    public var is_indoor: Bool
    public var validity_flag: Int
}

public struct Position: Codable {
    public var x: Float
    public var y: Float
    public var heading: Float
}

public struct LLH: Codable {
    public var lat: Double
    public var lon: Double
    public var heading: Double
}

public struct RoutingStart: Codable {
    public let level_id: Int
    public let x: Int
    public let y: Int
    public var absolute_heading: Int
    
    public init(level_id: Int, x: Int, y: Int, absolute_heading: Int) {
        self.level_id = level_id
        self.x = x
        self.y = y
        self.absolute_heading = absolute_heading
    }
}

public struct Point: Codable {
    public let level_id: Int
    public let x: Int
    public let y: Int
    
    public init(level_id: Int, x: Int, y: Int) {
        self.level_id = level_id
        self.x = x
        self.y = y
    }
}
