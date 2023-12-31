//
//  ChatDataContextProtocol.swift
//  LarkChat
//
//  Created by ByteDance on 2023/9/4.
//

import Foundation

protocol ChatDataContextProtocol {
    var identify: String { get } //仅用作日志，用于区分不同的Context实现

    var firstMessagePosition: Int32 { get }
    var lastMessagePosition: Int32 { get }
    var lastVisibleMessagePosition: Int32 { get }
    var readPositionBadgeCount: Int32 { get }
    var readPosition: Int32 { get }
    var lastReadPosition: Int32 { get }
}
