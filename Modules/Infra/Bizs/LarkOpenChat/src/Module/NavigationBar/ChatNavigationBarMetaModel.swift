//
//  ChatNavigationBarMetaModel.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/10/12.
//

import Foundation
import LarkModel
import LarkOpenIM

/// 导航栏所需的MetaModel
public struct ChatNavigationBarMetaModel: MetaModel {

    public let chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}
