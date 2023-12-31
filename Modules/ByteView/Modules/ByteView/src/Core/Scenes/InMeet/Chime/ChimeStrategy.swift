//
//  ChimeStrategy.swift
//  ByteView
//
//  Created by fakegourmet on 2023/4/28.
//

import Foundation
import ByteViewSetting

protocol ChimeStrategy {
    /// 自己入离会提示音
    var shouldPlaySelfChime: Bool { get }
    /// 他人入离会提示音
    var shouldPlayOtherChime: Bool { get }
    /// 更新策略
    func update()
}

final class ChimeStrategyFactory {
    func create(meeting: InMeetMeeting) -> ChimeStrategy {
        if meeting.subType == .webinar {
            return WebinarChimeStrategy(meeting: meeting)
        } else {
            return InMeetChimeStrategy(meeting: meeting)
        }
    }
}

private class BaseChimeStrategy: ChimeStrategy {

    let meeting: InMeetMeeting
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        update()
    }

    func update() {}

    var shouldPlaySelfChime: Bool {
        shouldPlayChime
    }

    var shouldPlayOtherChime: Bool {
        shouldPlayChime
    }

    /// 通用配置
    private var shouldPlayChime: Bool {
        meeting.type == .meet &&
        meeting.myself.settings.playEnterExitChimes != false  // 服务端设置（会中超过 16 人返回 false） && 用户本地配置
    }
}

private class InMeetChimeStrategy: BaseChimeStrategy {
    override var shouldPlaySelfChime: Bool {
        super.shouldPlaySelfChime &&
        meeting.participant.global.nonRingingCount > 1
    }
}

private class WebinarChimeStrategy: BaseChimeStrategy {

    private var isFullParticipantsReceived: Bool = false

    override func update() {
        super.update()
        isFullParticipantsReceived = meeting.participant.isFullParticipantsReceived
    }

    override var shouldPlaySelfChime: Bool {
        false // webinar 自己入会离会都不播放提示音，包括自己的嘉宾观众身份转变
    }

    override var shouldPlayOtherChime: Bool {
        super.shouldPlayOtherChime &&
        isFullParticipantsReceived && // 确保收到首次参会人全量推送
        !meeting.isWebinarAttendee    // 只有嘉宾入离会需要开启提示音
    }
}
