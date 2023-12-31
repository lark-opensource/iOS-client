//
//  ChatMagicInterceptor.swift
//  LarkChat
//
//  Created by mochangxing on 2020/11/11.
//

import Foundation
import LarkMagic

final class ChatMagicInterceptor: ScenarioInterceptor {
    var isAlterShowing: Bool = false
    var isPopoverShowing: Bool = false
    var isDrawerShowing: Bool = false
    var isModalShowing: Bool = false
    var otherInterceptEvent: Bool = false

    init() {
    }
}
