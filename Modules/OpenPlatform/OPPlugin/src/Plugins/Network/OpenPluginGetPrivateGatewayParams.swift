//
//  OpenPluginGetPrivateGatewayParams.swift
//  OPPlugin
//
//  Created by luogantong on 2022/9/5.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOInfra
import OPFoundation
import LarkAccountInterface
import LarkSetting
import LarkLocalizations
import OPPluginManagerAdapter
import LarkContainer
import SystemConfiguration
import LarkFoundation

// 技术方案: https://bytedance.feishu.cn/wiki/wikcnfX3j1wbiF1zqd5my9LNnxh

final class OpenAPIGetPrivateGatewayParams: OpenAPIBaseParams {

}


// 参数定义https://bytedance.feishu.cn/wiki/wikcnTsWmsOdJNt1GKVDMeUiUOd
final class OpenAPIGetPrivateGatewayParamsDataResult: OpenAPIBaseResult {
    
    // 语言环境
    public var xLgwLocale: String?
    
    // 应用版本号
    public var xLgwAppVersion: String?
    
    // 终端类型，iOS固定为4
    public var xLgwTerminalType: Int = 4
    
    // 用户id
    public var xLgwUserID: String?
    
    // 设备ID
    public var xLgwDeviceID: String?
    
    // 安装id
    public var xLgwInstallID: String?
    
    // 应用ID
    public var xLgwAppID: Int? = 0
    
    // 操作系统版本
    public var xLgwOSVersion: String?
    
    // 设备类型
    public var xLgwDeviceType: String?
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["x-lgw-locale" : xLgwLocale ?? "",
                "x-lgw-app-version" : xLgwAppVersion ?? "",
                "x-lgw-terminal-type" : xLgwTerminalType,
                "x-lgw-user-id" : xLgwUserID ?? "",
                "x-lgw-device-id" : xLgwDeviceID ?? "",
                "x-lgw-install-id" : xLgwInstallID ?? "",
                "x-lgw-app-id" : xLgwAppID ?? Int(0),
                "x-lgw-os-version" : xLgwOSVersion ?? "",
                "x-lgw-device-type" : xLgwDeviceType ?? ""]
    }
}

class OpenPluginGetPrivateGatewayParams: OpenBasePlugin {
    func getPrivateParams(params: OpenAPIGetPrivateGatewayParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {
        var dataResult = OpenAPIGetPrivateGatewayParamsDataResult()
        dataResult.xLgwLocale = LanguageManager.currentLanguage.languageIdentifier
        dataResult.xLgwAppVersion = LarkFoundation.Utils.appVersion
        dataResult.xLgwUserID = userResolver.userID
        let deviceService = InjectedOptional<DeviceService>().wrappedValue
        dataResult.xLgwDeviceID = deviceService?.deviceId
        dataResult.xLgwInstallID = deviceService?.installId
        dataResult.xLgwAppID = lark_safeAppID()
        dataResult.xLgwOSVersion = "\(UIDevice.current.systemVersion)"
        dataResult.xLgwDeviceType = LarkFoundation.Utils.machineType
        callback(.success(data: dataResult))
    }
    
    func lark_safeAppID()-> Int? {
        var appID = Int(0)
        if let appidString = Bundle.main.infoDictionary?["SSAppID"] as? String {
            appID = Int(appidString)!
        } else if let appid = Bundle.main.infoDictionary?["SSAppID"] as? Int {
            appID = appid
        }
        return appID
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "larkPrivateGatewayParams", pluginType: Self.self, paramsType: OpenAPIGetPrivateGatewayParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.getPrivateParams(params: params, context: context, callback: callback)
        }
    }
}

