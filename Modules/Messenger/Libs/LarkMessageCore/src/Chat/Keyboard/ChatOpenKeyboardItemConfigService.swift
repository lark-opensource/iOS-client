//
//  ChatOpenKeyboardItemConfigService.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/9/7.
//

import UIKit
import LarkChatKeyboardInterface
import LarkKeyboardView

/// 阅后即焚
public class ChatKeyboardBurnTimeItemConfig: ChatKeyboardItemConfig<KeyboardUIConfig, KeyboardSendConfig> {
    public override var key: KeyboardItemKey {
        return .burnTime
    }
}

public protocol ChatOpenKeyboardItemConfigService: AnyObject {
    func getChatKeyboardItemFor<T: AnyObject>(_ key: KeyboardItemKey) -> T?
}

public class ChatOpenKeyboardItemConfigEmptyServiceIMP: ChatOpenKeyboardItemConfigService {
    public func getChatKeyboardItemFor<T: AnyObject>(_ key: KeyboardItemKey) -> T? {
        return nil
    }
    public init() {}
}
