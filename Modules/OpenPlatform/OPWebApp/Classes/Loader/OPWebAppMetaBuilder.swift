//
//  OPWebAppMetaBuilder.swift
//  OPGadget
//
//  Created by Nicholas Tau on 2021/11/4.
//

import Foundation
import OPSDK
import TTMicroApp
import OPFoundation

extension OPWebAppMetaBuilder: MetaFromStringProtocol {
    //实现简单协议
    public func buildMetaModel(with metaJsonStr: String) throws -> AppMetaProtocol {
        if let adapter = try (self.buildFromJson(metaJsonStr) as? OPWebAppMeta)?.appMetaAdapter {
            return adapter
        }
        throw OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "OPDynamicComponentMeta buildFromJson cast exception")
    }
}

class OPWebAppMetaBuilder: OPAppMetaBuilder {
    
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
                let verisonType = jsonDic["versionType"] as? String,
                let extConfigJson = jsonDic["extConfig"] as? [String: Any] else {
                let opError = OPSDKMonitorCode.unknown_error.error(message: "buildFromJson failed")
                throw opError
            }
            let useOpenSchemas = jsonDic["useOpenSchemas"] as? Bool
            let openSchemas = jsonDic["openSchemas"] as? [[String: String]]
            let basicLibVersion = jsonDic["basicLibVersion"] as? String
            let extConfig = OPWebAppExtConfig(config: extConfigJson)
            return OPWebAppMeta(
                appID: appID,
                appName: appName,
                applicationVersion: version,
                appIconUrl: appIconUrl,
                appVersion: appVersion,
                appUniqueID: OPAppUniqueID(appID: appID, identifier: appIdentifier, versionType: OPAppVersionTypeFromString(verisonType), appType: .webApp),
                packageUrls: packageUrls,
                md5CheckSum: md5CheckSum,
                useOpenSchemas: useOpenSchemas,
                openSchemas: openSchemas?.compactMap { .init(dictionary: $0) },
                basicLibVersion: basicLibVersion,
                extConfig: extConfig)
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
                let infoDic: [String: Any]? = try? appBizMeta.meta.convertToJsonObject()
                let info = infoDic?["pkg"] as? [String: Any]
                let pkgInfo = info?["web_offline_pkg"] as? [String: Any]
                let url = pkgInfo?["url"] as? String ?? ""
                let backupUrls = pkgInfo?["backup_urls"] as? [String] ?? []
                let md5 = pkgInfo?["md5"]  as? String ?? ""
                
                let extConfigJsonOriginal = try appBizMeta.extConfig?.convertToJsonObject()
                guard let extConfigJsonOriginal = extConfigJsonOriginal,
                      let _ = extConfigJsonOriginal["v_host"] as? String else {
                    let opError = OPSDKMonitorCode.unknown_error.error(message: "buildFromData failed when parse meta/extConfig string to json")
                    throw opError
                }
                var extConfigJson = extConfigJsonOriginal
                //服务端返回默认下划线命名，需要做一次本地数据兼容处理
                extConfigJson["minLarkVersion"] = extConfigJson["min_lark_version"]
                extConfigJson["mainUrl"] = extConfigJson["main_url"]
                extConfigJson["vhost"] = extConfigJson["v_host"]
                extConfigJson["pcUrl"] = extConfigJson["pc_url"]
                extConfigJson["mobileUrl"] = extConfigJson["mobile_url"]
                extConfigJson["offlineEnable"] = extConfigJson["offline_enable"]
                extConfigJson["fallbackUrls"] = extConfigJson["fallback_path_list"]
                extConfigJson["version"] = appBizMeta.version
                let extConfig = OPWebAppExtConfig(config: extConfigJson)
                var packageUrls: [String] = [url]
                packageUrls.append(contentsOf: backupUrls)
                return OPWebAppMeta(
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
                    basicLibVersion: appBizMeta.basicLibVersion,
                    extConfig: extConfig)

            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
}
