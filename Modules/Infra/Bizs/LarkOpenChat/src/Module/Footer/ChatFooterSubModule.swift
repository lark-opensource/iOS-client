//
//  ChatFooterSubModule.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2022/7/7.
//

import UIKit
import Foundation
import LarkOpenIM

/// 注册不同类型的type, 并且type自带优先级,高优先级会优先展示,低优先级不展示
/// 后续如果新增一种footer时,需要先判断一下footer的优先级
public enum ChatFooterType: Int {
    case unkown
    case botBan
    case resignChatMask
    case applyToJoinGroup
}

/// 获取当前的FooterType,用于排序后决定显示哪个footer
public protocol HasFooeterType {
    var type: ChatFooterType { get }
}
open class BaseChatFooterSubModule: Module<ChatFooterContext, ChatFooterMetaModel>, HasFooeterType {
    private(set) var didCreate: Bool = false
    open func createViews(model: ChatFooterMetaModel) { self.didCreate = true }
    open func updateViews(model: ChatFooterMetaModel) {}
    /// 是否应该展示视图
    /// display == true：willGetContentView() -> contentView()
    /// display == false：空
    public var display: Bool = false
    open var type: ChatFooterType {
        assertionFailure("must be overrided")
        return .unkown
    }
    open func contentView() -> UIView? {
        return nil
    }
}

open class ChatFooterSubModule: BaseChatFooterSubModule {
}

open class CryptoChatFooterSubModule: BaseChatFooterSubModule {
}
