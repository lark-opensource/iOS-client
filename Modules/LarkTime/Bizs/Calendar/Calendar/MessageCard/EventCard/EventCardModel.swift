//
//  EventCardModel.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/26.
//
import UIKit
import RustPB
import EventKit
import RichLabel
import LarkModel
import EventKitUI
import Foundation
import EEFlexiable
import AsyncComponent
import CalendarFoundation
import LarkTimeFormatUtils

public enum CardType: Int, CaseIterable {
    case unknown = 0
    /// 被邀请人接受日程邀请，被邀请人卡片消息
    case replyAccept = 1
    /// 被邀请人拒绝日程邀请，被邀请人卡片消息
    case replyDecline = 2
    /// 被邀请人待定日程邀请，被邀请人卡片消息
    case replyTentative = 3
    /// 邀请你加入日程，卡片消息
    case eventInvite = 4
    /// 日程取消，卡片消息
    case eventDelete = 5
    /// 日程更新(后台使用，预留)
    case eventUpdate = 6
    /// 更新了日程时间，卡片消息
    case eventReschedule = 7
    /// 日历更新(后台使用，预留)
    case calendarUpdate = 8
    /// 更新了日程地点，卡片消息
    case eventUpdateLocation = 9
    /// 个人参与状态更新(后台使用，预留)
    case selfAttendeeStatusChange = 10
    /// 授予你对的共享日历的权限，文本消息
    case adjustShareCalendarMember = 11
    /// 将你从共享日历中移除，文本消息
    case removeShareCalendarMember = 12
    /// 删除了共享日历，文本消息 = 1
    case deleteShareCalendar = 13
    /// 更新了日程描述，卡片消息
    case eventUpdateDescription = 14
    /// 会议室邀请超时后又接受了邀请，文本消息
    case replyAcceptAfterDecline = 15
    /// 转让日程
    case transferEvent = 101
    /// RSVP附言卡片
    case rsvpComment = 102
    /// 切换日程的日历
    case switchCalendar = 103
    /// RSVP 新卡片
    case rsvpCard = 104
}

public protocol InviteEventCardModel: EventCardModel {
    var isCrossTenant: Bool { get }
    var descAttributedInfo: (string: NSAttributedString, range: [NSRange: URL])? { get }
    var status: CalendarEventAttendee.Status { get set }
    var hasReaction: Bool { get }
    var summary: String { get }
    var time: String { get }
    var rrule: String? { get }
    var attendeeIDs: [String]? { get }
    var attendeeNames: [String: String] { get }
    var groupIds: [String]? { get }
    var groupNames: [String: String] { get }
    var meetingRooms: String? { get }
    var meetingRoomsInfo: [(name: String, isDisabled: Bool)] { get }
    var location: String? { get }
    var desc: String? { get }
    var needAction: Bool { get }
    var showReplyInviterEntry: Bool { get }
    var rsvpCommentUserName: String? { get }
    var userInviteOperatorId: String? { get }
    var inviteOperatorLocalizedName: String? { get }
    var calendarID: String? { get }
    var eventId: String? { get }
    var eventServerID: String { get }
    var key: String? { get }
    var originalTime: Int? { get }
    var isAccepted: Bool { get }
    var isDeclined: Bool { get }
    var isTentatived: Bool { get }
    var isShowOptional: Bool { get }
    var isShowConflict: Bool { get }
    var isShowRecurrenceConflict: Bool { get }
    var conflictTime: Int64 { get }
    var messageType: Int? { get }
    var startTime: Int64? { get }
    var endTime: Int64? { get }
    var isAllDay: Bool? { get }
    var senderUserName: String { get }
    var senderUserId: String? { get }
    var attendeeCount: Int { get }
    var messageId: String { get }
    var richText: NSAttributedString? { get }
    var atMeForegroundColor: UIColor { get }
    var atOtherForegroundColor: UIColor { get }
    var atGroupForegroundColor: UIColor { get }
    var showTimeUpdatedFlag: Bool { get }
    var showRruleUpdatedFlag: Bool { get }
    var showLocationUpdatedFlag: Bool { get }
    var showMeetingRoomUpdatedFlag: Bool { get }
    var isInvalid: Bool { get }
    var chatId: String { get }
    // webinar
    var isWebinar: Bool { get }
    var speakerChatterIDs: [String] { get }
    var speakerNames: [String: String] { get }
    var speakerGroupIDs: [String] { get }
    var speakerGroupNames: [String: String] { get }
    var relationTag: String? { get }
    var successorUserId: String? { get }
    var organizerUserId: String? { get }
    var creatorUserId: String? { get }
}

public extension InviteEventCardModel {
    
    func getAttendeeInfo(isWebinar: Bool, userID: String, maxWidth: CGFloat) -> (attributedString: NSAttributedString?, tapableRangeDic: [NSRange: String]) {
        if !isWebinar {
            return attendeeNameGenerator(userID: userID,
                                         attendeeNames: attendeeNames,
                                         attendeeIDs: attendeeIDs,
                                         groupNames: groupNames,
                                         foregroundColor: (atMeForegroundColor, atOtherForegroundColor, atGroupForegroundColor),
                                         maxWidth: maxWidth)
        } else {
            return attendeeNameGenerator(userID: userID,
                                         attendeeNames: speakerNames,
                                         attendeeIDs: speakerChatterIDs,
                                         groupNames: speakerGroupNames,
                                         foregroundColor: (atMeForegroundColor, atOtherForegroundColor, atGroupForegroundColor),
                                         maxWidth: maxWidth)
        }
    }

   

    func isUpdated() -> Bool {
        let cardType = CardType(rawValue: self.messageType ?? CardType.unknown.rawValue) ?? .unknown
        switch cardType {
        case .eventDelete, .eventUpdate, .eventReschedule, .calendarUpdate, .eventUpdateLocation, .eventUpdateDescription:
            return true
        default: return false
        }
    }

    func isInvited() -> Bool {
        return status != .removed
    }
}

public protocol EventCardModel {
    // 时间
    var startTime: Int64? { get }
    var endTime: Int64? { get }
    var isAllDay: Bool? { get }

    // 冲突
    var isShowConflict: Bool { get }
    var isShowRecurrenceConflict: Bool { get }
    var conflictTime: Int64 { get }

    // 重复性
    var rrule: String? { get }

}

extension EventCardModel {

    func getConflictText(is12HourStyle: Bool) -> String? {
        if !(isShowConflict || isShowRecurrenceConflict) { // 没有冲突
            return nil
        }

        if isShowConflict { // 普通冲突
            return BundleI18n.Calendar.Calendar_Detail_Conflict
        }

        /// 重复性冲突
        let confilictDate = Date(timeIntervalSince1970: TimeInterval(conflictTime))
        let currentDate = Date(timeIntervalSinceNow: 0)

        // 如果冲突日期与卡片的展示日期在同一天，不显示冲突的具体日期
        let eventStartTime = Date(timeIntervalSince1970: TimeInterval(startTime ?? 0))
        if confilictDate.isInSameDay(eventStartTime) {
            return BundleI18n.Calendar.Calendar_Detail_Conflict
        }

        let shouldShowYear = confilictDate.year != currentDate.year

        let customOptions = Options(
            timeFormatType: shouldShowYear ? .long : .short,
            datePrecisionType: .day
        )

        return BundleI18n.Calendar.Calendar_Detail_ConflictRecurring(date: 
            TimeFormatUtils.formatDate(from: confilictDate, with: customOptions)
        )
    }

    func getTime(is12HourStyle: Bool) -> String? {
        if let startTime = startTime,
            let endTime = endTime,
            let isAllday = isAllDay {
            let startTime = Date(timeIntervalSince1970: TimeInterval(startTime))
            let endTime = Date(timeIntervalSince1970: TimeInterval(endTime))
            // 使用设备时区
            let customOptions = Options(
                timeZone: TimeZone.current,
                is12HourStyle: is12HourStyle,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
            return CalendarTimeFormatter.formatFullDateTimeRange(
                startFrom: startTime,
                endAt: endTime,
                isAllDayEvent: isAllday,
                with: customOptions
            )
        }
        return nil
    }

    func getRepeatText() -> String? {
        if let rruleStr = rrule, let rrule = EKRecurrenceRule.recurrenceRuleFromString(rruleStr) {
            return rrule.getReadableString()
        } else {
            return nil
        }
    }
    
    func attendeeNameGenerator(userID: String,
                               attendeeNames: [String: String],
                               attendeeIDs: [String]?,
                               groupNames: [String: String],
                               foregroundColor: (atMe: UIColor, atOther: UIColor, atGroup: UIColor),
                               maxWidth: CGFloat
    ) ->
        (attributedString: NSAttributedString?,
        tapableRangeDic: [NSRange: String]) {
            let nameDic = attendeeNames
            guard let attendeeIDs = attendeeIDs else {
                return (nil, [:])
            }
            if attendeeIDs.isEmpty {
                return (nil, [:])
            }
            let result: NSMutableAttributedString = NSMutableAttributedString()
            var tapableRange: [NSRange: String] = [:]
            for attendeeID in attendeeIDs where !attendeeID.isEmpty {
                guard let nameString = nameDic[attendeeID] else {
                    break
                }
                if attendeeID == userID {
                    var newString = AsyncRichLabelUtil.getTrimStrWithEllipsis(str: "@\(nameString)", limitWidth: maxWidth, font: UIFont.ud.body2, maxWidth: maxWidth)
                    let colorAttrbute = [NSAttributedString.Key.foregroundColor: foregroundColor.atMe,
                                         NSAttributedString.Key.font: UIFont.ud.body2]
                    let groupAttributedText = NSAttributedString(string: newString, attributes: colorAttrbute)
                    let attributeStr = NSMutableAttributedString(
                        attributedString: LKLabel.lu.genAtMeAttributedText(atMeAttrStr: groupAttributedText, bgColor: UIColor.ud.primaryContentDefault)
                    )
                    let range = NSRange(location: result.length, length: attributeStr.length)
                    tapableRange[range] = attendeeID
                    result.append(attributeStr)
                } else {
                    let newString = "@\(nameString)"
                    let colorAttrbute = [NSAttributedString.Key.foregroundColor: foregroundColor.atOther,
                                         NSAttributedString.Key.font: UIFont.ud.body2]
                    let attributedText = NSAttributedString(string: newString, attributes: colorAttrbute)
                    let range = NSRange(location: result.length, length: attributedText.length)
                    tapableRange[range] = attendeeID
                    result.append(attributedText)
                }
                result.append(NSAttributedString(string: " "))
            }
            let names = groupNames
            for (_, groupName) in names {
                let newString = "@\(groupName)"
                let colorAttrbute = [NSAttributedString.Key.foregroundColor: foregroundColor.atGroup,
                                     NSAttributedString.Key.font: UIFont.ud.body2]
                let groupAttributedText = NSAttributedString(string: newString, attributes: colorAttrbute)
                let attributeStr = NSMutableAttributedString(
                    attributedString: LKLabel.lu.genAtMeAttributedText(atMeAttrStr: groupAttributedText, bgColor: UIColor.ud.N600.withAlphaComponent(0.12))
                )
                result.append(attributeStr)
                result.append(NSAttributedString(string: " "))
            }
            return (result, tapableRange)
    }
    
    private func getTrimNameString(str: String, maxWidth: CGFloat) -> String {
        if maxWidth < 0 { return str }
        let tailText = "..."
        let tailWidth = tailText.getWidth(font: UIFont.ud.body2)
        var res: String = ""
        var curWidth: CGFloat = 0
        if str.getWidth(font: UIFont.ud.body2) > maxWidth {
            for i in str {
                if curWidth + "\(i)".getWidth(font: UIFont.ud.body2) + tailWidth + 1 > maxWidth {
                    break
                }
                res.append(i)
                curWidth += "\(i)".getWidth(font: UIFont.ud.body2)
            }
        } else {
            return str
        }
        return res + tailText
    }
}

public protocol ShareEventCardModel: EventCardModel {
    var hasReaction: Bool { get }
    /// 这三个字段定位一个event
    var calendarID: String { get }
    var key: String { get }
    var originalTime: Int { get }
    var messageId: String { get }

    // 这三个字段决定显示时间
    var startTime: Int64? { get }
    var endTime: Int64? { get }
    var isAllDay: Bool? { get }

    // 冲突视图
    var isShowConflict: Bool { get }
    var isShowRecurrenceConflict: Bool { get }
    var conflictTime: Int64 { get }

    var color: Int32 { get }
    var isJoined: Bool { get set }
    var title: String { get }
    var location: String? { get }
    var meetingRoom: String? { get }
    var desc: String { get }

    // 重复性日程
    var rrule: String? { get }

    // 参与者
    var attendeeNames: [String] { get }

    var isInvalid: Bool { get set }

    var isCrossTenant: Bool { get }
    // For RSVP
    var status: CalendarEventAttendee.Status { get set }
    var currentUsersMainCalendarId: String { get }
    // chat id
    var chatId: String { get }
    // event id
    var eventID: String { get }

    var isWebinar: Bool { get }

    var relationTag: String? { get }
}


public protocol RSVPCardModel: EventCardModel {
    var chatID: String { get }
    var hasReaction: Bool { get }
    var messageId: String { get }
  
    var calendarID: String { get }
    var userOwnChatterId: String { get }
    var organizerCalendarId: Int64 { get }
    var key: String { get }
    var originalTime: Int { get }
    // header
    var headerTitle: String { get }
    // 标题
    var summary: String { get }
    // 时间模块
    var startTime: Int64? { get }
    var endTime: Int64? { get }
    var isAllDay: Bool? { get }
    var rrule: String? { get }
    var isShowConflict: Bool { get }
    var isShowRecurrenceConflict: Bool { get }
    var conflictTime: Int64 { get }
    
    var location: String? { get }
    var meetingRoom: String? { get }
    var desc: String { get }
    
    // 参与人模块
    var needActionAttendeeIDs: [String] { get }
    var needActionAttendeeNames: [String: String] { get }
    
    var atMeForegroundColor: UIColor { get }
    var atOtherForegroundColor: UIColor { get }
    var atGroupForegroundColor: UIColor { get }
    
    var isAllUserInGroupReplyed: Bool { get }
    var rsvpAllReplyedCountString: String { get }
    var eventTotalAttendeeCount: Int64 { get }
    var needActionCount: Int64 { get }
    
    var attendeeRsvpInfo: [Basic_V1_AttendeeRSVPInfo] { get }

    // 状态
    var cardStatus: EventRSVPCardInfo.EventRSVPCardStatus { get }
    var selfAttendeeRsvpStatus: CalendarEventAttendee.Status { get set }
    
    var isJoined: Bool { get }
    var isInValid: Bool { get set }
    var isCrossTenant: Bool { get }
    var isAttendeeOverflow: Bool { get }
    var isWebinar: Bool { get }
    var isOptional: Bool { get }
    var isUpdated: Bool { get }
    var relationTag: String? { get }
    var isTimeUpdated: Bool { get }
    var isRruleUpdated: Bool { get }
    var meetingNotes: RustPB.Basic_V1_MeetingNotesInfo? { get}
    var isLocationUpdated: Bool { get }
    var isResourceUpdated: Bool { get }
}

#if !LARK_NO_DEBUG
extension ShareEventCardModel {
    var debugDescription: String {
        """
        calendarId: \(self.calendarID)
        key: \(self.key)
        originalTime: \(self.originalTime)
        summary: \(self.title)
        rrule: \(self.rrule ?? "")
        attendeeNames: \(self.attendeeNames.description)
        desc: \(self.desc)
        isCrossTenant: \(self.isCrossTenant.description)
        location: \(self.location ?? "")
        meetingRoom: \(self.meetingRoom?.description ?? "")
        startTime: \(self.startTime?.description ?? "")
        endTime: \(self.endTime?.description ?? "")
        conflictTime: \(self.conflictTime)
        isShowRecurrenceConflict: \(self.isShowRecurrenceConflict.description)
        isShowConflict: \(self.isShowConflict.description)
        isAllDay: \(self.isAllDay?.description ?? "")
        isJoined: \(self.isJoined.description)
        isInvalid: \(self.isInvalid.description)
        isWebinar: \(self.isWebinar)
        currentUsersMainCalendarId: \(self.currentUsersMainCalendarId)
        status: \(self.status)
        """
    }
}

extension InviteEventCardModel {
    var debugDescription: String {
        """
        summary: \(self.summary)
        rrule: \(self.rrule ?? "")
        attendeeIDs: \(self.attendeeIDs?.description ?? "")
        desc: \(self.desc ?? "")
        needAction: \(self.needAction)
        calendarId: \(self.calendarID ?? "")
        key: \(self.key ?? "")
        originalTime: \(self.originalTime?.description ?? "")
        location: \(self.location ?? "")
        meetingRoomsInfo: \(self.meetingRoomsInfo.description)
        startTime: \(self.startTime?.description ?? "")
        endTime: \(self.endTime?.description ?? "")
        isAllDay: \(self.isAllDay?.description ?? "")
        isAccepted: \(self.isAccepted)
        isDeclined: \(self.isDeclined)
        isTentatived: \(self.isTentatived)
        isShowConflict: \(self.isShowConflict)
        isShowRecurrenceConflict: \(self.isShowRecurrenceConflict)
        conflictTime: \(self.conflictTime)
        isWebinar: \(self.isWebinar)
        speakerChatterIDs: \(self.speakerChatterIDs.description)
        """
    }
}

extension RSVPCardModel {
    var debugDescription: String {
        """
        chatID: \(self.chatID)
        messageID: \(self.messageId)
        calendarId: \(self.calendarID)
        key: \(self.key)
        cardStatus: \(self.cardStatus)
        originalTime: \(self.originalTime)
        summary: \(self.summary)
        rrule: \(self.rrule ?? "")
        needActionAttendeeNames: \(self.needActionAttendeeNames.description)
        needActionAttendeeIDs: \(self.needActionAttendeeIDs.description)
        desc: \(self.desc)
        isCrossTenant: \(self.isCrossTenant.description)
        location: \(self.location ?? "")
        meetingRoom: \(self.meetingRoom?.description ?? "")
        startTime: \(self.startTime?.description ?? "")
        endTime: \(self.endTime?.description ?? "")
        conflictTime: \(self.conflictTime)
        isShowRecurrenceConflict: \(self.isShowRecurrenceConflict.description)
        isShowConflict: \(self.isShowConflict.description)
        isAllDay: \(self.isAllDay?.description ?? "")
        isJoined: \(self.isJoined.description)
        isInvalid: \(self.isInValid.description)
        isAllUserInGroupReplyed: \(self.isAllUserInGroupReplyed.description)
        isAttendeeOverflow: \(self.isAttendeeOverflow.description)
        eventTotalAttendeeCount: \(self.eventTotalAttendeeCount.description)
        selfAttendeeRsvpStatus: \(self.selfAttendeeRsvpStatus)
        isLocationUpdate: \(self.isLocationUpdated)
        isResourceUpdated: \(self.isResourceUpdated)
        """
    }
}
#endif
