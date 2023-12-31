//
//  AudioRecordManager.swift
//  LarkAudioKitDev
//
//  Created by 李晨 on 2021/6/22.
//

import UIKit
import Foundation
import AVFoundation
import LKCommonsLogging
import LKCommonsTracker
import LarkAudioKit
import LarkMedia
import RxSwift
import LarkSensitivityControl

protocol RecordAudioDelegate: AnyObject {
    func audioRecordUpdateMetra(_ metra: Float) // 在异步线程连续回调
    func audioRecordStateChange(state: AudioRecordState) // 返回状态变化 录音结束时 会返回带着 header 的 音频数据
    func audioRecordStreamData(data: Data) // 流式返回录音数据 不包括 wav header
}

enum AudioRecordState {
    case tooShort
    case prepare
    case start
    case cancel
    case failed(Error)
    case success(Data, TimeInterval)
}

extension AudioSessionScenario {
    static var recordScenario: AudioSessionScenario {
        if true {
            return AudioSessionScenario("lark.audio.record", category: .playAndRecord, mode: .default, options: [])
        } else {
            return AudioSessionScenario("lark.audio.record", category: .playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
        }
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

class AudioRecordManager: NSObject {

    static let logger = Logger.log(AudioRecordManager.self, category: "Module.Audio")

    static let sharedInstance: AudioRecordManager = AudioRecordManager()

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

    private var recorder: RecordService?
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

    var taskID: String {
        return self.currentTask.id
    }

    fileprivate override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterrupt), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
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
            let recorder = RecordService(
                sampleRate: self.sampleRate,
                channel: self.channel,
                bitsPerChannel: self.bitsPerChannel
            )
            recorder.useAveragePower = useAveragePower
            recorder.dataCallbackInterval = dataCallbackInterval
            self.recorder = recorder
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
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    let didActiveTime = Date().timeIntervalSince1970
                    let result = self.startRecordService(recorder: recorder, taskID: taskID)
                    if impact && supportImpactDuringRecording {
                        self.impactOccurred()
                    }
                    if result {
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
                        callback?(true)
                    } else {
                        AudioRecordManager.logger.error("start record failed")
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

    func cancelRrcordIfNeeded() {
        if self.currentTask.state == .default &&
            !self.currentTask.id.isEmpty {
            self.cancelRrcord()
        }
    }

    /**
     取消录音
     */
    func cancelRrcord() {
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
        feedbackGenerator.impactOccurred()
    }

    private func allowHapticsDuringRecordingObservable() -> Observable<Void> {
        return Observable.create { (ob) -> Disposable in
            DispatchQueue.main.async {
                if #available(iOS 13.0, *) {
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
                if let `self` = self,
                    taskID == self.taskID,
                    self.currentTask.state == .default {
                    AVAudioSession.entry(AudioSessionScenario.recordScenario, completion: {
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

    private func startRecordService(recorder: RecordService, taskID: String) -> Bool {
        guard recorder === self.recorder,
            taskID == self.taskID,
            self.currentTask.state == .default else {
            return false
        }
        let success = recorder.startRecord(token: Token("LARK-PSDA-im_audio_start_record"), encoder: self)
        if !success {
            self.stopRecordService()
            return false
        }
        AudioRecordManager.setIdleTimer(disabled: true)
        self.handleAudioRecordStateChange(state: .start)
        return true
    }

    private func stopRecordService() {
        defer { self.recorder = nil }
        guard let recorder = self.recorder else { return }
        recorder.stopRecord()
        self.queue.async {
            AVAudioSession.leave(AudioSessionScenario.recordScenario)
            AudioRecordManager.setIdleTimer(disabled: false)
        }
    }

    private func handleAudioRecordStateChange(state: AudioRecordState) {
        AudioRecordManager.logger.info("audio record state change \(state)")
        mainThread {
            self.delegate?.audioRecordStateChange(state: state)
        }
    }

    private class func setIdleTimer(disabled: Bool) {
        mainThread {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }
}

extension AudioRecordManager {
    @objc
    func handleAudioSessionInterrupt(_ noti: Notification) {
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
}

extension AudioRecordManager: RecordServiceDelegate {

    func recordServiceStart() {
        tempPCMdata = Data()
    }
    func recordServiceStop() {
        if self.currentTask.state == .finish {
            if let data = tempPCMdata {
                let time = Double(data.count) * Double(Data.Element.bitWidth) / Double(sampleRate) / Double(bitsPerChannel)
                let wavHeader = WavHeader(dataSize: Int32(data.count), numChannels: Int16(self.channel), sampleRate: Int32(self.sampleRate), bitsPerSample: Int16(self.bitsPerChannel))
                var wavData = Data()
                wavData.append(wavHeader.toData())
                wavData.append(data)
                self.handleAudioRecordStateChange(state: .success(wavData, time))
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
private func mainThread(_ handler: @escaping () -> Void) {
    if Thread.isMainThread {
        handler()
    } else {
        DispatchQueue.main.async {
            handler()
        }
    }
}
