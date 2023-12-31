import Foundation
import Swinject
import LarkAccountInterface
import LarkAppConfig
import WebBrowser
import LKCommonsLogging
import LarkContainer
import ECOInfra

public struct CommonJsAPIHandlerProvider: JsAPIHandlerProvider {

    private static let logger = Logger.oplog(CommonJsAPIHandlerProvider.self, category: "CommonJsAPIHandlerProvider")
    
    public let handlers: JsAPIHandlerDict

    public init(api: WebBrowser, resolver: UserResolver) {
        let reqUrlStr: String?
        if let appConfig = try? resolver.resolve(assert: AppConfiguration.self) {
            reqUrlStr = appConfig.h5JSSDKPrefix + "/config/get"
        } else {
            Self.logger.error("resolve AppConfiguration failed")
            reqUrlStr = nil
        }
        self.handlers = [
            "config": {
                return ConfigHandler(resolver: resolver)
            },
            "getSDKConfig": {
                let userSerivce = try? resolver.resolve(assert: PassportUserService.self)
                let deviceService = try? resolver.resolve(assert: DeviceService.self)
                if userSerivce == nil {
                    Self.logger.error("resolve PassportUserService failed")
                }
                if deviceService == nil {
                    Self.logger.error("resolve DeviceService failed")
                }
                
                let tenantId: String? = userSerivce?.userTenant.tenantID
                let userId = resolver.userID
                let deviceId: String? = deviceService?.deviceId
                return GetSDKConfigHandler(reqUrlStr: reqUrlStr, tenantId: tenantId, userId: userId, deviceId: deviceId)
            },
        ]
    }
}
