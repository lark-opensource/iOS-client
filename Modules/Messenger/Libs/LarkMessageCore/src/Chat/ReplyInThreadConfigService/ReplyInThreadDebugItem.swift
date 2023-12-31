//
//  ReplyInThreadDebugItem.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/6/2.
//

import Foundation
import UIKit
import EENavigator
import LarkDebugExtensionPoint
/// 产品希望后续iOS端在replyInThread上跑的快些，做一些实验功能给KDM体验，后续其他端对齐决策
/// 故有iOS的实验室功能 故在debug界面单起一个界面 方便后续快跑
struct ReplyInThreadDebugItem: DebugCellItem {
    let title = "reply in thread 实验室"
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let debugReplyThreadVC = ReplyInThreadDebugConfigVC()
        DispatchQueue.main.async {
            Navigator.shared.push(debugReplyThreadVC, from: debugVC) // Global
        }
    }
}
