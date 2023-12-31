////
////  MockCalendarEventAttendeeEntity.swift
////  CalendarTests
////
////  Created by zhouyuan on 2018/11/20.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import Foundation
//@testable import Calendar
//import RustPB
//
//struct MockAvatar: Avatar {
//    var avatarKey: String { return "http://p1.pstatp.com/origin/5d500039da061abb873b" }
//    var userName: String { return "zhouyuan" }
//}
//
//struct MockCalendarEventAttendeeEntity: CalendarEventAttendeeEntity {
//    var chatterOrChatId: String?
//
//    var mail: String?
//
//    var inviteOperatorID: String {
//        return ""
//    }
//
//    var isThirdParty: Bool {
//        return false
//    }
//
//    var isCrossTenant: Bool {
//        return false
//    }
//
//    var isEditable: Bool {
//        return false
//    }
//
//    var isDisabled: Bool {
//        return false
//    }
//
//    func isCustomer(currentTenantId: String) -> Bool {
//        return true
//    }
//
//    func isTobCurrentTenant(currentTenantId: String) -> Bool {
//        return false
//    }
//
//    func isTobExternalTenant(currentTenantId: String) -> Bool {
//        return false
//    }
//
//    var openSecurity: Bool {
//        return true
//    }
//
//    var showMemberLimit: Int32 {
//        return 100
//    }
//
//    var tenantId: String {
//        return "1"
//    }
//
//    var id: String
//    var attendeeCalendarId: String
//    var isOrganizer: Bool
//    var isResource: Bool
//    var status: MockCalendarEventAttendeeEntity.Status
//    var avatar: Avatar
//    var isOptional: Bool
//    var isGroup: Bool
//    var groupId: String
//    var localizedDisplayName: String
//    var groupMembers: [CalendarEventAttendeeEntity]
//    var isNewAdded: Bool
//    var shouldShowGroup: Bool
//    var isDisplayOrganinzer: Bool
//    var displayOrganizerCalId: String?
//    func originalModel() -> Any {
//        return ""
//    }
//    func isEqual(to attendee: CalendarEventAttendeeEntity) -> Bool {
//        guard self.localizedDisplayName == attendee.localizedDisplayName else {
//            return false
//        }
//        guard self.isGroup == attendee.isGroup else {
//            return false
//        }
//        if self.isGroup {
//            return self.groupId == attendee.groupId
//        }
//        return self.attendeeCalendarId == attendee.attendeeCalendarId
//    }
//    init() {
//        id = "6497014513127129357"
//        attendeeCalendarId = "1591560057517060"
//        shouldShowGroup = false
//        isNewAdded = false
//        isGroup = false
//        localizedDisplayName = "Yuan Zhou"
//        groupId = "0"
//        isResource = false
//        isOrganizer = true
//        status = .accept
//        groupMembers = []
//        isDisplayOrganinzer = false
//        isOptional = false
//        avatar = MockAvatar()
//    }
//}
