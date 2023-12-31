//
//  ChatBannerMetaModel.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/8.
//

import Foundation
import LarkModel
import LarkOpenIM

/// Chat中Banner场景所需的MetaModel
public struct ChatBannerMetaModel: MetaModel {
    /// chat因为更新太频繁，变化后不会主动调用ChatBannerModule.modelDidChange
    public let chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}
