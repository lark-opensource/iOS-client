//
//  RtcAudioPlayer.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/11/15.
//

import Foundation
import ByteViewMeeting
import ByteViewRtcBridge

enum RtcAlertSound {
    /// 倒计时结束音频
    case countDownEnd
    /// 倒计时还剩X分钟结束音频
    case countDownRemind
    /// 开启和结束录制音频
    case recordVoice(filePath: String)
    /// 会前响铃
    case dialing(ringtone: String?)
    case enterMeeting
    case leaveMeeting
    /// 开启和结束转录音频
    case transcribeVoice(filePath: String)
}

extension RtcAlertSound {

    /// 音频ID
    // disable-lint: magic number
    var soundId: Int {
        switch self {
        case .countDownEnd:
            return 1000
        case .countDownRemind:
            return 1001
        case .recordVoice:
            return 1002
        case .dialing:
            return 1003
        case .enterMeeting:
            return 1004
        case .leaveMeeting:
            return 1005
        case .transcribeVoice:
            return 1006
        }
    }
    // enable-lint: magic number

    /// 本地文件路径
    var filePath: String {
        switch self {
        case .countDownEnd:
            guard let path = Bundle.countDownEndFilePath else {
                Logger.countDown.debug("countDownEnd audio file path nil")
                return ""
            }
            return path
        case .countDownRemind:
            guard let path = Bundle.countDownRemindFilePath else {
                Logger.countDown.debug("countDownRemind audio file path nil")
                return ""
            }
            return path
        case .recordVoice(let path):
            return path
        case .dialing(let ringtone):
            return RingPlayer.shared.recentRingtonURL(ringtone: ringtone).relativePath
        case .enterMeeting:
            guard let path = LocalAlertSound.enterMeeting.filePath else {
                Logger.audio.debug("enterMeeting audio file path nil")
                return ""
            }
            return path
        case .leaveMeeting:
            guard let path = LocalAlertSound.leaveMeeting.filePath else {
                Logger.audio.debug("leaveMeeting audio file path nil")
                return ""
            }
            return path
        case .transcribeVoice(let path):
            return path
        }
    }
}

class RtcAudioPlayer: MeetingAudioPlayer, AudioPlayer {
    private let rtc: RtcAudio
    private static let logger = Logger.audio

    init?(session: MeetingSession) {
        if let audioOutput = session.audioDevice?.output, let rtc = session.service?.rtc {
            self.rtc = RtcAudio(engine: rtc)
            super.init(audioOutput: audioOutput)
        } else {
            return nil
        }
    }

    required init(meeting: InMeetMeeting) {
        self.rtc = RtcAudio(engine: meeting.rtc.engine)
        super.init(meeting: meeting)
    }

    func play(_ sound: RtcAlertSound, playCount: Int, completion: ((Bool) -> Void)? = nil) {
        guard isEnabled else {
            Self.logger.info("Current audio output mode is muted or disabled, skip playing rtc audio \(sound)")
            return
        }
        rtc.startAudioMixing(soundId: Int32(sound.soundId),
                             filePath: sound.filePath,
                             loopback: true,
                             playCount: playCount,
                             completion: completion)
    }

    func play(_ sound: RtcAlertSound, completion: ((Bool) -> Void)?) {
        play(sound, playCount: 1, completion: completion)
    }

    func stop(_ sound: RtcAlertSound, completion: (() -> Void)? = nil) {
        rtc.stopAudioMixing(soundId: Int32(sound.soundId), completion: completion)
    }
}
