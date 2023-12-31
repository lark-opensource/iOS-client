//
//  ChatSystemCellViewModel.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/3/31.
//

import Foundation
import LarkMessageCore
import LarkModel
import LarkMessageBase

final class ChatSystemCellViewModel: SystemCellViewModel<ChatContext>, HasCellConfig {
    var cellConfig: ChatCellConfig = ChatCellConfig()
}
