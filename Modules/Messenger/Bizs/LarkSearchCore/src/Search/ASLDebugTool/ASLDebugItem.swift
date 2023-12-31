//
//  ASLDebugItem.swift
//  LarkSearchCore
//
//  Created by chenziyue on 2021/12/13.
//

import Foundation
import LarkDebugExtensionPoint
import UIKit
import EENavigator
import LarkStorage
import LarkContainer

struct ASLDebugItem: DebugCellItem {
    var title: String = "ASL调试选项"
    var type: DebugCellType { return .disclosureIndicator }
    var debugViewController: ASLDebugViewController

    private static let globalStore = KVStores.SearchDebug.globalStore
    static var isLynxDebugOn: Bool = globalStore[KVKeys.SearchDebug.localDebugOn]

    var userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.debugViewController = ASLDebugViewController(userResolver: userResolver)
    }
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        self.userResolver.navigator.push(debugViewController, from: debugVC)
    }

    final class ASLTextFieldItem: ASLDebugCellItem {
        var isSwitchButtonOn: Bool = false
        var title: String = "Hosts:"
        var detail: String = globalStore[KVKeys.SearchDebug.lynxHostKey]
        var type: ASLDebugCellType { return .none }
    }

    final class ASLFGItem: ASLDebugCellItem {
        var isSwitchButtonOn: Bool = false
        var title: String = "AI&Search相关FG"
        var detail = ""
        var type: ASLDebugCellType { return .none }
        var userResolver: UserResolver
        init(userResolver: UserResolver) {
            self.userResolver = userResolver
        }
        func didSelect(_ item: ASLDebugCellItem, debugVC: UIViewController) {
            let fgNaviController = UINavigationController(rootViewController: ASLFeatureGatingController(resolver: self.userResolver))
            fgNaviController.modalPresentationStyle = .fullScreen
            self.userResolver.navigator.present(fgNaviController, from: debugVC)
        }
    }

    final class LynxLocalItem: ASLDebugCellItem {
        var isSwitchButtonOn: Bool = globalStore[KVKeys.SearchDebug.localDebugOn]
        var title: String = "是否开启本地调试"
        var detail = ""
        var type: ASLDebugCellType { return .switchButton }
        var switchValueDidChange: ((Bool) -> Void)? = { (on) in
            globalStore[KVKeys.SearchDebug.localDebugOn] = on
            ASLDebugItem.isLynxDebugOn = on
        }
    }

    final class ContextIdItem: ASLDebugCellItem {
        var isSwitchButtonOn: Bool = globalStore[KVKeys.SearchDebug.contextIdShow]
        var title: String = "是否浮现ContextId"
        var detail = ""
        var type: ASLDebugCellType { return .switchButton }
        var switchValueDidChange: ((Bool) -> Void)? = { (on) in
            globalStore[KVKeys.SearchDebug.contextIdShow] = on
            NotificationCenter.default.post(name: NSNotification.Name(KVKeys.SearchDebug.contextIdShow.raw), object: nil, userInfo: ["isOn": on])
        }
    }
}
