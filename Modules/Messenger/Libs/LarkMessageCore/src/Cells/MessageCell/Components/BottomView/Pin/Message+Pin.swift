//
//  Message + pin.swift
//  LarkMessageCore
//
//  Created by lizhiqiang on 2019/7/2.
//

import Foundation
import LarkModel
import LarkFeatureGating

public extension Message {
    func isSupportPin(cardSupportFg: Bool) -> Bool {
        let type = self.type

        switch type {
        case .audio, .shareCalendarEvent, .generalCalendar, .file, .folder,
             .image, .sticker, .media, .mergeForward, .text, .post, .shareGroupChat, .shareUserCard,
             .location, .todo, .vote:
            return true
        case .unknown, .system, .email, .calendar, .hongbao, .commercializedHongbao, .videoChat, .diagnose:
            // TODO: todo 适配
            return false
        case .card:
            guard let content = self.content as? LarkModel.CardContent else {
                return false
            }
            // 卡片中的 vote 可以pin
            if content.type == .vote {
                return true
            } else if cardSupportFg,
                      content.type == .text || content.type == .openCard,
                      // 不支持临时消息和 v1 旧版卡片的 pin 功能(样式不符合预期)
                      !isEphemeral, content.version >= 2 {
                return true
            } else {
                return false
            }
        @unknown default:
            return false
        }
    }
}
