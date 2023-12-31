//
//  OfflineResourceDelegate.swift
//  LarkApp
//
//  Created by Miaoqi Wang on 2019/11/27.
//

import Foundation
import AppContainer
import OfflineResourceManager
import LarkFoundation
import LarkSetting
import LarkReleaseConfig
import LarkAccountInterface
import LarkContainer
import LKCommonsLogging
import LarkAppConfig
import LarkEnv

/// 离线资源初始化，目前：Docs React 资源以及 Email 离线资源
public final class OfflineResourceApplicationDelegate: ApplicationDelegate {

    static public let config = Config(name: "OfflineResourceManager", daemon: true)
    private static let logger = Logger.log(OfflineResourceApplicationDelegate.self)

    @Provider var deviceService: DeviceService // Global

    @Provider var ugService: AccountServiceUG

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { (_, _: DidBecomeActive) in
            // 检查资源更新 如果有
            if !URLMapHandler.urlMappers.isEmpty {
                DispatchQueue.global().async {
                    URLMapHandler.urlMappers.forEach { (mapper) in
                        OfflineResourceManager.fetchResource(byId: mapper.dynamicUrlInfo.bizName)
                    }
                }
            }
        }
    }
}

extension OfflineResourceApplicationDelegate {
    static func cacheDirectory() -> String? {
        if let libraryDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            return "\(libraryDir)/OfflineResource"
        } else {
            return nil
        }
    }

    static func geckoDomain() -> String {
        guard var domain = DomainSettingManager.shared.currentSetting[.docsFeResourceUrl]?.first else {
            assertionFailure("no remote domain")
            return ""
        }
        if EnvManager.env.isStaging, !domain.hasSuffix(".boe-gateway.byted.org") {
            domain.append(contentsOf: ".boe-gateway.byted.org")
        }
        return domain
    }
}

extension OfflineResourceApplicationDelegate {

    func initOfflineResourceManager() {
        let cacheDir = OfflineResourceApplicationDelegate.cacheDirectory()
        let domain = OfflineResourceApplicationDelegate.geckoDomain()
        let dic = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "gurd_config"))["ka_dynamic_resource"] as? [String: String]
        let config = OfflineResourceConfig(
            appId: dic?["aid"] ?? ReleaseConfig.appId,
            appVersion: Utils.appVersion,
            deviceId: deviceService.deviceId,
            domain: domain,
            cacheRootDirectory: cacheDir,
            isBoe: EnvManager.env.isStaging
        )
        OfflineResourceManager.setConfig(config)

        activeInternalResource()
    }

    func activeInternalResource() {
        ugService.subscribePassportOfflineConfig {[weak self] passportConfig in
            guard let self = self else { return }
            if self.ugService.enableLarkGlobalOffline() {
                // 激活Lark Global 内置包
                let passportOfflineConfig = passportConfig
                let configs = passportOfflineConfig.offlineConfig
                configs.forEach { config in
                    config.channels.forEach { channel in
                        OfflineResourceManager.activeInternalPackage(with: "LarkGlobalResource", accessKey: config.accessKey, channel: channel)
                    }
                }
            }
        }
    }
}
