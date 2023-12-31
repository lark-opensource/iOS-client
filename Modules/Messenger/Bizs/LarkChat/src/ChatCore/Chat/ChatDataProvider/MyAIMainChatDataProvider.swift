//
//  MyAIMainChatDataProvider.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/19.
//

import Foundation
import LarkModel

class MyAIMainChatDataProvider: NormalChatDataProvider {
    override func filterMessages(_ messages: [Message]) -> [Message] {
        return messages
    }
}
