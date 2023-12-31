//
//  SearchPickerDebugItem.swift
//  LarkContact
//
//  Created by Yuri on 2023/11/29.
//

#if !LARK_NO_DEBUG
import Foundation
import LarkDebugExtensionPoint
import UIKit
import EENavigator
import LarkContainer

struct SearchPickerDebugItem: DebugCellItem {
    var title: String = "SearchPicker Demo"
    var type: DebugCellType { return .disclosureIndicator }
    let userResolver: LarkContainer.UserResolver
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let nav = UINavigationController(rootViewController: SearchPickerWebController(resolver: userResolver))
        nav.modalPresentationStyle = .fullScreen
        Navigator.shared.present(nav, from: debugVC)
    }
}
#endif
