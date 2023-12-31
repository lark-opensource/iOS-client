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

/// 离线资源初始化，目前：Docs React 资源以及 Email 离线资源
public class OfflineResourceApplicationDelegate {

    static public let config = Config(name: "OfflineResourceManager", daemon: true)
    private static let logger = Logger.log(OfflineResourceApplicationDelegate.self)

    @Provider var deviceService: DeviceService
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
        guard let domain = DomainSettingManager.shared.currentSetting[.docsFeResourceHotfix]?.first else {
            assertionFailure("no remote domain")
            return ""
        }
        return domain
    }
}

extension OfflineResourceApplicationDelegate {

    func initOfflineResourceManager() {
        let cacheDir = OfflineResourceApplicationDelegate.cacheDirectory()
        let domain = OfflineResourceApplicationDelegate.geckoDomain()
        let config = OfflineResourceConfig(
            appId: ReleaseConfig.appId,
            appVersion: Utils.appVersion,
            deviceId: deviceService.deviceId,
            domain: domain,
            cacheRootDirectory: cacheDir
        )
        OfflineResourceManager.setConfig(config)
    }
}
