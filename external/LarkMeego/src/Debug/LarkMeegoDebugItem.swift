//
//  LarkMeegoDebugItem.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/9/14.
//

import Foundation
import LarkDebugExtensionPoint
import UIKit

struct LarkMeegoDebugItem: DebugCellItem {
    let title: String = "Meego Env Debugger"
    let type: DebugCellType = .disclosureIndicator

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let debugger = MeegoEnvDebugViewController()
        debugVC.navigationController?.pushViewController(debugger, animated: true)
    }
}
