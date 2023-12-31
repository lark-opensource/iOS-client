//
//  SelectLanguageController+Tracker.swift
//  
//
//  Created by kongkaikai on 2021/6/15.
//

import Foundation
import LarkLocalizations
import Homeric
import LKCommonsTracker

/// https://bytedance.feishu.cn/sheets/shtcnuEpsnwXsFYmhg7UiK5DxQf?sheet=W2tnFO
/// Language switch tracker
public extension SelectLanguageController {
    internal func trackerClick(
        oldLang: LarkLocalizations.Lang,
        lang: LarkLocalizations.Lang,
        oldIsSelectSystem: Bool,
        isSelectSystem: Bool
    ) {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "language_show",
            "target": "none",
            "click_type": oldLang.localeIdentifier,
            "view_type": lang.localeIdentifier,
            "is_default_click": isSelectSystem,
            "is_default_view": oldIsSelectSystem
        ]))
    }

    func trackerLanguageSetting() {
        let osLanguage: String = LanguageManager.systemLanguage?.localeIdentifier ?? ""
        Tracker.post(TeaEvent(Homeric.SETTING_APP_LANGUAGE_VIEW, params: [
            "os_language": osLanguage,
            "app_language": LanguageManager.currentLanguage.localeIdentifier,
            "is_default": LanguageManager.isSelectSystem,
            "upload_type": "open"
        ]))
    }
}
