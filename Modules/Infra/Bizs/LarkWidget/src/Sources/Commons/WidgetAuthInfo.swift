//
//  WidgetAuthInfo.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/11.
//

import Foundation
import LarkLocalizations

public struct WidgetAuthInfo: Codable, Equatable {

    /// 是否为精简模式
    public var isMinimumMode: Bool
    /// 是否已登录
    public var isLogin: Bool
    /// 是否为国内租户（Feishu or Lark）
    public var isFeishuBrand: Bool
    /// 当前 App 语言
    public var appLanguage: String
    /// 帮助文档页面域名
    public var helpCenterHost: String?
    /// AppLink 域名
    public var applinkHost: String?
    /// Docs 主页面域名
    public var docsHost: String?
    
    /// 使用传入的 AuthInfo 更新 Widget 中所使用到的环境变量（Language、Host 等）
    public static func updateEnvironmentVariables(with authInfo: WidgetAuthInfo) {
        WidgetI18n.language = Lang(rawValue: authInfo.appLanguage)
        WidgetLink.applinkHost = authInfo.applinkHost ?? ""
        WidgetLink.helpCenterHost = authInfo.helpCenterHost ?? ""
        WidgetLink.docsHomeHost = authInfo.docsHost ?? ""
    }

    public init(isMinimumMode: Bool,
                isLogin: Bool,
                isFeishuBrand: Bool,
                appLanguage: String = LanguageManager.currentLanguage.rawValue,
                helpCenterHost: String?,
                applinkHost: String?,
                docsHost: String?) {
        self.isMinimumMode = isMinimumMode
        self.isLogin = isLogin
        self.isFeishuBrand = isFeishuBrand
        self.appLanguage = appLanguage
        self.helpCenterHost = helpCenterHost
        self.docsHost = docsHost
        self.applinkHost = applinkHost
    }

    public static func notLoginInfo(isFeishu: Bool, 
                                    hcHost: String? = nil,
                                    applinkHost: String? = nil,
                                    docsHost: String? = nil) -> WidgetAuthInfo {
        return WidgetAuthInfo(isMinimumMode: false,
                              isLogin: false,
                              isFeishuBrand: isFeishu,
                              helpCenterHost: hcHost,
                              applinkHost: applinkHost,
                              docsHost: docsHost)
    }
    
    public static func normalInfo(isFeishu: Bool,
                                    hcHost: String? = nil,
                                    applinkHost: String? = nil,
                                    docsHost: String? = nil) -> WidgetAuthInfo {
        return WidgetAuthInfo(isMinimumMode: false,
                              isLogin: true,
                              isFeishuBrand: isFeishu,
                              helpCenterHost: hcHost,
                              applinkHost: applinkHost,
                              docsHost: docsHost)
    }
}
