//
//  AudioOutputManager.swift
//  ByteView
//
//  Created by kiri on 2022/11/9.
//

import Foundation
import ByteViewMeeting
import AVFAudio
import LarkMedia
import AVKit
import ByteViewTracker
import ByteViewSetting
import ByteViewRtcBridge

protocol AudioOutputListener: AnyObject {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason)
    func audioOutputPickerWillAppear()
    func audioOutputPickerWillDisappear()
    func audioOutputPickerDidAppear()
    func audioOutputPickerDidDisappear()
}
extension AudioOutputListener {
    func audioOutputPickerWillAppear() {}
    func audioOutputPickerWillDisappear() {}
    func audioOutputPickerDidAppear() {}
    func audioOutputPickerDidDisappear() {}
}

/// 音频输出为纯本地行为，故在MeetingSession中放置一个全生命周期的audioOutputManager，用于管理音频输出
final class AudioOutputManager: MeetingSessionListener {
    private let session: MeetingSession
    private let logger = Logger.audio

    @RwAtomic
    private var isSpeakerOnForRinging: Bool?

    @RwAtomic
    var currentOutput: AudioOutput = LarkAudioSession.shared.currentOutput

    var isSpeakerOn: Bool { currentOutput == .speaker }
    @RwAtomic
    private(set) var fullOutputsName = ""
    @RwAtomic
    private(set) var lastRouteChangeReason: AVAudioSession.RouteChangeReason = .unknown

    /// 状态变化后，记录预期的output和scenario，以便过滤中间态输出频繁变化的问题。
    @RwAtomic
    var shouldIgnoreCategoryChange = false

    @RwAtomic
    private(set) var isMuted = false
    @RwAtomic
    private(set) var isNoConnect = false
    @RwAtomic
    private(set) var isPadMicSpeakerDisabled = false
    var isDisabled: Bool { isNoConnect || isPadMicSpeakerDisabled }

    private let picker = AudioOutputPicker()
    private let setting: MeetingSettingManager
    private let audioOutputSetting: AudioOutputSetting

    init(session: MeetingSession, setting: MeetingSettingManager) {
        self.session = session
        self.setting = setting
        self.audioOutputSetting = AudioOutputSetting(session: session, setting: setting)
        self.picker.delegate = self
        session.addListener(self)
        setting.addListener(self, for: .isMicSpeakerDisabled)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeRoute(_:)),
                                               name: LarkAudioSession.lkRouteChangeNotification, object: nil)

        self.log("init AudioOutputManager")
    }

    deinit {
        self.log("deinit AudioOutputManager")
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        release()
    }

    func didLeavePending(session: MeetingSession) {
        if session.state == .ringing && session.isAcceptRinging {
            return
        }
        self.prepareForEnterState(session.state)
    }

    func willEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        self.prepareForEnterState(state, from: from)
    }

    private func prepareForEnterState(_ state: MeetingState, from: MeetingState? = nil, function: String = #function) {
        log("prepareForEnterState: \(state), isCallKit: \(session.isCallKit), from: \(function), isPending: \(session.isPending), isEnd: \(session.isEnd)")

        self.setupOutput(for: state)

        guard !session.isPending, !session.isEnd else { return }

        guard state == .onTheCall else { return }
        if currentOutput == .speaker || currentOutput == .receiver {
            // recorver 存在延迟，因此此处需要根据配置刷新
            if from == .ringing, let isSpeakerOnForRinging {
                audioOutputSetting.saveCallOutputIfNeeded(isSpeakerOnForRinging ? .speaker : .receiver, from: from)
            } else {
                audioOutputSetting.saveCallOutputIfNeeded(currentOutput, from: from)
            }
        }
        setting.removeListener(self)
    }

    private var isSetupFinished = false
    private func setupOutput(for state: MeetingState) {
        log("will setupOutput state: \(state), isReleased: \(isReleased), isSetupFinished: \(isSetupFinished)")
        if isReleased || isSetupFinished || state == .end { return }
        if session.isPending, state != .ringing {
            // 忙线只设置ringing，其他状态等切成非忙线后再设置
            return
        }

        if LarkAudioSession.shared.isHeadsetConnected {
            // 如果当前有耳机选项，直接设置成当前路由，并取消强刷逻辑
            self.setCurrentRoute(LarkAudioSession.shared.currentRoute)
            self.isSetupFinished = true
            self.log("setupIfNeeded for \(state), output = \(currentOutput)")
            return
        }

        log("setupOutput state: \(state), meetType: \(session.meetType), videoChatInfoType: \(session.videoChatInfo?.type)")

        if state == .preparing,
           let entry = session.meetingEntry {
            switch entry {
            case .push, .voipPush:
                // 等到 ringing 状态设置
                return
            default:
                break
            }
        }

        if let output = audioOutputSetting.getPreferAudioOutputSetting(state) {
            self.setCurrentOutput(output: output)
        }
        if self.currentOutput == .unknown {
            // 所有其他情况，取当前值
            self.setCurrentRoute(LarkAudioSession.shared.currentRoute)
        }
        if isSpeakerOnForRinging == nil,
           state == .ringing,
           [.speaker, .receiver].contains(currentOutput) {
            self.isSpeakerOnForRinging = currentOutput == .speaker
        }
        self.isSetupFinished = true
        self.log("setupIfNeeded for \(state), output = \(self.currentOutput)")
    }

    @RwAtomic
    private var isReleased = false
    func release() {
        if isReleased { return }
        isReleased = true
        self.rtc = nil
        NotificationCenter.default.removeObserver(self, name: LarkAudioSession.lkRouteChangeNotification, object: nil)
        log("release AudioOutputManager")
    }

    func moveToLobby() {
        guard isReleased else { return }
        isReleased = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeRoute(_:)), name: LarkAudioSession.lkRouteChangeNotification, object: nil)
        setNoConnect(false)
        log("moveToLobby")
    }

    private let listeners = Listeners<AudioOutputListener>()
    private func fireListeners(_ reason: AudioOutputChangeReason) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.log("fire audioOutput listeners, reason = \(reason), isMuted = \(self.isMuted), isDisabled = \(self.isDisabled)")
            if self.isDisabled, reason != .disable { return }
            if self.isMuted, reason == .route { return }
            self.listeners.forEach { $0.didChangeAudioOutput(self, reason: reason) }
        }
    }

    func addListener(_ listener: AudioOutputListener) {
        self.listeners.addListener(listener)
    }

    func removeListener(_ listener: AudioOutputListener) {
        self.listeners.removeListener(listener)
    }

    // MARK: - Route

    /// - parameter offset: 向下偏移几像素
    func showPicker(scene: AudioOutputPickerScene, from: UIViewController, anchorView: UIView? = nil,
                    config: AudioOutputActionSheet.Config = .default) {
        guard !Util.isiOSAppOnMacSystem, !self.isDisabled else { return }
        self.picker.show(scene: scene, from: from, currentOutput: currentOutput, isMuted: isMuted, anchorView: anchorView, config: config)
    }

    func dismissPicker() {
        self.picker.dismissActionSheet()
    }

    func showToast(in view: UIView? = nil) {
        if isDisabled || isReleased { return }
        let content = isMuted ? I18n.View_MV_MutedNoTalk_Toast : self.fullOutputsName
        Toast.showOnVCScene(content, in: view)
    }

    private var lastOutputUid: String?
    @objc private func didChangeRoute(_ notification: Notification) {
        if isReleased { return }
        if session.state == .ringing, session.isAcceptRinging { return }
        guard let userInfo = notification.userInfo,
              let r0 = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: r0),
              let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else {
            log("didChangeRoute without userInfo: \(notification)")
            return
        }

        let startTime = CACurrentMediaTime()
        let currentRoute = LarkAudioSession.shared.currentRoute
        handleRouteChange(reason: reason, currentRoute: currentRoute, previousRoute: previousRoute)
        log("handleRouteChange finished, duration = \(Util.formatTime(CACurrentMediaTime() - startTime))")
    }

    @RwAtomic
    private var canFixBluetooth = true
    private var isCategoryChangeIgnored: Bool = false
    private func handleRouteChange(reason: AVAudioSession.RouteChangeReason, currentRoute: AVAudioSessionRouteDescription, previousRoute: AVAudioSessionRouteDescription) {
        let currentOutput = currentRoute.audioOutput
        log("didChangeRoute by \(reason), \(previousRoute) => \(currentRoute)")

        // track
        trackRouteChange(from: previousRoute.audioOutput, to: currentOutput)

        if reason == .categoryChange, previousRoute.outputs.isEmpty || currentRoute.outputs.isEmpty {
            // CallKit 响铃切换期间存在 currentRoute 取空的情况，此时需要略过，防止影响路由同步
            log("didChangeRoute ignore: output is empty")
            return
        }

        guard let currentOutputUid = currentRoute.outputs.first?.uid else { return }

        if reason == .categoryChange, shouldIgnoreCategoryChange {
            loge("categoryChange ignore")
            self.shouldIgnoreCategoryChange = false
            self.isCategoryChangeIgnored = true
            return
        }

        if self.isCategoryChangeIgnored {
            self.isCategoryChangeIgnored = false
        } else if currentOutputUid == self.lastOutputUid {
            // lastCategoryOrOutputMismatch的时候忽略去重逻辑，强刷currentOutput
            log("didChangeRoute ignore: uid not changed, \(reason)")
            return
        }

        if self.canFixBluetooth, currentOutput == .headphones || currentOutput == .bluetooth {
            log("run bluetoothFix for \(reason), \(currentOutput)")
            // 处理蓝牙无法切换听筒的问题
            enableSpeakerIfNeeded(false)
            if session.state == .onTheCall {
                // 会中只执行一次，enableSpeakerIfNeeded(false)可能会导致耳机切成听筒（待观察）
                self.canFixBluetooth = false
            }
        }

        self.lastRouteChangeReason = reason
        self.lastOutputUid = currentOutputUid
        self.setCurrentRoute(currentRoute)
    }

    /// 切换了音频输出
    private func trackRouteChange(from: AudioOutput, to: AudioOutput) {
        var params: TrackParams = [:]
        if from == to {
            params[.action_name] = "voice_source_unchanged"
            params[.extend_value] = ["from_voice_source": from.trackText, "after_voice_source": 0]
        } else {
            params[.action_name] = "voice_source_changed"
            params[.extend_value] = ["from_voice_source": from.trackText, "after_voice_source": to.trackText]
        }
        let name: TrackEventName
        switch (session.meetType, session.state) {
        case (.call, .onTheCall):
            name = .vc_call_page_onthecall
        case (.call, .calling), (.call, .dialing):
            name = .vc_call_page_calling
        case (.meet, .preparing):
            name = .vc_meeting_page_preview
        case (.meet, .onTheCall):
            name = .vc_meeting_page_onthecall
        default:
            return
        }
        VCTracker.post(name: name, params: params)
    }

    /// 只改设置，不会切换物理设备。如需切换物理设备，需使用showPicker
    private func setCurrentOutput(output: AudioOutput, function: String = #function) {
        log("setCurrentOutput \(output), from \(function)")
        if currentOutput == output, fullOutputsName == output.i18nText {
            return
        }
        currentOutput = output
        fullOutputsName = output.i18nText
        fireListeners(.route)
    }

    private func setCurrentRoute(_ route: AVAudioSessionRouteDescription, function: String = #function) {
        log("setCurrentRoute \(route), from \(function)")
        if currentOutput == route.audioOutput, fullOutputsName == route.fullOutputsName {
            return
        }
        currentOutput = route.audioOutput
        fullOutputsName = route.fullOutputsName
        fireListeners(.route)
    }

    func enableSpeakerIfNeeded(_ isSpeakerOn: Bool, force: Bool = false,
                               file: String = #fileID, function: String = #function, line: Int = #line) {
        LarkAudioSession.shared.enableSpeakerIfNeeded(isSpeakerOn, force: force,
                                                      file: file, function: function, line: line)
    }

    // MARK: - Mute
    @RwAtomic private var rtc: RtcAudio?
    func onJoinChannel() {
        log("onJoinChannel(audioOutput): isMuted = \(isMuted), isDisabled = \(isDisabled), currentOutput = \(currentOutput), isSpeakerOnForRinging: \(isSpeakerOnForRinging)")
        if let engine = self.session.service?.rtc {
            self.rtc = RtcAudio(engine: engine)
        }
        if case .shareToRoom = session.meetingEntry {
            // 投屏入会强制静音
            self.isMuted = true
        }
        if let isSpeakerOnForRinging {
            self.isRecoverSpeakerOn = isSpeakerOnForRinging
        }
        muteOrUnmuteRtc(force: true) { [weak self] isCompleted in
            if let self = self, isCompleted {
                self.fireListeners(.joinChannel)
            }
        }
    }

    func setMuted(_ isMuted: Bool) {
        if isReleased { return }
        let isChanged = self.isMuted != isMuted
        log("will setMuted \(isMuted), current is \(self.isMuted)")
        self.isMuted = isMuted
        if !isMuted, self.isRecoverSpeakerOn != nil {
            self.muteOrUnmuteRtc { [weak self] isCompleted in
                if let self = self, isCompleted {
                    // else等routeChange
                    self.fireListeners(.route)
                }
            }
        } else {
            self.muteOrUnmuteRtc()
            if isChanged {
                self.fireListeners(.mute)
            }
        }
    }

    @RwAtomic private var isRtcMuted = false
    @RwAtomic private var isRecoverSpeakerOn: Bool?

    /// mute/unmute rtc
    /// - parameter force: 是否强刷rtc
    /// - parameter completion: (isCompleted) -> Void
    private func muteOrUnmuteRtc(force: Bool = false, completion: ((Bool) -> Void)? = nil) {
        let isRtcMuted = self.isMuted || self.isNoConnect
        let recoverSpeakerIfNeeded: () -> Void = { [weak self] in
            guard let self = self else { return }
            if let isSpeakerOn = self.isRecoverSpeakerOn {
                self.isRecoverSpeakerOn = nil
                self.log("reset isSpeakerOn after unmute: \(isSpeakerOn)")
                self.enableSpeakerIfNeeded(isSpeakerOn)
                LarkAudioSession.shared.waitAudioSession("muteOrUnmuteRtc") { [weak self] in
                    completion?(self?.isSpeakerOn == isSpeakerOn)
                }
            } else {
                completion?(true)
            }
        }
        guard let rtc = rtc, force || isRtcMuted != self.isRtcMuted else {
            recoverSpeakerIfNeeded()
            return
        }
        self.isRtcMuted = isRtcMuted
        if isRtcMuted {
            rtc.muteOutput(true)
            /// 关闭设备 RTC 音频输出
            VCTracker.post(name: session.meetType.trackName, params: [.action_name: "no_audio"])
            completion?(true)
        } else {
            rtc.muteOutput(false, completion: recoverSpeakerIfNeeded)
        }
    }

    // MARK: Log
    private func log(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.logger.info("\(debugDescription): \(msg)", file: file, function: function, line: line)
    }

    private func loge(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.logger.error("\(debugDescription): \(msg)", file: file, function: function, line: line)
    }
}

// MARK: Description
extension AudioOutputManager: CustomDebugStringConvertible {
    var debugDescription: String {
        "AudioOutputManager(\(session.sessionId))[\(session.state)]\(session.isPending ? "[pending]" : "")"
    }
}

// MARK: NoConnect
extension AudioOutputManager {
    func setNoConnect(_ isNoConnect: Bool, shouldRecorverSpeakerOn: Bool = true) {
        if isReleased || self.isNoConnect == isNoConnect { return }
        log("setNoConnect \(isNoConnect) shouldRecorverSpeakerOn: \(shouldRecorverSpeakerOn)")
        self.isNoConnect = isNoConnect
        if isNoConnect, !isMuted, rtc != nil, shouldRecorverSpeakerOn {
            self.isRecoverSpeakerOn = self.isSpeakerOn
        }
        muteOrUnmuteRtc()
        fireListeners(.disable)
    }

}

// MARK: PadMicSpeakerDisabled
extension AudioOutputManager {
    func setPadMicSpeakerDisabled(_ isPadMicSpeakerDisabled: Bool) {
        guard !self.isReleased, self.isPadMicSpeakerDisabled != isPadMicSpeakerDisabled else { return }
        self.log("will setPadMicSpeakerDisabled \(isPadMicSpeakerDisabled)")
        self.isPadMicSpeakerDisabled = isPadMicSpeakerDisabled
        if isPadMicSpeakerDisabled {
            self.isMuted = true
            self.muteOrUnmuteRtc()
        }
        self.fireListeners(.disable)
    }

    func setPadMicSpeakerDisabledIfNeeded() {
        let isPadMicSpeakerDisabled = Display.pad && setting.isMicSpeakerDisabled && session.audioMode == .internet
        setPadMicSpeakerDisabled(isPadMicSpeakerDisabled)
    }
}

// MARK: AudioOutputPickerDelegate
extension AudioOutputManager: AudioOutputPickerDelegate {
    func audioOutputPicker(_ picker: AudioOutputPicker, didSelect item: AudioOutputPickerItem) {
        switch item {
        case .speaker, .receiver:
            let isSpeakerOn = item == .speaker
            if isMuted {
                self.isRecoverSpeakerOn = isSpeakerOn
                self.setMuted(false)
            } else {
                // 后同步实际路由
                // 响铃场景实际没有听筒功能，因此不需要执行
                if session.state != .ringing {
                    self.enableSpeakerIfNeeded(isSpeakerOn)
                } else {
                    self.isSpeakerOnForRinging = isSpeakerOn
                    self.setCurrentOutput(output: isSpeakerOn ? .speaker : .receiver)
                }
            }
        case .mute:
            self.setMuted(true)
        case .unmute, .picker:
            self.setMuted(false)
        default:
            break
        }
    }

    func audioOutputPickerWillAppear(_ picker: AudioOutputPicker) {
        listeners.forEach { $0.audioOutputPickerWillAppear() }
    }

    func audioOutputPickerWillDisappear(_ picker: AudioOutputPicker) {
        listeners.forEach { $0.audioOutputPickerWillDisappear() }
    }

    func audioOutputPickerDidAppear(_ picker: AudioOutputPicker) {
        listeners.forEach { $0.audioOutputPickerDidAppear() }
    }

    func audioOutputPickerDidDisappear(_ picker: AudioOutputPicker) {
        listeners.forEach { $0.audioOutputPickerDidDisappear() }
    }
}


// MARK: InMeetAudioModeListener
extension AudioOutputManager: InMeetAudioModeListener {
    func didChangeMicState(_ state: MicViewState) {
        setPadMicSpeakerDisabled(state == .forbidden)
    }
}

// MARK: MeetingSettingListener
extension AudioOutputManager: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isMicSpeakerDisabled {
            setPadMicSpeakerDisabled(isOn && session.audioMode == .internet)
        }
    }
}

// MARK: Others
private extension AVAudioSessionRouteDescription {
    var fullOutputsName: String {
        self.outputs.map {
            switch $0.portType {
            case .builtInReceiver:
                return I18n.View_G_Receiver
            case .builtInSpeaker:
                return I18n.View_VM_Speaker
            case .headphones:
                return I18n.View_G_Headphones
            default:
                return $0.portName
            }
        }.joined(separator: "\n")
    }
}

enum AudioOutputChangeReason {
    case route
    case mute
    case disable
    case joinChannel
}
