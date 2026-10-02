# TJJupiterSDK
### Version 2.0.20

[![Version](https://img.shields.io/cocoapods/v/TJJupiterSDK.svg?style=flat)](https://cocoapods.org/pods/TJJupiterSDK)
[![License](https://img.shields.io/cocoapods/l/TJJupiterSDK.svg?style=flat)](https://cocoapods.org/pods/TJJupiterSDK)
[![Platform](https://img.shields.io/cocoapods/p/TJJupiterSDK.svg?style=flat)](https://cocoapods.org/pods/TJJupiterSDK)

TJJupiterSDK is an iOS SDK that provides Jupiter-based indoor service features such as service lifecycle management, positioning result delivery, navigation destination updates, routing requests, and mocking mode support.

TJJupiterSDK is an iOS SDK that provides Jupiter-based indoor positioning and navigation services.

It delivers real-time indoor location results, navigation routing, and movement tracking using BLE signals and sensor fusion.

---

## ✨ Features

- 📍 Indoor positioning (BLE + Sensor fusion)
- 🚶 Pedestrian / 🚗 Vehicle mode support
- 🧭 Navigation routing (start / destination / waypoint)
- 🔄 Real-time positioning result stream
- 🏢 Indoor / Outdoor state detection

---

## 📦 Requirements

- iOS 15.0+
- Swift 5.0+
- Info.plist
    - Privacy - Motion Usage Description
    - Privacy - Bluetooth Peripheral Usage Description
    - Privacy - Bluetooth Always Usage Description
    - Privacy - Location When In Usage Description
    - Required device capabilities
        - item : Accelerometer
        - item : Gyroscope
        - item : Magnetometer
        - item : Bluetooth Low Energy
    - Required background modes
        - App communicates using CoreBluetooth
        - App registers for location updates

---

## 🚀 Installation

### CocoaPods

```ruby
pod 'TJJupiterSDK'
```
If you cannot find TJJupiterSDK in pod. Write below line in podfile.

```ruby
source '<https://github.com/CocoaPods/Specs.git>'
```

---

## 🔄 Migration Guide (2.0.17 → 2.0.20)

If you are upgrading from 2.0.17 or earlier, check the items below. Existing single-sector code keeps working except for **Breaking Changes**.

### ⚠️ Breaking Changes

| Before (≤ 2.0.17) | After (2.0.20) | Action |
|---|---|---|
| `setMockMode(mode:completion:)` | `setMockMode(mode:sectorId:completion:)` | Pass the sector whose simulation data to use. See [Mocking Mode](#-mocking-mode). |

New enum cases were added (see below). If you `switch` over these enums **exhaustively without `default`**, add the new cases:

| Enum | Added cases |
|---|---|
| `JupiterErrorCode` | `INVALID_SECTOR = 3` |
| `JupiterServiceCode` | `UVD_STOPPED = 301`, `BUILDING_LEVEL_CHANGING = 302` |
| `NavigationRouteFailureReason` | `networkError` |
| `JupiterRegion` | `SAUDI` |

### 🔁 Behavior Changes

- **`stopService` resets the navigation session.** The destination and route set before stopping are cleared. Call `setNaviDestination` again after restarting.
- **Initialization failures are now always delivered.** Previously, `onInitSuccess(false, ...)` for authorization or network failures could be missed because the delegate was connected after initialization started. Make sure `onInitSuccess` handles failures.
- **Network failures during routing are reported as `networkError`.** They were previously reported as `unknown`.
- **Codes not defined in 2.0.17 are delivered as-is** instead of `UNKNOWN` (`UVD_STOPPED`, `BUILDING_LEVEL_CHANGING`, `INVALID_SECTOR`).

### ✨ New Features

- **Multi-sector support.** Load several sectors once and switch between them without re-initializing. See [Initialize Service](#4-initialize-service) and [Start Service](#5-start-service).
    - `JupiterServiceManager(id:region:sectorIds:debugOption:)`
    - `startService(mode:sectorId:)` — `sectorId` is optional; omit it to use the current active sector.
    - The single-sector `JupiterServiceManager(id:region:sectorId:debugOption:)` still works.

### 📝 Documentation Fixes

- The `InitErrorCode` and `JupiterErrorCode` tables in the previous README did not match the SDK. They are corrected in [Core Enums](#-core-enums). The SDK values themselves did not change.
- The previous Example used an API that no longer existed (`startService(region:sectorId:mode:debugOption:)`). It is updated in [Example](#-example).

---

## 🏁 Guide
- If you need a more detailed guide, please refer to this link.
- https://www.notion.so/tjlabs/TJLABS-TJJupiterSDK-Guide-336aef6d5b728030b9f2d6354a6e23ca?source=copy_link

### 1. Import

```swift
import TJJupiterSDK
```

### 2. Server Configuration (Dev / Prod)
- Use `setServerConfig(branch:)` to select which server environment the SDK connects to.
- ⚠️ **This must be called before authentication (`auth`).** Calling it after `auth` has no effect on the authentication request.
- If you **do not** call `setServerConfig(branch:)`, the SDK connects to the **production (`.PROD`) server by default**.
- Use `.DEV` only for development/testing against the dev server.

```swift
public enum ServerBranch {
    case DEV
    case PROD
}
```

```swift
// Call BEFORE auth. Skip this call to use PROD automatically.
TJJupiterAuth.shared.setServerConfig(branch: .DEV)   // or .PROD
```

### 3. Authentication
- You must obtain a token to use the SDK.
- The link below is a guide to the token issuance process.
- https://www.notion.so/tjlabs/SDK-Authorization-33eaef6d5b728034856ddc23489588f0?source=copy_link
  
```swift
TJJupiterAuth.shared.auth(
    accessKey: "YOUR_ACCESS_KEY",
    secretAccessKey: "YOUR_SECRET_ACCESS_KEY"
) { code, success in
    print("Auth:", success)
}
```

### 4. Initialize Service

```swift
// Single sector
let manager = JupiterServiceManager(
    id: "USER_ID",
    region: JupiterRegion.KOREA.rawValue,
    sectorId: 123,
    debugOption: false
)
manager.delegate = self

// Multiple sectors: resources for all sectors are loaded once at initialization.
// The first sector becomes the active sector. If any sector fails to load, initialization fails.
let multiSectorManager = JupiterServiceManager(
    id: "USER_ID",
    region: JupiterRegion.KOREA.rawValue,
    sectorIds: [123, 456],
    debugOption: false
)
```

### 5. Start Service

```swift
// Start with the current active sector (the first sector right after initialization)
manager.startService(mode: .MODE_AUTO)

// Start with a specific sector loaded at initialization
manager.startService(mode: .MODE_AUTO, sectorId: 456)
```

- Positioning runs on one active sector at a time. To switch sectors, call `startService` with another `sectorId`; a running service is stopped and restarted on that sector without reloading resources.
- A sector that was not loaded at initialization fails with `onJupiterSuccess(false, .INVALID_SECTOR)`.
- `stopService` resets the navigation session (destination and route). Set the destination again after restarting.

### 6. Stop Service

```swift
manager.stopService { success, message in
    print("Stopped:", success)
}
```

---

## 📡 Delegate

```swift
extension ViewController: JupiterServiceManagerDelegate {

    func onInitSuccess(_ isSuccess: Bool, _ code: InitErrorCode?) {}

    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?) {}

    func onJupiterReport(_ code: JupiterServiceCode, _ msg: String) {}

    func onJupiterResult(_ result: JupiterResult) {}

    func isJupiterInOutStateChanged(_ state: InOutState) {}

    func isUserGuidanceOut() {}

    func isUserArrived() {}

    func isNavigationRouteChanged(_ routes: [(String, String, Float, Float)]) {}

    func isNavigationRouteFailed(_ reason: NavigationRouteFailureReason) {}

    func isWaypointChanged(_ waypoints: [[Double]]) {}
}
```

---


## 📚 Position Result

### JupiterResult

```swift
public struct JupiterResult: Codable {
    public var mobile_time: Int
    public var index: Int
    public var building_name: String
    public var level_name: String
    public var jupiter_pos: Position
    public var navi_pos: Position?
    public var remaining_distance: Int?   // meters to the destination (vehicle mode with a route only)
    public var llh: LLH?
    public var velocity: Float
    public var is_vehicle: Bool
    public var is_indoor: Bool
    public var validity_flag: Int
}
```

### Position

```swift
public struct Position {
    public var x: Float
    public var y: Float
    public var heading: Float
}
```

### LLH

```swift
public struct LLH {
    public var lat: Double
    public var lon: Double
    public var azimuth: Double
}
```

## 📚 Core Enums

### JupiterRegion

```swift
public enum JupiterRegion: String {
    case KOREA
    case US_EAST
    case CANADA
    case SAUDI
}
```

### UserMode

```swift
public enum UserMode: String {
    case MODE_PEDESTRIAN = "PDR"
    case MODE_VEHICLE = "DR"
    case MODE_AUTO = "AUTO"
}
```

### InOutState

```swift
public enum InOutState: Int {
    case UNKNOWN = -1
    case OUT_TO_IN = 0
    case INDOOR = 1
    case IN_TO_OUT = 2
    case OUTDOOR = 3
}
```

### InitErrorCode

```swift
public enum InitErrorCode: Int {
    case UNKNOWN = -1
    case NOT_AUTHORIZED = 0
    case INVALID_ID = 1
    case NETWORK_DISCONNECT = 2
    case LOGIN_FAIL = 3
    case LOAD_RESOURCE_FAIL = 4
}
```

### JupiterErrorCode

```swift
public enum JupiterErrorCode: Int {
    case UNKNOWN = -1
    case NOT_INITIALIZED = 0
    case DUPLICATED_SERVICE = 1
    case GENERATOR_FAIL = 2
    case INVALID_SECTOR = 3   // sectorId was not loaded at initialization
}
```

### JupiterServiceCode

```swift
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
    case UVD_STOPPED = 301
    case BUILDING_LEVEL_CHANGING = 302
}
```

### NavigationRouteFailureReason

```swift
public enum NavigationRouteFailureReason: String {
    case unknown = "unknown"
    case serverResponse = "server_response"
    case networkError = "network_error"
    case tooClose = "too_close"
}
```

---

## 🦿 Mocking Mode

- Since Jupiter performs positioning based on TJLABS' BLE beacons, it cannot receive indoor location data outside of the actual service area.
- If you use the mocking mode below, you can receive a randomly defined JupiterResult even outside the service area.
- Specify the sector whose simulation data is used. It must be a sector loaded at initialization; otherwise `success` is false.
- In mock mode, `startService` without a `sectorId` starts on the mock sector.

```swift
manager.setMockMode(mode: .VEHICLE_INDOOR_OUTDOOR, sectorId: 123) { success in
    print("Mock mode:", success)
}
```

---

## 📌 Example

- Sample code is below.
- For a more detailed example, please refer to the demo project at the link below.
- https://github.com/tjlabs/TJJupiter-demo-ios
  
```swift
final class ViewController: UIViewController, JupiterServiceManagerDelegate {

    private var manager: JupiterServiceManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        TJJupiterAuth.shared.auth(
            accessKey: "KEY",
            secretAccessKey: "SECRET"
        ) { [weak self] _, success in

            guard success else { return }

            let manager = JupiterServiceManager(
                id: "USER_ID",
                region: JupiterRegion.KOREA.rawValue,
                sectorIds: [123, 456],
                debugOption: false
            )
            manager.delegate = self

            manager.startService(mode: .MODE_AUTO, sectorId: 123)

            self?.manager = manager
        }
    }
}
```

---

## 📄 License

TJJupiterSDK is proprietary software provided by TJLabs under a separate commercial license agreement. Redistribution is not permitted except as agreed in writing.
