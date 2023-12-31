//
//  UDDebug.swift
//  UDDebug
//
//  Created by 白镜吾 on 2021/8/5.
//

#if !LARK_NO_DEBUG
import Foundation
import LarkDebugExtensionPoint
import EENavigator

struct UDDebugItem: DebugCellItem {
    let title = "UD Debug"
    let type: DebugCellType = .disclosureIndicator

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let vc = UDListViewController()
        Navigator.shared.push(vc, from: debugVC)
    }

    init() {
    }
}
#endif


