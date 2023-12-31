//
//  DRHelper.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/3/30.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import OfflineResourceManager
import LarkFeatureGating
import UniverseDesignTheme
import LarkSetting
import OpenCombine
import LarkBoxSetting

final class DynamicResourceHelper {
    struct Response: SettingDecodable {
        static var settingKey = UserSettingKey.make(userKeyLiteral: "gecko_config")
        let kaDynamicResource: KADynamicResource
    }

    struct KADynamicResource: Decodable {
        let accessKey: String
        let domainKey: String
    }

    static let logger = Logger.log(DynamicResourceHelper.self, category: "Module.DynamicResourceHelper")

    static func accessKey() -> AnyPublisher<String, Error> {
        SettingManager.shared.observe(type: Response.self, decodeStrategy: .convertFromSnakeCase).map {
            let accessKey = $0.kaDynamicResource.accessKey
            Self.logger.info("dynamic resource: accessKey \(accessKey)")
            return accessKey
        }.mapError {
            $0 as Error
        }.eraseToAnyPublisher()
    }
    
    static func syncAccessKey() -> String? {
        try? SettingManager.shared.setting(with: Response.self).kaDynamicResource.accessKey
    }

    static func identifier() -> String {
        let accountService = AccountServiceAdapter.shared
        // 当前的租户ID
        let tenantId = accountService.currentTenant.tenantId
        Self.logger.info("ka id is: \(tenantId)")
        return "ka_\(tenantId)"
    }

    static func isChinaMainland() -> Bool {
        /// MG 改造备注: hujinzang
        /// 理论上此处应该根据unit来判断
        /// 由于海外租户现在还未使用动态资源，所以暂时国内使用一个accessKey，国外统一使用一个
        /// 后续会再优化 跟 xuwei 的沟通 2022.1.26
        let isChinaMainland = AccountServiceAdapter.shared.isChinaMainlandGeo
        Self.logger.info("is China mainland: \(isChinaMainland)")
        return isChinaMainland
    }

    static func currentTheme() -> String {
        if #available(iOS 13.0, *) {
            switch UDThemeManager.getRealUserInterfaceStyle() {
            case .light:    return "light"
            case .dark:     return "dark"
            default:        return "light"
            }
        }
        return "light"
    }

    static func shouldUseDynamicResource() -> Bool {
        return
            AccountServiceAdapter.shared.isLogin &&
        LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.ka.dynamicres") && !BoxSetting.isBoxOff()
    }
}
