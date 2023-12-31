//
//  MeetingSourceAppLinkInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_MeetingSourceAppLinkInfo
public struct MeetingSourceAppLinkInfo: Equatable {
    public init(type: TypeEnum, paramCalendar: ParamFromCalendar?, paramGroup: ParamFromGroup?) {
        self.type = type
        self.paramCalendar = paramCalendar
        self.paramGroup = paramGroup
    }

    public var type: TypeEnum

    /// 日历详情applink所需参数
    public var paramCalendar: ParamFromCalendar?

    /// 发起群会话applink所需参数
    public var paramGroup: ParamFromGroup?

    public enum TypeEnum: Int, Hashable {
        /// 表示此详情页不需要展示发起源applink
        case unknown // = 0

        /// 表示参数为日程详情页applink参数
        case calendar // = 1

        /// 表示参数为发起群会话applink参数
        case group // = 2
    }

    public struct ParamFromCalendar: Equatable {
        public init(calendarID: String, key: String, originalTime: Int32, startTime: Int32) {
            self.calendarID = calendarID
            self.key = key
            self.originalTime = originalTime
            self.startTime = startTime
        }

        ///对应日程详情applink中calendarId参数
        public var calendarID: String

        ///对应日程详情applink中key参数
        public var key: String

        ///对应日程详情applink中originalTime参数
        public var originalTime: Int32

        ///对应日程详情applink中startTime参数
        public var startTime: Int32
    }

    public struct ParamFromGroup: Equatable {
        public init(chatID: String) {
            self.chatID = chatID
        }

        /// 群组id
        public var chatID: String
    }
}
