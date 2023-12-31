//
//  EventModel.swift
//  CalendarEvent
//
//  Created by zhuchao on 13/12/2017.
//  Copyright © 2017 EE. All rights reserved.
//

import RustPB

struct CalendarMember: Avatar, ShareMemberViewModel, Equatable {
    var avatarKey: String {
        return self.pb.avatarKey
    }

    var identifier: String {
        if self.pb.memberType == .group {
            return self.pb.chatID
        } else {
            return self.pb.userID
        }
    }

    var chatId: String {
        return self.pb.chatID
    }
    var accessRole: CalendarModel.AccessRole {
        get { return self.pb.accessRole }
        set { self.pb.accessRole = newValue }
    }
    var status: CalendarModel.Status {
        get { return self.pb.status }
        set { self.pb.status = newValue }
    }

    var localizedName: String {
        return self.pb.localizedName
    }

    var userName: String {
        return self.pb.name
    }

    var userID: String {
        return self.pb.userID
    }

    private var pb: RustPB.Calendar_V1_CalendarMember
    init(pb: RustPB.Calendar_V1_CalendarMember) {
        self.pb = pb
    }

    func getCalendarMemberPb() -> RustPB.Calendar_V1_CalendarMember {
        return self.pb
    }

    var isGroup: Bool {
        return self.pb.memberType == .group
    }

    var groupMemberCount: Int {
        return Int(self.pb.chatMemberCount)
    }

    public static func == (lhs: CalendarMember, rhs: CalendarMember) -> Bool {
        return lhs.pb == rhs.pb
    }

    var isUserCountVisible: Bool {
        return self.pb.isUserCountVisible
    }

}

struct CalendarWithMembers {
    var calendarId: String {
        get { return self.pb.calendarID }
        set { self.pb.calendarID = newValue }
    }

    var calendarMember: [CalendarMember] {
        return self.pb.calendarMembers.map({ CalendarMember(pb: $0) })
    }

    private var pb: RustPB.Calendar_V1_CalendarWithMembers
    init(pb: RustPB.Calendar_V1_CalendarWithMembers) {
        self.pb = pb
    }
}

extension Array where Element == CalendarMember {
    func toCalendarMemberCellModel(haveOwnerAccess: Bool,
                                    ownerUserId: String,
                                   selfUserId: String) -> [CalendarMemberCellModel] {
        return map({ (member) -> CalendarMemberCellModel in
            let memberId = member.getCalendarMemberPb().userID
            var isMemberTheOwner = ownerUserId == memberId
            let isMemberEqualToSelf = selfUserId == memberId
            if member.isGroup {
                isMemberTheOwner = false
            }
            /*
             1. 如果参与人是第一位参与者（自己）或者是有管理权限的其他人，则点击编辑参与人权限不响应
             2. 如果非以上两种情况且本地用户对当前用户有管理权限，则可以点击编辑参与人权限
             */
            let haveEditAccess = !(isMemberEqualToSelf || isMemberTheOwner) && haveOwnerAccess
            return CalendarMemberCellModel.from(member,
                                                haveEditAccess: haveEditAccess,
                                                isGroup: member.isGroup,
                                                groupMemberCount: member.groupMemberCount)
        })
    }
}
