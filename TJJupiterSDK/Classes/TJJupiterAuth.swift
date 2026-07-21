
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
        
        let dev = tjBranch == .DEV
        let clientMeta = makeClientMeta()
        TJLabsAuthConstants.setServerURL(cloud: "GCP", region: AuthRegion.KOREA.rawValue, serverType: "jupiter", dev: dev)
        SecretConfig.set(customerKey: "JUPITER", clientMeta: clientMeta)
    }
    
    private func setDeviceInfo() {
        deviceModel = UIDevice.modelName
        deviceOsInfo = UIDevice.current.systemVersion
        let arr = deviceOsInfo.components(separatedBy: ".")
        deviceOsVersion = Int(arr[0]) ?? 0
    }
    
    private func makeClientMeta() -> ClientMeta {
        let clientSdks = [
            SdkMeta(name: "TJLabsAuth", version: "1.0.5"),
            SdkMeta(name: "TJLabsCommon", version: "1.0.6"),
            SdkMeta(name: "TJLabsResource", version: "0.1.7"),
            SdkMeta(name: "TJLabsJupiter", version: "2.0.12")
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
    
    public func setServerConfig(branch: ServerBranch) {
        tjBranch = branch
        let dev = tjBranch == .DEV
        TJLabsAuthConstants.setServerURL(cloud: "GCP", region: AuthRegion.KOREA.rawValue, serverType: "jupiter", dev: dev)
    }
}
