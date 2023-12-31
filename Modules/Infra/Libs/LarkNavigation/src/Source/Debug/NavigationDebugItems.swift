//
//  NavigationDebugItems.swift
//  LarkNavigation
//
//  Created by CharlieSu on 11/28/19.
//

import UIKit
import Foundation
import LarkDebugExtensionPoint
import EENavigator
import LarkFeatureSwitch
import LarkAccountInterface
import Swinject

struct IPadFeatureSwitchDebugItem: DebugCellItem {
    var title: String { return "iPadFeatureSwitch" }
    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let vc = PadFeatureSwitchViewController()
        vc.modalPresentationStyle = .fullScreen
        Navigator.shared.present(UINavigationController(rootViewController: vc), from: debugVC)
    }
}

struct CustomNaviDebutItem: DebugCellItem {
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }
    var title: String { return "主导航自定义调试" }
    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(NavigationDebugViewController(resolver: resolver), from: debugVC)
    }
}

public var enableNaviDebugGuide: Bool = false
struct ShowNavigationGuide: DebugCellItem {
    var title: String { return "展示导航引导" }
    var type: DebugCellType { return .switchButton }
    var isSwitchButtonOn: Bool = enableNaviDebugGuide

    let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        enableNaviDebugGuide = isOn
    }
}
