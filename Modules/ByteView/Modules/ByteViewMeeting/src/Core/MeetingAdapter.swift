//
//  MeetingAdapter.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/5/31.
//

import Foundation

/// 不同业务方的会议适配
public protocol MeetingAdapter {
    /// 处理会议框架初始化
    static func handleMeetingEnvInitialization()
    /// 处理状态机事件
    static func handleEvent(_ event: MeetingEvent, session: MeetingSession) throws -> MeetingState
}

public extension MeetingSession {
    static func setAdapter(_ adapter: MeetingAdapter.Type, for sessionType: MeetingSessionType) {
        sessionType.helper.adapter = adapter
    }
}
