//
//  ChatKeyboardTopExtendSubModule.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/8/9.
//

import UIKit
import Foundation
import LarkOpenIM

protocol HasTopExtendType {
    var type: ChatKeyboardTopExtendType { get }
}

/// 复写方法时，记得先调用super
open class BaseChatKeyboardTopExtendSubModule: Module<ChatKeyboardTopExtendContext, ChatKeyboardTopExtendMetaModel>, HasTopExtendType {
    open var type: ChatKeyboardTopExtendType {
        assertionFailure("must override")
        return .unknown
    }

    open func createContentView(model: ChatKeyboardTopExtendMetaModel) {
        assertionFailure("must override")
    }

    open func contentView() -> UIView? { return nil }

    /// contentView相对于顶部的margin，默认使用ChatKeyboardTopExtendView.contentTopMargin = 8，和线上保持一致
    open func contentTopMargin() -> CGFloat { return 8 }
}

open class ChatKeyboardTopExtendSubModule: BaseChatKeyboardTopExtendSubModule {
}

open class CryptoChatKeyboardTopExtendSubModule: BaseChatKeyboardTopExtendSubModule {
}
