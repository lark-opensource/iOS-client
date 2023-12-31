//
//  IMMentionContext.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/9.
//

import Foundation

public struct IMMentionContext {
    var currentChatterId: String
    var currentTenantId: String
    var currentChatId: String
    // 群人数
    var chatUserCount: Int32
    // 当前用户在本群能否ATALL
    var isEnableAtAll: Bool
    var showChatUserCount: Bool
}
