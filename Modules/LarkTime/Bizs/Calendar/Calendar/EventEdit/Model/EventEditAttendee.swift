//
//  EventEditAttendee.swift
//  Calendar
//
//  Created by 张威 on 2020/4/29.
//

import RustPB
import EventKit
import LarkModel
import LarkContainer
import CalendarFoundation

struct AvatarImpl: Avatar {
    var avatarKey: String
    var userName: String
    var identifier: String
}

// MARK: 日程参与人基本信息
// 编辑页无法拿到群成员的全部信息，只有时区、头像、calendarID等
// 构造本数据结构用于编辑页与忙闲页、选择时间多时区页交互

struct UserAttendeeBaseDisplayInfo {
    var calendarId: String
    var status: AttendeeStatus
    var name: String
    var tenantId: String
    var avatar: Avatar
    var timeZone: TimeZone?
    init(fromNormal attendee: EventEditUserAttendee) {
        self.calendarId = attendee.calendarId
        self.status = attendee.status
        self.name = attendee.name
        self.avatar = attendee.avatar
        self.timeZone = attendee.timeZone
        self.tenantId = attendee.tenantId
    }
    init(fromDetail attendee: CalendarEventAttendeeEntity) {
        self.calendarId = attendee.attendeeCalendarId
        self.status = attendee.status
        self.name = attendee.localizedDisplayName
        self.avatar = attendee.avatar
        self.timeZone = TimeZone(identifier: attendee.timeZoneId ?? "") ?? .current
        self.tenantId = attendee.tenantId
    }
    init(fromEmail attendee: EventEditEmailAttendee) {
        assert(attendee.canParsed == true)
        self.calendarId = attendee.toProfileCalendarId ?? ""
        self.status = attendee.status
        self.name = attendee.displayName
        self.avatar = attendee.avatar
        self.tenantId = attendee.tenantId ?? ""
        self.timeZone = TimeZone.current
    }
}

extension Rust.IndividualSimpleAttendee {
    static func from(attendee: Rust.Attendee) -> Rust.IndividualSimpleAttendee {
        var simpleAttendee = Rust.IndividualSimpleAttendee()
        simpleAttendee.calendarID = attendee.attendeeCalendarID
        simpleAttendee.isOptional = attendee.isOptional
        simpleAttendee.isEditable = attendee.isEditable
        simpleAttendee.status = attendee.status
        simpleAttendee.inviterCalendarID = attendee.inviterCalendarID

        switch attendee.category {
        case .user:
            var user = Rust.IndividualSimpleLarkAttendee()
            user.chatterID = attendee.user.userID
            simpleAttendee.attendeeUserInfo = .user(user)
            simpleAttendee.category = .user
        case .thirdPartyUser:
            var user = Rust.IndividualSimpleEmailAttendee()
            user.email = attendee.thirdPartyUser.email
            simpleAttendee.attendeeUserInfo = .thirdPartyUser(user)
            simpleAttendee.category = .thirdPartyUser
        @unknown default:
            assertionFailure("not user category")
        }

        return simpleAttendee
    }

}

extension Rust.GroupSimpleAttendee {
    static func from(attendee: Rust.Attendee) -> Rust.GroupSimpleAttendee {
        guard attendee.category == .group else {
            assertionFailure("not group category")
            return Rust.GroupSimpleAttendee()
        }
        var simpleAttendee = Rust.GroupSimpleAttendee()
        simpleAttendee.groupID = attendee.group.groupID
        simpleAttendee.isOptional = attendee.isOptional
        simpleAttendee.isSelfInGroup = attendee.group.isSelfInGroup
        simpleAttendee.validMemberCount = attendee.group.validMemberCount
        simpleAttendee.status = attendee.status
        return simpleAttendee
    }
}

extension Rust.ResourceSimpleAttendee {
    static func from(attendee: Rust.Attendee) -> Rust.ResourceSimpleAttendee {
        guard attendee.category == .resource else {
            assertionFailure("not resource category")
            return Rust.ResourceSimpleAttendee()
        }
        var simpleAttendee = Rust.ResourceSimpleAttendee()
        simpleAttendee.calendarID = attendee.attendeeCalendarID
        simpleAttendee.tenantID = attendee.resource.tenantID
        simpleAttendee.inviterCalendarID = attendee.inviterCalendarID
        simpleAttendee.status = attendee.status
        simpleAttendee.attendeeSchema = attendee.attendeeSchema
        simpleAttendee.schemaExtraData = attendee.schemaExtraData
        return simpleAttendee
    }
}

extension Rust.Attendee {
    func toIndividualSimpleAttendee() -> Rust.IndividualSimpleAttendee {
        return Rust.IndividualSimpleAttendee.from(attendee: self)
    }

    func toGroupSimpleAttendee() -> Rust.GroupSimpleAttendee {
        return Rust.GroupSimpleAttendee.from(attendee: self)
    }

    func toResourceSimpleAttendee() -> Rust.ResourceSimpleAttendee {
        return Rust.ResourceSimpleAttendee.from(attendee: self)
    }
}

// MARK: 用户参与人

public struct EventEditUserAttendee: EventUserAttendeeType,
    CustomPermissionConvertible,
    HasAvatar {

    private(set) var simpleAttendee: Rust.IndividualSimpleAttendee
    let name: String
    public let avatar: Avatar
    let timeZone: TimeZone?
    let tenantId: String
    let relationTagStr: String

    var chatterId: String { simpleAttendee.user.chatterID }
    public var status: AttendeeStatus {
        get { simpleAttendee.status }
        set { simpleAttendee.status = newValue }
    }
    var isOptional: Bool {
        get { simpleAttendee.isOptional }
        set { simpleAttendee.isOptional = newValue }
    }
    public var calendarId: String {
        get { simpleAttendee.calendarID }
        set { simpleAttendee.calendarID = newValue }
    }
    var permission: PermissionOption

    init(from simpleAttendee: Rust.IndividualSimpleAttendee, displayInfo: Rust.AttendeeDisplayInfo) {
        self.simpleAttendee = simpleAttendee

        self.name = displayInfo.displayName
        self.avatar = AvatarImpl(avatarKey: displayInfo.avatarKey,
                                 userName: displayInfo.displayName,
                                 identifier: simpleAttendee.user.chatterID)
        self.timeZone = TimeZone.current
        self.tenantId = displayInfo.tenantID
        self.relationTagStr = displayInfo.relationTagStr

        if simpleAttendee.hasIsEditable && !simpleAttendee.isEditable {
            self.permission = .readable
        } else {
            self.permission = .writable
        }
    }

    init(from attendee: Rust.Attendee) {
        self.simpleAttendee = Rust.IndividualSimpleAttendee.from(attendee: attendee)

        self.name = attendee.displayName
        self.avatar = AvatarImpl(avatarKey: attendee.avatarKey, userName: name, identifier: attendee.user.userID)
        self.timeZone = TimeZone(identifier: attendee.user.timezoneID)
        self.tenantId = attendee.user.tenantID
        if simpleAttendee.hasIsEditable && !simpleAttendee.isEditable {
            self.permission = .readable
        } else {
            self.permission = .writable
        }
        self.relationTagStr = attendee.relationTagStr
    }

    func getPBModel() -> Rust.Attendee {
        var attendee = Rust.Attendee()
        attendee.category = .user
        attendee.displayName = name
        attendee.user.tenantID = self.tenantId
        attendee.user.userID = simpleAttendee.user.chatterID
        attendee.avatarKey = avatar.avatarKey
        attendee.user.timezoneID = self.timeZone?.identifier ?? ""
        attendee.attendeeCalendarID = self.simpleAttendee.calendarID
        attendee.isOptional = self.simpleAttendee.isOptional
        attendee.isEditable = self.simpleAttendee.isEditable
        attendee.isOrganizer = self.simpleAttendee.isOrganizer
        attendee.status = self.simpleAttendee.status
        attendee.inviterCalendarID = self.simpleAttendee.inviterCalendarID
        attendee.id = "0"

        return attendee
    }

}

extension EventEditUserAttendee {

    static func currentAttendee(
        withUserInfo currentInfo: CurrentUserInfo,
        calendarId: String
    ) -> Self {
        var simpleAttendee = Rust.IndividualSimpleAttendee()
        simpleAttendee.calendarID = calendarId
        var user = Rust.IndividualSimpleLarkAttendee()
        user.chatterID = currentInfo.id
        simpleAttendee.attendeeUserInfo = .user(user)
        simpleAttendee.category = .user

        var displayInfo = Rust.AttendeeDisplayInfo()
        displayInfo.avatarKey = currentInfo.avatarKey
        displayInfo.displayName = FG.useChatterAnotherName ? currentInfo.nameWithAnotherName : currentInfo.displayName
        displayInfo.tenantID = currentInfo.tenantId

        return Self(from: simpleAttendee, displayInfo: displayInfo)
    }

}

// MARK: 群组参与人

struct EventEditGroupAttendee: EventGroupAttendeeType,
                               CustomPermissionConvertible {
    typealias PBModel = RustPB.Calendar_V1_CalendarEventAttendee

    private var pb: PBModel
    init(from pb: PBModel,
         seeds: [Rust.IndividualSimpleAttendee]? = nil,
         encryptedSeeds: [Rust.EncryptedSimpleAttendee]? = nil) {
        self.pb = pb
        if pb.hasIsEditable && !pb.isEditable {
            permission = .readable
        } else {
            permission = .writable
        }
        self.members = pb.group.members.map { EventEditUserAttendee(from: $0) }
        self.memberSeeds = seeds ?? []
        self.encryptedSeeds = encryptedSeeds ?? []
    }

    func getPBModel() -> PBModel {
        return pb
    }

    var chatId: String { pb.group.groupID }

    var name: String { pb.displayName }

    var avatar: Avatar { AvatarImpl(avatarKey: pb.avatarKey, userName: name, identifier: pb.group.groupID) }

    // 可展示成员信息，memberSeeds 的子集
    var members: [EventEditUserAttendee]

    // 精简成员信息，包含完整的群成员
    var memberSeeds: [Rust.IndividualSimpleAttendee]

    // 加密的群成员
    var encryptedSeeds: [Rust.EncryptedSimpleAttendee]

    var hasMoreMembers: Bool?

    var pageOffset: String?

    var status: AttendeeStatus {
       get { pb.status }
       set { pb.status = newValue }
    }

    var openSecurity: Bool { pb.group.openSecurity }

    //
    var isCrossTenant: Bool { pb.group.isCrossTenant }

    // 最多展示的成员数量
    var memberShownLimit: Int32 {
        pb.group.hasOpenSecurity ? pb.group.showMemberLimit : Int32.max
    }

    var permission: PermissionOption

    var validMemberCount: Int32 {
        get { pb.group.validMemberCount }
        set { pb.group.validMemberCount = newValue }
    }

    var isAnyRemoved: Bool { pb.group.isAnyRemoved }

    var isSelfInGroup: Bool { pb.group.isSelfInGroup }

    var relationTagStr: String { pb.relationTagStr }

    var isUserCountVisible: Bool { pb.group.isUserCountVisible }
}

// MARK: 本地日程参与人

struct EventEditLocalAttendee: EventLocalAttendeeType, CustomPermissionConvertible {
    let ekModel: EKParticipant

    var name: String {
        if let name = ekModel.name {
            return name
        }
        let emailAddress = ekModel.url.absoluteString.replacingOccurrences(
            of: "mailto:",
            with: "",
            options: .literal,
            range: nil
        )
        return emailAddress
    }

    var status: AttendeeStatus {
        ekModel.participantStatus.toCalendarEvnetAttendeeStatus()
    }

    let permission: PermissionOption = .readable

    var isCurrentUser: Bool {
        ekModel.isCurrentUser
    }
}

// MARK: 邮件参与人
struct EventEditEmailAttendee: EventEmailAttendeeType, CustomPermissionConvertible, PBModelConvertible, HasAvatar {
    var type: EmailContactType {
        get { pb.thirdPartyUser.mailContactType }
        set { pb.thirdPartyUser.mailContactType = newValue }
    }

    typealias PBModel = RustPB.Calendar_V1_CalendarEventAttendee
    private(set) var pb: PBModel

    var mailContactService: MailContactService?

    func getPBModel() -> PBModel {
        return pb
    }

    init(from attendee: Rust.Attendee) {
        self.pb = attendee
        if attendee.hasIsEditable && !attendee.isEditable {
            permission = .readable
        } else {
            permission = .writable
        }
    }

    init(
        address: String,
        calendarId: String,
        status: AttendeeStatus = .needsAction,
        permission: PermissionOption = .writable
    ) {
        pb = PBModel()
        pb.id = "0"
        pb.attendeeCalendarID = calendarId
        pb.category = .thirdPartyUser
        pb.thirdPartyUser.email = address
        pb.displayName = address
        pb.status = status
        self.permission = permission
    }

    init(simpleAttendee: Rust.IndividualSimpleAttendee, type: EmailContactType) {
        pb = PBModel()
        pb.id = "0"
        pb.attendeeCalendarID = simpleAttendee.calendarID
        pb.category = .thirdPartyUser
        pb.thirdPartyUser.email = simpleAttendee.thirdPartyUser.email
        pb.displayName = simpleAttendee.thirdPartyUser.email
        pb.status = simpleAttendee.status
        pb.thirdPartyUser.mailContactType = type

        if simpleAttendee.hasIsEditable && !simpleAttendee.isEditable {
            permission = .readable
        } else {
            permission = .writable
        }
    }
    var address: String {
        get { pb.thirdPartyUser.email }
        set { pb.thirdPartyUser.email = newValue }
    }

    var displayName: String {
        get {
            if let mailContactService = mailContactService,
               let displayName = mailContactService.getMailContactsParsed(mails: [address]).first?.value.displayName {
                return displayName
            }
            return pb.displayName
        }
        set { pb.displayName = newValue }
    }

    var status: AttendeeStatus {
        get { pb.status }
        set { pb.status = newValue }
    }

    var calendarId: String {
        get { pb.attendeeCalendarID }
        set { pb.attendeeCalendarID = newValue }
    }

    // 邮件参与人解析在跳转 profile 场景使用的 calendarId
    var toProfileCalendarId: String? {
        if let mailContactService = mailContactService,
           let calendarId = mailContactService.getMailContactsParsed(mails: [address]).first?.value.calendarId {
            return calendarId
        }
        return nil
    }

    var permission: PermissionOption

    var avatar: Avatar {
        return AvatarImpl(avatarKey: avatarKey,
                          userName: displayName,
                          identifier: avatarIdendifier)
    }

    var avatarIdendifier: String {
        if let mailContactService = mailContactService,
           let identifier = mailContactService.getMailContactsParsed(mails: [address]).first?.value.entityId {
            return identifier
        }
        return pb.thirdPartyUser.email
    }

    var avatarKey: String {
        if let mailContactService = mailContactService,
           let avatartKey = mailContactService.getMailContactsParsed(mails: [address]).first?.value.avatartKey {
            return avatartKey
        }
        return pb.avatarKey
    }

    var canParsed: Bool {
        guard let mailContactService = mailContactService else { return false }
        return !mailContactService.getMailContactsParsed(mails: [address]).isEmpty
    }

    var relationTagStr: String? {
        guard let mailContactService = mailContactService,
              let entity = mailContactService.getMailContactsParsed(mails: [address]).first?.value else { return nil }
        if let relationTag = entity.relationTag,
           !relationTag.relationTagStr.isEmpty {
            return relationTag.relationTagStr
        } else if entity.type == .emailEntity {
            /// 解析成邮箱联系人时的标签是端上给到
            return I18n.Calendar_EmailEvent_EmailContact
        } else {
            return nil
        }
    }

    var tenantId: String? {
        if let mailContactService = mailContactService,
           let tenantId = mailContactService.getMailContactsParsed(mails: [address]).first?.value.tenantId {
            return tenantId
        }
        return nil
    }
}

typealias EventEditAttendee = EventAttendee<
    EventEditUserAttendee,
    EventEditGroupAttendee,
    EventEditEmailAttendee,
    EventEditLocalAttendee
>

extension EventEditAttendee: CustomPermissionConvertible {

    var permission: PermissionOption {
        switch self {
        case .email(let emailAttendee):
            return emailAttendee.permission
        case .user(let userAttendee):
            return userAttendee.permission
        case .group(let groupAttendee):
            return groupAttendee.permission
        case .local(let localAttendee):
            return localAttendee.permission
        }
    }

    var uniqueId: String {
        switch self {
        case .email(let emailAttendee):
            return emailAttendee.address.lowercased()
        case .user(let userAttendee):
            return userAttendee.calendarId
        case .group(let groupAttendee):
            return groupAttendee.chatId
        case .local(let localAttendee):
            return localAttendee.name
        }
    }

    var status: AttendeeStatus {
        switch self {
        case .email(let emailAttendee):
            return emailAttendee.status
        case .user(let userAttendee):
            return userAttendee.status
        case .group(let groupAttendee):
            return groupAttendee.status
        case .local(let localAttendee):
            return localAttendee.status
        }
    }

}

// MARK: Tranform

extension EventEditAttendee {
    static func makeAttendee(from pb: Rust.Attendee) -> EventEditAttendee? {
        switch pb.category {
        case .group: return .group(EventEditGroupAttendee(from: pb))
        case .user: return .user(EventEditUserAttendee(from: pb))
        case .thirdPartyUser: return .email(EventEditEmailAttendee(from: pb))
        @unknown default: return nil
        }
    }

    static func makeAttendees(from pbList: [Rust.Attendee]) -> [EventEditAttendee] {
        pbList.compactMap { EventEditAttendee.makeAttendee(from: $0) }
    }

    static func makeGroupAttendee(from attendee: PBAttendee) -> EventEditAttendee {
        return .group(EventEditGroupAttendee(from: attendee.pb, seeds: attendee.groupMemberSeeds))
    }

    static func makeAttenee(from simpleAttendee: Rust.IndividualSimpleAttendee, displayInfo: Rust.AttendeeDisplayInfo?) -> EventEditAttendee? {
        switch simpleAttendee.category {
        case .user:
            guard let displayInfo = displayInfo else { return nil }
            return .user(EventEditUserAttendee(from: simpleAttendee, displayInfo: displayInfo))
        case .thirdPartyUser: return .email(EventEditEmailAttendee(simpleAttendee: simpleAttendee, type: .unknown))
        @unknown default: return nil
        }
    }

    static func makeAttendee(from detailModel: CalendarEventAttendeeEntity) -> EventEditAttendee? {
        if let pbAttendee = detailModel as? PBAttendee, detailModel.isGroup {
            return makeGroupAttendee(from: pbAttendee)
        }

        if let pb = detailModel.originalModel() as? CalendarEventAttendee {
            return makeAttendee(from: pb)
        }
        if let ekModel = detailModel.originalModel() as? EKParticipant {
            return .local(EventEditLocalAttendee(ekModel: ekModel))
        }
        return nil
    }

    static func makeAttendees(from detailModels: [CalendarEventAttendeeEntity]) -> [EventEditAttendee] {
        detailModels.compactMap { Self.makeAttendee(from: $0) }
    }

    func getPBModel() -> Rust.Attendee? {
        switch self {
        case .user(let userAttendee):
            return userAttendee.getPBModel()
        case .group(let groupAttendee):
            return groupAttendee.getPBModel()
        case .email(let emailAttendee):
            return emailAttendee.getPBModel()
        case .local:
            return nil
        }
    }

    static func getPBModels(from attendees: [Self]) -> [Rust.Attendee] {
        return attendees.compactMap { $0.getPBModel() }
    }

}

extension Array where Element == EventEditAttendee {
    func hasExternalAttendee(tenantId: String) -> Bool {
        let tenant = Tenant(currentTenantId: tenantId)
        let isExternalUtil = {
            return tenant.isExternalTenant(tenantId: $0, isCrossTenant: false)
        }
        return self.contains(where: { attendee in
            switch attendee {
            case .email(let user):
                if let tenantId = user.tenantId {
                    return isExternalUtil(tenantId)
                }
                return true
            case .group(let group): return group.isCrossTenant
            case .local: return false
            case .user(let user):
                return isExternalUtil(user.tenantId)
            }
        })
    }
}
