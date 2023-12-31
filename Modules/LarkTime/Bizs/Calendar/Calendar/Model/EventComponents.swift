//
//  EventComponents.swift
//  Calendar
//
//  Created by 张威 on 2020/3/4.
//

import UIKit
import Foundation
import CoreLocation
import EventKit

// MARK: Avatar

public protocol HasAvatar {
    var avatar: Avatar { get }
}

// MARK: Calendar

public enum EventCalendarSource {
    case local      // 本地（设备）日历
    case lark       // Lark 日历
    case google     // Google 日历
    case exchange   // Exchange 日历
}

// 日程所属日历
public protocol EventCalendarType {
    var id: String { get }
    var source: EventCalendarSource { get }
}

// MARK: Attendee

public typealias AttendeeStatus = CalendarEventAttendee.Status
public typealias EmailContactType = CalendarEventAttendee.MailContactType

// 日程参与人种子信息（譬如 chatterId，chatId，emailAddress）
// emailContact 暂时不具备通过id拿信息的能力，需要知道全量信息
public enum EventAttendeeSeed {
    case user(chatterId: String)        // 用户（lark）
    case group(chatId: String)          // 普通群组
    case meetingGroup(chatId: String)   // 会议群
    case email(address: String)         // 邮件参与人
    case emailContact(address: String,
                      name: String,
                      avatarKey: String,
                      entityId: String,
                      type: EmailContactType)
}

extension EventAttendeeSeed: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .user(let chatterId): return "userSeed: \(chatterId)"
        case .group(let chatId): return "groupSeed: \(chatId)"
        case .meetingGroup(let chatId): return "meetingGroupSeed: \(chatId)"
        case .email(let address): return "emailSeed: \(address)"
        case let .emailContact(address, name, avatarKey, entityId, type): return "emailContact: \(address), \(name), \(avatarKey), \(entityId), \(type)"
        }
    }
}

extension EventAttendeeSeed {
    var mail: String? {
        switch self {
        case .email(let address), .emailContact(let address, _, _, _, _):
            return address
        default:
            return nil
        }
    }
}

// 日程参与人（用户）
public protocol EventUserAttendeeType: CustomDebugStringConvertible {
    var calendarId: String { get }
    var status: AttendeeStatus { get }
    var deduplicatedKey: String { get }
}

extension EventUserAttendeeType {
    public var debugDescription: String {
        return "calendarId: \(calendarId), status: \(status.rawValue)"
    }

    public var deduplicatedKey: String { return "calendarId:\(self.calendarId.encryptedString)" }
}

// 日程参与人（群组）
public protocol EventGroupAttendeeType: CustomDebugStringConvertible {
    var chatId: String { get }
    var name: String { get }
    var avatar: Avatar { get }
    var members: [EventEditUserAttendee] { get }
    var memberSeeds: [Rust.IndividualSimpleAttendee] { get }
    var encryptedSeeds: [Rust.EncryptedSimpleAttendee] { get }
    var hasMoreMembers: Bool? { get }
    var status: AttendeeStatus { get }
    var deduplicatedKey: String { get }
    var openSecurity: Bool { get }
    var memberShownLimit: Int32 { get }
    var validMemberCount: Int32 { get }
    var isUserCountVisible: Bool { get }
}

extension EventGroupAttendeeType {
    public var debugDescription: String {
        return "chatId: \(chatId), status: \(status.rawValue), members: [\(members.debugDescription)]"
    }

    var deduplicatedKey: String { return "chatId:\(self.chatId)" }
}

// 日程参与人（for 本地日程）
public protocol EventLocalAttendeeType: CustomDebugStringConvertible {
    var name: String { get }
    var status: AttendeeStatus { get }
}

extension EventLocalAttendeeType {
    public var debugDescription: String {
        return "name: \(name), status: \(status.rawValue)"
    }
}

// 日程参与人（邮件）
public protocol EventEmailAttendeeType: CustomDebugStringConvertible {
    var address: String { get }
    var status: AttendeeStatus { get }
    var type: EmailContactType { get }
}

extension EventEmailAttendeeType {
    public var debugDescription: String {
        return "address: \(address), status: \(status.rawValue)"
    }
}

// 日程参与人基础信息（包括 avatar、name 等）
public enum EventAttendee<UserAttendee, GroupAttendee, EmailAttendee, LocalAttendee>
    where UserAttendee: EventUserAttendeeType,
        GroupAttendee: EventGroupAttendeeType,
        EmailAttendee: EventEmailAttendeeType,
        LocalAttendee: EventLocalAttendeeType {
    case user(UserAttendee)
    case group(GroupAttendee)
    case email(EmailAttendee)
    case local(LocalAttendee)
}

extension EventAttendee: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .user(let attendee): return "user attendee"
        case .group(let attendee): return "group attendee"
        case .local(let attendee): return "local attendee"
        case .email(let attendee): return "email attendee"
        }
    }
}

// MARK: Reminder

// 日程提醒
public protocol EventReminderType {
    // 单位：分钟；比如提前 5 分钟：5；开始后 8 小时：-480
    var minutes: Int32 { get }
}

// MARK: Location

// 日程地址
public protocol EventLocationType {
    var name: String { get }
    var address: String { get }
    var coordinate: CLLocationCoordinate2D { get }
}

// 日程可见性
public typealias EventVisibility = CalendarEvent.Visibility

// 日程忙闲
public enum EventFreeBusy {
    case free
    case busy
}

// 日程重复性规则
public typealias EventRecurrenceRule = EKRecurrenceRule
public typealias EventRecurrenceEnd = EKRecurrenceEnd
public typealias EventRecurrenceDayOfWeek = EKRecurrenceDayOfWeek
public typealias EventWeekday = EKWeekday

// 日程描述

public enum EventNotes {
    case html(text: String)
    case plain(text: String)
    // 其中 plainText 用于兼容低版本
    case docs(data: String, plainText: String)
}

extension EventNotes {

    var isEmpty: Bool {
        switch self {
        case .html(let text): return text.isEmpty
        case .plain(let text): return text.isEmpty
        case .docs(let data, let text): return data.isEmpty && text.isEmpty
        }

    }
}

extension EventNotes: Equatable {

    public static func == (_ lhs: EventNotes, _ rhs: EventNotes) -> Bool {
        switch (lhs, rhs) {
        case (.html(let text1), .html(let text2)):
            return text1 == text2
        case (.plain(let text1), .plain(let text2)):
            return text1 == text2
        case (.docs(let data1, let plainText1), .docs(let data2, let plainText2)):
            return data1 == data2 && plainText1 == plainText2
        default:
            return false
        }
    }

}

extension EventNotes: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .docs(let data, let plainText):
            return "data notes. data: \(data), plainText: \(plainText)"
        case .html(let text):
            return "html notes. text: \(text)"
        case .plain(let text):
            return "plain notes. text: \(text)"
        }
    }
}

extension EventFreeBusy: Equatable, CustomStringConvertible {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.free, .free), (.busy, .busy): return true
        default: return false
        }
    }

    public var description: String {
        switch self {
        case .free: return BundleI18n.Calendar.Calendar_Detail_Free
        case .busy: return BundleI18n.Calendar.Calendar_Detail_Busy
        }
    }

}

extension EventVisibility: CustomStringConvertible {

    public var description: String {
        switch self {
        case .default: return BundleI18n.Calendar.Calendar_Edit_DefalutVisibility
        case .public: return BundleI18n.Calendar.Calendar_Edit_Public
        case .private: return BundleI18n.Calendar.Calendar_Edit_Private
        }
    }
}
