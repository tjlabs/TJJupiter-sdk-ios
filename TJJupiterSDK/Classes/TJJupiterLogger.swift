
import Foundation

public class TJJupiterLogger {
    static var debugOption = true
    static var infoOption = true
    
    public static func setDebugOption(set: Bool) {
        debugOption = set
    }
    
    public static func setInfoOption(set: Bool) {
        infoOption = set
    }
    
    static func d(tag: String, message: String) {
        if debugOption {
            print("[DEBUG] [\(tag)] \(message)")
        }
    }
    
    static func i(tag: String, message: String) {
        if debugOption {
            print("[INFO]  [\(tag)] \(message)")
        }
    }
    
    static func w(tag: String, message: String) {
        if debugOption {
            print("[WARN]  [\(tag)] \(message)")
        }
    }
    
    static func e(tag: String, message: String) {
        if debugOption {
            print("[ERROR] [\(tag)] \(message)")
        }
    }
}
