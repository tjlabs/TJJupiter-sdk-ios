# TJJupiterSDK
### Version 2.0.0

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

---

## 🚀 Installation

### CocoaPods

```ruby
pod 'TJJupiterSDK'
```

---

## 🏁 Guide
- If you need a more detailed guide, please refer to this link.
- https://www.notion.so/tjlabs/TJLABS-TJJupiterSDK-Guide-336aef6d5b728030b9f2d6354a6e23ca?source=copy_link

### 1. Import

```swift
import TJJupiterSDK
```

### 2. Authentication

```swift
TJJupiterAuth.shared.auth(
    accessKey: "YOUR_ACCESS_KEY",
    secretAccessKey: "YOUR_SECRET_ACCESS_KEY"
) { code, success in
    print("Auth:", success)
}
```

### 3. Initialize Service

```swift
let manager = JupiterServiceManager(id: "USER_ID")
manager.delegate = self
```

### 4. Start Service

```swift
manager.startService(
    region: JupiterRegion.KOREA.rawValue,
    sectorId: 123,
    mode: .MODE_AUTO,
    debugOption: false
)
```

### 5. Stop Service

```swift
manager.stopService { success, message in
    print("Stopped:", success)
}
```

---

## 📡 Delegate

```swift
extension ViewController: JupiterServiceManagerDelegate {

    func onJupiterSuccess(_ isSuccess: Bool, _ code: JupiterErrorCode?) {}

    func onJupiterReport(_ code: JupiterServiceCode, _ msg: String) {}

    func onJupiterResult(_ result: JupiterResult) {}

    func isJupiterInOutStateChanged(_ state: InOutState) {}

    func isUserGuidanceOut() {}

    func isNavigationRouteChanged(_ routes: [(String, String, Int, Float, Float)]) {}

    func isNavigationRouteFailed() {}

    func isWaypointChanged(_ waypoints: [[Double]]) {}
}
```

---


## 🧭 Navigation

- It is not supported yet.
  
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
    public var heading: Double
}
```

## 📚 Core Enums

### JupiterRegion

```swift
public enum JupiterRegion: String {
    case KOREA
    case US_EAST
    case CANADA
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
    case OUT_TO_IN = 0
    case INDOOR = 1
    case IN_TO_OUT = 2
    case OUTDOOR = 3
    case UNKNOWN = -1
}
```

### JupiterErrorCode

```swift
public enum JupiterErrorCode: Int {
    case INVALID_ID
    case INVALID_MODE
    case NETWORK_DISCONNECT
    case DUPLICATED_SERVICE
    case LOGIN_FAIL
    case GENERATOR_FAIL
    case CALC_INIT_FAIL
}
```

### JupiterServiceCode

```swift
public enum JupiterServiceCode: Int {
    case SERVICE_FAIL
    case SERVICE_SUCCESS
    case BECOME_BACKGROUND
    case BECOME_FOREGROUND
    case BLUETOOTH_UNAVAILABLE
    case BLUETOOTH_OFF
    case BLUETOOTH_SCAN_STOP
    case NETWORK_DISCONNECT
}
```

---

## 🦿 Mocking Mode

- Since Jupiter performs positioning based on TJLABS' BLE beacons, it cannot receive indoor location data outside of the actual service area.
- If you use the mocking mode below, you can receive a randomly defined JupiterResult even outside the service area.
- 
```swift
manager.setMockingMode()
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

            let manager = JupiterServiceManager(id: "USER_ID")
            manager.delegate = self

            manager.startService(
                region: JupiterRegion.KOREA.rawValue,
                sectorId: 123,
                mode: .MODE_AUTO,
                debugOption: false
            )

            self?.manager = manager
        }
    }
}
```
