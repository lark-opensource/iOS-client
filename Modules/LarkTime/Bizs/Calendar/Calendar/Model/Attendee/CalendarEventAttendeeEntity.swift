//
//  EventModel.swift
//  CalendarEvent
//
//  Created by zhuchao on 13/12/2017.
//  Copyright © 2017 EE. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import RustPB
import EventKit
import Contacts
import CalendarFoundation
import LarkContainer
// 参与人
protocol CalendarEventAttendeeEntity {

    typealias Status = CalendarEventAttendee.Status
    var inviteOperatorID: String { get }
    var id: String { get set }
    var displayName: String { get set }
    // required
    var attendeeCalendarId: String { get }
    var isOrganizer: Bool { get set }
    var isResource: Bool { get set }
    var status: Status { get set }
    var avatar: Avatar { get }
    var isOptional: Bool { get set }
    var isGroup: Bool { get }
    var groupId: String { get }
    var localizedDisplayName: String { get }
    var groupMembers: [CalendarEventAttendeeEntity] { get set }
    var isMeetingGroup: Bool { get }
    var groupMemberSeeds: [Rust.IndividualSimpleAttendee] { get }
    var groupStatus: GroupStatus { get }
    /// 参与人是群组的是否展开群成员
    var shouldShowGroup: Bool { get set }
    var isDisplayOrganinzer: Bool { get }
    var tenantId: String { get }
    var openSecurity: Bool { get }
    var showMemberLimit: Int32 { get }
    var isEditable: Bool { get }
    var isDisabled: Bool { get }
    var isCrossTenant: Bool { get }
    var isThirdParty: Bool { get }
    var chatterId: String? { get }
    var chatId: String? { get }
    var mail: String? { get }
    var timeZoneId: String? { get }

    func originalModel() -> Any
    func getStatusColor() -> UIColor?
    func isEqual(to attendee: CalendarEventAttendeeEntity) -> Bool
    static func attendeeCompareable(_ a0: CalendarEventAttendeeEntity,
                                    _ a1: CalendarEventAttendeeEntity) -> Bool
}

extension CalendarEventAttendeeEntity {

    var timeZoneId: String? { nil }

    func calValue() -> Int {
        var value = 0
        if isDisplayOrganinzer {
            value += 100_000
        }
        value += statusScore()
        return value
    }

    func statusScore() -> Int {
        var value = 0
        switch status {
        case .accept:
            value += 1000
        case .decline:
            value += 100
        case .tentative:
            value += 10
        case .needsAction:
            value += 1
        @unknown default:
            break
        }
        return value
    }

    static func attendeeCompareable(_ a0: CalendarEventAttendeeEntity,
                                    _ a1: CalendarEventAttendeeEntity) -> Bool {
        /// 群放最前面
        if a0.isGroup != a1.isGroup {
            return a0.isGroup
        }
        /// 组织者放在最前面
        if a0.isDisplayOrganinzer != a1.isDisplayOrganinzer {
            return a0.isDisplayOrganinzer
        }
        /// 接受 -> 拒绝 -> 待定 -> 待操作
        if a0.status != a1.status {
            return a0.calValue() > a1.calValue()
        }
        return a0.localizedDisplayName.localizedCompare(a1.localizedDisplayName) == .orderedAscending
    }

    func getStatusColor() -> UIColor? {
        switch self.status {
        case .accept:
            return UIColor.ud.colorfulTurquoise
        case .decline:
            return UIColor.ud.functionDangerContentDefault
        case .tentative:
            return UIColor.ud.textDisabled
        @unknown default:
            return nil
        }
    }

    func getStatusImage() -> UIImage? {
        switch self.status {
        case .accept:
            return UIImage.cd.image(named: "yes_filled")
        case .decline:
            return UIImage.cd.image(named: "decline_filled")
        case .tentative:
            return UIImage.cd.image(named: "maybe_filled")
        @unknown default:
            return nil
        }
    }
}

extension PBAttendee: Avatar {
    var avatarKey: String {
        return pb.avatarKey
    }

    var identifier: String {
        switch pb.category {
        case .user:
            return pb.user.userID
        case .group:
            return pb.group.groupID
        case.thirdPartyUser:
            return mailAttendeeParsed?.entityId ?? ""
        @unknown default:
            return ""
        }
    }

    var userName: String {
        return self.localizedDisplayName
    }
}

struct GroupStatus {
    var isAnyRemoved: Bool
    var isSelfInGroup: Bool
    var validMemberCount: Int
}

struct PBAttendee: CalendarEventAttendeeEntity {
    var mail: String? {
        if pb.category == .thirdPartyUser {
            return pb.thirdPartyUser.email
        }
        return nil
    }

    var chatterId: String? {
        switch pb.category {
        case .user:
            return pb.user.userID
        default:
            return nil
        }
    }

    var chatId: String? {
        switch pb.category {
        case .group:
            return pb.group.groupID
        default:
            return nil
        }
    }

    var isThirdParty: Bool {
        return pb.category == .thirdPartyUser
    }

    var isCrossTenant: Bool {
        return pb.group.isCrossTenant
    }

    var isEditable: Bool {
        get { pb.isEditable }
        set { pb.isEditable = newValue }
    }

    var isDisabled: Bool {
        return self.pb.resource.isDisabled
    }

    var tenantId: String {
        switch pb.category {
        case .user:
            return pb.user.tenantID
        case .group:
            return pb.group.tenantID
        case .resource:
            return pb.resource.tenantID
        case .thirdPartyUser:
            return ""
        @unknown default:
            return ""
        }
    }

    var timeZoneId: String? {
        if case .user = pb.category {
            return pb.user.timezoneID
        } else {
            return nil
        }
    }

    func isEqual(to attendee: CalendarEventAttendeeEntity) -> Bool {
        guard self.localizedDisplayName == attendee.localizedDisplayName else {
            return false
        }
        guard self.isGroup == attendee.isGroup else {
            return false
        }
        if self.isGroup {
            return self.groupId == attendee.groupId
        }
        guard self.isThirdParty == attendee.isThirdParty else {
            return false
        }
        if self.isThirdParty {
            return self.mail == attendee.mail
        }
        return self.attendeeCalendarId == attendee.attendeeCalendarId
    }

    var avatar: Avatar {
        return self
    }

    func originalModel() -> Any {
        return self.pb
    }

    var id: String {
        get { return self.pb.id }
        set { self.pb.id = newValue }
    }

    var displayName: String {
        get { return self.pb.displayName }
        set { self.pb.displayName = newValue }
    }

    // required
    var attendeeCalendarId: String {
        return self.pb.attendeeCalendarID
    }

    var toProfileCalendarId: String? {
        if isMailAttendeeParsed,
           let calendarId = mailAttendeeParsed?.calendarId {
            return calendarId
        }
        return isThirdParty ? nil : attendeeCalendarId
    }

    var isOrganizer: Bool {
        get { return self.pb.isOrganizer }
        set { self.pb.isOrganizer = newValue }
    }
    var isResource: Bool {
        get { return self.pb.category == .resource }
        set {
            if newValue { self.pb.category = .resource }
        }
    }
    var status: Status {
        get { return self.pb.status }
        set { self.pb.status = newValue }
    }
    var isOptional: Bool {
        get { return self.pb.isOptional }
        set { self.pb.isOptional = newValue }
    }
    var isGroup: Bool {
        return self.pb.category == .group
    }

    var groupId: String {
        return self.pb.group.groupID
    }

    var openSecurity: Bool {
        return self.pb.group.openSecurity
    }

    var showMemberLimit: Int32 {
        return pb.group.showMemberLimit
    }

    var localizedDisplayName: String {
        get { return displayName }
        set { self.pb.displayName = newValue }
    }

    var groupMembers: [CalendarEventAttendeeEntity] {
        get {
            return self.pb.group.members.map({ (attendee) -> PBAttendee in
                return PBAttendee(pb: attendee, displayOrganizerCalId: displayOrganizerCalId)
            })
        }
        set {
            // swiftlint:disable force_cast
            self.pb.group.members = newValue.map({ $0.originalModel() as! CalendarEventAttendee })
        }
    }

    var isMeetingGroup: Bool = false

    var groupMemberSeeds: [Rust.IndividualSimpleAttendee] = []

    var groupEncryptedMembers: [Rust.EncryptedSimpleAttendee] = []

    var groupStatus: GroupStatus {
        return GroupStatus(
            isAnyRemoved: pb.group.isAnyRemoved,
            isSelfInGroup: pb.group.isSelfInGroup,
            validMemberCount: Int(pb.group.validMemberCount)
        )
    }

    var inviteOperatorID: String {
        return self.pb.inviterCalendarID
    }

    var shouldShowGroup: Bool = false
    var isDisplayOrganinzer: Bool {
        return attendeeCalendarId == displayOrganizerCalId
    }

    var relationTagStr: String {
        return pb.relationTagStr
    }

    // only for group/meetingGroup attendee
    var forbidenChatterIDs: [Int64] = []

    private var displayOrganizerCalId: String?

    // 是否是可解析的普通邮箱参与人
    private(set) var isMailAttendeeParsed: Bool = false
    private var mailAttendeeParsed: MailContactParsed?

    private(set) var pb: CalendarEventAttendee

    // displayOrganizerCalId 用来显示是否真正的组织者
    init(pb: CalendarEventAttendee, displayOrganizerCalId: String? = nil) {
        self.pb = pb
        self.displayOrganizerCalId = displayOrganizerCalId
    }

    init(userInfo: CurrentUserInfo, calendarId: String) {
        var pb = CalendarEventAttendee()
        pb.displayName = FG.useChatterAnotherName ? userInfo.nameWithAnotherName : userInfo.displayName
        pb.attendeeCalendarID = calendarId
        pb.category = .user
        pb.id = "0"
        pb.avatarKey = userInfo.avatarKey
        self.pb = pb
    }

    init(email: String, attendeeCalendarId: String? = nil) {
        var pb = CalendarEventAttendee()
        pb.displayName = email
        pb.attendeeCalendarID = attendeeCalendarId ?? ""
        pb.category = .thirdPartyUser
        pb.id = "0"
        pb.thirdPartyUser.email = email
        self.pb = pb
    }

    // 邮件联系人（带类型和头像等）
    init(emailContact: String,
         type: EmailContactType,
         avatarKey: String,
         displayName: String) {
        var pb = CalendarEventAttendee()
        pb.displayName = displayName
        pb.category = .thirdPartyUser
        pb.attendeeCalendarID = ""
        pb.id = "0"
        pb.thirdPartyUser.email = emailContact
        pb.thirdPartyUser.mailContactType = type
        pb.avatarKey = avatarKey
        self.pb = pb
    }

    typealias ShowMemberLimit = Int32
    init(chatID: String,
         chatterIDs: [String],
         forbidenChatterIDs: [Int64],
         chatterCalendarIdMap: [String: String],
         displayInfo: Rust.AttendeeDisplayInfo,
         primaryCalendarID: String,
         showMemberLimit: ShowMemberLimit,
         openSecurity: Bool,
         isUserCountVisible: Bool) {
        var pb = CalendarEventAttendee()
        pb.displayName = displayInfo.displayName
        pb.avatarKey = displayInfo.avatarKey
        pb.attendeeCalendarID = ""
        pb.category = .group
        pb.id = "0"
        pb.inviterCalendarID = primaryCalendarID

        pb.group.groupID = chatID
        pb.group.showMemberLimit = showMemberLimit
        pb.group.openSecurity = openSecurity
        pb.group.isCrossTenant = displayInfo.group.isCrossTenant
        pb.group.isUserCountVisible = isUserCountVisible
        pb.relationTag = displayInfo.relationTag

        let calendarIDs = chatterIDs.compactMap { chatterID in
            return chatterCalendarIdMap[chatterID]
        }

        pb.group.validMemberCount = Int32(calendarIDs.count - forbidenChatterIDs.count)
        pb.group.isSelfInGroup = calendarIDs.contains(primaryCalendarID)

        self.groupMemberSeeds = chatterIDs.filter { !forbidenChatterIDs.map { "\($0)" }.contains($0) }.compactMap({ chatterID in
            guard let calendarID = chatterCalendarIdMap[chatterID] else { return nil }
            var simpleAttendee = Rust.IndividualSimpleAttendee()
            simpleAttendee.category = .user
            simpleAttendee.user.chatterID = chatterID
            simpleAttendee.isEditable = true
            simpleAttendee.status = .needsAction
            simpleAttendee.calendarID = calendarID

            return simpleAttendee
        })
        self.forbidenChatterIDs = forbidenChatterIDs
        self.pb = pb
    }

}

// MARK: 普通邮件联系人解析
extension PBAttendee {
    mutating func changeNormalMailContactPBIfNeeded(_ mailContactService: MailContactService?) {
        if isThirdParty, let mailContactService = mailContactService {
            if let mail = mail,
               let mailContact = mailContactService.getMailContactsParsed(mails: [mail]).first?.value {
                pb.avatarKey = mailContact.avatartKey ?? pb.avatarKey
                pb.relationTag = mailContact.relationTag ?? pb.relationTag
                pb.displayName = mailContact.displayName ?? pb.displayName
                // 不要轻易修改 attendeeCalendarID，可能会造成 SDK 保存接口错误
//                pb.attendeeCalendarID = mailContact.calendarId ?? pb.attendeeCalendarID
                mailAttendeeParsed = mailContact
                isMailAttendeeParsed = true
            }
        }
    }
}
