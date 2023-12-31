//
//  MessageMenuDebugItem.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/7/1.
//

#if DEBUG || ALPHA || BETA
import Foundation
import UIKit
import EENavigator
import LarkStorage
import LarkContainer
import LarkDebugExtensionPoint

/// 长按消息菜单，是否出现CopyMsgId选项，Debug使用
struct MessageMenuDebugItem: DebugCellItem {
    let title = "Message Menu Enable CopyMsgId"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return KVStores.Messenger.global().bool(forKey: DebugMessageActionSubModule.debugKey)
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        KVStores.Messenger.global()[DebugMessageActionSubModule.debugKey] = on
    }
}
#endif
