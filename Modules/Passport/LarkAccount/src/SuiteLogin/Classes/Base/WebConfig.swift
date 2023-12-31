//
//  WebConfig.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/2.
//

import Foundation
import LarkLocalizations
import LarkAccountInterface
import LarkReleaseConfig

enum WebUrlKey: String {
    case quitTeam = "out_team_release"
    case accountSecurityCenter = "account_security_center"
    case accountPasswordSetting = "password_setting"
    case accountManagement = "account_management"
    case securityPasswordSetting = "security_password_setting"
    case deviceManagement = "device_management"
    case accountDeactivate = "account_deactivate"
    case accountCenterHomePage = ""
}

struct WebConfig {

    /// 这些 step 支持标记流程起点
    static let closeAllStartPointSteps: [PassportStep] = [
        .verifyChoose,      // 账号安全中心
        .bioAuth,           // 人脸识别
        .verifyIdentity,    // 预留
        .setPwd,            // 预留
        .recoverAccountCarrier, //老流程的帐号找回
        .retrieveOpThree    //新模型的实名认证
    ]

    enum Key {
        static let hideNavi = "op_platform_service"
        static let lang = "lang"
    }

    enum Value {
        static let hideNavi = "hide_navigator"
    }

    /// Add common params from native
    static func commonParamsUrlFrom(url: URL, with otherParams: [String: String]) -> URL {
        var params = [
            Key.lang: LanguageManager.currentLanguage.languageIdentifier
        ]

        params.merge(otherParams, uniquingKeysWith: { $1 })
        return url.append(parameters: params, forceNew: true)
    }
}

extension V3LoginService {
    func webUrl(for key: WebUrlKey) -> URL? {

        if let host = configuration.serverInfoProvider.getUrl(.passportAccounts).value,
           let url = config.webUrl(for: key.rawValue, host: host) {
            return url
        } else {
            Self.logger.errorWithAssertion("no url found for \(key)")
            return nil
        }
    }

    func openWebUrl(for key: WebUrlKey, from: UIViewController) -> Bool {

        guard let url = webUrl(for: key) else {
            return false
        }
        let newUrl = WebConfig.commonParamsUrlFrom(url: url, with: [:])
        dependency.openDynamicURL(newUrl, from: from)
        return true
    }
}
