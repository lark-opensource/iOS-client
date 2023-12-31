//
//  ReplyInThreadConfigService.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/5/12.
//

import Foundation
import UIKit
import LarkMessengerInterface
import LarkSetting
import LarkModel
import LKCommonsLogging

final class ReplyInThreadConfigServiceIMP: ReplyInThreadConfigService {
    func canCreateThreadForChat(_ chat: Chat) -> Bool {
        return isSupportChat(chat)
    }

    /// 是否可以转发Thread
    func canForwardThread(message: Message) -> Bool {
        guard message.localStatus == .success, !message.isEphemeral else { return false }
        switch message.type {
        case .text, .post, .audio, .image, .sticker, .media, .file, .folder, .mergeForward,
                .card, .location, .todo, .shareGroupChat, .shareUserCard, .shareCalendarEvent, .hongbao, .videoChat, .commercializedHongbao, .vote:
            return true
        case .unknown, .system, .email, .calendar, .diagnose:
            return false
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent,
                is RoundRobinCardContent,
                is SchedulerAppointmentCardContent:
                return true
            default:
                return false
            }
        }
    }

    /// 是否支持创建话题
    func canReplyInThread(message: Message) -> Bool {
        guard message.localStatus == .success, !message.isEphemeral else { return false }
        switch message.type {
        case .text, .post, .audio, .image, .sticker, .media, .file, .folder, .mergeForward,
                .card, .location, .todo, .shareGroupChat, .shareUserCard, .shareCalendarEvent, .hongbao, .videoChat, .commercializedHongbao, .vote:
            return true
        case .unknown, .system, .email, .calendar, .diagnose:
            return false
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent,
                is RoundRobinCardContent,
                is SchedulerAppointmentCardContent:
                return true
            default:
                return false
            }
        }
    }

    private func isSupportChat(_ chat: Chat) -> Bool {
        // 密聊
        if chat.isCrypto {
            return false
        }
        /// oncall 超大群 小组 密盾群 不支持
        if chat.isSuper || chat.isOncall || chat.chatMode == .threadV2 || chat.isPrivateMode {
            return false
        }

        /// chat不可以用 或者禁止发言
        if !chat.isAllowPost || !chat.chatable {
            return false
        }

        if chat.type == .p2P, let chatter = chat.chatter {
            return !chatter.isResigned
        }

        if let openApp = chat.chatter?.openApp,
           (openApp.state != .usable || openApp.chatable == .unchatable) {
            return false
        }
        return true
    }
}
