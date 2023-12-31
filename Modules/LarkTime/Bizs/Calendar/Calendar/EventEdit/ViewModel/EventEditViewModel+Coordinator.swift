//
//  EventEditViewModel+Coordinator.swift
//  Calendar
//
//  Created by 张威 on 2020/4/16.
//

import RxSwift
import RxRelay

extension EventEditViewModel {

    var originalEvent: EventEditModel? {
        switch input {
        case .editFrom(let pbEvent, let pbInstance), .editWebinar(let pbEvent, let pbInstance):
            return EventEditModel(from: pbEvent, instance: pbInstance)
        default:
            return nil
        }
    }

    // MARK: for 提醒

    // 是否支持选择多个 reminders
    var allowsMultipleSelectionForReminder: Bool {
        if let calendar = eventModel?.rxModel?.value.calendar, calendar.source == .exchange {
            return false
        }
        return true
    }

    // MARK: for 参与人

    var originalGroupAttendee: [EventEditAttendee] {
        originalEvent?.attendees.filter {
            if case .group = $0 {
                return true
            }
            return false
        } ?? []
    }

    var individualSimpleAttendees: [Rust.IndividualSimpleAttendee] {
        return attendeeModel?.individualSimpleAttendees ?? []
    }

    var newSimpleAttendees: [Rust.IndividualSimpleAttendee] {
        return attendeeModel?.rxNewSimpleAttendees.value ?? []
    }

    var originalIndividualAttendees: [Rust.IndividualSimpleAttendee] {
        return attendeeModel?.rxOriginalIndividualimpleAttendees.value ?? []
    }

    var groupSimpleAttendees: [Rust.GroupSimpleAttendee] {
        attendeeModel?.groupSimpleAttendees ?? []
    }

    var groupSimpleMembers: [String: [Rust.IndividualSimpleAttendee]] {
        attendeeModel?.groupSimpleMembers ?? [:]
    }

    var groupCryptedMembers: [String: [Rust.EncryptedSimpleAttendee]] {
        attendeeModel?.groupEncryptedMembers ?? [:]
    }

    var resourceSimpleAttendees: [Rust.ResourceSimpleAttendee] {
        eventModel?.rxModel?.value.meetingRooms.map { $0.getPBModel().toResourceSimpleAttendee() } ?? []
    }

    var totalAttendeesLoaded: Bool {
        attendeeModel?.haveAllAttendee ?? true
    }

    // 群成员中被过滤的高管 [groupID: chatterIDs]
    var rejectedGroupUsersMap: [String: [Int64]] {
        return attendeeModel?.rejectedGroupUserMap ?? [:]
    }

    // webinar 嘉宾
    var speakerIndividualSimpleAttendees: [Rust.IndividualSimpleAttendee] {
        webinarAttendeeModel?.getAttendeeContext(with: .speaker)?.individualSimpleAttendees ?? []
    }
    var speakerGroupSimpleAttendees: [Rust.GroupSimpleAttendee] {
        webinarAttendeeModel?.getAttendeeContext(with: .speaker)?.groupSimpleAttendees ?? []
    }
    var originalSpeakerIndividualAttendees: [Rust.IndividualSimpleAttendee] {
        return webinarAttendeeModel?.getAttendeeContext(with: .speaker)?.rxOriginalIndividualimpleAttendees.value ?? []
    }

    // webinar 观众
    var audienceIndividualSimpleAttendees: [Rust.IndividualSimpleAttendee] {
        return webinarAttendeeModel?.getAttendeeContext(with: .audience)?.individualSimpleAttendees ?? []
    }
    var audienceGroupSimpleAttendees: [Rust.GroupSimpleAttendee] {
        webinarAttendeeModel?.getAttendeeContext(with: .audience)?.groupSimpleAttendees ?? []
    }
    var originalAudienceIndividualAttendees: [Rust.IndividualSimpleAttendee] {
        return webinarAttendeeModel?.getAttendeeContext(with: .audience)?.rxOriginalIndividualimpleAttendees.value ?? []
    }


    // MARK: for 重复性规则

    // 是否支持月重复选择多天（PM-Liu zhaoyi - lark 同步 exchange 需求，产品方案降级，都不支持多选）
    var allowsMultipleSelectionForRruleMonthDay: Bool {
        false
    }

    // MARK: for 会议室

    // 会议室最长可预约截止时间
    func meetingRoomMaxEndDateInfo() -> MeetingRoomEndDateInfo? {
        return meetingRoomMaxEndDateInfoWithModel(eventModel?.rxModel?.value)
    }

    // 防止在combineLatest中取eventModel?.rxModel?.value导致死锁问题
    func meetingRoomMaxEndDateInfoWithModel(_ model: EventEditModel?) -> MeetingRoomEndDateInfo? {
        let info = model?.meetingRooms.meetingRoomMaxEndDateInfo()
        if let event = model, event.rrule != nil,
           let info = info {
            let furthestDate = Rust.ResourceStrategy.adjustEventFurthestDate(originDate: info.furthestDate, timezone: event.timeZone, endDate: event.endDate)
            return (info.roomName, furthestDate)
        } else {
            return info
        }
    }

    /// 已选中的 meetingRooms
    var selectedMeetingRooms: [CalendarMeetingRoom] {
        eventModel?.rxModel?.value.meetingRooms.filter { $0.status != .removed } ?? []
    }

    /// 产生一个空的 notes
    func makeEmptyNotes() -> EventNotes {
        guard let calendar = eventModel?.rxModel?.value.calendar else {
            return .html(text: "")
        }
        switch calendar.source {
        case .exchange, .google: return .html(text: "")
        case .lark: return .docs(data: "", plainText: "")
        case .local: return .html(text: "")
        }
    }

    // MARK: for 切换日历

    // swiftlint:disable cyclomatic_complexity
    /// 切换日历的 alert
    func alertTextsForSelectingCalendar(_ calendar: EventEditCalendar)
        -> EventEditConfirmAlertTexts? {
        guard let eventModel = eventModel?.rxModel?.value,
              let prevCalendar = eventModel.calendar else {
            assertionFailure()
            return nil
        }

        var needClearAttachments = false
        if let attachmentsInfo = attachmentModel?.rxDisplayingAttachmentsInfo.value, !attachmentsInfo.attachments.isEmpty {
            needClearAttachments = true
        }

        var title: String = ""
        // 需要被清除的内容
        var itemsNeedClear = [String]()
        // 需要调整的内容
        var itemsNeedAdjust = [String]()

        let prevSource = prevCalendar.source
        let nextSource = calendar.source
        switch (prevSource, nextSource) {
        case (.lark, .google), (.exchange, .google):
            // lark/exchange -> google: 清除参与人、会议室、附件
            if !eventModel.attendees.isEmpty {
                itemsNeedClear.append(BundleI18n.Calendar.Calendar_Common_Guests)
            }
            if !eventModel.meetingRooms.isEmpty {
                itemsNeedClear.append(BundleI18n.Calendar.Calendar_Common_Room)
            }
            if needClearAttachments {
                itemsNeedClear.append(I18n.Calendar_Common_Attachment.lowercased())
            }
            title = BundleI18n.Calendar.Calendar_GoogleCal_SureSwitchToGoogle
        case (.google, .lark), (.exchange, .lark):
            // google/exchange -> lark: 清除参与人和会议室
            if !eventModel.attendees.isEmpty {
                itemsNeedClear.append(BundleI18n.Calendar.Calendar_Common_Guests)
            }
            if !eventModel.meetingRooms.isEmpty {
                itemsNeedClear.append(BundleI18n.Calendar.Calendar_Common_Room)
            }
            title = BundleI18n.Calendar.Calendar_GoogleCal_SureSwitchToLark()
        case (.lark, .exchange), (.google, .exchange):
            // lark/google -> exchange:
            //  1. 清除参与人、会议室、附件
            //  2. 调整月重复性规则、提醒
            if !eventModel.attendees.isEmpty {
                itemsNeedClear.append(BundleI18n.Calendar.Calendar_Common_Guests)
            }
            if !eventModel.meetingRooms.isEmpty {
                itemsNeedClear.append(BundleI18n.Calendar.Calendar_Common_Room)
            }
            if let days = eventModel.rrule?.daysOfTheMonth, days.count > 1 {
                itemsNeedAdjust.append(BundleI18n.Calendar.Calendar_Common_RRule)
            }
            if eventModel.reminders.count > 1 {
                itemsNeedAdjust.append(BundleI18n.Calendar.Calendar_Edit_Alert)
            }
            if needClearAttachments {
                itemsNeedClear.append(I18n.Calendar_Common_Attachment.lowercased())
            }
            title = BundleI18n.Calendar.Calendar_Exchange_Switch
        case (.local, _), (_, .local): assertionFailure()
        default: break
        }

        let (comma, and) = (
            BundleI18n.Calendar.Calendar_Common_Comma,
            BundleI18n.Calendar.Calendar_Common_And
        )

        let clearStr: String
        if itemsNeedClear.count > 2 {
            clearStr = itemsNeedClear.prefix(itemsNeedClear.count - 1).joined(separator: comma) + and + itemsNeedClear.last!
        } else if itemsNeedClear.count > 1 {
            clearStr = itemsNeedClear.joined(separator: and)
        } else {
            clearStr = itemsNeedClear.first ?? ""
        }

        let adjustStr: String
        if itemsNeedAdjust.count > 2 {
            adjustStr = itemsNeedAdjust.prefix(itemsNeedAdjust.count - 1).joined(separator: comma) + and + itemsNeedClear.last!
        } else if itemsNeedClear.count > 1 {
            adjustStr = itemsNeedAdjust.joined(separator: and)
        } else {
            adjustStr = itemsNeedAdjust.first ?? ""
        }

        let message: String
        switch (!clearStr.isEmpty, !adjustStr.isEmpty) {
        case (true, true):
            message = BundleI18n.Calendar.Calendar_Exchange_ChangeCalTips(Param1: clearStr, Param2: adjustStr)
        case (true, false):
            message = BundleI18n.Calendar.Calendar_Exchange_ChangeCalTipsClear(Param1: clearStr)
        case (false, true):
            message = BundleI18n.Calendar.Calendar_Exchange_ChangeCalTipsAdjust(Param2: adjustStr)
        case (false, false):
            message = ""
        }
        if !message.isEmpty {
            return EventEditConfirmAlertTexts(title: title, message: message)
        } else {
            return nil
        }
    }

    // MARK: for 搜索参与人

    // 参与人列表页是否应该显示「仅可删除你添加的参与人」
    func shouldShowNonFullEditPermissonTip(attendees: [EventEditAttendee]) -> Bool {
        let hasEditAttendeePermission = permissionModel?.rxPermissions.value.attendees.isEditable ?? false

        guard hasEditAttendeePermission else { return false }

        return attendees.contains(where: {
            $0.permission.isReadOnly
        })
    }

    // 添加邮件参与人时，需要自动插入的邮件参与人
    func emailAttendeeThatNeedsAutoInsert() -> EventEditEmailAttendee? {
        return attendeeModel?.autoInsertEmailAttendee()
    }

    // 是否可以搜索外部参与人
    private func enableSearchingOuterTenant(with pbEvent: Rust.Event) -> Bool {
        // 在 外部群/日程 添加成员时，支持搜索添加外部成员
        if pbEvent.isCrossTenant {
            return true
        }
        // 会议日程限制添加外部参与人
        if pbEvent.type == .meeting {
            return false
        }
        // 有会议纪要，限制添加外部参与人
        if !pbEvent.meetingMinuteURL.isEmpty {
            return false
        }
        return true
    }

    // 搜索参与人所需的数据
    typealias SearchLarkAttendeeContext = (
        // 是否该搜索其他租户的参与人
        enableSearchingOuterTenant: Bool,
        // 当前用户有邮箱
        hasUsableEmailAddress: Bool,
        // 已添加的 chatterIds
        chatterIds: [String],
        // 已添加的 groupIds
        chatIds: [String],
        // 已添加的 email addresses
        emailAddresses: [String]
    )

    func contextForSearchingAttendee(visibleAttendees: [EventEditAttendee]) -> (SearchLarkAttendeeContext) {
        var (chatterIds, chatIds, addresses) = ([String](), [String](), [String]())
        for attendee in visibleAttendees {
            switch attendee {
            case .user(let attendee): chatterIds.append(attendee.chatterId)
            case .group(let attendee): chatIds.append(attendee.chatId)
            case .email(let attendee): addresses.append(attendee.address)
            default: assertionFailure()
            }
        }

        let enableSearchingOuterTenant: Bool
        switch input {
        case .createWithContext, .copyWithEvent, .createWebinar:
            enableSearchingOuterTenant = true
        case .editFrom(let pbEvent, _), .editWebinar(let pbEvent, _):
            enableSearchingOuterTenant = self.enableSearchingOuterTenant(with: pbEvent)
        case .editFromLocal:
            assertionFailure()
            enableSearchingOuterTenant = false
        }

        let hasUsableEmailAddress = false
        return (
            enableSearchingOuterTenant,
            hasUsableEmailAddress,
            chatterIds,
            chatIds,
            addresses
        )
    }

    // MARK: for 安排时间

    typealias ArrangeDateContext = (
        attendeeEntities: [UserAttendeeBaseDisplayInfo],
        startDate: Date,
        endDate: Date,
        organizerCalendarId: String,
        eventServerId: String,
        eventKey: String,
        eventOriginalTimestamp: Int64,
        timeZoneId: String,
        rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>
    )

    func contextForArrangingDate() -> ArrangeDateContext {
        let visibleAttendees = attendeeModel?.rxAttendeeData.value.visibleAttendees ?? []
        let attendeeEntities: [UserAttendeeBaseDisplayInfo] = EventEditAttendee.allUserAttendees(of: visibleAttendees)
        let eventModel = eventModel?.rxModel?.value ?? EventEditModel()
        let pbEvent = eventModel.getPBModel()
        return (
            attendeeEntities: attendeeEntities,
            startDate: eventModel.startDate,
            endDate: eventModel.endDate,
            organizerCalendarId: eventModel.organizerCalendarId,
            eventServerId: pbEvent.serverID,
            eventKey: pbEvent.key,
            eventOriginalTimestamp: pbEvent.originalTime,
            timeZoneId: eventModel.timeZone.identifier,
            rxTimezoneDisplayType: self.rxTimezoneDisplayType
        )
    }

}
