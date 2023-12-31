//
//  OPBlockMetaBuilder.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/12.
//

import Foundation
import OPSDK
import LarkOPInterface
import ECOProbe
import LKCommonsLogging
import OPFoundation
import TTMicroApp

extension OPBlockMetaBuilder: MetaFromStringProtocol {
    //实现简单协议
    public func buildMetaModel(with metaJsonStr: String) throws -> AppMetaProtocol {
        if let adapter = try (self.buildFromJson(metaJsonStr) as? OPBlockMeta)?.appMetaAdapter {
            return adapter
        }
        throw OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "OPDynamicComponentMeta buildFromJson cast exception")
    }
}

class OPBlockMetaBuilder: NSObject, OPAppMetaBuilder {

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
            var extConfig: OPBlockMetaExtConfig
            if let configDic = jsonDic["extConfig"] as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: configDic, options: []),
               let config = try? JSONDecoder().decode(OPBlockMetaExtConfig.self, from: data) {
                extConfig = config
            } else {
                extConfig = OPBlockMetaExtConfig.defaultConfig()
            }
            return OPBlockMeta(
                appID: appID,
                appName: appName,
                applicationVersion: version,
                appIconUrl: appIconUrl,
                appVersion: appVersion,
                appUniqueID: OPAppUniqueID(appID: appID, identifier: appIdentifier, versionType: OPAppVersionTypeFromString(verisonType), appType: .block),
                packageUrls: packageUrls,
                md5CheckSum: md5CheckSum,
                useOpenSchemas: useOpenSchemas,
                openSchemas: openSchemas?.compactMap { .init(dictionary: $0) },
                basicLibVersion: basicLibVersion,
                extConfig: extConfig
            )
        } catch {
            throw error
        }
    }

    func buildFromData(_ data: Data, uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol {
        do {
            let (baseInfo, appBizMeta) = try deserializeResponse(with: data, uniqueID: uniqueID)
            do {
               let infoDic = try appBizMeta.meta.convertToJsonObject()
                guard let info = infoDic["pkg"] as? [String: Any],
                      let pkgInfo = info["block_mobile_lynx_pkg"] as? [String: Any] ?? info["block_h5_zip"] as? [String: Any],
                      let url = pkgInfo["url"] as? String,
                      let backupUrls = pkgInfo["backup_urls"] as? [String], let md5 = pkgInfo["md5"]  as? String else {
                    let opError = OPSDKMonitorCode.unknown_error.error(message: "buildFromData failed")
                    throw opError
                }
                var extConfig: OPBlockMetaExtConfig
                if let configStr = appBizMeta.extConfig,
                   let data = configStr.data(using: .utf8),
                   let config = try? JSONDecoder().decode(OPBlockMetaExtConfig.self, from: data) {
                    extConfig = config
                } else {
                    extConfig = OPBlockMetaExtConfig.defaultConfig()
                }
                var packageUrls: [String] = [url]
                packageUrls.append(contentsOf: backupUrls)
                return OPBlockMeta(
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
                    extConfig: extConfig,
                    updateType: appBizMeta.updateType,
                    updateDescription: appBizMeta.updateDescription,
					devtoolSocketAddress: appBizMeta.devtoolSocketAddress
                )

            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
}
