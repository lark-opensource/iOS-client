//
//  ChatBannerSubModule.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/7.
//

import UIKit
import Foundation
import LarkOpenIM

public protocol HasBannerType {
    var type: ChatBannerType { get }
}

open class BaseChatBannerSubModule: Module<ChatBannerContext, ChatBannerMetaModel>, HasBannerType {
    /// 开始构造视图，canHandle == true && activated == true，才会执行后续方法
    internal private(set) var didCreate: Bool = false
    open func createViews(model: ChatBannerMetaModel) { self.didCreate = true }
    open func updateViews(model: ChatBannerMetaModel) {}

    /// 是否应该展示视图
    /// display == true：willGetContentView() -> contentView()
    /// display == false：空
    public var display: Bool = false

    @available(*, deprecated, message: "this function is not support")
    open func willGetContentView() {}

    open func contentView() -> UIView? { return nil }

    open var type: ChatBannerType {
        assertionFailure("must override")
        return .unknown
    }
}

open class ChatBannerSubModule: BaseChatBannerSubModule {
}

// 密聊场景使用
open class CryptoChatBannerSubModule: BaseChatBannerSubModule {
}
