//
//  OPBlockMeta.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/2.
//

import Foundation
import OPSDK
import LarkOPInterface
import OPFoundation

public enum OPBlockRenderType: String, Codable {
    case blockDSL = "block_dsl"
    case offlineWeb = "block_h5"
}

//block meta 额外信息：目前包含block web离线包相关meta配置
struct OPBlockMetaExtConfig: Codable {
    // pkg_type: 0表示DSL, 1表示H5离线包
    let pkgType: OPBlockRenderType
    // v_host: 虚拟域名
    // 示例: <scheme>://<AppID_BlockTypeID>.offlineweb.block.<host>/<path>
    let vHost: String
    /// 降级 url 列表（不带文件名）
    let fallbackPathList: [String]?

    enum CodingKeys: String, CodingKey {
        case pkgType = "pkg_type"
        case vHost = "v_host"
        case fallbackPathList = "fallback_path_list"
    }

    // 提供一个默认配置，在后端extConfig为空字串、配置错误等情况下使用
    static func defaultConfig() -> OPBlockMetaExtConfig {
        OPBlockMetaExtConfig(pkgType: .blockDSL, vHost: "", fallbackPathList: nil)
    }
}

class OPBlockMeta: NSObject, OPBizMetaProtocol, OPMetaPackageProtocol {

    // basic
    let appID: String

    let appName: String

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

    let appVersion: String

    // package

    let packageUrls: [String]

    let md5CheckSum: String

    let basicLibVersion: String?
    
    // 更新类型, 无持久化需要
    let updateType: OPAppExtensionMetaUpdateType?
    
    // 更新描述， 无持久化需要
    let updateDescription: String?

    // extConfig
    let extConfig: OPBlockMetaExtConfig

	// 真机调试socket_address, 无需持久化
	let devtoolSocketAddress: String?

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
         extConfig: OPBlockMetaExtConfig,
         updateType: OPAppExtensionMetaUpdateType? = nil,
         updateDescription: String? = nil,
		 devtoolSocketAddress: String? = nil) {
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
        self.updateType = updateType
        self.updateDescription = updateDescription
        self.extConfig = extConfig
		self.devtoolSocketAddress = devtoolSocketAddress
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
            "extConfig":[
                "pkg_type": extConfig.pkgType.rawValue,
                "v_host": extConfig.vHost,
                "fallback_path_list": extConfig.fallbackPathList
            ]
        ]

        // 这里任何一个为空，都等价于无白名单校验
        if let useOpenSchema = useOpenSchemas, let openSchema = _openSchemas {
            jsonDic["useOpenSchemas"] = useOpenSchema
            jsonDic["openSchemas"] = openSchema.map { $0.toDictionary() }
        }
        
        if let basicVersion = basicLibVersion {
            jsonDic["basicLibVersion"] = basicVersion
        }
        do {
            return try jsonDic.convertToJsonStr()
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
            throw opError
        }
    }

}
