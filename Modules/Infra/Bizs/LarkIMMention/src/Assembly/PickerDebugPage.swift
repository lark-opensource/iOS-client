//
//  PickerDebugPage.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/5/10.
//
#if !LARK_NO_DEBUG
import Foundation
import LarkDebugExtensionPoint
import UIKit
import EENavigator

struct PickerDebugPage: DebugCellItem {
    var title: String = "IMMention"
    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(IMMentionDebugViewController(), from: debugVC)
    }
}
#endif
