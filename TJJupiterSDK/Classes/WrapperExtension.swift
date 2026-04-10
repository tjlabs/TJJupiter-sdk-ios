
import Foundation
import TJLabsCommon
import TJLabsJupiter

// MARK: - To Common
extension UserMode {
    func toJupiter() -> TJLabsCommon.UserMode {
        return TJLabsCommon.UserMode(rawValue: self.rawValue) ?? .MODE_AUTO
    }
}

// MARK: - To Jupiter
extension Point {
    func toJupiter() -> TJLabsJupiter.Point {
        return TJLabsJupiter.Point(
            level_id: self.level_id,
            x: self.x,
            y: self.y
        )
    }
}

extension RoutingStart {
    func toJupiter() -> TJLabsJupiter.RoutingStart {
        return TJLabsJupiter.RoutingStart(
            level_id: self.level_id,
            x: self.x,
            y: self.y,
            absolute_heading: self.absolute_heading
        )
    }
}

extension JupiterRegion {
    func toJupiter() -> TJLabsJupiter.JupiterRegion {
        return TJLabsJupiter.JupiterRegion(rawValue: self.rawValue) ?? .KOREA
    }
}


// MARK: - To Wrap 필요

extension TJLabsJupiter.InOutState {
    func toWrap() -> InOutState {
        return InOutState(rawValue: self.rawValue) ?? .UNKNOWN
    }
}

extension TJLabsJupiter.JupiterErrorCode {
    func toWrap() -> JupiterErrorCode {
        return JupiterErrorCode(rawValue: self.rawValue) ?? .INVALID_ID
    }
}

extension TJLabsJupiter.JupiterServiceCode {
    func toWrap() -> JupiterServiceCode {
        return JupiterServiceCode(rawValue: self.rawValue) ?? .SERVICE_FAIL
    }
}

extension TJLabsJupiter.Position {
    func toWrap() -> Position {
        return Position(
            x: self.x,
            y: self.y,
            heading: self.heading
        )
    }
}

extension TJLabsJupiter.LLH {
    func toWrap() -> LLH {
        return LLH(
            lat: self.lat,
            lon: self.lon,
            heading: self.heading
        )
    }
}

extension TJLabsJupiter.JupiterResult {
    func toWrap() -> JupiterResult {
        return JupiterResult(
            mobile_time: self.mobile_time,
            index: self.index,
            building_name: self.building_name,
            level_name: self.level_name,
            jupiter_pos: self.jupiter_pos.toWrap(),
            navi_pos: self.navi_pos?.toWrap(),
            llh: self.llh?.toWrap(),
            velocity: self.velocity,
            is_vehicle: self.is_vehicle,
            is_indoor: self.is_indoor,
            validity_flag: self.validity_flag
        )
    }
}

extension InOutState {
    func toJupiter() -> TJLabsJupiter.InOutState {
        return TJLabsJupiter.InOutState(rawValue: self.rawValue) ?? .UNKNOWN
    }
}

extension JupiterErrorCode {
    func toJupiter() -> TJLabsJupiter.JupiterErrorCode {
        return TJLabsJupiter.JupiterErrorCode(rawValue: self.rawValue) ?? .INVALID_ID
    }
}

extension JupiterServiceCode {
    func toJupiter() -> TJLabsJupiter.JupiterServiceCode {
        return TJLabsJupiter.JupiterServiceCode(rawValue: self.rawValue) ?? .SERVICE_FAIL
    }
}

extension Position {
    func toJupiter() -> TJLabsJupiter.Position {
        return TJLabsJupiter.Position(
            x: self.x,
            y: self.y,
            heading: self.heading
        )
    }
}

extension LLH {
    func toJupiter() -> TJLabsJupiter.LLH {
        return TJLabsJupiter.LLH(
            lat: self.lat,
            lon: self.lon,
            heading: self.heading
        )
    }
}

extension JupiterResult {
    func toJupiter() -> TJLabsJupiter.JupiterResult {
        return TJLabsJupiter.JupiterResult(
            mobile_time: self.mobile_time,
            index: self.index,
            building_name: self.building_name,
            level_name: self.level_name,
            jupiter_pos: self.jupiter_pos.toJupiter(),
            navi_pos: self.navi_pos?.toJupiter(),
            llh: self.llh?.toJupiter(),
            velocity: self.velocity,
            is_vehicle: self.is_vehicle,
            is_indoor: self.is_indoor,
            validity_flag: self.validity_flag
        )
    }
}
