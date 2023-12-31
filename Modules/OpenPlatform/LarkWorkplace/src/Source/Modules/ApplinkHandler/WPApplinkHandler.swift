//
//  WPApplinkHandler.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/3/25.
//

import Foundation
import LarkSceneManager
import EENavigator
import LarkTab
import LarkUIKit
import RoundedHUD
import LKCommonsLogging
import EEMicroAppSDK
import LarkSetting
import Blockit
import LarkOPInterface
import LarkContainer
import LarkAccountInterface

/// 离线 Web
public enum WPThirdAppLink {
    static let logger = Logger.log(WPThirdAppLink.self)

    /// offlineWeb 关联 appId
    case offlineWeb(appId: String)

    // 为离线 H5 应用构造 applink url
    var urlString: String {
        switch self {
        case .offlineWeb(let appId):
            let defaultValue: String

            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
            let userService = try? userResolver.resolve(assert: PassportUserService.self)
            if userService?.isChinaMainlandGeo ?? true {
                defaultValue = "applink.feishu.cn"
            } else {
                defaultValue = "applink.larksuite.com"
            }
            var host: String
            if let domain = DomainSettingManager.shared.currentSetting[.appLink]?.first {
                host = domain
            } else {
                host = defaultValue
                Self.logger.error("can not get applink domain from setting, use default value")
            }
            var components = URLComponents()
            components.scheme = "https"
            components.host = host
            components.path = "/client/web_app/open"
            let queryItem = URLQueryItem(name: "appId", value: appId)
            components.queryItems = [queryItem]
            guard let applinkUrlString = components.url?.absoluteString else {
                Self.logger.error("generate url with invalid components: \(components)")
                return "https://\(host)/client/web_app/open?appId=\(appId)"
            }
            return applinkUrlString
        }
    }
}

extension LarkSetting.DomainKey {
    static let appLink: LarkSetting.DomainKey = "applink"
}
