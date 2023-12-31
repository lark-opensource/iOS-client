//
//  ChatPinSummaryCellMetaModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkModel
import LarkOpenIM

public struct ChatPinSummaryCellMetaModel: MetaModel {
    public var chat: Chat {
        return self.getChat()
    }
    private let getChat: () -> Chat
    public let pin: ChatPin
    public init(getChat: @escaping () -> Chat, pin: ChatPin) {
        self.getChat = getChat
        self.pin = pin
    }
}
