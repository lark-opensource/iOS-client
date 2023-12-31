//
//  FontLaunchTask.swift
//  LarkFontAssembly
//
//  Created by 白镜吾 on 2023/3/21.
//

import Foundation
import LarkLocalizations
import BootManager
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme
import LKCommonsLogging
import LKCommonsTracker
import LarkSetting

final class FontLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "FontLaunchTask"

    override var runOnlyOnce: Bool { return true }//目前这个Task和user相关，但是暂时只希望执行一次

    override func execute(_ context: BootContext) {
        initUDTrackerIfNeeded()
        initIconFontIfNeeded()

//        guard LarkFont.isNewFontEnabled(fg: userResolver.fg) else { return }
//
//        guard #available(iOS 12.0, *) else { return }
//
//        // Lark Circular 多语言混排：https://bytedance.feishu.cn/docx/IQzsdkHfKoCannxP0WKce9C8nIh
//        let circularBanList: [Lang] = [.ja_JP, .vi_VN]
//
//        if circularBanList.contains(LanguageManager.currentLanguage) {
//            LarkFont.shared.addObserver()
//        } else {
//            LarkFont.setFontAppearance()
//            LarkFont.setComponentFontIfNeeded()
//            LarkFont.swizzleIfNeeded()
//            LarkFont.shared.addObserver()
//            NotificationCenter.default.post(name: LarkFont.systemFontDidChange, object: nil)
//        }
    }

    func initUDTrackerIfNeeded() {
        // 临时将 UDIcon 的日志在这儿注入
        if LarkFont.isUDTrackerEnabled(fg: userResolver.fg) {
            let tracker = UDTracker()
            UDIcon.tracker = tracker
            UDColor.tracker = tracker
            UDFont.tracker = tracker
        } else {
            UDIcon.tracker = nil
            UDColor.tracker = nil
            UDFont.tracker = nil
        }
    }

    func initIconFontIfNeeded() {
        if LarkFont.isIconFontEnabled(fg: userResolver.fg) {
            UDIcon.iconFontEnable = true
        } else {
            UDIcon.iconFontEnable = false
        }
    }
}
