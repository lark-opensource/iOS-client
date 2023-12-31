//
//  ForceTouchApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import AppContainer
import EENavigator
import RunloopTools
import LarkUIKit
import LarkFeatureSwitch
import LarkFeatureGating
import LKCommonsTracker
import Homeric
import LarkFoundation
import LarkTab
import QRCode

let feedURL = Tab.feed.url

enum ShortcutItemsType: String {
    case scan

    func shortCutItem() -> UIApplicationShortcutItem {
        switch self {
        case .scan:
            let scanIcon = UIApplicationShortcutIcon(templateImageName: "navi_plus_scan")
            let scanItem = UIMutableApplicationShortcutItem(type: self.rawValue, localizedTitle: BundleI18n.LarkQRCode.Lark_Legacy_LarkScan, localizedSubtitle: nil, icon: scanIcon, userInfo: nil)
            if #available(iOS 13.0, *) {
                scanItem.targetContentIdentifier = "default"
            }
            return scanItem
        }
    }
}

public final class ForceTouchApplicationDelegate: ApplicationDelegate {
    public static let config = Config(name: "ForceTouch", daemon: true)

    public required init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.performAction(message)
        }

        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.performSceneAction(message)
            }
        }
    }

    func setup() {
        let scanEnable: Bool = !Utils.isiOSAppOnMacSystem
        if scanEnable {
            UIApplication.shared.shortcutItems = [ShortcutItemsType.scan.shortCutItem()]
        } else {
            UIApplication.shared.shortcutItems = []
        }
    }

    private func performAction(_ message: PerformAction) {
        self.performAction(shortcutItemType: message.shortcutItem.type, completionHandler: message.completionHandler)
    }

    @available(iOS 13.0, *)
    private func performSceneAction(_ message: WindowScenePerformAction) {
        self.performAction(shortcutItemType: message.shortcutItem.type, completionHandler: message.completionHandler)
    }

    private func performAction(shortcutItemType: String, completionHandler: (Bool) -> Void) {
        guard let itemType = ShortcutItemsType(rawValue: shortcutItemType) else {
            completionHandler(false)
            return
        }
        switch itemType {
        case .scan:
            Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_CONTACTS,
                                  params: ["source": "iOS_3dtouch"
                                  ]))
            var params = NaviParams()
            params.switchTab = feedURL
            LarkQRCodeNavigator.showQRCodeViewControllerIfNeeded(from: self, params: params)
        }
        completionHandler(true)
    }
}

extension ForceTouchApplicationDelegate: NavigatorFrom {
    public var fromViewController: UIViewController? {
        Navigator.shared.mainSceneTopMost ?? UIViewController() //Global
    }
}
