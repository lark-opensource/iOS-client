//
//  AudioOutputSetting.swift
//  ByteView
//
//  Created by FakeGourmet on 2023/9/22.
//

import Foundation
import LarkMedia
import ByteViewMeeting
import ByteViewSetting
import ByteViewNetwork

class AudioOutputSetting {

    private let logger = Logger.audio
    private let session: MeetingSession
    private let setting: MeetingSettingManager

    init(session: MeetingSession, setting: MeetingSettingManager) {
        self.session = session
        self.setting = setting

        self.log("init, usersetting: \(setting.userjoinAudioOutputSetting), meet: \(setting.lastMeetAudioOutput()), voiceCall: \(setting.lastCallAudioOutput(isVoiceCall: true)), videoCall: \(setting.lastCallAudioOutput(isVoiceCall: false))")
    }

    deinit {
        log("deinit")
    }

    private func log(_ msg: String) {
        logger.info("[AudioOutputSetting(\(session.sessionId))] \(msg)")
    }

    func getPreferAudioOutputSetting(_ state: MeetingState) -> AudioOutput? {
        switch state {
        case .preparing:
            guard let entry = session.meetingEntry else { return nil }
            switch entry {
            case .preview, .noPreview:
                // 预览页默认扬声器，https://bytedance.feishu.cn/docx/doxcnvdNen9VtZioJpjgb5ZAkle
                let route = getPreferAudioOutputSetting(meetType: .meet)
                log("preview route: \(route)")
                return route
            case .call(let startParams):
                let route = getPreferAudioOutputSetting(meetType: .call, isVoiceCall: startParams.isVoiceCall)
                log("call route: \(route)")
                return route
            case .enterpriseCall:
                return .receiver
            case .push, .voipPush:
                // 后面进入ringing/onTheCall时设置
                return nil
            case .rejoin(let rejoinParams):  // rejoin 可能是meet，也可能是call
                let rejoinMeetType = rejoinParams.info.type
                var route: AudioOutput = .speaker
                if rejoinMeetType == .meet {
                    route = getPreferAudioOutputSetting(meetType: .meet)
                } else if rejoinMeetType == .call { // 1v1不会出现rejoin，先也把逻辑写下防止以后加上rejoin遗漏
                    route = getPreferAudioOutputSetting(meetType: .call, isNormalCall: rejoinParams.info.settings.subType != .enterprisePhoneCall, isVoiceCall: rejoinParams.info.isVoiceCall)
                }
                log("rejoin route: \(route)")
                return route
            case .shareToRoom:  // shareToRoom是强制静音 也不用处理
                break
            }
        case .ringing:
            guard let info = session.videoChatInfo else { return nil }
            // ringing的meetType可能是call也可能是meet
            let route = getPreferAudioOutputSetting(meetType: session.meetType, isNormalCall: session.callInType == .vc, isVoiceCall: info.isVoiceCall)
            log("ringing route: \(route), session.isCallKit: \(session.isCallKit), isCallKitFromVoIP: \(session.isCallKitFromVoIP)")
            return route
        default:
            return nil
        }
        return nil
    }

    private func getPreferAudioOutputSetting(meetType: MeetingType, isNormalCall: Bool? = nil, isVoiceCall: Bool? = nil) -> AudioOutput {
        /* 增加会议设置可选择默认接听设备  https://bytedance.feishu.cn/docx/KzCtdV6N3ovkrsxcK1ac7ppknQc  */
        if Display.phone {
            /* 1.其他通话类型设成听筒，https://bytedance.feishu.cn/docx/doxcn4CkYVjMlIdsfoYMZMCejTf
               2.无论用户通用设置成什么，非正常vc call一律设置为receiver，这里主要是办公电话场景
             */
            if meetType == .call, let isNormalCall = isNormalCall, !isNormalCall {
                log("getPrefer unNormalCall receiver")
                return .receiver
            }

            switch setting.userjoinAudioOutputSetting {
            case .last:
                if meetType == .meet { // 会议
                    return getLastMeetOutput()
                } else if meetType == .call, let isVoiceCall = isVoiceCall { // 1v1
                    return getLastCallOutput(isVoiceCall: isVoiceCall)
                } else { // unknow
                    return .speaker
                }
            case .receiver:
                log("getPrefer userset receiver")
                return .receiver
            case .speaker:
                log("getPrefer userset speaker")
                return .speaker
            }
        } else {
            log("getPrefer uniphone speaker")
            return .speaker
        }
    }

    // 获取meet类型的记忆output
    private func getLastMeetOutput() -> AudioOutput {
        let localSetting: AudioOutput = setting.lastMeetAudioOutput() == 1 ? .receiver : .speaker
        Logger.audio.info("get histroy meet audio: \(localSetting)")
        return localSetting
    }

    // 获取call类型的记忆output
    private func getLastCallOutput(isVoiceCall: Bool) -> AudioOutput {
        // 1v1通话取本地设置，https://bytedance.feishu.cn/docx/VI8kdNWUEoBai0xSxwsc6cQxneh
        let localSetting: AudioOutput = setting.lastCallAudioOutput(isVoiceCall: isVoiceCall) == 1 ? .receiver : .speaker
        log("get histroy call audio: \(localSetting), isVoiceCall: \(isVoiceCall)")
        return localSetting
    }

    func saveCallOutputIfNeeded(_ output: AudioOutput, from: MeetingState?) {
        switch from {
        case .preparing:
            saveMeetOutput(output)
        case .calling:
            if let params = session.startCallParams {
                saveCallOutput(output, isVoiceCall: params.isVoiceCall)
            }
        case .ringing:
            if session.meetType == .call, let info = session.videoChatInfo {
                let callInType = info.callInType(accountId: session.userId)
                if callInType == .vc {
                    saveCallOutput(output, isVoiceCall: info.isVoiceCall)
                }
            }
        default:
            break
        }
    }

    // 保存meet类型的记忆output
    private func saveMeetOutput(_ output: AudioOutput) {
        Logger.audio.info("save meet audio: \(output)")
        setting.saveLastMeetAudioOutput(output == .receiver ? 1 : 0)
    }

    // 保存call类型的记忆output
    private func saveCallOutput(_ output: AudioOutput, isVoiceCall: Bool) {
        Logger.audio.info("save call audio: \(output)")
        setting.saveLastCallAudioOutput(output == .receiver ? 1 : 0, isVoiceCall: isVoiceCall)
    }
}
