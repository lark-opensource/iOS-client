//
//  EventAttendee+Util.swift
//  Calendar
//
//  Created by 张威 on 2020/4/21.
//

import Foundation

extension EventAttendeeSeed {

    fileprivate struct AvatarImpl: Avatar {
        var avatarKey: String
        var userName: String
        var identifier: String
    }

}

extension EventGroupAttendeeType {
    func visibleMembers() -> [EventEditUserAttendee] {
        return members.filter { $0.status != .removed }
    }
}

extension EventAttendeeSeed {

    var deduplicatedKey: String {
        switch self {
        case .email(let address):
            return "address:\(address.lowercased())"
        case .user(let chatterId):
            return "chatterId:\(chatterId)"
        case .group(let chatId), .meetingGroup(let chatId):
            return "chatId:\(chatId)"
        case let .emailContact(address, name, avatarKey, entityId, type):
            return "email_contact:\(address.lowercased())"
        }
    }

    /// 去重
    static func deduplicated(of seeds: [Self]) -> [Self] {
        var idSet = Set<String>()
        var deduplicatedArr = [Self]()
        for seed in seeds {
            let key = seed.deduplicatedKey
            if idSet.contains(key) {
                continue
            }
            idSet.insert(key)
            deduplicatedArr.append(seed)
        }
        return deduplicatedArr
    }

}

extension EventLocalAttendeeType {

    var avatar: Avatar {
        return EventAttendeeSeed.AvatarImpl(
            avatarKey: "",
            userName: name,
            identifier: ""
        )
    }

}

extension EventEmailAttendeeType {

    func hasAddress(_ address: String, caseInsensitive: Bool = true) -> Bool {
        if caseInsensitive {
            return self.address.lowercased() == address.lowercased()
        } else {
            return self.address == address
        }
    }

    func hasSameAddress(with other: Self, caseInsensitive: Bool = true) -> Bool {
        return hasAddress(other.address, caseInsensitive: caseInsensitive)
    }

}

extension Rust.GroupSimpleAttendee {
    var deduplicatedKey: String {
        return "chatId:\(groupID)"
    }

    /// 去重
    static func deduplicated(of attendees: [Self]) -> [Self] {
        var idSet = Set<String>()
        var deduplicatedArr = [Self]()
        for attendee in attendees {
            let key = attendee.deduplicatedKey
            if idSet.contains(key) {
                // 保留非 removed 状态的参与人
                if attendee.status != .removed {
                    deduplicatedArr.removeAll(where: { $0.deduplicatedKey == key })
                    deduplicatedArr.append(attendee)
                }
                continue
            }
            idSet.insert(key)
            deduplicatedArr.append(attendee)
        }
        return deduplicatedArr
    }
}

extension Rust.EncryptedSimpleAttendee {
    var deduplicatedKey: String {
        return "calendarId:\(self.encryptedCalendarID)"
    }
}

typealias CalendarID = String

extension CalendarID {
    var encryptedString: String {
        return ("08a441" + self).sha1()
    }
}

extension Rust.IndividualSimpleAttendee {
    var deduplicatedKey: String {
        switch attendeeUserInfo {
        case .thirdPartyUser(let user):
            return "address:\(user.email.lowercased())"
        case .user:
            return "calendarId:\(self.calendarID.encryptedString)"
        @unknown default:
            return ""
        }
    }

    /// 去重
    static func deduplicated(of attendees: [Self]) -> [Self] {
        var idSet = Set<String>()
        var deduplicatedArr = [Self]()
        for attendee in attendees {
            let key = attendee.deduplicatedKey
            if idSet.contains(key) {
                // 保留非 removed 状态的参与人
                if attendee.status != .removed {
                    deduplicatedArr.removeAll(where: { $0.deduplicatedKey == key })
                    deduplicatedArr.append(attendee)
                }
                continue
            }
            idSet.insert(key)
            deduplicatedArr.append(attendee)
        }
        return deduplicatedArr
    }
}

extension EventAttendee where UserAttendee: HasAvatar, EmailAttendee: HasAvatar {
    var avatar: Avatar {
        switch self {
        case .email(let email): return email.avatar
        case .user(let user): return user.avatar
        case .group(let group): return group.avatar
        case .local(let local): return local.avatar
        }
    }
}

extension EventAttendee {
    var hasEmailContactType: Bool? {
        switch self {
        case .email(let email): return email.type != .normalMail
        default: return nil
        }
    }

    var status: AttendeeStatus {
        switch self {
        case .email(let email): return email.status
        case .user(let user): return user.status
        case .group(let group): return group.status
        case .local(let local): return local.status
        }
    }

    var deduplicatedKey: String {
        switch self {
        case .email(let email):
            return "address:\(email.address.lowercased())"
        case .local(let local):
            return "name:\(local.name)"
        case .user(let user):
            return user.deduplicatedKey
        case .group(let group):
            return group.deduplicatedKey
        }
    }

    static func chooseAttendeeForSameKey(in attendeees: [Self]) -> [Self] {
        guard let first = attendeees.first else {
            return attendeees
        }
        // 处理相同key的特殊情况

        // 如果邮件地址相同，取有邮件参与人类型的参与人
        // hasEmailContactType != nil 表示是端上生成的邮件参与人
        // sdk返回的邮件参与人实质是三方参与人类型，比端上生成的多了 attendeeCalendarId 字段
        // 如果邮件参与人重复，则将sdk的 attendeeCalendarId 赋给端上的结构体
        if attendeees.allSatisfy({ $0.hasEmailContactType != nil }) {
            if let firstContactTypeEmail = attendeees.first(where: { $0.hasEmailContactType == true }),
               let firstSDKReturnEmail = attendeees.first(where: { $0.hasEmailContactType == false }) {
                if let eventEditContactMail = firstContactTypeEmail as? EventEditAttendee,
                   let sdkReturnEmail = firstSDKReturnEmail as? EventEditAttendee,
                   case .email(var contactMail) = eventEditContactMail,
                   case .email(let sdkMail) = sdkReturnEmail {
                    contactMail.calendarId = sdkMail.calendarId
                    return [.email(contactMail as! EmailAttendee)]
                }
                return [firstContactTypeEmail]
            }
        }
        // 默认取第一个不是removed状态的，没有的话取第一个
        return [attendeees.first(where: { $0.status !=  .removed }) ?? first]
    }

    /// 去重
    static func deduplicated(of attendees: [Self]) -> [Self] {
        var groupedAttendees = Dictionary(grouping: attendees, by: { $0.deduplicatedKey })

        var deduplicatedArr = [Self]()
        for attendee in attendees {
            guard let sameKeyAttendees = groupedAttendees[attendee.deduplicatedKey] else {
                continue
            }

            let remainAttendee = sameKeyAttendees.count > 1 ? chooseAttendeeForSameKey(in: sameKeyAttendees) : sameKeyAttendees
            groupedAttendees[attendee.deduplicatedKey] = nil
            deduplicatedArr.append(contentsOf: remainAttendee)
        }
        return deduplicatedArr
    }

    /// 返回 lark 用户参与人；群成员也会被考虑；根据 calendarId 去重
    ///
    /// - Parameters:
    ///   - attendees: 参与人
    ///   - ignoreRemoved: 是否忽略 removed 的成员，默认 `true`
    static func allUserAttendees(
        of attendees: [EventAttendee],
        ignoreRemoved: Bool = true
    ) -> [UserAttendeeBaseDisplayInfo] {
        var normalUserAttendees = [EventEditUserAttendee]()
        var emailUserAttendees = [EventEditEmailAttendee]()
        for attendee in attendees {
            switch attendee {
            case .local:
                continue
            case .email(let emailAttendee):
                if let attendee = emailAttendee as? EventEditEmailAttendee,
                   attendee.canParsed {
                    emailUserAttendees.append(attendee)
                }
            case .user(let userAttende):
                if let attendee = userAttende as? EventEditUserAttendee {
                    normalUserAttendees.append(attendee)
                }
            case .group(let groupAttendee):
                if ignoreRemoved && groupAttendee.status == .removed {
                    continue
                }

                normalUserAttendees.append(contentsOf: groupAttendee.members as? [EventEditUserAttendee] ?? [])
            }
        }
        var idSet = Set<String>()
        var result = [UserAttendeeBaseDisplayInfo]()
        for item in normalUserAttendees {
            if idSet.contains(item.calendarId) {
                continue
            }
            if ignoreRemoved && item.status == .removed {
                continue
            }
            if !(ignoreRemoved && item.status == .removed) {
                result.append(UserAttendeeBaseDisplayInfo(fromNormal: item))
            }
            idSet.insert(item.calendarId)
        }

        for item in emailUserAttendees {
            guard let calendarId = item.toProfileCalendarId else {
                continue
            }
            if idSet.contains(calendarId) {
                continue
            }
            if ignoreRemoved && item.status == .removed {
                continue
            }
            if !(ignoreRemoved && item.status == .removed) {
                result.append(UserAttendeeBaseDisplayInfo(fromEmail: item))
            }
            idSet.insert(calendarId)
        }
        return result
    }

    /// 计算参与人的数量；如果是群参与人，则打散成员纳入计算；进行了去重处理
    ///
    /// - Parameters:
    ///   - attendees: 参与人
    ///   - ignoreRemoved: 是否忽略 removed 的成员，默认 `true`
    static func allBreakedUpAttendeeCount(
        of attendees: [EventAttendee],
        individualSimpleAttendees: [Rust.IndividualSimpleAttendee] = [],
        ignoreRemoved: Bool = true
    ) -> Int {
        var simpleAttendees: [Rust.IndividualSimpleAttendee] = individualSimpleAttendees
        var encryptedAttendees: [Rust.EncryptedSimpleAttendee] = []

        var removedIdSet = Set<String>()
        var idSet = Set<String>()

        for attendee in attendees {
            if idSet.contains(attendee.deduplicatedKey) {
                continue
            }

            switch attendee {
            case .email(let emailAttendee):
                if ignoreRemoved && emailAttendee.status == .removed {
                    removedIdSet.insert(attendee.deduplicatedKey)
                    continue
                }
                idSet.insert(attendee.deduplicatedKey)
            case .local(let localAttendee):
                if ignoreRemoved && localAttendee.status == .removed {                    removedIdSet.insert(attendee.deduplicatedKey)
                    continue
                }
                idSet.insert(attendee.deduplicatedKey)
            case .user(let userAttendee):
                if ignoreRemoved && userAttendee.status == .removed {                    removedIdSet.insert(attendee.deduplicatedKey)
                    continue
                }
                idSet.insert(attendee.deduplicatedKey)
            case .group(let groupAttendee):
                if ignoreRemoved && groupAttendee.status == .removed {
                    continue
                }
                groupAttendee.memberSeeds.forEach {
                    if !(ignoreRemoved && $0.status == .removed) {                    removedIdSet.insert(attendee.deduplicatedKey)
                        idSet.insert($0.deduplicatedKey)
                    }
                }
                simpleAttendees.append(contentsOf: groupAttendee.memberSeeds)
                encryptedAttendees.append(contentsOf: groupAttendee.encryptedSeeds)
            }
        }

        for item in simpleAttendees {
            // 完整参与人已remove则不处理
            if removedIdSet.contains(item.deduplicatedKey) {
                continue
            }

            if idSet.contains(item.deduplicatedKey) {
                continue
            }
            if ignoreRemoved && item.status == .removed {
                continue
            }
            idSet.insert(item.deduplicatedKey)
        }

        for item in encryptedAttendees {
            // 完整参与人已remove则不处理
            if removedIdSet.contains(item.deduplicatedKey) {
                continue
            }

            if idSet.contains(item.deduplicatedKey) {
                continue
            }
            if ignoreRemoved && item.status == .removed {
                continue
            }
            idSet.insert(item.deduplicatedKey)
        }

        return idSet.count
    }

    static func groupSecurityLimit(of attendees: [EventAttendee], meetingGroupIds: [String]) -> (groupNames: [String], ids: [String], limit: Int32) {
        var limit: Int32 = INT32_MAX
        var groupNames: [String] = []
        var ids: [String] = []
        for attendee in attendees {
            switch attendee {
            case .email, .local, .user:
                continue
            case .group(let groupAttendee):
                if meetingGroupIds.contains(groupAttendee.chatId) &&
                    groupAttendee.openSecurity && groupAttendee.memberShownLimit < groupAttendee.validMemberCount {
                    // 多个不可打散的会议群取 memberShownLimit 最小值
                    limit = min(groupAttendee.memberShownLimit, limit)
                    groupNames.append(groupAttendee.name)
                    ids.append(groupAttendee.chatId)
                }
            }
        }
        return (groupNames: groupNames, ids: ids, limit: limit)
    }

    /// 可见参与人。略过 status == .removed 的参与人
    static func visibleAttendees(of attendees: [Self]) -> [Self] {
        attendees.filter { attendee -> Bool in
            switch attendee {
            case .local:
                return true
            case .email(let emailAttende):
                return emailAttende.status != .removed
            case .user(let userAttende):
                return userAttende.status != .removed
            case .group(let groupAttendee):
                return groupAttendee.status != .removed
            }
        }
    }

}
