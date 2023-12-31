//
//  TabDetailRecordInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabDetailRecordInfo
public struct TabDetailRecordInfo: Equatable {
    public init(type: RecordType, url: [String], minutesInfo: [MinutesInfo], minutesInfoV2: [MinutesInfo], recordInfo: [RecordInfo], minutesBreakoutInfo: [MinutesInfo]) {
        self.type = type
        self.url = url
        self.minutesInfo = minutesInfo
        self.minutesInfoV2 = minutesInfoV2
        self.recordInfo = recordInfo
        self.minutesBreakoutInfo = minutesBreakoutInfo
    }

    public var type: RecordType

    public var url: [String]

    public var minutesInfo: [MinutesInfo]

    public var minutesInfoV2: [MinutesInfo]

    public var recordInfo: [RecordInfo]

    /// 分组录制妙记
    public var minutesBreakoutInfo: [MinutesInfo]

    public enum RecordType: Int, Hashable {
        case larkMinutes // = 0
        case record // = 1
    }

    public enum RecordStatus: Int, Hashable {
        case pending // = 0
        case complete // = 1
    }

    public struct MinutesInfo: Equatable {
        public init(url: String, topic: String, owner: ByteviewUser, hasViewPermission: Bool, duration: Int64, status: RecordStatus, coverUrl: String, breakoutRoomID: Int64, objectID: Int64) {
            self.url = url
            self.topic = topic
            self.owner = owner
            self.hasViewPermission = hasViewPermission
            self.duration = duration
            self.status = status
            self.coverUrl = coverUrl
            self.breakoutRoomID = breakoutRoomID
            self.objectID = objectID
        }

        /// 妙记URL
        public var url: String

        /// 妙记标题
        public var topic: String

        /// 妙记归属用户
        public var owner: ByteviewUser

        /// 是否有查看权限
        public var hasViewPermission: Bool

        /// 录制时长(单位：毫秒)
        public var duration: Int64

        /// 录制文件生成状态
        public var status: RecordStatus

        /// 妙记封面
        public var coverUrl: String

        ///  0: 表示没有分会场，1: 存在分会场并该会议是主会场
        public var breakoutRoomID: Int64

        public var objectID: Int64
    }

    public struct RecordInfo: Equatable {
        public init(url: String, topic: String, owner: ByteviewUser, duration: Int64, status: RecordStatus, breakoutRoomID: Int64) {
            self.url = url
            self.topic = topic
            self.owner = owner
            self.duration = duration
            self.status = status
            self.breakoutRoomID = breakoutRoomID
        }
        /// 录制URL
        public var url: String
        /// 录制标题
        public var topic: String
        /// 录制归属用户
        public var owner: ByteviewUser
        /// 录制时长(单位：毫秒)
        public var duration: Int64
        /// 录制文件生成状态
        public var status: RecordStatus
        ///  0: 表示没有分会场，1: 存在分会场并该会议是主会场
        public var breakoutRoomID: Int64

    }
}

extension TabDetailRecordInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "TabDetailRecordInfo",
            "type: \(type)",
            "url: \(url.count)",
            "minutesInfo: \(minutesInfo)",
            "recordInfo: \(recordInfo)"
        )
    }
}

extension TabDetailRecordInfo.MinutesInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "TabDetailRecordInfo.MinutesInfo",
            "url: \(url.hash)",
            "owner: \(owner)",
            "hasViewPermission: \(hasViewPermission)",
            "duration: \(duration)"
        )
    }
}

extension TabDetailRecordInfo.RecordInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "TabDetailRecordInfo.RecordInfo",
            "url: \(url.hash)",
            "owner: \(owner)",
            "duration: \(duration)"
        )
    }
}
