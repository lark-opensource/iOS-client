//
//  AudioDeviceManager.swift
//  ByteView
//
//  Created by FakeGourmet on 2023/7/24.
//

import Foundation
import ByteViewMeeting
import LarkMedia

extension MeetingSession {
    var audioDevice: AudioDeviceManager? { component(for: AudioDeviceManager.self) }
}

final class AudioDeviceManager: MeetingComponent {

    private let logger = Logger.audio

    let input: AudioInputManager
    let output: AudioOutputManager

    private let session: MeetingSession

    init?(session: ByteViewMeeting.MeetingSession, event: ByteViewMeeting.MeetingEvent, fromState: ByteViewMeeting.MeetingState) {
        guard let setting = session.service?.setting else {
            return nil
        }
        self.session = session
        self.input = AudioInputManager(session: session)
        self.output = AudioOutputManager(session: session, setting: setting)
    }

    func willReleaseComponent(session: ByteViewMeeting.MeetingSession, event: ByteViewMeeting.MeetingEvent, toState: ByteViewMeeting.MeetingState) {
        input.willReleaseComponent(session: session, event: event, toState: toState)
        output.willReleaseComponent(session: session, event: event, toState: toState)
    }

    func lockStateForCallKitRinging() {
        let output = LarkAudioSession.shared.currentOutput
        let isSpeakerOn = output == .unknown || output == .speaker
        var options: ScenarioEntryOptions = [.manualActive]
        if isSpeakerOn {
            options.insert(.enableSpeakerIfNeeded)
        }
        tryLock(scene: .vcRing) {
            $0?.audioSession.enter(.callKitInternalScenario, options: options)
        }
    }

    func unlockStateForCallKitRinging() {
        unlock(scene: .vcRing, options: .leaveScenarios)
    }

    func lockState() {
        guard let scene = session.state.mediaMutexScene else {
            return
        }
        let resource = tryLock(scene: scene, options: [.mixWithOthers, .onlyAudio])

        if session.state == .ringing, session.isCallKit {
            // callkit ringing 不进行 AudioSession 配置
            return
        }

        var options: ScenarioEntryOptions = []
        if output.currentOutput == .speaker {
            options.insert(.enableSpeakerIfNeeded)
        }
        if session.state == .onTheCall, session.isCallKit {
            options.insert(.manualActive)
        }

        output.shouldIgnoreCategoryChange = true
        resource?.audioSession.enter(.byteviewScenario(session: session), options: options) { [weak self] in
            self?.output.shouldIgnoreCategoryChange = false
        }
    }

    func unlockState() {
        guard let scene = session.state.mediaMutexScene else {
            return
        }
        if scene == .vcMeeting,
           scene.isActive,
           let resource = session.audioDevice?.unlock(scene: scene) {
            var options: ScenarioEntryOptions = []
            if MeetingManager.shared.sessions.contains(where: { $0.isPending }) {
                // 存在 pending 时, leave 不进行 category 切换
                options = .disableCategoryChange
            }
            resource.audioSession.leave(.byteviewScenario(session: session), options: options)
        } else {
            unlock(scene: scene, options: .leaveScenarios)
        }
    }

    @discardableResult
    private func tryLock(scene: MediaMutexScene, options: MediaMutexOptions = []) -> LarkMediaResource? {
        return LarkMediaManager.shared.tryLock(scene: scene, options: options, observer: self).value
    }

    private func tryLock(scene: MediaMutexScene, options: MediaMutexOptions = [], completion: @escaping (LarkMediaResource?) -> Void) {
        LarkMediaManager.shared.tryLock(scene: scene, options: options) { result in
            if case .success(let resource) = result {
                completion(resource)
            } else {
                completion(nil)
            }
        }
    }

    @discardableResult
    private func unlock(scene: MediaMutexScene, options: MediaMutexOptions = []) -> LarkMediaResource? {
        defer {
            LarkMediaManager.shared.unlock(scene: scene, options: options)
        }
        return getResource(scene: scene)
    }

    func addMicrophoneObserver(_ observer: LarkMicrophoneObserver) {
        getResource(scene: .vcMeeting)?.microphone.addObserver(observer)
    }

    private func getResource(scene: MediaMutexScene) -> LarkMediaResource? {
        LarkMediaManager.shared.getMediaResource(for: scene)
    }

    func release() {
        input.release()
        output.release()
    }
}

extension AudioDeviceManager: MediaResourceInterruptionObserver {
    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        Logger.audioSession.info("mediaResourceWasInterrupted by scene: \(scene) type: \(type) msg: \(msg)")
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        Logger.audioSession.info("mediaResourceInterruptionEnd from scene: \(scene) type: \(type)")
    }
}

extension MeetingState {
    var mediaMutexScene: MediaMutexScene? {
        switch self {
        case .ringing: return .vcRing
        case .start: return nil
        default: return .vcMeeting
        }
    }
}
