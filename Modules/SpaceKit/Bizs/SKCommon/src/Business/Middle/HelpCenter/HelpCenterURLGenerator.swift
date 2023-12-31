//
//  HelpCenterURLGenerator.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/3/8.
//

import Foundation
import LarkSetting
import SKResource
import SKInfra

public extension HelpCenterURLGenerator.ArticleID {
    // https://bytedance.feishu.cn/docx/ZTDwdEGwGooBPNxfvlmcn96nnQN
    public static var cmApplyDelete: Self {
        .init(feishuID: "075978095260", larkID: "991489909111")
    }
    public static var cmApplyMove: Self {
        .init(feishuID: "394436478773", larkID: "756157089386")
    }
    public static var secretBannerHelpCenter: Self {
        .init(feishuID: "991220891340", larkID: "150212615307")
    }
    public static var dlpBannerHelpCenter: Self {
        .init(feishuID: "809587899257", larkID: "593647785207")
    }
    public static var privacySettingHelpCenter: Self {
        .init(feishuID: "669630434840", larkID: "360034747813")
    }
    public static var templateCenterHelpCenter: Self {
        .init(feishuID: "360049067736", larkID: "352554751443")
    }
    public static var wikiRouterHelpCenter: Self {
        .init(feishuID: "910118328862", larkID: "910118328862")
    }
    public static var coverHelpCenter: Self {
        .init(feishuID: "990851076781", larkID: "560882006899")
    }
    public static var quotaHelpCenter: Self {
        .init(feishuID: "360034114413", larkID: "497171699982")
    }
    public static var learnMoreHelpCenter: Self {
        .init(feishuID: "183307421587", larkID: "362275149321")
    }
    public static var baseAdPermSettingTips: Self {
        .init(feishuID: "173353144094", larkID: "067313445121")
    }
}

public extension HelpCenterURLGenerator {
    struct Config {
        public var domain: String?
        public var locale: String
        public var isFeishu: Bool

        public init(domain: String?, locale: String, isFeishu: Bool) {
            self.domain = domain
            self.locale = locale
            self.isFeishu = isFeishu
        }

        public static var `default`: Config {
            let domain = DomainSettingManager.shared.currentSetting[.helpCenter]?.first
            let locale = I18n.currentLanguageIdentifier()
            let isFeishu: Bool
            switch DomainConfig.envInfo.brand {
            case .feishu:
                isFeishu = true
            case .lark:
                isFeishu = false
            }
            return Config(domain: domain, locale: locale, isFeishu: isFeishu)
        }
    }
}

public struct HelpCenterURLGenerator {

    public enum HelpCenterError: Error {
        case domainNotFound
        case invalidURL
    }

    public struct ArticleID {
        public let feishuID: String
        public let larkID: String

        public init(feishuID: String, larkID: String) {
            self.feishuID = feishuID
            self.larkID = larkID
        }
    }

    public static func generateURL(article: ArticleID, query: [String: String]? = nil, config: Config = .default) throws -> URL {
        guard let domain = config.domain else {
            // 取不到帮助中心的 domain，具体兜底逻辑后续再细化，先由上层处理
            throw HelpCenterError.domainNotFound
        }
        let articleID = config.isFeishu ? article.feishuID : article.larkID
        // url rule: https://${domain}/hc/${locale}/articles/${articlesID}
        guard var components = URLComponents(string: "https://\(domain)/hc/\(config.locale)/articles/\(articleID)") else {
            throw HelpCenterError.invalidURL
        }
        components.queryItems = query?.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        guard let url = components.url else {
            throw HelpCenterError.invalidURL
        }
        return url
    }
}
