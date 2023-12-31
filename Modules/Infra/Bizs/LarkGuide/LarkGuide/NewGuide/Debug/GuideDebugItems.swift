//
//  LarkGuideDebugItem.swift
//  LarkNavigation
//
//  Created by zhenning on 2020/12/10.
//

import UIKit
import Foundation
import LarkDebugExtensionPoint
import EENavigator
import LarkUIKit

struct LarkGuideDebugItem: DebugCellItem {
    var title: String { return "Guide Debug" }
    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let vc = LarkGuideDebugController()
        vc.modalPresentationStyle = .fullScreen
        Navigator.shared.present(UINavigationController(rootViewController: vc), from: debugVC)
    }
}
