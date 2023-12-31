//
//  AttendeeFromLocal.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/14.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import EventKit

extension AttendeeFromLocal: Avatar {
    var avatarKey: String {
       return ""
    }

    var identifier: String {
        return ""
    }

    var userName: String {
        return self.localizedDisplayName
    }
}
struct AttendeeFromLocal: CalendarEventAttendeeEntity {
    var groupStatus: GroupStatus = GroupStatus(isAnyRemoved: false, isSelfInGroup: false, validMemberCount: 0)

    var mail: String?

    var chatterId: String?

    var chatId: String?

    var isThirdParty: Bool {
        return true
    }

    var inviteOperatorID: String { return "" }

    var isCrossTenant: Bool {
        return false
    }

    var isEditable: Bool {
        return false
    }

    var isMeetingGroup: Bool = false

    var groupMemberSeeds: [Rust.IndividualSimpleAttendee] = []

    var isDisabled: Bool {
        return false
    }

    var tenantId: String = Tenant.noTenantId

    private var localAttendee: EKParticipant
    private var organizerHashValue: String

    var id: String {
        get { return String(localAttendee.hashValue) }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var displayName: String {
        get {
            //节省开销
            if let name = localAttendee.name {
                return name
            }
            let emailFromURL = localAttendee.url.absoluteString.replacingOccurrences(of: "mailto:", with: "", options: .literal, range: nil)
            return emailFromURL
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var attendeeCalendarId: String {
        get {
            return "no calendar ID for local calendar\(arc4random())"
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isOrganizer: Bool {
        get { return false }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isResource: Bool {
        get {
            return localAttendee.participantType == .resource || localAttendee.participantType == .room
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var status: AttendeeFromLocal.Status {
        get {
            return localAttendee.participantStatus.toCalendarEvnetAttendeeStatus()
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var avatar: Avatar {
        get { return self as Avatar }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isOptional: Bool {
        get { return false }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isGroup: Bool {
        return false
    }

    var groupId: String {
        return "no group id for local attendee\(arc4random())"
    }

    var localizedDisplayName: String {
        return displayName
    }

    var groupMembers: [CalendarEventAttendeeEntity] {
        get { return [] }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var shouldShowGroup: Bool {
        get { return false }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isDisplayOrganinzer: Bool {
        return "\(self.localAttendee.url)" == organizerHashValue
    }

    var displayOrganizerCalId: String? {
        get { return organizerHashValue }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var openSecurity: Bool {
        return false
    }

    var showMemberLimit: Int32 {
        return .max
    }

    func originalModel() -> Any {
        return localAttendee
    }

    func isEqual(to attendee: CalendarEventAttendeeEntity) -> Bool {
        guard let attendee = attendee as? AttendeeFromLocal else {
            return false
        }
        return attendee.localAttendee == localAttendee
    }

    init(localAttendee: EKParticipant, organizerHash: String) {
        self.localAttendee = localAttendee
        self.organizerHashValue = organizerHash
    }
}
