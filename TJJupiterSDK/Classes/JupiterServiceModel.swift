
import TJLabsCommon
import TJLabsJupiter

public protocol JupiterServiceManagerDelegate: AnyObject {
    func onInitSuccess(_ isSuccess: Bool, _ code: InitErrorCode?)
    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?)
    func onJupiterReport(_ code: JupiterServiceCode, _ msg: String)
    func onJupiterResult(_ result: JupiterResult)
    func isJupiterInOutStateChanged(_ state: InOutState)
    func isUserGuidanceOut()
    func isUserArrived()
    func isNavigationRouteChanged(_ routes: [(String, String, Float, Float)])
    func isNavigationRouteFailed(_ reason: NavigationRouteFailureReason)
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
    case UNKNOWN = -1
    case OUT_TO_IN = 0
    case INDOOR = 1
    case IN_TO_OUT = 2
    case OUTDOOR = 3
}

public enum InitErrorCode: Int {
    case UNKNOWN = -1
    case NOT_AUTHORIZED = 0
    case INVALID_ID = 1
    case NETWORK_DISCONNECT = 2
    case LOGIN_FAIL = 3
    case LOAD_RESOURCE_FAIL = 4
}

public enum JupiterErrorCode: Int {
    case UNKNOWN = -1
    case NOT_INITIALIZED = 0
    case DUPLICATED_SERVICE = 1
    case GENERATOR_FAIL = 2
}

public enum JupiterServiceCode: Int {
    case UNKNOWN = -1
    case SERVICE_FAIL = 0
    case SERVICE_SUCCESS = 1
    case BECOME_BACKGROUND = 2
    case BECOME_FOREGROUND = 3
    case BLUETOOTH_UNAVAILABLE = 4
    case BLUETOOTH_OFF = 5
    case BLUETOOTH_SCAN_STOP = 6
    case NETWORK_DISCONNECT = 7
    case GET_FIRST_RESULT = 8
    case PEAK_DETECTED = 300
}

public enum NavigationRouteFailureReason: String, Codable {
    case unknown = "unknown"
    case serverResponse = "server_response"
    case tooClose = "too_close"
}

public enum JupiterMockMode: String {
    case NONE = "NONE"
    case VEHICLE_INDOOR_OUTDOOR = "indoor_outdoor"
    case VEHICLE_OUTDOOR_PARKING = "outdoor_parking"
    case PEDESTRIAN_INDOOR_PARKING = "indoor_parking"
    case PEDESTRIAN_PARKING_INDOOR = "parking_indoor"
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
    public var azimuth: Double
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
