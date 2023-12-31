//
//  LarkStorageDebugItem.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/10/31.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import EENavigator
import LarkDebugExtensionPoint

struct LarkStorageDebugItem: DebugCellItem {
    let title = "LarkStorage"
    var type: DebugCellType { .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(LarkStorageDebugController(), from: debugVC)
    }
}
#endif
