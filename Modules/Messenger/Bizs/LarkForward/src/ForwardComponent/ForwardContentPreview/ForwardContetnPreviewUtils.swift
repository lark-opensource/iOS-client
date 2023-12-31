//
//  ForwardContetnPreviewUtils.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import LarkModel
import LarkMessengerInterface

public class ForwardContentPreviewUtils {
    // 各类消息转发一级预览View
    static func calendarEventShareView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? EventShareContent else {
            return nil
        }
        var title = ""
        if content.isInvalid {
            title = BundleI18n.LarkForward.Lark_Legacy_EventShareExpired
        } else {
            title = content.title.isEmpty ? BundleI18n.LarkForward.Lark_Legacy_NoTitle : content.title
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    static func calendarEventRSVPView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? GeneralCalendarEventRSVPContent else {
            return nil
        }
        var title = ""
        if content.cardStatus == .invalid {
            title = BundleI18n.LarkForward.Lark_Legacy_EventShareExpired
        } else {
            title = content.title.isEmpty ? BundleI18n.LarkForward.Lark_Legacy_NoTitle : content.title
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    static func calendarSchedulerAppointmentView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? SchedulerAppointmentCardContent else {
            return nil
        }
        var title = BundleI18n.LarkForward.Calendar_Scheduling_EventNoAvailable_Bot
        if content.status == .statusActive {
            if content.action == .actionReschedule {
                title = BundleI18n.LarkForward.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName)
            } else if content.action == .actionCancel {
                title = BundleI18n.LarkForward.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.guestName, host: content.hostName)
            } else {
                title = BundleI18n.LarkForward.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
            }
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    static func calendarSchedulerRoundRobinView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? RoundRobinCardContent else {
            return nil
        }
        var title = BundleI18n.LarkForward.Calendar_Scheduling_EventNoAvailable_Bot
        if content.status == .statusActive {
            title = BundleI18n.LarkForward.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    static func videoChatFooterView(message: Message) -> ForwardVideoChatMessageConfirmFooter? {
        guard let content = message.content as? VChatMeetingCardContent else { return  nil }
        return ForwardVideoChatMessageConfirmFooter(content: content)
    }

    static func calendarBotFooterView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? CalendarBotCardContent else { return nil }
        var title = ""
        if content.isInvalid {
            title = BundleI18n.LarkForward.Lark_Legacy_EventShareExpired
        } else {
            title = content.summary.isEmpty ? BundleI18n.LarkForward.Lark_Legacy_NoTitle : content.summary
        }
        let time = modelService.getCalendarBotTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title, subMessage: time, image: Resources.eventShare)
    }

    static func todoShareView(message: Message) -> TodoShareConfirmFooter? {
        guard let content = message.content as? TodoContent else {
            return nil
        }
        var title: String
        let isInvalid = content.pbModel.msgStatus == .deleted
        let isDeleted = content.pbModel.todoDetail.deletedMilliTime > 0
        if isInvalid {
            title = BundleI18n.LarkForward.Todo_Task_BotMsgTaskCardExpired
        } else if isDeleted {
            title = BundleI18n.LarkForward.Todo_Task_MsgTypeTask
        } else {
            title = content.pbModel.todoDetail.summary
        }
        return TodoShareConfirmFooter(
            message: title,
            image: Resources.todoShare
        )
    }
}
