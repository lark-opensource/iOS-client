//
//  InMeetKeyboardMuteHandler.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/11/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewSetting

class InMeetKeyboardMuteHandler: InMeetKeyboardProcessor {
    private let resolver: InMeetViewModelResolver
    private var isMutedBeforePress = true
    private let micToast = MicVolumeToast()
    // 长按一定时延后取消静音
    private let longPressDuration: TimeInterval
    private var longPressTimer: Timer?
    // 按住空格时，切换页面、toolbar 消失等场景下，不会收到松开空格的事件，导致音量 toast 僵死
    // 使用 timer 定时检查来保证及时清理
    // 不使用 weak 的原因：在计时器执行之前，如果出现僵死 toast，保证该 press 对象存活，以便判断当前状态
    private var currentPress: UIPress?
    private var safeGuardTimer: Timer?
    // 开始解除静音的时间，用于埋点中持续时长计算
    private var startUnmuteDate: Date?
    // 从按键发送unmute成功后到抬起键盘时为true
    private var isOn = false
    // 从按键发送unmute请求时到抬起键盘时为true
    private var unmuting = false
    private let meeting: InMeetMeeting

    private static let logger = Logger.audio

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.longPressDuration = TimeInterval(meeting.setting.keyboardMuteConfig.longPressDuration) / 1000.0
        meeting.volumeManager.addListener(self)
        Self.logger.info("[KeyboardMuteHandler] long press duration = \(longPressDuration)")
    }

    func shouldHandle(press: UIPress, stage: KeyPressStage) -> Bool {
        guard let key = press.key, let responder = press.responder else { return false }
        // 1. 功能开启
        let isEnabled = meeting.setting.isKeyboardMuteEnabled
        // 2. 按下空格键，并且当前的响应者不是输入视图
        let isPressSpaceBar = key.keyCode == .keyboardSpacebar && isNotInputView(responder: responder)
        // 3. 非小窗模式，会中
        let isInMeeting = !meeting.router.isFloating && !meeting.isEnd
        // 4. 有音频权限
        let isAudioAuthorized = Privacy.micAccess.value.isAuthorized
        // 5. 非 MagicShare 编辑态
        let isEditing = resolver.resolve(InMeetFollowManager.self)?.currentRuntime?.isEditing ?? false
        // 6. 有音频入口
        let enableMic = meeting.setting.showsMicrophone
        // 7. 是否闭麦
        let isMuted = meeting.audioModeManager.currentMicState == .off
        return isEnabled && isPressSpaceBar && isInMeeting && isAudioAuthorized && !isEditing && enableMic && isMuted
    }

    func keyPressBegan(_ press: UIPress) -> Bool {
        currentPress = press
        startLongPressTimer()
        return false
    }

    private func doUnmute() {
        Self.logger.info("[KeyboardMuteHandler] Long press keyboard begin. Temporarily unmuting myself...")
        isMutedBeforePress = meeting.microphone.isMuted
        guard isMutedBeforePress else { return }
        unmuting = true
        meeting.microphone.muteMyself(false, source: .keyboardLongPress, showToastOnSuccess: false) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                Util.runInMainThread {
                    guard self.unmuting else {
                        return
                    }
                    self.isOn = true
                    self.startUnmuteDate = Date()
                    self.showMicToast()
                    self.startTimer()
                }
            default:
                break
            }
        }
    }

    func keyPressEnded(_ press: UIPress) -> Bool {
        Self.logger.info("[KeyboardMuteHandler] Long press keyboard end.")
        // 计时、toast、状态设置等清理工作
        stopLongPressTimer()
        hideMicToast()
        stopTimer()
        currentPress = nil
        if isOn {
            unmuting = false
            if !meeting.microphone.isMuted {
                meeting.microphone.muteMyself(true, source: .keyboardLongPress, showToastOnSuccess: false, completion: nil)
            }
        } else {
            if unmuting {
                Self.logger.info("[KeyboardMuteHandler] User is mute before long press, and is unmute now. Resetting mute state...")
                unmuting = false
                meeting.microphone.muteMyself(true, source: .keyboardLongPress, showToastOnSuccess: false, completion: nil)
                // 埋点
                let duration: Int
                if let startUnmuteDate = startUnmuteDate {
                    duration = Int(ceil(Date().timeIntervalSince(startUnmuteDate)))
                } else {
                    duration = 0
                }
                MeetingTracksV2.trackKeyboarMute(isSharingContent: meeting.shareData.isSharingContent,
                                                 duration: duration)
            }
        }
        isOn = false
        return false
    }

    func destroy() {
        Self.logger.info("[KeyboardMuteHandler] destroy handler.")
        micToast.destroy()
        stopTimer()
    }

    // MARK: - Utils

    private func isNotInputView(responder: UIResponder) -> Bool {
        // 进入一个包含单一输入视图的页面时，键盘按压事件的 responder 是这个输入视图，即使不处于编辑态。
        // 因此这里需要把这种情况识别出来，并返回 false。
        // 测试发现只要 responder.isFirstResponder 为 false 就可以判断不在输入态，
        // 但是由于 isFirstResponder 是自定义可以重写并返回 true 的方法，为了保持影响范围可控，这里依然只对输入视图做这个判断
        if [UITextField.self, UITextView.self].allSatisfy({ !responder.isKind(of: $0) }) {
            return true
        } else {
            // UITextField 也可以用 isEditing 做判断
            return !responder.isFirstResponder
        }
    }

    private func showMicToast() {
        micToast.show()
    }

    private func hideMicToast() {
        micToast.hide()
    }

    private func startTimer() {
        // nolint-next-line: magic number
        let timer = Timer(timeInterval: 0.5, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if let press = self.currentPress, (press.phase == .ended || press.phase == .cancelled) && self.isOn {
                _ = self.keyPressEnded(press)
            } else if self.currentPress == nil {
                _ = self.keyPressEnded(UIPress())
            }
        })
        RunLoop.main.add(timer, forMode: .common)
        safeGuardTimer = timer
    }

    private func stopTimer() {
        safeGuardTimer?.invalidate()
        safeGuardTimer = nil
    }

    private func startLongPressTimer() {
        let timer = Timer(timeInterval: longPressDuration, repeats: false, block: { [weak self] _ in
            self?.doUnmute()
        })
        RunLoop.main.add(timer, forMode: .common)
        longPressTimer = timer
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
}

extension InMeetKeyboardMuteHandler: VolumeManagerDelegate {
    func volumeDidChange(to volume: Int, rtcUid: RtcUID) {
        if rtcUid == meeting.myself.bindRtcUid {
            micToast.micView.micOnView.updateVolume(volume)
        }
    }
}
