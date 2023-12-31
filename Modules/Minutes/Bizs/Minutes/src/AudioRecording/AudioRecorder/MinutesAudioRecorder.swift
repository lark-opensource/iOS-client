//
//  MinutesAudioRecorder.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/16.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import AVFoundation
import LarkAudioKit
import LarkMedia
import LarkContainer
import LarkAccountInterface
import MinutesFoundation
import LarkSetting

public enum MinutesAudioRecorderStatus {
    case idle
    case recording
    case paused

    func shouldDisableIdleTimer() -> Bool {
        switch self {
        case .recording:
            return true
        default:
            return false
        }
    }
}

public protocol MinutesAudioRecorderListener: AnyObject {
    func audioRecorderDidChangeStatus(status: MinutesAudioRecorderStatus)
    func audioRecorderTryMideaLockfailed(error: LarkMedia.MediaMutexError, isResume: Bool)
    func audioRecorderOpenRecordingSucceed(isForced: Bool)
    func audioRecorderTimeUpdate(time: TimeInterval)
}

public final class MinutesAudioRecorder {
    public static let shared = MinutesAudioRecorder()

    public static let maxRecordTime: TimeInterval = 60 * 60 * 4
    public static let showTipsTime: TimeInterval = 60 * 60 * 3.5

    let stoppedHandle = MinutesRecordStoppedTaskStateHandle()

    var hasShownHud = false

    var codecType: String = "aac"

    lazy var recordFinishOptimize: Bool = {
        guard let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "minutes_upload_optimize")) else {
            MinutesLogger.record.info("get record_finish_optimize config failed")
            return false
        }
        if let enabled = settings["record_finish_optimize"] as? Bool {
            MinutesLogger.record.info("get record_finish_optimize enabled: \(enabled)")
            return enabled
        } else {
            MinutesLogger.record.info("get record_finish_optimize failed")
            return false
        }
    }()


    static let recordAudioSessionScenario = AudioSessionScenario("minutes.audio.record", category: .playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers, .interruptSpokenAudioAndMixWithOthers])

    var listeners = MulticastListener<MinutesAudioRecorderListener>()

    var currentUserSession: String?
    public var isRecording: Bool {
        status != .idle
    }

    var adaptAudioUnmuteEnabled: Bool {
        if let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "vc_minutes_ios17_audio_unmute")) {
            if let enabled = settings["adapt_audio_unmute"] as? Bool {
                MinutesLogger.record.info("get adapt audio unmute enabled: \(enabled)")
                return enabled
            } else {
                MinutesLogger.record.info("get adapt audio unmute key failed")
            }
        } else {
            MinutesLogger.record.info("get adapt audio unmute config failed")
        }
        return false
    }

    public var status: MinutesAudioRecorderStatus = .idle {
        didSet {
            guard status != oldValue else { return }
            
            self.listeners.invokeListeners { listener in
                listener.audioRecorderDidChangeStatus(status: status)
            }
            
            setIdleTimer(disabled: status.shouldDisableIdleTimer())
            MinutesLogger.record.info("MinutesAudioRecorderStatus changed from \(oldValue) to \(status)")

            if oldValue == .idle {
                InnoPerfMonitor.shared.entry(scene: .minutesRecording)
            } else if status == .idle {
                InnoPerfMonitor.shared.leave(scene: .minutesRecording)
            }
        }
    }
    public var interruptionType: AVAudioSession.InterruptionType?
    public var didInterruption: ((AVAudioSession.InterruptionType) -> Void)?

    public var decibelData: MinutesAudioDecibel = MinutesAudioDecibel()

    var tracker: MinutesTracker?
    public private(set) var minutes: Minutes? {
        didSet {
            var extra: [String: Any] = [:]
            extra["objectToken"] = minutes?.objectToken ?? ""
            extra["hasVideo"] = minutes?.basicInfo?.mediaType == .video
            extra["contentSize"] = minutes?.data.subtitlesContentSize ?? 0
            extra["mediaDuration"] = minutes?.basicInfo?.duration ?? 0
            InnoPerfMonitor.shared.update(extra: extra)

            if let minutes = minutes {
                tracker = MinutesTracker(minutes: minutes)
            }
        }
    }

    public private(set) var audioPower: Float32 = 0.0 {
        didSet {
            decibelData.addDecibelPower(audioPower)
        }
    }
    private var recordService: RecordService?

    private var recordedTime: TimeInterval = 0.0
    public var recordingTime: TimeInterval {
        guard status == .recording else { return recordedTime }
        let currentTime = recordService?.currentTime ?? 0.0
        return recordedTime + currentTime
    }
    
    public var language: Language = Language(name: "普通话", code: "zh_cn") {
        didSet {
            uploader?.language = language.code
        }
    }

    var shouldFetchLanguage: Bool = false {
        willSet {
            fetchDefaultLanguage()
        }
    }

    private var uploader: MinutesAudioDataUploader?

    private init () {
        NotificationCenter.default.addObserver(self, selector: #selector(onAudioInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }

    func fetchDefaultLanguage() {
        MinutesRecord.fetchDefaultLanguage(catchError: false) { [weak self] result in
            switch result {
            case .success(let lang):
                self?.language = lang
                MinutesLogger.record.info("fetch default spoken to: \(lang)")
            case .failure(let error):
                MinutesLogger.record.warn("fetch default spoken launguage failed with:\(error)")
            }
        }
    }

    @objc func onAudioInterruption(_ notification: Notification) {
        if status == .idle {
            return
        }
        if let userInfo = notification.userInfo,
           let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
           let type = AVAudioSession.InterruptionType(rawValue: typeValue) {

            if type == .began {
                MinutesLogger.record.info("Recording Interrupt began")
                pause()
            } else if type == .ended {
                MinutesLogger.record.info("Recording Interrupt ended")
            }

            interruptionType = type
            didInterruption?(type)
        }
    }
    
    public func didChangeModuleAction() {
        // meeting end
        MinutesLogger.record.info("Meeting end, Recording Interrupt ended")

        interruptionType = .ended
        didInterruption?(.ended)
    }

    public func perpare() -> Bool {
        MinutesLogger.record.info("recorder perpare. status: \(status) has recordService: \(self.recordService == nil) has minutes: \(self.minutes == nil)")

        guard status == .idle else { return false }
        guard self.recordService == nil else { return false }
        guard self.minutes == nil else { return false }

        return true
    }

    public func tryOpenAudio(isForced: Bool) {
        LarkMediaManager.shared.tryLock(scene: .mmRecord, options: .mixWithOthers, observer: self) { [weak self] in
            guard let self = self else {
                return
            }
            switch $0 {
            case .success(let resource):
                if self.adaptAudioUnmuteEnabled, #available(iOS 17, *), case .success = resource.microphone.requestMute(false) {
                    MinutesLogger.record.info("NewAudioRecord: lockManager lock")
                }

                resource.audioSession.enter(MinutesAudioRecorder.recordAudioSessionScenario)
                DispatchQueue.main.async {
                    // disable-lint: magic number
                    let service = RecordService(sampleRate: 44_100, channel: 1, bitsPerChannel: 16)
                    service.dataCallbackInterval = Double(1024) / Double(44100)
                    service.averagePowerCallbackInterval = 0.06
                    // enable-lint: magic number
                    service.useAveragePower = true
                    if service.startRecord(encoder: self) {
                        self.recordService = service
                        MinutesLogger.record.info("start record service sucess.")
                        self.listeners.invokeListeners { listener in
                            MinutesLogger.record.info("start record service, delegate: \(listener)")
                            listener.audioRecorderOpenRecordingSucceed(isForced: isForced)
                        }
                    } else {
                        MinutesLogger.record.info("start record service failed.")
                        self.listeners.invokeListeners { listener in
                            listener.audioRecorderTryMideaLockfailed(error: .unknown, isResume:  false)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.listeners.invokeListeners { listener in
                        listener.audioRecorderTryMideaLockfailed(error: error, isResume: false)
                    }
                }
                MinutesLogger.record.warn("start record service failed with error: \(error)")
            }
        }
    }
    
    public func cleanup() {
        MinutesLogger.record.info("recorder cleanup.")
        self.currentUserSession = nil
        DispatchQueue.main.async {
            self.recordService?.delegate = nil
            self.recordService?.stopRecord()
            self.recordService = nil
            MinutesAudioDataUploadCenter.shared.containerView = nil
            self.minutes = nil
            self.uploader = nil
            self.recordedTime = 0.0
            self.status = .idle
            self.hasShownHud = false
            LarkMediaManager.shared.unlock(scene: .mmRecord, options: .leaveScenarios)
        }
    }

    public func start(_ minutes: Minutes, container: UIView?, session: String?) {
        if let curSession = self.currentUserSession, session != currentUserSession {
            MinutesAudioRecorder.shared.stop()
        }
        MinutesLogger.record.info("recorder start.")
        LKMonitor.beginEvent(event: "minutes_record")
        self.minutes = minutes
        self.currentUserSession = session
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name.init("LarkEnterContext"), object: nil, userInfo: ["name": "minutes_recording"])
            let token = minutes.objectToken
            let uploader = MinutesAudioDataUploader(token, uploaderListKey: nil, container: container)
            uploader.language = self.language.code
            self.uploader = uploader
            MinutesAudioDataUploadCenter.shared.register(uploader: uploader)
            MinutesAudioDataUploadCenter.shared.containerView = container
            let droptime = self.recordService?.currentTime ?? 0.0
            self.recordedTime = 0.0 - droptime
        }
    }

    public func stop() {
        // 防止第三方打断录音，丢失埋点
        tracker?.tracker(name: .minutesDev, params: ["action_name": "recording_click", "click": "stop_recording", "target": "none", "minutes_token": minutes?.objectToken ?? "", "minutes_type": "audio_record", "audio_codec_type": MinutesAudioRecorder.shared.codecType])

        if recordFinishOptimize {
            stoppedHandle.markStoppedMinutes(with: minutes?.objectToken)
        }

        MinutesLogger.record.info("recorder stop.")
        LKMonitor.endEvent(event: "minutes_record")
        self.currentUserSession = nil
        DispatchQueue.main.async {
            let token = self.minutes?.objectToken ?? ""
            MinutesLogger.record.info("recordService stopRecord, token: \(token.suffix(6))")
            self.minutes?.record?.recordingStopped()
            self.recordService?.delegate = nil
            self.recordService?.stopRecord()
            self.uploader?.endAudioData()
            self.recordService = nil
            MinutesAudioDataUploadCenter.shared.containerView = nil
            self.minutes = nil
            self.uploader = nil
            self.recordedTime = 0.0
            self.status = .idle
            self.hasShownHud = false
            
            NotificationCenter.default.post(name: NSNotification.Name.init("LarkLeaveContext"), object: nil, userInfo: ["name": "minutes_recording"])
            LarkMediaManager.shared.unlock(scene: .mmRecord, options: .leaveScenarios)
        }
    }

    public func pause() {
        if status != .recording {
            return
        }

        MinutesLogger.record.info("recorder pause.")
        DispatchQueue.main.async {
            let recordedTime = self.recordingTime
            self.recordService?.delegate = nil
            self.recordService?.stopRecord()
            self.status = .paused
            self.recordedTime = recordedTime

            self.minutes?.record?.pause()
            
            LarkMediaManager.shared.unlock(scene: .mmRecord, options: .leaveScenarios)
        }
    }

    public func resume() {
        if status != .paused {
            return
        }
        guard interruptionType != .began else { return }
        MinutesLogger.record.info("recorder resume.")
       
        LarkMediaManager.shared.tryLock(scene: .mmRecord, options: .mixWithOthers, observer: self) { [weak self] in
            guard let self = self else {
                return
            }
            
            switch $0 {
            case .success(let resource):
                resource.audioSession.enter(MinutesAudioRecorder.recordAudioSessionScenario)
                DispatchQueue.main.async {
                    if self.recordService?.startRecord(encoder: self) == true {
                        self.minutes?.record?.resume()
                    } else {
                        MinutesLogger.record.warn("resume record service failed")
                        self.listeners.invokeListeners { listener in
                            listener.audioRecorderTryMideaLockfailed(error: .unknown, isResume: true)
                        }
                        self.stop()
                    }
                }
            case .failure(let error):
                MinutesLogger.record.warn("resume record service failed by mediamutex")
                self.listeners.invokeListeners { listener in
                    listener.audioRecorderTryMideaLockfailed(error: error, isResume: true)
                }
                self.stop()
            }
        }
    }
}

extension MinutesAudioRecorder: MediaResourceInterruptionObserver {
   
    public func mediaResourceWasInterrupted(by scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType, msg: String?) {
        MinutesLogger.record.info("mediaResourceWasInterrupted by scene: \(scene) type: \(type) msg: \(msg)")
        self.pause()
    }

    public func mediaResourceInterruptionEnd(from scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType) {
        MinutesLogger.record.info("mediaResourceInterruptionEnd from scene: \(scene) type: \(type)")
    }
}

extension MinutesAudioRecorder {

    private func setIdleTimer(disabled: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }

}

extension MinutesAudioRecorder: RecordServiceDelegate {
    public func recordServiceStart() {
        MinutesLogger.record.info("recorder service start.")
        status = .recording
    }

    public func recordServiceStop() {
        MinutesLogger.record.info("recorder service stop.")
    }

    public func onMicrophoneData(_ data: Data) {
        MinutesLogger.recordFile.info("onMicrophoneData, \(data.count)")
        self.uploader?.appendAudioData(data)
        self.listeners.invokeListeners { listener in
            listener.audioRecorderTimeUpdate(time: recordingTime)
        }
        if data.count > 0, recordingTime > Self.maxRecordTime {
            MinutesLogger.recordFile.info("recordingTime > maxRecordTime, stop")
            self.stop()
        }
    }

    public func onPowerData(power: Float32) {
        audioPower = power
    }

}

