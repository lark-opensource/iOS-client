//
//  OPWebAppMeta.swift
//  OPGadget
//
//  Created by Nicholas Tau on 2021/11/4.
//

import Foundation
import OPSDK
import OPFoundation

public struct OPWebAppExtConfig {
    // code from taofengping，下边的 public 只是让外边可以调用属性
    /// 离线包版本
    public let version: String
    /// 兼容最小飞书版本
    public let minLarkVersion: String?
    /// 虚拟域名版本
    public let vhost: String
    /// 主入口URL
    public let mainUrl: String?
    ///离线能力是否开启
    public let offlineEnable: Bool
    ///在线H5 PC URL信息
    public let pcUrl: String?
    ///在线H5 mobile url信息
    public let mobileUrl: String?
    //允许回滚到在线页面的访问地址
    public let fallbackUrls: [String]?
    
    init(config: [String: Any]) {
        if let version = config["version"] as? String,
           let vhost = config["vhost"] as? String{
            self.version = version
            self.vhost = vhost
        } else {
            //
            self.version = "0"
            self.vhost = ""
        }
        self.minLarkVersion = config["minLarkVersion"] as? String
        self.mainUrl = config["mainUrl"] as? String
        self.offlineEnable = config["offlineEnable"] as? Bool ?? false
        self.mobileUrl = config["mobileUrl"] as? String
        self.pcUrl = config["pcUrl"] as? String
        self.fallbackUrls = config["fallbackUrls"] as? [String]
    }
}

class OPWebAppMeta: NSObject, OPBizMetaProtocol, OPMetaPackageProtocol {

    // basic
    let appID: String

    let appName: String
    // 应用版本
    let applicationVersion: String

    let appIconUrl: String

    var openSchemas: [Any]? {
        _openSchemas
    }

    // 这里用一个私有存储成员，来提供类型检查
    private let _openSchemas: [OPAppSchema]?

    let useOpenSchemas: Bool?

    let botID: String = ""

    let canFeedBack: Bool = false

    let shareLevel: Int = 0

    // biz
    let uniqueID: OPAppUniqueID
    // 包版本
    let appVersion: String

    // package

    let packageUrls: [String]

    let md5CheckSum: String

    let basicLibVersion: String?
    
    let extConfig: OPWebAppExtConfig

    init(appID: String,
         appName: String,
         applicationVersion: String,
         appIconUrl: String,
         appVersion: String,
         appUniqueID: OPAppUniqueID,
         packageUrls: [String],
         md5CheckSum: String,
         useOpenSchemas: Bool?,
         openSchemas: [OPAppSchema]?,
         basicLibVersion: String?,
         extConfig: OPWebAppExtConfig) {
        self.appID = appID
        self.appName = appName
        self.applicationVersion = applicationVersion
        self.appIconUrl = appIconUrl
        self.appVersion = appVersion
        self.uniqueID = appUniqueID
        self.packageUrls = packageUrls
        self.md5CheckSum = md5CheckSum
        self.useOpenSchemas = useOpenSchemas
        self._openSchemas = openSchemas
        self.basicLibVersion = basicLibVersion
        self.extConfig = extConfig
    }

    func toJson() throws -> String {
        var jsonDic: [String: Any] = [
            "appType": uniqueID.appType.rawValue,
            "appIdentifier": uniqueID.identifier,
            "appID": appID,
            "version": applicationVersion,
            "versionType": OPAppVersionTypeToString(uniqueID.versionType),
            "appName": appName,
            "appIconUrl": appIconUrl,
            "appVersion": appVersion,
            "package":[
                "packageUrls":packageUrls,
                "md5CheckSum":md5CheckSum
            ],
        ]

        // 这里任何一个为空，都等价于无白名单校验
        if let useOpenSchema = useOpenSchemas, let openSchema = _openSchemas {
            jsonDic["useOpenSchemas"] = useOpenSchema
            jsonDic["openSchemas"] = openSchema.map { $0.toDictionary() }
        }
        
        if let basicVersion = basicLibVersion {
            jsonDic["basicLibVersion"] = basicVersion
        }
        var jsonExtConfig: [String: Any] = [
            "version": self.extConfig.version,
            "vhost": self.extConfig.vhost,
            "offlineEnable": self.extConfig.offlineEnable
        ]
        if let mainUrl = self.extConfig.mainUrl {
            jsonExtConfig["mainUrl"] = mainUrl
        }
        if let minLarkVersion = self.extConfig.minLarkVersion {
            jsonExtConfig["minLarkVersion"] = minLarkVersion
        }
        if let fallbackUrls = self.extConfig.fallbackUrls {
            jsonExtConfig["fallbackUrls"] = fallbackUrls
        }
        if let pcUrl = self.extConfig.pcUrl {
            jsonExtConfig["pcUrl"] = pcUrl
        }
        if let mobileUrl = self.extConfig.mobileUrl {
            jsonExtConfig["mobileUrl"] = mobileUrl
        }
        jsonDic["extConfig"] = jsonExtConfig
        
        do {
            return try jsonDic.convertToJsonStr()
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
            throw opError
        }
    }

}
