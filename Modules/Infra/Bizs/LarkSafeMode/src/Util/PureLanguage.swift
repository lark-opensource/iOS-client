//
//  PureLanguage.swift
//  LarkSafeMode
//
//  Created by luyz on 2023/9/18.
//

import Foundation

final class PureLanguage {
    @inlinable
    static var pureSafeModeViewTitle: String {
        return getLanguageType().contains("zh-") ? "安全模式" : "Safe mode"
    }
    
    @inlinable
    static var pureSafeModeViewDataError: String {
        return getLanguageType().contains("zh-") ? "数据异常" : "Data error"
    }
    
    @inlinable
    static var pureSafeModeViewDescTitle: String {
        return getLanguageType().contains("zh-") ? "系统检测到应用数据异常，需进行修复，\n修复完成后，你可能需要重新登录账号，\n你的所有数据将不受影响" : "The system has detected a data error.\n But don't worry, your data will be securely kept. Once the issue is fixed, \nyou can log in to your account."
    }
    
    @inlinable
    static var pureSafeModeViewStartFixTitle: String {
        return getLanguageType().contains("zh-") ? "开始修复" : "Start Fixing"
    }
    
    @inlinable
    static var pureSafeModeViewDataFixingTitle: String {
        return getLanguageType().contains("zh-") ? "数据修复中" : "Data fixing"
    }
    
    @inlinable
    static var pureSafeModeViewDataFixingButtonTitle: String {
        return getLanguageType().contains("zh-") ? "正在修复数据" : "Fixing Data"
    }
    
    @inlinable
    static var pureSafeModeViewGotItTitle: String {
        return getLanguageType().contains("zh-") ? "我知道了" : "Got It"
    }
    
    @inlinable
    static var pureSafeModeViewRestartTitle: String {
        return getLanguageType().contains("zh-") ? "修复完成请重启应用" : "Repair completed. Please restart the app"
    }
    
    static func getLanguageType() -> String {
        let def = UserDefaults.standard
        let allLanguages: [String] = def.object(forKey: "AppleLanguages") as? [String] ?? [""]
        let chooseLanguage = allLanguages.first
        return chooseLanguage ?? "en"
    }
}
