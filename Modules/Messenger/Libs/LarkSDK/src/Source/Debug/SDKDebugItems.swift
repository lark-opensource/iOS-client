//
//  SDKDebugItems.swift
//  LarkSDK
//
//  Created by CharlieSu on 11/25/19.
//

import UIKit
import Foundation
import LarkDebugExtensionPoint
import LarkSDKInterface
import LarkAlertController
import EENavigator
import LarkAccountInterface
import LarkStorage

struct ClearCurrentUserUserDefaultsItem: DebugCellItem {
    var title: String { return "清除当前用户的UserDefaults数据" }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let alertController = LarkAlertController()
        alertController.addSecondaryButton(text: "取消")
        alertController.setTitle(text: "确定要清除当前用户的UserDefaults数据？")
        alertController.addDestructiveButton(text: "确定", dismissCompletion: {
            KVStores.clearAllForCurrentUser(type: .udkv)
        })

        DispatchQueue.main.async {
            Navigator.shared.present(alertController, from: debugVC)
        }
    }
}

struct ClearStandardUserDefaultsItem: DebugCellItem {
    var title: String { return "清除标准的UserDefaults数据" }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let alertController = LarkAlertController()
        alertController.addSecondaryButton(text: "取消")
        alertController.setTitle(text: "确定要清除标准的UserDefaults数据？")
        alertController.addDestructiveButton(text: "确定", dismissCompletion: {
            KVStores.clearAllForStandard()
        })
        DispatchQueue.main.async {
            Navigator.shared.present(alertController, from: debugVC)
        }
    }
}

struct ClearLaunchGuideUserDefaultsItem: DebugCellItem {
    var title: String { return "清除启动引导页UserDefaults数据" }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let alertController = LarkAlertController()
        alertController.addSecondaryButton(text: "取消")
        alertController.setTitle(text: "确定要清除LaunchGuide的UserDefaults数据?")
        alertController.addDestructiveButton(text: "确定", dismissCompletion: {
            KVStores.udkv(
                space: .global,
                domain: Domain.biz.core.child("LaunchGuide")
            ).clearAll()
        })
        DispatchQueue.main.async {
            Navigator.shared.present(alertController, from: debugVC)
        }
    }
}

struct ResetLarkItem: DebugCellItem {
    var title: String { return "重置Lark" }

    private let userSpace: () -> UserSpaceService?

    init(userSpace: @escaping () -> UserSpaceService?) {
        self.userSpace = userSpace
    }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let alertController = LarkAlertController()
        alertController.addSecondaryButton(text: "取消")
        alertController.setTitle(text: "确定要重置Lark？\n(重置后,需要杀掉应用后重新登录)")
        alertController.addDestructiveButton(text: "确定", dismissCompletion: {
            // Remove user data
            if let userDirURL = self.userSpace()?.currentUserDirectory {
                try? userDirURL.asAbsPath().notStrictly.removeItem()
            }

            // Remove rust auth client storage data
            let rustPath = AbsPath.document + "sdk_storage"
            try? rustPath.notStrictly.removeItem()

            KVStores.clearAllForCurrentUser()
            KVStores.clearAllForStandard()
        })
        DispatchQueue.main.async {
            Navigator.shared.present(alertController, from: debugVC)
        }
    }
}
