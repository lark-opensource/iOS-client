//
//  ChatPinActionItemType.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkModel

public enum ChatPinActionItemType {
    case commonType(ChatPinActionCommonType)
    case item(ChatPinActionItem)
}

public enum ChatPinActionCommonType {
    case unPin /// 移除
    case stickToTop /// 固定到首位
    case unSticktoTop /// 取消固定到首位
}

// Pin Action
public protocol ChatPinActionHandler {
    func handle(pin: ChatPin, chat: Chat)
}

public struct ChatPinActionItem {
    public let title: String
    public let image: UIImage
    public let handler: ChatPinActionHandler

    public init(title: String, image: UIImage, handler: ChatPinActionHandler) {
        self.title = title
        self.image = image
        self.handler = handler
    }
}


