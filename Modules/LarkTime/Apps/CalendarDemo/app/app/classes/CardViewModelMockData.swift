//
//  CardViewModelMockData.swift
//  CalendarDemo
//
//  Created by heng zhu on 2019/6/28.
//

import UIKit
import Foundation
import UniverseDesignColor
@testable import Calendar

final class ShareCardModelMock: ShareEventCardModel {

    var isWebinar: Bool = false

    var relationTag: String?

    var eventID: String = ""

    var chatId: String = ""

    var status: CalendarEventAttendee.Status = .accept

    var currentUsersMainCalendarId: String = ""

    var hasReaction: Bool = false

    var reactionIsEmpty: Bool = true
    var isCrossTenant: Bool = true
    var calendarID: String = "1"
    var key: String = "1"
    var originalTime: Int = 0
    var messageId: String = "0"
    var startTime: Int64? = 1_561_154_400
    var endTime: Int64? = 1_561_157_100
    var isAllDay: Bool? = false
    var isShowConflict: Bool = true
    var isShowRecurrenceConflict: Bool = false
    var conflictTime: Int64 = 1_561_415_400
    var color: Int32 = 0
    var isJoined: Bool = false
    var title: String = "分享卡片长长长长长长长长长长长长长长长长长长长长长长长"
    var location: String? = "Xueqing Jiachuang Mansion"
    var meetingRoom: String? = "F1-M7 🎦(5) Beijing-Xueqing(学清)"
    var desc: String = "12123"
    var rrule: String? = "FREQ=DAILY;INTERVAL=1;UNTIL=20190719T030949Z"
    var attendeeNames: [String] = ["邹嘉懿", "朱衡"]
    var isInvalid: Bool = false
}

final class CardViewModelMock: InviteEventCardModel {

    var isWebinar: Bool = false

    var speakerChatterIDs: [String] = []

    var speakerNames: [String : String] = [:]

    var speakerGroupIDs: [String] = []

    var speakerGroupNames: [String : String] = [:]

    var relationTag: String?

    var senderUserId: String?

    var chatId: String = ""

    var eventServerID: String = ""
    
    var showTimeUpdatedFlag: Bool = true

    var showRruleUpdatedFlag: Bool = true

    var showLocationUpdatedFlag: Bool = true

    var showMeetingRoomUpdatedFlag: Bool = true

    var isInvalid: Bool = false

    var rsvpCommentUserName: String?

    var responderUserLocalizedName: String?
    
    var inviteOperatorLocalizedName: String?
    
    var showReplyInviterEntry: Bool = true

    var userInviteOperatorId: String?

    var inviteLocalizedName: String?

    var status: CalendarEventAttendee.Status = .accept

    var eventId: String?

    var hasReaction: Bool = false

    var reactionIsEmpty: Bool = true

    var descAttributedInfo: (string: NSAttributedString, range: [NSRange: URL])?
    var isCrossTenant: Bool = false
    var summary: String = ""
    var time: String = ""
    var rrule: String?
    var attendeeIDs: [String]?
    var attendeeNames: [String: String] = [:]
    var groupIds: [String]?
    var groupNames: [String: String] = [:]
    var meetingRooms: String?
    var meetingRoomsInfo: [(name: String, isDisabled: Bool)] = []
    var location: String?
    var desc: String?
    var needAction: Bool = false
    var calendarID: String?
    var key: String?
    var originalTime: Int?
    var isAccepted: Bool = false
    var isDeclined: Bool = false
    var isTentatived: Bool = false
    var isShowOptional: Bool = false
    var isShowConflict: Bool = false
    var isShowRecurrenceConflict: Bool = false
    var conflictTime: Int64 = 0
    var isShowDetailEntrance: Bool = false
    var messageType: Int?
    var selfId: String = ""
    var startTime: Int64?
    var endTime: Int64?
    var isAllDay: Bool?
    var senderUserName: String = "宏宾"
    var attendeeCount: Int = 0
    var messageId: String = ""
    var richText: NSAttributedString?
    var atMeForegroundColor: UIColor = UIColor.ud.N00
    var atOtherForegroundColor: UIColor = UIColor.ud.B600
    var atGroupForegroundColor: UIColor = UIColor.ud.G600
    var successorUserId: String?
    var organizerUserId: String?
    var creatorUserId: String?

    static func mockData() -> CardViewModelMock {
        let mockData = CardViewModelMock()
        mockData.summary = "会议主题长长长长长长长长长长长长长长长长长长"
        mockData.isShowOptional = true
        mockData.isCrossTenant = true
        mockData.isShowConflict = true
        mockData.isShowRecurrenceConflict = false
        mockData.location = "Xueqing Jiachuang Mansion"
        mockData.meetingRooms = "F1-M7 🎦(5) Beijing-Xueqing(学清)"
        mockData.senderUserName = "邹嘉懿"
        mockData.endTime = 1_561_157_100
        mockData.startTime = 1_561_154_400
        mockData.attendeeIDs = ["6606102192271130883", "6507392613258100995"]
        mockData.groupIds = ["6746362299310686475"]
        mockData.attendeeCount = 2
        mockData.calendarID = "1612817918321684"
        mockData.key = "37f205fb-1c10-48ba-8c80-922de169132f"
        mockData.originalTime = 0
        mockData.attendeeNames = ["6507392613258100995": "邹嘉懿",
                                  "6606102192271130883": "朱衡"]
        mockData.groupNames = ["6746362299310686475": "长城长长城长长城长城长城长城长城123123123123123123"]
        mockData.messageId = "6704815947707859211"
        mockData.isAllDay = false
        mockData.messageType = CardType.eventDelete.rawValue
        mockData.isShowDetailEntrance = true
        mockData.conflictTime = 1_561_415_400
        mockData.isShowConflict = true
        mockData.isShowRecurrenceConflict = false
        mockData.originalTime = 0
        mockData.inviteOperatorLocalizedName = "🍐🐴"
        mockData.rsvpCommentUserName = "朱衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡衡"
        mockData.responderUserLocalizedName = "朱衡衡衡"
        mockData.needAction = true
        mockData.desc = "候选人：蔡强<br/>职位：Rust/C++工程师<br/>面试类型：视频面试  <br/>面试地址：<a href=\'https://people.toutiaocloud.com/recruitment/interview/interviewer/67c27f68-5e90-11e9-8ec1-3cfdfe5a5610\'>视频链接</a> <br/>面试官：<br/>一面：朱衡（2019-05-08 15:00 Asia/Shanghai）<br/>二面：李玉国（2019-05-08 16:00 Asia/Shanghai）<br/>三面：吴冬（2019-05-08 17:00 Asia/Shanghai）<br/>四面：张黎莉（2019-05-08 18:00 Asia/Shanghai）<br/><br/>简历及面试记录请<a href=\'https://people.bytedance.net/recruitment/my/interview/detail/10038181\'>点击此链接</a><br/><br/>有任何疑问，请联系<a href=\'https://people.bytedance.net/recruitment/chat/2071978?layout=false\'>郑亚娜</a>。<br/>"
        mockData.rrule = "FREQ=DAILY;INTERVAL=1;UNTIL=20190719T030949Z"

        return mockData
    }
}
