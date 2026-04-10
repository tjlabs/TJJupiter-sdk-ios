
import Foundation
import TJLabsAuth
import TJLabsCommon

public class TJJupiterAuth {
    public static let shared = TJJupiterAuth()
    
    var deviceModel: String = ""
    var deviceOsInfo: String = ""
    var deviceOsVersion: Int = 0
    var sdkVersion: String = ""
    
    init () {
        setDeviceInfo()
        let clientMeta = makeClientMeta()
        SecretConfig.set(clientMeta: clientMeta)
    }
    
    private func setDeviceInfo() {
        deviceModel = UIDevice.modelName
        deviceOsInfo = UIDevice.current.systemVersion
        let arr = deviceOsInfo.components(separatedBy: ".")
        deviceOsVersion = Int(arr[0]) ?? 0
    }
    
    private func makeClientMeta() -> ClientMeta {
        let clientSdks = [
            SdkMeta(name: "TJLabsCommon", version: "0.1.0"),
            SdkMeta(name: "TJLabsResource", version: "0.1.0"),
            SdkMeta(name: "TJLabsJupiter", version: "0.1.0")
        ]
        
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
        let appVersion: String = version + "(\(build))"
        let appPackage: String = bundleIdentifier
        let deviceMode: String = self.deviceModel
        let osVersion: String = self.deviceOsInfo
        
        let clientMeta = ClientMeta(
            app_version: appVersion,
            app_package: appPackage,
            device_model: deviceMode,
            os_version: osVersion,
            sdks: clientSdks
        )
        
        return clientMeta
    }
    
    public func auth(accessKey: String, secretAccessKey: String, completion: @escaping (Int, Bool) -> Void) {
        TJLabsAuthManager.shared.auth(accessKey: accessKey, secretAccessKey: secretAccessKey, completion: completion)
    }
}
