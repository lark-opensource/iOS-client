//
//  ScreenshotMonitor.swift
//  LarkMonitor
//
//  Created by qihongye on 2021/7/13.
//

import Foundation
import LKCommonsTracker
import Homeric
import UIKit
import EENavigator
import BootManager
import LarkDebugExtensionPoint
import LarkEMM
import LarkSensitivityControl

final class ScreenshotMonitor {
    static func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(Self.onScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: UIApplication.shared
        )
    }

    @objc
    static func onScreenshot() {
        let topClassName = getDemangledTopVC()
        Tracker.post(TeaEvent(
            Homeric.PUBLIC_KEYBOARD_SHORTCUT_CLICK,
            params: [
                "feature": "screenshot_mobile",
                "screenshot_mobile_view": topClassName
            ]
        ))
        ScreenMonitorHelper.auditEvent(currentPage: topClassName, eventType: .screenShot)

        if ScreenShotFindControllerItem.featureEnable {
            guard let topMost = Navigator.shared.mainSceneTopMost else { //Global
                return
            }
            let className = topMost.tkClassName
            let alert = UIAlertController(title: topMost.tkClassName, message: nil, preferredStyle: .alert)
            let copyAction = UIAlertAction(title: "复制", style: .default) { _ in
                // Todo 和 OpenPlatform 的 Demo 无法编译通过，这里不引用 LarkSensitivityControl/DebugEntry，直接使用字符串
                // let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
                let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
                SCPasteboard.general(config).string = className
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(copyAction)
            alert.addAction(cancelAction)
            Navigator.shared.present(alert, from: topMost) //Global
        }
    }

    private static func getDemangledTopVC() -> String {
        guard let topMost = Navigator.shared.mainSceneTopMost else { //Global
            return ""
        }
        return topMost.tkClassName
    }
}

final class ScreenshotMonitorLaunchTask: FlowBootTask, Identifiable { //Global
    static var identify = "ScreenshotMonitorLaunchTask"

    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        ScreenshotMonitor.setup()
    }
}

final class ScreenShotFindControllerItem: DebugCellItem {
    let title: String = "截屏查找控制器"
    let type: DebugCellType = .switchButton

    static var featureEnable = false
    var isSwitchButtonOn: Bool { return Self.featureEnable }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = { (isOn: Bool) in
            Self.featureEnable = isOn
        }
    }
}
