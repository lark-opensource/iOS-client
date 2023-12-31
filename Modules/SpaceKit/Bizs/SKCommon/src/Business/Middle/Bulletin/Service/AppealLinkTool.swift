//
//  AppealService.swift
//  SKCommon
//
//  Created by peilongfei on 2023/10/18.
//  

import SKFoundation
import SKUIKit
import SKInfra
import SKResource
import LarkStorage
import SpaceInterface

class AppealLinkTool {

    private typealias Resource = BundleI18n.SKResource

    // 新版申诉链接
    static func appealLinkText(state: ComplaintState, entityId: String) -> [(String, String)] {
        switch state {
        case .machineVerify:
            return [
                (Resource.LarkCCM_Security_UserAgreement_Link, Self.userAgreementLink()),
                (Resource.LarkCCM_Security_SubmitAppeal_Link, Self.submitAppealLink(with: entityId))
            ]
        case .verifyFailed:
            return [(Resource.LarkCCM_Security_Appeal_Link, Self.submitAppealLink(with: entityId))]
        case .unchanged:
            return []
        case .reachVerifyLimitOfDay:
            return [(Resource.LarkCCM_Security_ContactSupport_Link, Self.contactSupportLink())]
        case .reachVerifyLimitOfAll:
            return [(Resource.LarkCCM_Security_ContactSupport_Link, Self.contactSupportLink())]
        case .verifying:
            return [(Resource.LarkCCM_Security_AppealProgress_Link, Self.appealProgressLink(with: entityId))]
        }
    }

    static func submitAppealLink(with entityId: String) -> String {
        let path = "/appeal"
        let link = Self.appealLink(with: path, entityId: entityId)
        return link
    }

    static func appealProgressLink(with entityId: String) -> String {
        let path = "/appeal/detail"
        let link = Self.appealLink(with: path, entityId: entityId)
        return link
    }

    static func contactSupportLink() -> String {
        let mpDomain = DomainConfig.mpAppLinkDomain
        let link = "https://\(mpDomain)/TdSgr1y9"
        return link
    }

    static func userAgreementLink() -> String {
        if DomainConfig.envInfo.isFeishuBrand {
            guard let config = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.shareLinkToastURL) else {
                DocsLogger.info("no userAgreementLink")
                return ""
            }
            var serviceSite = ""
            if var serviceURL = config["service_term_url"] as? String {
                serviceSite = "https://" + serviceURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            }
            return serviceSite
        } else {
            guard let docsManagerDelegate = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
                DocsLogger.info("no userAgreementLink")
                return ""
            }
            let serviceSite = docsManagerDelegate.serviceTermURL
            return serviceSite
        }
    }

    static func reportLink(token: String, type: DocsType) -> URL? {
        var link = Self.reportPath()
        // 这个跟lark确认了，先保留，不适配KA
        let params = "{\"obj_token\":\"\(token)\",\"obj_type\":\(type.rawValue)}".urlEncoded()
        let lang = DocsSDK.currentLanguage.rawValue
        link = link + "/?type=docs&params=\(params)&lang=\(lang)"
        if SKFoundationConfig.shared.isStagingEnv, let boe_env = KVPublic.Common.ttenv.value() {
            link = link + "&x-tt-env=\(boe_env)"
        }
        return URL(string: link)
    }

    private static func reportPath() -> String {
        let domain = DomainConfig.larkReportDomain
        let feishuDomain = DomainConfig.tnsReportDomain
        let reportPath = SettingConfig.tnsReportConfig?.reportPath ?? TnsReportConfig.default.reportPath
        if DomainConfig.envInfo.isFeishuBrand {
            return "https://" + feishuDomain + reportPath
        } else {
            return "https://" + domain + reportPath
        }
    }

    private static func appealLink(with path: String, entityId: String) -> String {
        var link = Self.reportPath()
        let lang = DocsSDK.currentLanguage.rawValue
        link = link + path + "?entity_id=\(entityId)&entity_type=ccm_web_id&scene=ccm_ban&lang=\(lang)"
        if SKFoundationConfig.shared.isStagingEnv, let boe_env = KVPublic.Common.ttenv.value()?.description {
            link = link + "&x-tt-env=\(boe_env)"
        }
        return link
    }
}
