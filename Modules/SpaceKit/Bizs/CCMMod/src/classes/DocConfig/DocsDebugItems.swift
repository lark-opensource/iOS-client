//
//  DocsDebugItems.swift
//  LarkSpaceKit
//
//  Created by CharlieSu on 11/28/19.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator
import SpaceKit
import SKCommon

struct DocsDebugItem: DebugCellItem {
    let title: String = "Docs"
    let type: DebugCellType = .disclosureIndicator

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(DocsSercetDebugViewController(), from: debugVC)
    }
}
