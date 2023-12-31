//
//  OPDynamicComponentMeta.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2022/05/25.
//

import Foundation
import OPSDK
import OPFoundation

class OPDynamicComponentMeta: NSObject, OPBizMetaProtocol, OPMetaPackageProtocol {

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
         basicLibVersion: String?) {
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
        
        do {
            return try jsonDic.convertToJsonStr()
        } catch {
            let opError = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
            throw opError
        }
    }

}
