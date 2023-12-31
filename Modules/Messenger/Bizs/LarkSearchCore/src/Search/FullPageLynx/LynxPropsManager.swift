//
//  LynxPropsManager.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2023/1/17.
//

import Lynx
import Foundation
import LarkUIKit
import LarkAccountInterface
import UniverseDesignTheme
import LarkLocalizations
import LarkReleaseConfig
import LarkContainer
import LarkEnv

public protocol LynxPropsManagerProtocol {
    func getGlobalProps() -> LynxTemplateData
}

public class LynxPropsManager: LynxPropsManagerProtocol {
    private var passportService: PassportService?
    var userService: User?
    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.passportService = try? userResolver.resolve(assert: PassportService.self)
        self.userService = (try? userResolver.resolve(assert: PassportUserService.self))?.user
    }

    public func getGlobalProps() -> LynxTemplateData {
        let language: String = LanguageManager.currentLanguage.localeIdentifier
        let appID = ReleaseConfig.appId
        var environment: String {
            switch EnvManager.env.type {
            case .preRelease: return "prerelease"
            case .staging: return "boe"
            case .release: return "release"
            }
        }
        let appName = LanguageManager.bundleDisplayName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let appInfoDict: [String: String] = [
            "appID": appID,
            "appName": appName,
            "appVersion": appVersion,
            "environment": environment
        ]
        let userInfo: [String: Any] = [
            "userId": userResolver.userID,
            "device_id": passportService?.deviceID ?? "",
            "tenantId": userService?.tenant.tenantID ?? "",
            "tenantBrand": passportService?.tenantBrand.rawValue ?? "",
            "unit": EnvManager.env.unit,
            "geo": EnvManager.env.geo
        ]
        var theme: String {
            if #available(iOS 13.0, *) {
                switch UDThemeManager.getRealUserInterfaceStyle() {
                case .dark:
                    return "dark"
                case .light:
                    return "light"
                case .unspecified:
                    return "light"
                @unknown default:
                    return "light"
                }
            } else {
                return "light"
            }
        }
        var plateform: String {
            return Display.pad ? "ipad" : "ios"
        }
        return LynxTemplateData(dictionary: ["language": language,
                                            "appInfo": appInfoDict,
                                            "userInfo": userInfo,
                                            "plateform": plateform,
                                            "theme": theme])
    }
}
