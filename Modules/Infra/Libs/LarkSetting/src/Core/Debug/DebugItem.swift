//
//  DebugItem.swift
//  LarkSetting
//
//  Created by Supeng on 2021/7/21.
//

import UIKit
import Foundation
#if ALPHA

import LarkDebugExtensionPoint
import EENavigator
import LarkContainer
import LarkAccountInterface
import SwiftUI

/// LarkSetting调试项
struct LarkSettingDebugItem: DebugCellItem {
    let title = "LarkSetting"
    let type = DebugCellType.disclosureIndicator

    @Provider private var accountService: AccountService
    private var currentChatterId: String { accountService.currentChatterId }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.present(LarkSettingDebugController(userID: currentChatterId).navigationWrapper, from: debugVC)
    }
}

/// FG调试项
struct FeatureGatingDebugItem: DebugCellItem {
    let title = "FeatureGating"
    let type = DebugCellType.disclosureIndicator

    @Provider private var accountService: AccountService
    private var currentChatterId: String { accountService.currentChatterId }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        if #available(iOS 16.0, *) {
            Navigator.shared.push(
                UIHostingController(rootView: FeatureGatingDebugView(userID: currentChatterId)),
                from: debugVC)
        } else {
            // Fallback on earlier versions
            Navigator.shared.present(FeatureGatingController(chatterID: currentChatterId).navigationWrapper, from: debugVC)
        }
    }
}

private extension UIViewController {
    var navigationWrapper: UINavigationController {
        let navigation = UINavigationController(rootViewController: self)
        navigation.modalPresentationStyle = .fullScreen
        return navigation
    }
}

#endif

#if DEBUG
public func debugViewControllerOfFG() -> UIViewController {
    if #available(iOS 16.0, *) {
        return UIHostingController(rootView: FeatureGatingDebugView(userID: "currentChatterId"))
    } else {
        // Fallback on earlier versions
        return FeatureGatingController(chatterID: "currentChatterId").navigationWrapper
    }
}
#endif
