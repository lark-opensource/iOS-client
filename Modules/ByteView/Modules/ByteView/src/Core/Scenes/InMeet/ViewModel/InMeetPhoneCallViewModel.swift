//
//  InMeetPhoneCallStateManager.swift
//  ByteView
//
//  Created by admin on 2022/8/18.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker
import ByteViewSetting

/// callkit 通话保持时需要监听系统电话的状态，电话被动挂断后，主动解除 callkit 保持状态
final class InMeetPhoneCallViewModel {
    enum PhoneCallMicToastType {
        case unknown
        case backOn
        case off
    }

    private let meeting: InMeetMeeting

    /// 退出系统电话状态需要重新打开麦克风
    @RwAtomic
    private var shoudOpenMicIfDisconnected: Bool = false

    static let phoneCallLogger = Logger.getLogger("phoneCallState")

    /// 曾经进入过系统电话状态
    @RwAtomic private var entryCount = 0
    private var isSystemPhoneCalling: Bool { meeting.setting.isSystemPhoneCalling }

    init(meeting: InMeetMeeting) {
        Self.phoneCallLogger.info("InMeetPhoneCallViewModel init \(meeting.meetingId)")
        self.meeting = meeting
        if self.isSystemPhoneCalling {
            self.entryCount = 1
        }
        startObservePhoneCallStateIfNeeded()

        /// 入会时判断当前是否有系统电话（callkit模式下系统电话保持通话，非callkit下需要将系统电话状态告知服务器）
        if !meeting.isCallKit || (meeting.isCallKit && meeting.isHeldByCallkit) {
            PhoneCall.shared.hasActiveSystemCalls { [weak self] hasActive in
                if hasActive {
                    self?.updateSysCallingStatusToBusy()
                } else {
                    self?.updateSysCallingStatusToIdle()
                }
            }
        } else {
            updateSysCallingStatusToIdle()
        }
    }

    private func updateCalling(_ isCalling: Bool) {
        meeting.setting.updateSettings {
            $0.isSystemPhoneCalling = isCalling
        }
        if isCalling {
            entryCount += 1
        }
    }

    private func updateSysCallingStatusToBusy() {
        SystemCallingManager.changeMobileCallingStatus(meeting: meeting, status: .busy)
        self.updateCalling(true)
        if !meeting.microphone.isMuted {
            self.shoudOpenMicIfDisconnected = true
            meeting.microphone.muteMyself(true, source: .phone_call_status) { [weak self] result in
                if case .success = result {
                    if self?.updateMicState(.disabled()) ?? false {
                        Toast.showOnVCScene(I18n.View_MV_ReceiveCallMicOff)
                    }
                }
            }
        } else {
            self.shoudOpenMicIfDisconnected = false
            SystemCallingManager.shared.setMicState(state: .disabled(), sessionID: meeting.sessionId)
        }
    }

    private func updateSysCallingStatusToIdle() {
        SystemCallingManager.changeMobileCallingStatus(meeting: meeting, status: .idle)
    }
}

extension InMeetPhoneCallViewModel: PhoneCallObserver {
    func startObservePhoneCallStateIfNeeded() {
        Self.phoneCallLogger.info("\(meeting.meetingId) observe phone call state")
        PhoneCall.shared.addObserver(self, needCached: false)
    }

    func didChangePhoneCallState(from: PhoneCall.State, to: PhoneCall.State, callUUID: UUID?) {
        if to == .disconnected, meeting.isCallKit, meeting.isHeldByCallkit {
            Self.phoneCallLogger.info("\(meeting.meetingId) phone call state changed: \(from) -> \(to), need release callkit hold")
            meeting.callCoordinator.releaseHold()
        }

        guard meeting.isActive else {
            Self.phoneCallLogger.info("\(meeting.meetingId) is not active")
            return
        }
        guard let uuid = callUUID else {
            Self.phoneCallLogger.info("\(meeting.meetingId) mismatch call uuid")
            return
        }
        // 对于运营商的系统电话和非飞书的callkit电话才进入系统优化方法
        let meetingID = meeting.meetingId
        meeting.callCoordinator.isByteViewCall(uuid: uuid) { [weak self] isByteViewCall in
            guard let self = self, !isByteViewCall else {
                Self.phoneCallLogger.info("\(meetingID) invalid self or it`s byteview call")
                return
            }
            // 系统电话挂断，音频打断通知也不会触发，需要手动通知 RTC
            switch to {
            case .unknown:
                break
            case .incoming, .dialing:
                if !self.meeting.isCallKit {
                    self.meeting.microphone.stopAudioCapture()
                }
            case .connected:
                if self.meeting.isCallKit {
                    self.meeting.microphone.stopAudioCapture()
                }
            case .disconnected, .holding:
                if self.meeting.audioMode == .internet {
                    self.meeting.microphone.startAudioCapture(scene: .disconnectPhonecall)
                }
            }
            if self.meeting.isCallKit {
                self.handleCallkitCallingStatus(from: from, to: to)
            } else {
                self.handleNotCallkitCallingStatus(from: from, to: to)
            }
        }
    }

    private func handleCallkitCallingStatus(from: PhoneCall.State, to: PhoneCall.State) {
        let isCallMe = meeting.audioModeManager.isPstnCalling || meeting.audioModeManager.isInCallMe
        Self.phoneCallLogger.info("\(#function),fromState is \(from), toState is \(to), isCallMe is \(isCallMe)")
        // callkit场景下，来电并不是callme情况下发送请求
        if to == .incoming, !isCallMe {
            self.shoudOpenMicIfDisconnected = !meeting.microphone.isMuted
            self.updateCalling(false)
        }
        if to == .connected, !isCallMe {
            // 在callkit场景下，非callme和接听电话时向服务器发送busy
            SystemCallingManager.changeMobileCallingStatus(meeting: meeting, status: meeting.isHeldByCallkit ? .busy : .idle)
            if meeting.isHeldByCallkit {
                self.shoudOpenMicIfDisconnected = !meeting.microphone.isMuted
            }
            // 在其他地方已经mute了
            // 麦克风置灰
            self.updateCalling(meeting.isHeldByCallkit)
            let iconState: MicIconState = meeting.isHeldByCallkit ? .disabled() : (shoudOpenMicIfDisconnected ? .on() : .off())
            if iconState == .disabled() {
                muteMySelfMic(isMuted: true, forceDisabled: true, toastType: .off)
            } else if iconState == .off() {
                muteMySelfMic(isMuted: true, toastType: .backOn)
            } else if iconState == .on() {
                muteMySelfMic(isMuted: false, toastType: .backOn)
            }
            _ = updateMicState(iconState)
        }
        // 系统电话被通话保持
        let isHolding = to == .holding && !isCallMe && self.entryCount > 0
        // callkit场景接起电话后挂断
        let isHangup = to == .disconnected && self.isSystemPhoneCalling
        if isHolding || isHangup {
            SystemCallingManager.changeMobileCallingStatus(meeting: meeting, status: .idle)
            self.updateCalling(false)
            if !meeting.isWebinarAttendee {
                if self.shoudOpenMicIfDisconnected {
                    self.shoudOpenMicIfDisconnected = false
                    muteMySelfMic(isMuted: false, toastType: .backOn)
                } else {
                    muteMySelfMic(isMuted: true, toastType: .backOn)
                    _ = updateMicState(.off())
                }
            }
        } else if to == .disconnected && !self.isSystemPhoneCalling {
            // callkit场景拒接电话
            self.shoudOpenMicIfDisconnected = false
        }
        VCTracker.post(
            name: .vc_phone_call_interrupt,
            params: [
                "from_souce": "onthecall_page",
                "is_callkit": "true",
                "is_callme": isCallMe ? "true" : "false"
            ]
        )
    }

    private func handleNotCallkitCallingStatus(from: PhoneCall.State, to: PhoneCall.State) {
        let isCallMe = meeting.audioModeManager.isPstnCalling || meeting.audioModeManager.isInCallMe
        Self.phoneCallLogger.info("\(#function),fromState is \(from), toState is \(to), isCallMe is \(isCallMe)")
        // 在非callkit场景下，非callme和来电时向服务器发送busy
        let isWebinarAttendee = meeting.isWebinarAttendee
        if (to == .incoming || to == .dialing) && !isCallMe {
            SystemCallingManager.changeMobileCallingStatus(meeting: meeting, status: .busy)
            self.updateCalling(true)
            self.shoudOpenMicIfDisconnected = !meeting.microphone.isMuted
            muteMySelfMic(isMuted: true, forceDisabled: true, toastType: .off)
            _ = updateMicState(.disabled())
        } else if to == .disconnected {
            SystemCallingManager.changeMobileCallingStatus(meeting: meeting, status: .idle)
            self.updateCalling(false)
            let isMicSpeakerDisabled = meeting.audioModeManager.isPadMicSpeakerDisabled
            if !isMicSpeakerDisabled && !isWebinarAttendee {
                if self.shoudOpenMicIfDisconnected {
                    self.shoudOpenMicIfDisconnected = false
                    muteMySelfMic(isMuted: false, toastType: .backOn)
                } else {
                    muteMySelfMic(isMuted: true, toastType: .backOn)
                    _ = updateMicState(.off())
                }
            }
        }
        VCTracker.post(
            name: .vc_phone_call_interrupt,
            params: [
                "from_souce": "onthecall_page",
                "is_callkit": "false",
                "is_callme": isCallMe ? "true" : "false"
            ]
        )
    }

    private func muteMySelfMic(
        isMuted: Bool,
        forceDisabled: Bool = false,
        toastType: PhoneCallMicToastType = .unknown
    ) {
        // 当麦克风有权限时，才对麦克风进行开关操作。这样为了避免接听和挂断系统电话设置麦克风的时候弹出无权限toast
        guard Privacy.audioAuthorized else { return }
        let sessionId = meeting.sessionId
        let isMicSpeakerDisabled = meeting.audioModeManager.isPadMicSpeakerDisabled

        meeting.microphone.muteMyself(
            isMuted,
            source: .phone_call_status,
            showToastOnSuccess: false
        ) { [weak self] result in
            switch result {
            case .success:
                // 结束系统电话后打开麦克风
                if !isMuted && self?.meeting.audioMode == .internet && !isMicSpeakerDisabled {
                    SystemCallingManager.shared.setMicState(state: .on(), sessionID: sessionId)
                    if self?.updateMicState(.on()) ?? false, toastType == .backOn {
                        Toast.showOnVCScene(I18n.View_MV_MicBackOn)
                    }
                }
                // 非callkit场景若接听系统电话前麦克风是打开状态，在接系统电话时，
                // 需要手动mute并将图标置为.off状态，为保证最后为.disabled需要在置为.off后置为.disabled
                if isMuted && self?.meeting.audioMode == .internet && !isMicSpeakerDisabled {
                    let iconState: MicIconState = forceDisabled ? .disabled() : .off()
                    if self?.updateMicState(iconState) ?? false {
                        switch toastType {
                        case .backOn:
                            Toast.showOnVCScene(I18n.View_MV_MicBackOn)
                        case .off:
                            Toast.showOnVCScene(I18n.View_MV_ReceiveCallMicOff)
                        default:
                            break
                        }
                    }
                }
            default:
                break
            }
        }
    }
}

extension InMeetPhoneCallViewModel {
    func updateMicState(_ iconState: MicIconState) -> Bool {
        let isMicSpeakerDisabled = meeting.audioModeManager.isPadMicSpeakerDisabled
        if meeting.audioMode == .internet && !isMicSpeakerDisabled {
            SystemCallingManager.shared.setMicState(state: iconState, sessionID: meeting.sessionId)
            return true
        }
        return false
    }
}
