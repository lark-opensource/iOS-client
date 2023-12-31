//
//  AudioInputManager.swift
//  ByteView
//
//  Created by FakeGourmet on 2023/8/17.
//

import Foundation
import ByteViewMeeting
import LarkMedia

/// 麦克风硬件静音管理
final class AudioInputManager: MeetingSessionListener {

    private lazy var logger = Logger.audio.withContext(session.sessionId).withTag("[AudioInput(\(session.sessionId))]")

    private let session: MeetingSession
    private let listeners = Listeners<LarkMicrophoneObserver>()

    init(session: MeetingSession) {
        self.session = session
        session.addListener(self)
        logger.info("init AudioInputManager")
    }

    deinit {
        logger.info("deinit AudioInputManager")
    }

    func willReleaseComponent(session: ByteViewMeeting.MeetingSession, event: ByteViewMeeting.MeetingEvent, toState: ByteViewMeeting.MeetingState) {
        listeners.removeAllListeners()
    }

    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        registerObserver(session: session)
    }

    func didLeavePending(session: MeetingSession) {
        registerObserver(session: session)
    }

    func addListener(_ listener: LarkMicrophoneObserver) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: LarkMicrophoneObserver) {
        listeners.removeListener(listener)
    }

    private func registerObserver(session: MeetingSession) {
        if !session.isPending, // 忙线响铃状态下不能监听麦克风静音通知，否则会解绑会议的监听
           let scene = session.state.mediaMutexScene,
           let resource = LarkMediaManager.shared.getMediaResource(for: scene) {
            // AudioInputManager 暂不监听静音变化事件
        } else {
            logger.warn("registerObserver failed")
        }
    }

    func setInputMuted(_ muted: Bool) {
        logger.info("will setInputMuted:\(muted)")
        guard let scene = session.state.mediaMutexScene else {
            logger.error("setInputMuted:\(muted) failed, error: scene not found")
            return
        }
        LarkMediaManager.shared.getMediaResource(for: scene)?.microphone.requestMute(muted) { [weak self] result in
            if let error = result.error {
                self?.logger.error("setInputMuted:\(muted) failed, error: \(error)")
            } else {
                self?.logger.info("did setInputMuted:\(muted)")
            }
        }
    }

    @RwAtomic
    private var isReleased = false
    func release() {
        if isReleased { return }
        isReleased = true
        logger.info("release AudioInputManager")
    }
}

extension AudioInputManager: LarkMicrophoneObserver {
    func applicationMicrophoneMuteStateDidChange(isMuted: Bool, isTriggeredInApp: Bool?) {
        listeners.forEach {
            $0.applicationMicrophoneMuteStateDidChange(isMuted: isMuted, isTriggeredInApp: isTriggeredInApp)
        }
    }
}
