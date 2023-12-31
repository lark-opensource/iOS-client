//
//  MessageListCalendarComponent.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/12/4.
//

import Foundation
import WebKit
import RxSwift
import Homeric
import UniverseDesignActionPanel

private let CAL_KEY_FEEDBACK: String = "calendar-card-feedback"
private let CAL_KEY_CONTENT: String  = "calendar-card-content"
private let CAL_KEY_FOOTER: String   = "calendar-card-footer"
private let CAL_KEY_INVALID: String  = "calendar-card-invalid"
private let CAL_KEY_REMOVED: String  = "calendar-card-removed"
private let CAL_KEY_NOTFOUND: String = "calendar-card-notfound"

// MARK: CalendarEventComponent
class MailMessageCalendarEventComponent: MailMessageEventHandleComponent {
    let disposeBag = DisposeBag()
    var calendarProvider: CalendarProxy?
    weak var delegate: MailMessageEventHandleComponentDelegate?

    func handleInvoke(webView: WKWebView, method: MailMessageListJSMessageType, args: [String: Any]) -> Bool {
        switch method {
        case .showCalendarDetail:
            showCalendarDetail(args: args, in: webView)
        case .acceptCalendar, .refuseCalendar, .pendingCalendar:
            if let messageId = args["messageId"] as? String,
               let threadId = args["threadId"] as? String,
               let calendarEvent = calendarEventIn(messageId) {
                var option: MailCalendarEventReplyOption?
                var logStr = ""
                switch method {
                case .acceptCalendar:
                    option = .accept
                    logStr = "acpt"
                case .refuseCalendar:
                    option = .reject
                    logStr = "decl"
                case .pendingCalendar:
                    option = .tentative
                    logStr = "mayb"
                default:
                    option = nil
                    mailAssertionFailure("impossible error for \(method)")
                }

                if let option = option {
                    MailLogger.info("handle \(method) for \(threadId), msgID: \(messageId)")
                    replyCalendarEventInvite(option: option,
                                             serverID: calendarEvent.eventServerID,
                                             mailID: calendarEvent.mailID,
                                             messageID: messageId,
                                             threadID: threadId)
                    reportEventReplyAction(logStr)
                }
            } else {
                mailAssertionFailure("reply calendar without messageId/threadId, \(args)")
            }
        case .updateCalendarAction:
            if let messageId = args["messageId"] as? String,
               let threadId = args["threadId"] as? String,
               let lastAction = args["lastAction"] as? String {
                showCalendarActionSheet(messageId: messageId, threadId: threadId, lastAction: lastAction)
            } else {
                mailAssertionFailure("reply calendar without messageId/threadId/lastAction, \(args)")
            }
        default:
            return false
        }
        return true
    }

    init(delegate: MailMessageEventHandleComponentDelegate, calendarProvider: CalendarProxy?) {
        self.delegate = delegate
        self.calendarProvider = calendarProvider
    }
}

// MARK: CalendarReplaceComponent
class MailMessageCalendarReplaceComponent: MailMessageReplaceComponent {
    var is12HourStyle: Bool {
        guard let provider = serviceProvider.configurationProvider else {
            return false
        }
        return !provider.is24HourTime
    }

    var sectionCalendarCard: String = ""

    var sectionCalendarCardBody: String = ""

    var sectionCalendarCardFeedback: String = ""

    var sectionCalendarCardFooter: String = ""

    var sectionCalendarCardInvalid: String = ""

    var sectionCalendarCardRemoved: String = ""

    var sectionCalendarCardNotFound: String = ""

    var sectionCalendarLoading: String = ""

    let serviceProvider: ServiceProvider

    init(serviceProvider: ServiceProvider) {
        self.serviceProvider = serviceProvider
    }

    func getSection(template: MailMessageListTemplate) {
        sectionCalendarCard = template.sectionCalendarCard
        sectionCalendarCardBody = template.sectionCalendarCardBody
        sectionCalendarCardFeedback = template.sectionCalendarCardFeedback
        sectionCalendarCardFooter = template.sectionCalendarCardFooter
        sectionCalendarCardInvalid = template.sectionCalendarCardInvalid
        sectionCalendarCardRemoved = template.sectionCalendarCardRemoved
        sectionCalendarCardNotFound = template.sectionCalendarCardNotFound
        sectionCalendarLoading = template.sectionCalendarLoading
    }

    func replaceTemplate(keyword: String, mailItem: MailItem?, messageItem: MailMessageItem) -> String? {
        var target: String?
        switch keyword {
        case "calendar_card":
            if messageItem.state.calendarState == .empty {
                // 需要展示loading
                MailLogger.info("Mail show calendarLoading for t_id: \(mailItem?.threadId ?? "") msgId: \(messageItem.message.id)")
                target = sectionCalendarLoading
            } else {
                target = replaceForCalendarCard(mail: messageItem)
            }
        default:
            break
        }
        return target
    }
}

// MARK: template
extension MailMessageCalendarReplaceComponent {
    /// 日程卡片
    func replaceForCalendarCard(mail: MailMessageItem) -> String {
        if mail.message.hasCalendarEventCard {
            let eventCard = mail.message.calendarEventCard
            if let eventInfo = mail.message.calendarEventCard.eventInfo {
                markCalendarShowAction(action: eventInfo.statActionType)
                switch eventInfo {
                case .eventInvite(let event):
                    return replaceCalendarEventInvite(eventCard: eventCard,
                                                      event: event,
                                                      mail: mail)
                case .eventUpdate(let event):
                    return replaceCalendarEventUpdate(eventCard: eventCard,
                                                      event: event,
                                                      mail: mail)
                case .eventUpdateOutdated(let event):
                    if event.outdatedType == .cancel {
                        return replaceCalendarCancelType(eventCard: eventCard,
                                                         eventInfo: eventInfo,
                                                          mail: mail)
                    } else {
                        return replaceCalendarEventUpdateOutdated(eventCard: eventCard,
                                                                  event: event,
                                                                  mail: mail)
                    }

                case .eventReply(let event):
                    return replaceCalendarEventReply(eventCard: eventCard,
                                                     event: event,
                                                     mail: mail)
                case .eventCancel(_):
                    return replaceCalendarCancelType(eventCard: eventCard,
                                                     eventInfo: eventInfo,
                                                      mail: mail)
                case .eventSelfDelete(_):
                    return replaceCalendarCancelType(eventCard: eventCard,
                                                     eventInfo: eventInfo,
                                                       mail: mail)
                case .eventNotFound(_):
                    return replaceCalendarCancelType(eventCard: eventCard,
                                                        eventInfo: eventInfo,
                                                        mail: mail)
                case .eventCreateFail(_):
                    return replaceCalendarCancelType(eventCard: eventCard,
                                                     eventInfo: eventInfo,
                                                        mail: mail)
                case .unkown:
                    return ""
                @unknown default:
                    return ""
                }
            }
        }
        return ""
    }

    private func replaceCalendarEventInvite(eventCard: MailCalendarEventInfo,
                                    event: MailCalendarEventInvite,
                                    mail: MailMessageItem) -> String {
        let calendarCard = replaceCalendarEventFullCard(eventCard: eventCard,
                                                        eventInfo: event.eventInfo,
                                                        mail: mail,
                                                        isCancel: false)
        return calendarCard
    }

    private func replaceCalendarEventUpdate(eventCard: MailCalendarEventInfo,
                                    event: MailCalendarEventUpdate,
                                    mail: MailMessageItem) -> String {

        let calendarCard = replaceCalendarEventFullCard(eventCard: eventCard,
                                                        eventInfo: event.eventInfo,
                                                        mail: mail,
                                                        isCancel: false)
        return calendarCard
    }

    private func replaceCalendarEventUpdateOutdated(eventCard: MailCalendarEventInfo,
                                            event: MailCalendarEventUpdateOutdated,
                                            mail: MailMessageItem) -> String {
        var feedback = ""
        var title = ""
        var isCancel = false
        /// 卡片未过期
        if event.outdatedType == .ontime {
            feedback = BundleI18n.MailSDK.Mail_Calendar_CardOutOfDate
            return replaceCalendarEventPartCard(eventCard: eventCard,
                                                            eventInfo: event.eventInfo,
                                                            mail: mail,
                                                            isCancel: isCancel,
                                                            feedback: feedback)
        } else if event.outdatedType == .update {
            /// 因日程更新而过期
            title = BundleI18n.MailSDK.Mail_Calendar_CardOutOfDate
            isCancel = true
            return replaceCalendarHeader(title: title,
                                                summary: event.eventInfo.summary,
                                                content: bodyOnlyShowMore(),
                                                isAttendeeOptional: false,
                                                isExternal: event.eventInfo.interType == .external,
                                                isCancle: isCancel)
        }
        return ""
    }

    private func replaceCalendarEventReply(eventCard: MailCalendarEventInfo,
                                   event: MailCalendarEventReply,
                                   mail: MailMessageItem) -> String {
        var feedback = ""
        var isCancel = false
        if event.replyStatus == .mailAccept {
            feedback = event.isLatest ? BundleI18n.MailSDK.Mail_Calendar_AcceptByOtherParty : BundleI18n.MailSDK.Mail_Calendar_AcceptedByOtherParty
        } else if event.replyStatus == .mailTentative {
            feedback = event.isLatest ? BundleI18n.MailSDK.Mail_Calendar_TentativeByOtherParty : BundleI18n.MailSDK.Mail_Calendar_TentativedByOtherParty
        } else if event.replyStatus == .mailDecline {
            feedback = event.isLatest ? BundleI18n.MailSDK.Mail_Calendar_RejectByOtherParty : BundleI18n.MailSDK.Mail_Calendar_RejectedByOtherParty
            isCancel = true
        }

        let title = createCalendarTitle(eventCard: eventCard, mail: mail)
        let calendarCard = replaceCalendarHeader(title: title,
                                                 summary: event.eventInfo.summary,
                                                 content: replaceCalendarPartBody(reply: event),
                                                 isAttendeeOptional: event.eventInfo.isSelfAttendeeOptional,
                                                 isExternal: event.eventInfo.interType == .external,
                                                 isCancle: isCancel)
        return calendarCard
    }

    private func isSender(message: MailClientMessage) -> Bool {
        if message.deliveryState != .received {
            return true
        }
        if let addresses = Store.settingData.getCachedCurrentSetting()?.emailAlias.allAddresses {
              if addresses.first(where: { $0.larkEntityIDString == message.from.larkEntityIDString }) != nil {
                return true
              }
              if addresses.first(where: { $0.address == message.from.address }) != nil {
                return true
              }
            }
        return false
    }

    private func replaceCalendarCancelType(eventCard: MailCalendarEventInfo,
                                           eventInfo: MailCalendarEventInfo.OneOf_EventInfo,
                                           mail: MailMessageItem) -> String {
        var startTime:Int64 = 0
        var endTime:Int64 = 0
        var isAllDay = false
        var summary = ""
        var isExtern = false
        var title = ""
        let isSender = isSender(message: mail.message)
        switch eventInfo {
            case .eventCancel(let event):
                title = BundleI18n.MailSDK.Mail_Event_YouCanceledEvent
                if !isSender {
                    title = eventCard.senderEmail + "已取消日程"
                }
                startTime = event.fullEventInfo.startTime
                endTime = event.fullEventInfo.endTime
                isAllDay = event.fullEventInfo.isAllDay
                summary = event.eventInfo.summary
                isExtern = event.eventInfo.interType == .external
            case .eventSelfDelete(let event):
                startTime = event.fullEventInfo.startTime
                endTime = event.fullEventInfo.endTime
                isAllDay = event.fullEventInfo.isAllDay
                summary = event.eventInfo.summary
                isExtern = event.eventInfo.interType == .external
                title = BundleI18n.MailSDK.Mail_Calendar_SelfDeleteEvent
            case .eventNotFound(let event):
                startTime = event.eventInfo.startTime
                endTime = event.eventInfo.endTime
                isAllDay = event.eventInfo.isAllDay
                summary = event.eventInfo.summary
                isExtern = event.eventInfo.interType == .external
                title = BundleI18n.MailSDK.Mail_Calendar_CannotFindEvent()
            case .eventCreateFail(let event):
                startTime = event.eventInfo.startTime
                endTime = event.eventInfo.endTime
                isAllDay = event.eventInfo.isAllDay
                summary = event.eventInfo.summary
                isExtern = event.eventInfo.interType == .external
                title = BundleI18n.MailSDK.Mail_Event_FailedToCreateEvent
            case .eventUpdateOutdated(let event):
                startTime = event.fullEventInfo.startTime
                endTime = event.fullEventInfo.endTime
                isAllDay = event.fullEventInfo.isAllDay
                title = BundleI18n.MailSDK.Mail_Calendar_CardOutOfDateAndCancel
                summary = event.eventInfo.summary
            case .unkown:
                return ""
            case .eventInvite(_):
                return ""
            case .eventUpdate(_):
                return ""
            case .eventReply(_):
                return ""
            default:
                return ""
        }
        let actionTime  = serviceProvider
            .calendarProvider?
            .formattCalenderTime(startTime: startTime,
                                 endTime: endTime,
                                 isAllDay: isAllDay,
                                 is12HourStyle: is12HourStyle) ?? ""
        let calendarCardNotFound = replaceFor(template: sectionCalendarCardNotFound) { (keyword) -> String? in
            switch keyword {
            case "calender-action-time":
                return actionTime
            case "hide-time":
                return actionTime.isEmpty ? "hide-time" : ""
            case "hide-empty-bg":
                return actionTime.isEmpty ? "" : "hide-empty-bg"
            default:
                return nil
            }
        }
        return replaceCalendarHeader(title: title,
                                     summary: summary,
                                     notFound: calendarCardNotFound,
                                     isAttendeeOptional: false,
                                     isExternal: isExtern,
                                     isCancle: true)
    }

    private func createCalendarTitle(eventCard: MailCalendarEventInfo, mail: MailMessageItem) -> String {
        var title = ""
        let name = eventCard.senderEmail
        var calenderType = ""
        let isSender = isSender(message: mail.message)
        switch eventCard.type {
        case .eventInvite:
            if isSender {
                return BundleI18n.MailSDK.Mail_Event_YouSentEventInvitation
            }
            calenderType = BundleI18n.MailSDK.Mail_Calendar_InvitationNotify
         case .eventUpdateOutdated, .eventCancel:
            calenderType = BundleI18n.MailSDK.Mail_Calendar_InvitationNotify
        case .eventUpdate:
            if isSender {
                return BundleI18n.MailSDK.Mail_Event_YouUpdatedEvent
            }
            calenderType = BundleI18n.MailSDK.Mail_Calendar_InvitationUpdate
        case .eventReply:
            if eventCard.eventReply.replyStatus == .mailAccept {
                return BundleI18n.MailSDK.Mail_Calendar_AcceptByOtherParty
            } else if eventCard.eventReply.replyStatus == .mailDecline {
                return BundleI18n.MailSDK.Mail_Calendar_RejectByOtherParty
            } else if eventCard.eventReply.replyStatus == .mailTentative {
                return BundleI18n.MailSDK.Mail_Calendar_TentativeByOtherParty
            }
            return ""
        @unknown default:
            break
        }
        title.append(name)
        title.append(calenderType)
        return title
    }

    private func replaceCalendarEventPartCard(eventCard: MailCalendarEventInfo,
                                              eventInfo: MailCalendarPartEventInfo,
                                              mail: MailMessageItem,
                                              isCancel: Bool,
                                              feedback: String) -> String {
        let title = createCalendarTitle(eventCard: eventCard, mail: mail)
        let calendarCard = replaceCalendarHeader(title: title,
                                                 summary: eventInfo.summary,
                                                 content: replaceCalendarCardInvalid(feedback, state: feedback),
                                                 isAttendeeOptional: eventInfo.isSelfAttendeeOptional,
                                                 isExternal: eventInfo.interType == .external,
                                                 isCancle: isCancel)
        return calendarCard
    }

    private func replaceCalendarEventFullCard(eventCard: MailCalendarEventInfo,
                                              eventInfo: MailCalendarFullEventInfo,
                                              mail: MailMessageItem,
                                              isCancel: Bool) -> String {
        let isSender = isSender(message: mail.message)
        let title = createCalendarTitle(eventCard: eventCard, mail: mail)
        let calendarCard = replaceCalendarHeader(title: title,
                                                 summary: eventInfo.summary,
                                                 content: replaceCalendarBody(eventInfo:eventInfo,
                                                                              eventCard: eventCard),
                                                 footer: replaceCalendarFooter(attendeeStatus: eventInfo.selfAttendeeStatus,
                                                                               isSender: isSender),
                                                 isAttendeeOptional: eventInfo.isSelfAttendeeOptional,
                                                 isExternal: eventInfo.interType == .external,
                                                 isCancle: isCancel)
        return calendarCard
    }

    /// 日程卡片头部内容
    private func replaceCalendarHeader(title: String,
                                       summary: String,
                                       content: String = "",
                                       feedback: String = "",
                                       footer: String = "",
                                       removed: String = "",
                                       notFound: String = "",
                                       isAttendeeOptional: Bool,
                                       isExternal: Bool,
                                       isCancle: Bool) -> String {
        /// 头部标签
        //// 标签 - 可选参加
        var optionAttendText = ""
        var optionAttendHidden = ""
        if isAttendeeOptional {
            optionAttendText = BundleI18n.MailSDK.Mail_Calendar_Optional.htmlEncoded
            optionAttendHidden = ""
        } else {
            optionAttendHidden = "hidden-tag"
        }
        var externText = ""
        var externHidden = ""
        //// 标签 - 外部
        if isExternal {
            externText = BundleI18n.MailSDK.Mail_Calendar_External.htmlEncoded
            externHidden = ""
        } else {
            externHidden = "hidden-tag"
        }

        return replaceFor(template: sectionCalendarCard) { (keyword) -> String? in
            switch keyword {
            case "calendar-card-option-attend-tag-text":
                return optionAttendText
            case "calendar-card-extern-tag-text":
                return externText
            case "hidden-option-tag":
                return optionAttendHidden
            case "hidden-extern-tag":
                return externHidden
            case "calendar-is-cancel":
                return isCancle ? "is-cancel" : ""
            case "white-style":
                return isCancle ? "" : "is-cancel"
            case "tag-cancel-style":
                return isCancle ? "tag-cancel-style" : ""
            case "calendar-title":
                return title
            case "calendar-summary":
                if summary.isEmpty {
                    return BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty
                }
                return summary
            case CAL_KEY_CONTENT:
                return content
            case CAL_KEY_FEEDBACK:
                return feedback
            case CAL_KEY_FOOTER:
                return footer
            case CAL_KEY_REMOVED:
                return removed
            case CAL_KEY_NOTFOUND:
                return notFound
            case CAL_KEY_INVALID:
                return ""
            default:
                return nil

            }
        }
    }

    /// 日程卡片内容
    private func replaceCalendarBody(eventInfo: MailCalendarFullEventInfo,
                                     eventCard: MailCalendarEventInfo ) -> String {
        let startTime = eventInfo.startTime /// 开始的时间戳
        let endTime = eventInfo.endTime /// 结束的时间戳
        let isAllDay = eventInfo.isAllDay /// 是否是全天日程
        let repeated = eventInfo.rrule // 重复性规则
        let location = eventInfo.location /// 日程地点
        let organizerEmail = eventInfo.organizerEmail /// 组织者邮箱
        let attendeeEmails = eventInfo.attendeeEmails /// 参与人邮箱列表
        let isConflict = eventInfo.conflictInfo.conflictType != .none /// 日程冲突
        let allAttendeeList: [String] = [organizerEmail] + attendeeEmails.filter { $0 != organizerEmail }
        let allAttendeeCount = allAttendeeList.count
        var hideMore = false
        if eventCard.eventReply.hasReplyStatus {
            if eventCard.eventReply.replyStatus == .mailAccept ||
                eventCard.eventReply.replyStatus == .mailTentative ||
                eventCard.eventReply.replyStatus == .mailDecline {
                hideMore = true
            }
        }

        func getTime(is12HourStyle: Bool) -> String {
            if let time = serviceProvider.calendarProvider?.formattCalenderTime(startTime: startTime,
                                                                                        endTime: endTime,
                                                                                        isAllDay: isAllDay,
                                                                                        is12HourStyle: is12HourStyle) {
                return time
            }
            return ""
        }

        /// 参与者列表
        var attendeeList = ""
        for (index, attendee) in allAttendeeList.enumerated() {
            if index == allAttendeeList.count - 1 {
                attendeeList = attendeeList + attendee
            } else {
                attendeeList = attendeeList + attendee + ", "
            }
        }

        /// 日程内容
        return replaceFor(template: sectionCalendarCardBody) { (keyword) -> String? in
            switch keyword {
            case "calender-action-time":
                return getTime(is12HourStyle: is12HourStyle)
            case "calendar-no-repeated":
                return repeated.isEmpty ? "no-repeated" : ""
            case "calendar-action-repeated":
                return repeated.isEmpty ? "" : repeated
            case "calendar-no-location":
                return location.isEmpty ? "no-location" : ""
            case "calendar-no-attendee":
                return allAttendeeCount == 0 ? "no-attendee": ""
            case "calendar-no-more":
                return hideMore ? "no-more" : ""
            case "hidden-conflict":
                return isConflict ? "": "hidden-conflict"
            case "calendar-attendee-list":
                return String(attendeeList)
            case "calender-action-location":
                return location
            case "calendar-conflict-tip":
                return BundleI18n.MailSDK.Mail_Calendar_ConflictTip
            case "calendar-more-tip":
                return BundleI18n.MailSDK.Mail_Calendar_MoreDetail
            default:
                return nil
            }
        }
    }

    private func bodyOnlyShowMore() -> String {
        return replaceFor(template: sectionCalendarCardBody) { (keyword) -> String? in
            switch keyword {
            case "calendar-no-time":
                return "no-time"
            case "calendar-no-repeated":
                return "no-repeated"
            case "calendar-no-location":
                return "no-location"
            case "calendar-no-attendee":
                return "no-attendee"
            case "calendar-no-more":
                return ""
            case "calendar-more-tip":
                return BundleI18n.MailSDK.Mail_Calendar_MoreDetail
            default:
                return nil
            }
        }
    }

    private func replaceCalendarPartBody(reply: MailCalendarEventReply) -> String {
        let startTime = reply.startTime /// 开始的时间戳
        let endTime = reply.endTime /// 结束的时间戳
        let isAllDay = reply.isAllDay
        let repeated = reply.rrule /// 重复性规则
        var hideMore = false
        if reply.hasReplyStatus {
            if reply.replyStatus == .mailAccept ||
                reply.replyStatus == .mailTentative ||
                reply.replyStatus == .mailDecline {
                hideMore = true
            }
        }

        func getTime(is12HourStyle: Bool) -> String {
            if let time = serviceProvider.calendarProvider?.formattCalenderTime(startTime: startTime,
                                                                                        endTime: endTime,
                                                                                        isAllDay: isAllDay,
                                                                                        is12HourStyle: is12HourStyle) {
                return time
            }
            return ""
        }

        /// 日程内容
        return replaceFor(template: sectionCalendarCardBody) { (keyword) -> String? in
            switch keyword {
            case "calender-action-time":
                return getTime(is12HourStyle: is12HourStyle)
            case "calendar-no-repeated":
                return repeated.isEmpty ? "no-repeated" : ""
            case "calendar-action-repeated":
                return repeated.isEmpty ? "" : repeated
            case "calendar-no-location":
                return "no-location"
            case "calendar-no-attendee":
                return "no-attendee"
            case "calendar-no-more":
                return hideMore ? "no-more" : ""
            case "hidden-conflict":
                return "hidden-conflict"
            case "calendar-attendee-list":
                return ""
            case "calendar-conflict-tip":
                return BundleI18n.MailSDK.Mail_Calendar_ConflictTip
            case "calendar-more-tip":
                return BundleI18n.MailSDK.Mail_Calendar_MoreDetail
            default:
                return nil
            }
        }
    }

    /// 日程卡片内容(失效的日程)
    private func replaceCalendarCardInvalid(_ feedback: String, state: String) -> String {
        let calendarCardInvalid = replaceFor(template: sectionCalendarCardInvalid) { (keyword) -> String? in
            switch keyword {
            case "calender-invalid-state":
                return state
            case "calendar-hidden-icon":
                // invalid的不同样式 不展示icon
                if feedback == BundleI18n.MailSDK.Mail_Calendar_SelfDeleteEvent {
                    return "hidden-icon"
                } else {
                    return ""
                }
            default:
                return nil
            }
        }
        return calendarCardInvalid
    }

    /// 日程卡片底部
    private func replaceCalendarFooter(attendeeStatus: MailCalendarAttendeeStatus,
                                       isSender: Bool) -> String {
        if attendeeStatus == .removed {
            return replaceCalendarFeedback("calendar-card-feedback", feedback: BundleI18n.MailSDK.Mail_Calendar_Deleted, false)
        } else {
            if isSender {
                return ""
            }
            if FeatureManager.open(FeatureKey(fgKey: .calendarRsvpReply, openInMailClient: false)) {
                return replaceFor(template: sectionCalendarCardFooter) { (key) -> String? in
                    switch key {
                    case "calendar-rsvp-style":
                        return "new"
                    case "calendar-accept-tip":
                        return BundleI18n.MailSDK.Mail_Calendar_Accept
                    case "calendar-refuse-tip":
                        return BundleI18n.MailSDK.Mail_Calendar_Refuse
                    case "calendar-pending-tip":
                        return BundleI18n.MailSDK.Mail_Calendar_Maybe
                    case "calendar-action":
                        switch attendeeStatus {
                        case .accept:
                            return "accepted"
                        case .decline:
                            return "refused"
                        case .tentative:
                            return "pended"
                        @unknown default:
                            return "none"
                        }
                    default:
                        return nil
                    }
                }
            }
            // 旧替换方法
            return replaceFor(template: sectionCalendarCardFooter) { (key) -> String? in
                switch key {
                case "calendar-rsvp-style":
                    return "old"
                case "calendar-accept-active-tip":
                    return BundleI18n.MailSDK.Mail_Calendar_Accepted
                case "calendar-accept-tip":
                    return BundleI18n.MailSDK.Mail_Calendar_Accept
                case "calendar-refuse-active-tip":
                    return BundleI18n.MailSDK.Mail_Calendar_Refused
                case "calendar-refuse-tip":
                    return BundleI18n.MailSDK.Mail_Calendar_Refuse
                case "calendar-pending-active-tip":
                    return BundleI18n.MailSDK.Mail_Calendar_Maybe
                case "calendar-pending-tip":
                    return BundleI18n.MailSDK.Mail_Calendar_Maybe
                case "calender-action-accept":
                    return attendeeStatus == .accept ? "active" : ""
                case "calender-action-pending":
                    return attendeeStatus == .tentative ? "active" : ""
                case "calender-action-refuse":
                    return attendeeStatus == .decline ? "active" : ""
                default:
                    return nil
                }
            }
        }
    }

    /// 日程卡片反馈
    private func replaceCalendarFeedback(_ templateStr: String, feedback: String, _ showSeparator: Bool = false) -> String {
        return replaceFor(template: sectionCalendarCardFeedback) { (keyword) -> String? in
            switch keyword {
            case "calender-feedback-state":
                return feedback
            default:
                return nil
            }
        }
    }
}

// MARK: js action handler
extension MailMessageCalendarEventComponent {
    func calendarEventIn(_ messageId: String) -> MailCalendarEventInfo? {
        if let mail = delegate?.currentMailItem.messageItems.first(where: { $0.message.id == messageId }) {
            guard mail.message.hasCalendarEventCard else {
                return nil
            }
            return mail.message.calendarEventCard
        }
        return nil
    }

    func showCalendarDetail(args: [String: Any], in webView: WKWebView?) {
        guard let vc = delegate?.componentViewController() else {
            return
        }
        if let messageId = args["messageId"] as? String {
            if let calendarEvent = calendarEventIn(messageId) {
                if calendarEvent.type == .eventInvite ||
                    calendarEvent.type == .eventUpdate ||
                    calendarEvent.type == .eventUpdateOutdated {
                    calendarProvider?.showCalendarEventDetail(eventKey: calendarEvent.uid,
                                                                                      calendarId: calendarEvent.calendarID,
                                                                                      originalTime: calendarEvent.originalTime,
                                                                                      from: vc)
                }
            }
        }
    }

    func showCalendarActionSheet(messageId: String, threadId: String, lastAction: String) {
        guard let vc = delegate?.componentViewController() else {
            return
        }
        let pop = UDActionSheet(config: UDActionSheetUIConfig())
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Calendar_Accept) { [weak self] in
            if let calendarEvent = self?.calendarEventIn(messageId), lastAction != "accepted" {
                MailLogger.info("handle acceptCalendar for \(threadId), msgID: \(messageId)")
                self?.replyCalendarEventInvite(option: .accept,
                                               serverID: calendarEvent.eventServerID,
                                               mailID: calendarEvent.mailID,
                                               messageID: messageId,
                                               threadID: threadId)
                self?.reportEventReplyAction("acpt")
            }
        }
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Calendar_Refuse) { [weak self] in
            if let calendarEvent = self?.calendarEventIn(messageId), lastAction != "refused" {
                self?.replyCalendarEventInvite(option: .reject,
                                               serverID: calendarEvent.eventServerID,
                                               mailID: calendarEvent.mailID,
                                               messageID: messageId,
                                               threadID: threadId)
                self?.reportEventReplyAction("decl")
            }
        }
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Calendar_Maybe) { [weak self] in
            if let calendarEvent = self?.calendarEventIn(messageId), lastAction != "pended" {
                MailLogger.info("handle pendingCalendar for \(threadId), msgID: \(messageId)")
                self?.replyCalendarEventInvite(option: .tentative,
                                               serverID: calendarEvent.eventServerID,
                                               mailID: calendarEvent.mailID,
                                               messageID: messageId,
                                               threadID: threadId)
                self?.reportEventReplyAction("mayb")
            }
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
            MailLogger.info("updateCalendarAction cancel.")
        }
        vc.present(pop, animated: true)
    }

    func showEventReplyLoading() {
        if let vc = delegate?.componentViewController() {
            MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Calendar_ToastReplying, on: vc.view, disableUserInteraction: false)
        }
    }

    func showEventReplySuccess() {
        if let vc = delegate?.componentViewController() {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_ReplySuccess, on: vc.view)
        }
    }

    func showEventReplyFailure() {
        if let vc = delegate?.componentViewController() {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_ReplyFailed,
                                       on: vc.view, event: ToastErrorEvent(event: .read_calendar_reply_fail))
        }
    }

    private func reportEventReplyAction(_ action: String) {
        MailTracker.log(event: Homeric.CAL_REPLY_EVENT, params: ["action_source": "email_card_message",
                                                                 "cal_event_resp": action])
    }

    func replyCalendarEventInvite(option: MailCalendarEventReplyOption, serverID: String, mailID: String, messageID: String, threadID: String) {
        MailLogger.info("reply calendar \(serverID), mailID \(mailID)")
        showEventReplyLoading()
        MailDataServiceFactory
            .commonDataService?
            .mailReplyCalendarEvent(eventServerID: serverID, mailID: mailID, option: option)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](_) in
                guard let `self` = self else { return }
                if let messageListVC = self.delegate?.componentViewController() as? MailMessageListController {
                    let state: String
                    switch option {
                    case .accept:
                        state = "0"
                        /// 拒绝
                    case .reject:
                        state = "1"
                        /// 待定
                    case .tentative:
                        state = "2"
                    @unknown default:
                        state = ""
                    }
                    if state.count > 0 {
                        if FeatureManager.open(FeatureKey(fgKey: .calendarRsvpReply, openInMailClient: false)) {
                            messageListVC.callJSFunction("updateCalendarBtn", params: [messageID, state], withThreadId: threadID)
                        } else {
                            messageListVC.callJSFunction("updateCalendarBtnOld", params: [messageID, state], withThreadId: threadID)
                        }
                    }
                }
                self.showEventReplySuccess()
            }, onError: { [weak self](_) in
                guard let `self` = self else { return }
                self.showEventReplyFailure()
            }).disposed(by: self.disposeBag)
    }
}

private enum StatClickActionType: String {
    case invitation
    case updates
    case cancel
    case reply
    case forward
}

extension MailCalendarEventInfo.OneOf_EventInfo {
    fileprivate var statActionType: StatClickActionType {
        var type = StatClickActionType.invitation
        switch self {
        case .eventInvite(_):
            type = .invitation
        case .eventCancel(_):
            type = .cancel
        case .eventReply(_):
            type = .reply
        case .eventUpdate(_):
            type = .updates
        case .eventSelfDelete(_):
            type = .updates
        case .eventUpdateOutdated(_):
            type = .updates
        case .eventNotFound(_):
            type = .invitation
        @unknown default:
            break
        }
        return type
    }
}

extension MailMessageCalendarReplaceComponent {
    private func markCalendarShowAction(action: StatClickActionType) {
        MailTracker.log(event: "email_invitation_click", params: ["action_type": action.rawValue])
    }
}
