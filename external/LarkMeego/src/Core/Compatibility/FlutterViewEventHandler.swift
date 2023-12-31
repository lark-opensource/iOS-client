//
//  FlutterViewEventHandler.swift
//  LarkMeego
//
//  Created by qsc on 2023/8/15.
//

import Foundation
import EENavigator
import LarkFlutterContainer
import UniverseDesignDialog
import LarkLocalizations
import LarkStorage
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import LarkMeegoLogger

/// 弹窗配置中若未提供当前语言的提示内容，默认使用英文内容
let DEFAULT_LANGUAGE = "en_us"

/// FlutterVC 显示后，根据弹窗配置显示弹窗
class FlutterViewEventHandler {

    private(set) var abilityConfig: MeegoAbilityConfig
    /// 当前页面路由，埋点参数
    private(set) var route: String
    /// 来源信息，埋点参数
    private(set) var from: String

    private let kvStore = Container.shared.getCurrentUserResolver().udkv(domain: Domain.biz.meego)

    private var needShowDialog = true

    init(abilityConfig: MeegoAbilityConfig, route: String, from: String) {
        self.abilityConfig = abilityConfig
        self.route = route
        self.from = from
    }

    func buildDialog() -> UDDialog? {

        // 一次打开只显示一次，防止飞书 Native 路由后再次显示弹窗
        guard needShowDialog else {
            return nil
        }
        let config = abilityConfig.compatibility
        let currentLanguage = LanguageManager.currentLanguage.localeIdentifier.lowercased()

        let title = config.title?[currentLanguage] ?? config.title?[DEFAULT_LANGUAGE]
        let content = config.content?[currentLanguage] ?? config.content?[DEFAULT_LANGUAGE]

        guard let content = content else {
            return nil
        }

        if let freqLimit = config.freqLimit, freqLimit > 0 {
            @KVConfig(key: KVKey("meego.upgrade_remind.timestamp", default: 0), store: kvStore)
            var lastUpgradeRemindTime: Int

            // 有频控参数且频控有效
            let currentUnixTimestamp = Int(NSDate().timeIntervalSince1970)
            if currentUnixTimestamp - lastUpgradeRemindTime < freqLimit {
                // 上次展示时间距现在 < 频控时间，退出
                MeegoLogger.info("meego.upgrade_remind.timestamp match freq_limit")
                return nil
            } else {
                // 更新展示时间
                lastUpgradeRemindTime = currentUnixTimestamp
                MeegoLogger.info("update meego.upgrade_remind.timestamp = \(lastUpgradeRemindTime)")
            }
        }

        let dialog = UDDialog(config: UDDialogUIConfig())
        if let title = title {
            dialog.setTitle(text: title)
        }
        dialog.setContent(text: content)
        dialog.addPrimaryButton(text: BundleI18n.LarkMeego.Meego_Shared_MobileCommon_NewFeaturePleaseUpdateAppPopUp_GotItButton)
        return dialog
    }
}

extension FlutterViewEventHandler: LarkFlutterViewLifecycleEventProtocol {

    func onViewDidLoad(viewControler: UIViewController) {}

    func onViewWillAppear(viewControler: UIViewController) {}

    func onViewDidAppear(viewControler: UIViewController) {
        if let diaglog = buildDialog() {
            self.needShowDialog = false // 一次生命周期只显示一次弹窗
            Navigator.shared.present(diaglog, from: viewControler)
            trackMeegoUpgradeReminder()
        }
    }

    func onViewWillDisappear(viewControler: UIViewController) {}

    func onViewDidDisappear(viewControler: UIViewController) {}
}

extension FlutterViewEventHandler {
    func trackMeegoUpgradeReminder() {
        let slardarEvent = SlardarEvent(
            name: "meego_upgrade_reminder",
            metric: [:],
            category: [
                "route": route,
                "from": from
            ],
            extra: [:]
        )
        Tracker.post(slardarEvent)
    }
}
