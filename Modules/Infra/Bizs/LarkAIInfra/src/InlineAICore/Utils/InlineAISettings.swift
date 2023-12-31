//
//  InlineAISettings.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/10/30.
//  


import UIKit
import LarkSetting
import LarkContainer

struct InlineAISettings {
    
    @Setting(.useDefaultKeys)
    static var urlRegexConfig: DocsURLRegexConfig?
    
    var userResolver: LarkContainer.UserResolver
    init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
    }

    var urlParseEnable: Bool {
       let fg = try? userResolver.resolve(type: FeatureGatingService.self)
       return fg?.staticFeatureGatingValue(with: "ccm.mobile.inline_ai_parse_url_enable") ?? false
    }
    
    enum AIConfigKey: String {
        case urlSchemeHandleEnable = "url_scheme_handle_enable"
        case xmlParseEnable = "xml_parse_enable"
    }

    private func config(of key: AIConfigKey) -> Any? {
        let setting = try? userResolver.resolve(type: SettingService.self)
        let config = try? setting?.staticSetting(with: .make(userKeyLiteral: "ccm_mobile_inline_ai_configs"))
        return config?[key.rawValue]
    }
    
    var urlSchemeHandleEnable: Bool {
        return (config(of: .urlSchemeHandleEnable) as? Bool) ?? false
    }
    
    var xmlParseEnable: Bool {
        return (config(of: .xmlParseEnable) as? Bool) ?? false
    }
}

///  邮箱、URL正则匹配规则
 struct DocsURLRegexConfig: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "ccm_at_regex_config")
    let linkRegex: String
    let newRuleEnable: Bool
    let blackSuffixList: [String]
}
