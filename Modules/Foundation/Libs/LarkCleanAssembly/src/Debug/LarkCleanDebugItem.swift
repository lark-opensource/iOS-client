//
//  LarkCleanDebugItem.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/6/29.
//  

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import EENavigator
import LarkDebugExtensionPoint

struct LarkCleanDebugItem: DebugCellItem {
    let title = "LarkClean"
    var type: DebugCellType { .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(DebugHomeViewController(), from: debugVC)
    }
}

#endif
