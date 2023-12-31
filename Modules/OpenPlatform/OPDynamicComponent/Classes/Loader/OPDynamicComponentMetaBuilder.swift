//
//  OPDynamicComponentMetaBuilder.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2022/05/25.
//

import Foundation
import OPSDK
import OPFoundation
import TTMicroApp

extension OPDynamicComponentMetaBuilder: MetaFromStringProtocol {
    //实现简单协议
    public func buildMetaModel(with metaJsonStr: String) throws -> AppMetaProtocol {
        if let adapter = try (self.buildFromJson(metaJsonStr) as? OPDynamicComponentMeta)?.appMetaAdapter {
            return adapter
        }
        throw OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "OPDynamicComponentMeta buildFromJson cast exception")
    }
}

class OPDynamicComponentMetaBuilder: OPAppMetaBuilder {
    
    //从DB从获取数据，构建对象
    func buildFromJson(_ jsonStr: String) throws -> OPBizMetaProtocol {
        do {
            let jsonDic = try jsonStr.convertToJsonObject()
            guard let appIdentifier = jsonDic["appIdentifier"] as? String,
                let appID = jsonDic["appID"] as? String,
                let version = jsonDic["version"] as? String,
                let appVersion = jsonDic["appVersion"] as? String,
                let appName = jsonDic["appName"] as? String,
                let appIconUrl = jsonDic["appIconUrl"] as? String,
                let package = jsonDic["package"] as? [String: Any],
                let packageUrls = package["packageUrls"] as? [String],
                let md5CheckSum = package["md5CheckSum"] as? String,
                let verisonType = jsonDic["versionType"] as? String else {
                let opError = OPSDKMonitorCode.unknown_error.error(message: "buildFromJson failed")
                throw opError
            }
            let useOpenSchemas = jsonDic["useOpenSchemas"] as? Bool
            let openSchemas = jsonDic["openSchemas"] as? [[String: String]]
            let basicLibVersion = jsonDic["basicLibVersion"] as? String
            return OPDynamicComponentMeta(
                appID: appID,
                appName: appName,
                applicationVersion: version,
                appIconUrl: appIconUrl,
                appVersion: appVersion,
                appUniqueID: OPAppUniqueID(appID: appID, identifier: appIdentifier, versionType: OPAppVersionTypeFromString(verisonType), appType: .dynamicComponent),
                packageUrls: packageUrls,
                md5CheckSum: md5CheckSum,
                useOpenSchemas: useOpenSchemas,
                openSchemas: openSchemas?.compactMap { .init(dictionary: $0) },
                basicLibVersion: basicLibVersion)
        } catch {
            throw error
        }
    }

    //从服务端返回的数据构建对象
    func buildFromData(_ data: Data, uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol {
        do {
            let (baseInfo, appBizMeta) = try deserializeResponse(with: data, uniqueID: uniqueID)
            do {
                //兼容在线数据，如果是在线类型。服务端可能不发以下字段
                let infoDic: [String: Any]? = try appBizMeta.meta.convertToJsonObject()
                let info = infoDic?["pkg"] as? [String: Any]
                let pkgInfo = info?["gadget_plugin_splits_pkg"] as? [String: Any]
                let url = pkgInfo?["url"] as? String ?? ""
                let backupUrls = pkgInfo?["backup_urls"] as? [String] ?? []
                let md5 = pkgInfo?["md5"]  as? String ?? ""
                
                var packageUrls: [String] = [url]
                packageUrls.append(contentsOf: backupUrls)
                return OPDynamicComponentMeta(
                    appID: baseInfo.appID,
                    appName: baseInfo.name,
                    applicationVersion: baseInfo.version,
                    appIconUrl: baseInfo.icon,
                    appVersion: appBizMeta.version,
                    appUniqueID: uniqueID,
                    packageUrls: packageUrls,
                    md5CheckSum: md5,
                    useOpenSchemas: baseInfo.useOpenSchemas,
                    openSchemas: baseInfo.openSchemas,
                    basicLibVersion: appBizMeta.basicLibVersion)

            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
}
