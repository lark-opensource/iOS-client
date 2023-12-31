//
//  UnknownChatPinPayload.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/4.
//

import Foundation
import LarkOpenChat
import RustPB

struct UnknownChatPinPayload: ChatPinPayload {
    let title: String
    let icon: Im_V1_UniversalChatPinIcon
}
