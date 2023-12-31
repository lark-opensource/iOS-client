//
//  MessageActionMetaModel.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/18.
//

import Foundation
import LarkModel
import LarkMessageBase
import RustPB

/// MessageMenu场景所需的MetaModel
public class MessageActionMetaModel: MetaModel {
    public let chat: Chat

    public let message: Message
    /// 当前是否是MyAI的分会场
    public let myAIChatMode: Bool
    /// Thread消息是否处于开启状态
    public let isOpen: Bool
    /// 创建菜单时是否在部分选择状态
    public let isInPartialSelect: Bool
    /// 唤起菜单时的触发区域
    public let copyType: CopyMessageType
    /// 获取最新选择内容
    public let selected: () -> CopyMessageSelectedType

    public init(chat: Chat,
                message: Message,
                myAIChatMode: Bool,
                isOpen: Bool,
                copyType: CopyMessageType,
                isInPartialSelect: Bool = false,
                selected: @escaping () -> CopyMessageSelectedType) {
        self.chat = chat
        self.message = message
        self.myAIChatMode = myAIChatMode
        self.isOpen = isOpen
        self.copyType = copyType
        self.selected = selected
        self.isInPartialSelect = isInPartialSelect
    }
}
