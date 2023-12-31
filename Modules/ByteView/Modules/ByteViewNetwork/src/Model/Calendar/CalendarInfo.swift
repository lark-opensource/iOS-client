//
//  CalendarInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_CalendarInfo
public struct CalendarInfo: Equatable {
    public init(topic: String, groupID: Int64, desc: String, total: Int32, canEnterOrCreateGroup: Bool,
                theEventStartTime: Int64, theEventEndTime: Int64, wholeEventEndTime: Int64, isAllDay: Bool,
                rooms: [String: CalendarRoom], roomStatus: [String: CalendarAcceptStatus], viewRooms: [String: CalendarRoom],
                calendarLocations: [CalendarLocation]) {
        self.topic = topic
        self.groupID = groupID
        self.desc = desc
        self.total = total
        self.canEnterOrCreateGroup = canEnterOrCreateGroup
        self.theEventStartTime = theEventStartTime
        self.theEventEndTime = theEventEndTime
        self.wholeEventEndTime = wholeEventEndTime
        self.isAllDay = isAllDay
        self.rooms = rooms
        self.roomStatus = roomStatus
        self.viewRooms = viewRooms
        self.calendarLocations = calendarLocations
    }

    ///日程名，时间、重复性、地点、会议室、参与人、描述
    public var topic: String

    /// 具体一次event的开始时间
    public var theEventStartTime: Int64

    /// 具体一次event的结束时间
    public var theEventEndTime: Int64

    /// 整个单次/循环日程的结束时间
    public var wholeEventEndTime: Int64

    public var desc: String

    /// 普通未绑定view room的会议室
    public var rooms: [String: CalendarRoom]

    /// room的日程状态：接受、拒绝、待定
    public var roomStatus: [String: CalendarAcceptStatus]

    /// 参与者数量
    public var total: Int32

    public var canEnterOrCreateGroup: Bool

    /// 是不是一个全天的日常，用于显示时间格式
    public var isAllDay: Bool

    /// 日程设置的location.日历给到的接口是一个list，但实际情况只会有一个元素，考虑到将来的兼容，这里传一个list。
    public var calendarLocations: [CalendarLocation]

    ///日程群组ID,0代表没有日程群
    public var groupID: Int64

    /// 已绑定view room的会议室，可进行视频通话的room
    public var viewRooms: [String: CalendarRoom]

    public enum CalendarAcceptStatus: Int, Hashable {
        case unknown // = 0

        /// 接受日程邀请
        case accept // = 1

        /// 拒绝日程邀请
        case reject // = 2

        /// 待定（用户未接受也未拒绝）
        case tbd // = 3
    }

    public struct CalendarLocation: Equatable {
        public init(name: String, address: String) {
            self.name = name
            self.address = address
        }

        public var name: String
        public var address: String
    }

    /// 会议室实体, Videoconference_V1_Room
    public struct CalendarRoom: Equatable {
        public init(roomID: String, name: String, capacity: Int32, controllerIDList: [String], location: RoomLocation,
                    meetingNumber: String, avatarKey: String, tenantID: String,
                    fullNameParticipant: String, fullNameSite: String, primaryNameParticipant: String,
                    primaryNameSite: String, secondaryName: String, isUnbind: Bool) {
            self.roomID = roomID
            self.name = name
            self.capacity = capacity
            self.controllerIDList = controllerIDList
            self.location = location
            self.meetingNumber = meetingNumber
            self.avatarKey = avatarKey
            self.tenantID = tenantID
            self.fullNameSite = fullNameSite
            self.fullNameParticipant = fullNameParticipant
            self.primaryNameParticipant = primaryNameParticipant
            self.primaryNameSite = primaryNameSite
            self.secondaryName = secondaryName
            self.isUnbind = isUnbind
        }
        /// 会议室名字
        public var name: String

        /// 会议室id
        public var roomID: String

        /// 容纳人数
        public var capacity: Int32

        /// 绑定的控制器列表
        public var controllerIDList: [String]

        /// 会议室位置信息
        public var location: RoomLocation

        /// 会议号
        public var meetingNumber: String

        /// 会议室头像地址
        public var avatarKey: String

        /// 会议室租户id
        public var tenantID: String

        /// 会议室作为参会人在全端各场景中会议室名的显示
        public var fullNameParticipant: String

        /// 表示会议室的物理信息，主要用于 Rooms 各端、预定、绑定、初始化等场景
        public var fullNameSite: String

        /// 需要采用主副标题异化显示，且会议室作为参会人时，作为主要信息显示
        public var primaryNameParticipant: String

        /// 需要采用主副标题异化显示，且场景为显示会议室物理信息时，作为主要信息显示
        public var primaryNameSite: String

        /// 需要采用主副标题异化显示时，作为辅助信息显示
        public var secondaryName: String

        /// optional string primary_name_participant_pinyin  = 20; // 会议室名全拼，用于客户端排序
        /// optional string full_name_participant_pinyin  = 21; // 会议室全名全拼，用于客户端排序
        /// optional string fm_room_id = 22; // FM开头的ROOM ID
        public var isUnbind: Bool
    }
}

extension CalendarInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "CalendarInfo",
            "eventStartTime: \(theEventStartTime)",
            "eventEndTime: \(theEventEndTime)",
            "wholeEventEndTime: \(wholeEventEndTime)",
            "rooms.count: \(rooms.count)",
            "total: \(total)",
            "canEnterOrCreateGroup: \(canEnterOrCreateGroup)",
            "isAllDay: \(isAllDay)",
            "calendarLocations.count: \(calendarLocations.count)",
            "groupId: \(groupID)",
            "viewRooms.count: \(viewRooms.count)"
        )
    }
}
