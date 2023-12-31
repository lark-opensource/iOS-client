//
//  AudioRecordManager.swift
//  Lark
//
//  Created by lichen on 2017/5/10.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import LKCommonsLogging
import LKCommonsTracker
import LarkAudioKit
import LarkMedia
import RxSwift
import LarkUIKit
import LarkFeatureGating
import LarkSetting
import LarkContainer
import LarkSensitivityControl
import EENavigator

protocol RecordAudioDelegate: AnyObject {
    func audioRecordUpdateMetra(_ metra: Float) // 在主线程连续回调
    func audioRecordStateChange(state: AudioRecordState) // 返回状态变化 录音结束时 会返回带着 header 的 音频数据
    func audioRecordStreamData(data: Data) // 流式返回录音数据 不包括 wav header
    func audioSessionInterruption()
    // NewAudioRecordManager会回调，替代audioRecordStateChange(state: AudioRecordState)
    func audioRecordStateChange(state: AudioRecordState, taskID: String) // 返回状态变化 录音结束时 会返回带着 header 的 音频数据
}

extension RecordAudioDelegate {
    func audioSessionInterruption() {}
    func audioRecordStateChange(state: AudioRecordState, taskID: String) {}
}

enum AudioRecordState {
    case tooShort
    case prepare
    case start
    case cancel
    case failed(RecordError)
    case success(Data, TimeInterval)

    var isRecording: Bool {
        switch self {
        case .prepare, .start: return true
        default: return false
        }
    }
}

extension AudioSessionScenario {
    static var recordScenario: AudioSessionScenario {
        // 使用内置麦克风
        let options: AVAudioSession.CategoryOptions
        if #available(iOS 14.5, *) {
            options = [.overrideMutedMicrophoneInterruption]
        } else {
            options = []
        }
        return AudioSessionScenario("lark.audio.record", category: .playAndRecord, mode: .default, options: options)
    }
}

/// audio record task
struct AudioRecordTask {
    enum State {
        case `default`
        case cancel
        case finish
    }

    var state: State = .default
    var id: String = ""
}

enum RecordError: Int, Error {
    case dataEmpty = -8848
    case startFailed = -8849
    case tryLockFailed = -8850
}

final class AudioRecordManager: NSObject {

    static let logger = Logger.log(AudioRecordManager.self, category: "Module.Audio")

    var sampleRate: Float64 = 16_000 //采样频率
    var channel: UInt32 = 1
    var bitsPerChannel: UInt32 = 16 // 采样位数
    var timeLimit: TimeInterval = 1 //判断录音太短依据

    private let queue = DispatchQueue(label: "audio.record.manager", qos: .userInteractive)

    private let feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()

    private let disposeBag: DisposeBag = DisposeBag()

    private var recorder: RecordServiceProtocol?
    private var tempPCMdata: Data?

    var isRecording: Bool {
        if let record = self.recorder {
            return record.isRecording
        }
        return false
    }

    var currentTime: TimeInterval {
        if let record = self.recorder {
            return record.currentTime
        }
        return 0
    }

    weak var delegate: RecordAudioDelegate?

    private(set) var startTime: TimeInterval = 0 //录音开始时间
    private(set) var endTime: TimeInterval = 0 //录音结束时间

    private(set) var currentTask: AudioRecordTask = AudioRecordTask()

    /// 是否需要调整为 audiUnit record service
    /// 发生录音失败 无法录音的场景触发
    private(set) var useUnitRecordService = false

    var taskID: String {
        return self.currentTask.id
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterrupt(_:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionNotification(_:)), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionNotification(_:)),
            name: AVAudioSession.mediaServicesWereLostNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionNotification(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionNotification(_:)),
            name: AVAudioSession.silenceSecondaryAudioHintNotification,
            object: AVAudioSession.sharedInstance()
        )
        if #available(iOS 15.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionNotification(_:)),
                name: AVAudioSession.spatialPlaybackCapabilitiesChangedNotification,
                object: AVAudioSession.sharedInstance()
            )
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     获取录音权限并初始化录音
     */
    func checkPermissionAndSetupRecord(callback: @escaping (Bool) -> Void) {
        do {
            try AudioRecordEntry.requestRecordPermission(
                forToken: Token("LARK-PSDA-im_audio_request_record_permission"),
                session: AVAudioSession.sharedInstance()) { allowed in
                if !allowed {
                    Self.logger.warn("cannot access microphone")
                }
                callback(allowed)
            }
        } catch {
            Self.logger.error("failed to request record permission: \(error)")
            callback(false)
        }
    }

    /**
     开始录音
     */
    func startRecord(
        useAveragePower: Bool = false,
        dataCallbackInterval: Float64 = 0.1,
        averagePowerCallbackInterval: TimeInterval = 0.1,
        impact: Bool = true,
        taskID: String = UUID().uuidString,
        callback: ((Bool) -> Void)? = nil
    ) {
        let startTime = Date().timeIntervalSince1970
        let isOtherAudioPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying
        mainThread {
            if let recorder = self.recorder {
                recorder.stopRecord()
            }
            self.currentTask = AudioRecordTask(id: taskID)
            self.startTime = CACurrentMediaTime()

            var recorder: RecordServiceProtocol
            if self.useUnitRecordService {
                let unitRecorder = UnitRecordService(
                    sampleRate: self.sampleRate,
                    channel: self.channel,
                    bitsPerChannel: self.bitsPerChannel
                )
                recorder = unitRecorder
                self.recorder = unitRecorder
            } else {
                let queueRecorder = RecordService(
                    sampleRate: self.sampleRate,
                    channel: self.channel,
                    bitsPerChannel: self.bitsPerChannel
                )
                queueRecorder.useAveragePower = useAveragePower
                queueRecorder.dataCallbackInterval = dataCallbackInterval
                queueRecorder.averagePowerCallbackInterval = averagePowerCallbackInterval
                recorder = queueRecorder
                self.recorder = queueRecorder
            }

            self.handleAudioRecordStateChange(state: .prepare)
            /// 是否支持录音时震动
            let supportImpactDuringRecording = self.impactEnableDuringRecording()
            var observers: [Observable<Void>] = []
            /// 需要确保设置震动
            observers.append(self.prepareStartRecord(taskID: taskID))
            if impact {
                if supportImpactDuringRecording {
                    /// 这里需要确保执行顺序在 prepareStartRecord 之后
                    /// setup AVAudioSession 会重置震动属性
                    observers.append(self.allowHapticsDuringRecordingObservable())
                } else {
                    observers.append(self.impactObservable())
                }
            }
            AudioRecordManager.logger.info("start record, prepare time: \(Date().timeIntervalSince1970)")

            Observable.concat(observers)
                .takeLast(1)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    let didActiveTime = Date().timeIntervalSince1970
                    let result = self.startRecordService(recorder: recorder, taskID: taskID)
                    /// 如果支持录音中震动 我们在音频录音 ready 之后再震动
                    if impact && supportImpactDuringRecording {
                        AudioRecordManager.logger.info("NewAudioRecord: really Impact \(impact) \(supportImpactDuringRecording)")
                        self.impactOccurred()
                    }
                    if result == noErr {
                        let endTime = Date().timeIntervalSince1970
                        AudioRecordManager.logger.info("start record, prepare time end: \(endTime)")
                        Tracker.post(SlardarEvent(
                            name: "chat_audio_active",
                            metric: [
                                "all": endTime - startTime,
                                "active": didActiveTime - startTime,
                                "service": endTime - didActiveTime
                            ],
                            category: ["isOtherAudioPlaying": (isOtherAudioPlaying ? "1" : "0")],
                            extra: [:])
                        )
                        AudioReciableTracker.shared.audioRecordCost(startTime: startTime, endTime: endTime, isOtherAudioPlaying: isOtherAudioPlaying)
                        callback?(true)
                    } else {
                        // result 为 -1 时，代表本次操作取消，不计入错误埋点
                        if result != -1 {
                            AudioRecordManager.logger.error("start record failed")
                            AudioReciableTracker.shared.audioRecordError(result: result, isOtherAudioPlaying: isOtherAudioPlaying)
                        } else {
                            AudioRecordManager.logger.error("start record cancel")
                        }
                        callback?(false)
                    }
                }).disposed(by: self.disposeBag)
        }
    }

    /**
     停止录音
     */
    func stopRecord() {
        mainThread {
            guard let recorder = self.recorder else {
                self.currentTask.state = .cancel
                return
            }

            self.endTime = CACurrentMediaTime()
            if (self.endTime - self.startTime) < self.timeLimit ||
                recorder.currentTime < self.timeLimit {
                self.currentTask.state = .cancel
                self.handleAudioRecordStateChange(state: .tooShort)
                self.stopRecordService()
            } else {
                self.currentTask.state = .finish
                self.stopRecordService()
            }
        }
    }

    func cancelRrcordIfNeeded(
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        AudioRecordManager.logger.info("click cancelRrcordIfNeeded \(file) \(function) \(line)")
        if self.currentTask.state == .default &&
            !self.currentTask.id.isEmpty {
            self.cancelRrcord()
        }
    }

    /**
     取消录音
     */
    func cancelRrcord(
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        AudioRecordManager.logger.info("click cancelRrcord \(file) \(function) \(line)")
        mainThread {
            self.currentTask.state = .cancel
            self.handleAudioRecordStateChange(state: .cancel)
            self.stopRecordService()
        }
    }

    private func impactEnableDuringRecording() -> Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }

    private func impactObservable() -> Observable<Void> {
        return Observable.create { [weak self] (ob) -> Disposable in
            DispatchQueue.main.async {
                self?.impactOccurred()
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
                    ob.onNext(())
                    ob.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    private func impactOccurred() {
        AudioRecordManager.logger.info("NewAudioRecord: invoke impact function")
        feedbackGenerator.impactOccurred()
    }

    private func allowHapticsDuringRecordingObservable() -> Observable<Void> {
        return Observable.create { (ob) -> Disposable in
            DispatchQueue.main.async {
                if #available(iOS 13.0, *) {
                    AudioRecordManager.logger.info("NewAudioRecord: impact allow")
                    try? AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
                }
                ob.onNext(())
                ob.onCompleted()
            }
            return Disposables.create()
        }
    }

    /**
     准备录音
     */
    private func prepareStartRecord(taskID: String) -> Observable<Void> {
        return Observable.create { [weak self] (ob) -> Disposable in
            self?.queue.async {
                AudioRecordManager.logger.info("audio record prepare record taskID \(taskID) self id \(self?.taskID) state \(self?.currentTask.state)")
                if let `self` = self,
                    taskID == self.taskID,
                    self.currentTask.state == .default {
                    AudioRecordManager.logger.info("NewAudioRecord: impact prepare")
                    AudioRecordManager.logger.info("audio record prepare record active")
                    LarkMediaManager.shared.getMediaResource(for: .imRecord)?.audioSession.enter(AudioSessionScenario.recordScenario, completion: {
                        ob.onNext(())
                        ob.onCompleted()
                    })
                } else {
                    ob.onNext(())
                    ob.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    private func startRecordService(recorder: RecordServiceProtocol, taskID: String) -> OSStatus {
        guard recorder.uuid == self.recorder?.uuid,
            taskID == self.taskID,
            self.currentTask.state == .default else {
            return -1
        }
        var result: OSStatus = noErr
        let success = recorder.startRecord(token: Token("LARK-PSDA-im_audio_start_record"), encoder: self, result: &result)
        if !success {
            self.stopRecordService()
            return result
        }
        AudioRecordManager.setIdleTimer(disabled: true)
        self.handleAudioRecordStateChange(state: .start)
        return noErr
    }

    private func stopRecordService() {
        defer { self.recorder = nil }
        guard let recorder = self.recorder else { return }
        recorder.stopRecord()
        guard let resource = LarkMediaManager.shared.getMediaResource(for: .imRecord) else {
            return
        }
        self.queue.async { [weak self] in
            resource.audioSession.leave(AudioSessionScenario.recordScenario)
            AudioRecordManager.setIdleTimer(disabled: false)
            AudioMediaLockManager.shared.unlock()
        }
    }

    private func handleAudioRecordStateChange(
        state: AudioRecordState
    ) {
        AudioRecordManager.logger.info("audio record state change \(state)")
        mainThread {
            AudioRecordManager.logger.info("NewAudioRecord: state \(state)")
            self.delegate?.audioRecordStateChange(state: state)
        }
    }

    class func setIdleTimer(disabled: Bool) {
        mainThread {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }

    private func switchToAudioUnitIfNeeded() {
        if let settings = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_audio_config")),
            let audioConfig = settings["record"] as? [String: Any] {
              Self.logger.info("get audio engine config \(audioConfig)")
              if let audioUnitEnable = audioConfig["audio_unit_enable"] as? Int {
                  self.useUnitRecordService = audioUnitEnable == 1
              }
        }
    }
}

extension AudioRecordManager {
    @objc
    func handleAudioSessionInterrupt(_ noti: Notification) {
        AudioRecordManager.logger.info("receive audio noti name \(noti.name) object \(noti.object) userinfo \(noti.userInfo)")
        if let userinfo = noti.userInfo,
            let typeValue = userinfo[AVAudioSessionInterruptionTypeKey] as? NSValue {
            var intValue: UInt = 0
            typeValue.getValue(&intValue)
            if intValue == AVAudioSession.InterruptionType.began.rawValue {
                if self.isRecording {
                    AudioRecordManager.logger.info("audio record handle audio session interrupt")
                    self.stopRecord()
                }
            }
        }
    }

    @objc
    func handleAudioSessionNotification(_ noti: Notification) {
        AudioRecordManager.logger.info("receive audio noti name \(noti.name) object \(noti.object) userinfo \(noti.userInfo)")
    }
}

extension AudioRecordManager: RecordServiceDelegate {

    func recordServiceStart() {
        tempPCMdata = Data()
    }
    func recordServiceStop() {
        if self.currentTask.state == .finish {
            if let data = tempPCMdata, !data.isEmpty {
                let time = Double(data.count) * Double(Data.Element.bitWidth) / Double(sampleRate) / Double(bitsPerChannel)
                let wavHeader = WavHeader(dataSize: Int32(data.count), numChannels: Int16(self.channel), sampleRate: Int32(self.sampleRate), bitsPerSample: Int16(self.bitsPerChannel))
                var wavData = Data()
                wavData.append(wavHeader.toData())
                wavData.append(data)
                self.handleAudioRecordStateChange(state: .success(wavData, time))
            } else {
                AudioRecordManager.logger.error("record failed without any audioData")
                AudioReciableTracker.shared.audioRecordError(result: OSStatus(RecordError.dataEmpty.rawValue), isOtherAudioPlaying: false)
                switchToAudioUnitIfNeeded()
                self.handleAudioRecordStateChange(state: .failed(RecordError.dataEmpty))
            }
        }
        tempPCMdata?.removeAll()
        self.startTime = 0
        self.endTime = 0
    }
    func onMicrophoneData(_ data: Data) {
        tempPCMdata?.append(data)
        self.delegate?.audioRecordStreamData(data: data)
    }
    func onPowerData(power: Float32) {
        mainThread {
            self.delegate?.audioRecordUpdateMetra(power)
        }
    }
}

@inline(__always)
func mainThread(_ handler: @escaping () -> Void) {
    if Thread.isMainThread {
        handler()
    } else {
        DispatchQueue.main.async {
            handler()
        }
    }
}
