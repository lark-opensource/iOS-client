//
//  NewAudioRecordManager.swift
//  LarkAudio
//
//  Created by kangkang on 2023/12/21.
//

import RxSwift
import LarkMedia
import Foundation
import LarkSetting
import EENavigator
import LarkAudioKit
import AVFoundation
import LarkContainer
import LKCommonsLogging
import LarkSensitivityControl

protocol RecordTaskDelegate: AnyObject {
    func recordStopFailed()
}
final class NewAudioRecordManager: NSObject {

    var sampleRate: Float64 = 16_000 //采样频率
    var channel: UInt32 = 1
    var bitsPerChannel: UInt32 = 16 // 采样位数
    var currentTime: TimeInterval {
        if let currentTask {
            return currentTask.currentTime
        }
        return 0
    }

    private static let logger = Logger.log(NewAudioRecordManager.self, category: "Module.Audio")
    private let userResolver: UserResolver
    private var currentTask: RecordTask?
    private var useUnitRecordService = false
    private let queue = DispatchQueue(label: "audio.record.manager", qos: .userInteractive)
    private let feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init()
        addNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addNotification() {
        // swiftlint:disable line_length
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterrupt(_:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionNotification(_:)), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionNotification(_:)), name: AVAudioSession.mediaServicesWereLostNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionNotification(_:)), name: AVAudioSession.mediaServicesWereResetNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionNotification(_:)), name: AVAudioSession.silenceSecondaryAudioHintNotification, object: AVAudioSession.sharedInstance())
        if #available(iOS 15.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionNotification(_:)), name: AVAudioSession.spatialPlaybackCapabilitiesChangedNotification, object: AVAudioSession.sharedInstance())
        }
        // swiftlint:enable line_length
    }

    func startRecord(delegate: RecordAudioDelegate,
                     from: NavigatorFrom?,
                     useAveragePower: Bool = false,
                     dataCallbackInterval: Float64,
                     averagePowerCallbackInterval: TimeInterval,
                     impact: Bool = true,
                     taskID: String) {
        Self.logger.info("manager start record")
        if let currentTask {
            //currentTask.interruptNotificationBegan()
            currentTask.stop()
        }
        currentTask = RecordTask(userResolver: userResolver,
                                 useUnitRecordService: useUnitRecordService,
                                 useAveragePower: useAveragePower,
                                 dataCallbackInterval: dataCallbackInterval,
                                 averagePowerCallbackInterval: averagePowerCallbackInterval,
                                 sampleRate: sampleRate,
                                 channel: channel,
                                 bitsPerChannel: bitsPerChannel,
                                 impact: impact,
                                 taskID: taskID, from: from, feedbackGenerator: feedbackGenerator, timeLimit: 1, queue: queue,
                                 delegate: delegate, managerDelegate: self, finishCompletion: { [weak self] in
            self?.currentTask = nil
        })
        currentTask?.start()
    }

    func stopRecord(taskID: String,
                    file: String = #fileID,
                    function: String = #function,
                    line: Int = #line) {
        Self.logger.info("manager stop record \(file) \(function) \(line)")
        guard let currentTask, currentTask.taskID == taskID else { return }
        currentTask.stop()
    }

    func cancelRecord(taskID: String,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {
        Self.logger.info("manager cancel record \(file) \(function) \(line)")
        guard let currentTask, currentTask.taskID == taskID else { return }
        currentTask.cancel()
    }

    @objc
    func handleAudioSessionInterrupt(_ noti: Notification) {
        if let userinfo = noti.userInfo,
            let typeValue = userinfo[AVAudioSessionInterruptionTypeKey] as? NSValue {
            var intValue: UInt = 0
            typeValue.getValue(&intValue)
            if intValue == AVAudioSession.InterruptionType.began.rawValue {
                currentTask?.interruptNotificationBegan()
            }
        }
    }
    @objc
    func handleAudioSessionNotification(_ noti: Notification) {
        Self.logger.info("receive audio noti name \(noti.name) object \(noti.object) userinfo \(noti.userInfo)")
    }
}

extension NewAudioRecordManager: RecordTaskDelegate {
    func recordStopFailed() {
        if let settings = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_audio_config")),
            let audioConfig = settings["record"] as? [String: Any] {
            Self.logger.info("get audio engine config \(audioConfig)")
            if let audioUnitEnable = audioConfig["audio_unit_enable"] as? Int {
                self.useUnitRecordService = audioUnitEnable == 1
            }
        }
    }
}

final class RecordTask: UserResolverWrapper {

    private enum FinishState {
        case none
        case invokeStop
        case invokeCancel
        case failed
        case success
    }

    private enum TaskError: String, Error {
        case weakSelf
        case lockCancel
        case tryLockFailed
        case enterCancel
        case enterFailed
        case hapticsCancel
        case startCancel
        case startFailed
        case leaveFailed
    }

    var currentTime: TimeInterval {
        return record?.currentTime ?? 0
    }

    let userResolver: UserResolver
    let taskID: String
    private static let logger = Logger.log(RecordTask.self, category: "Module.Audio")
    private let useUnitRecordService: Bool
    private let useAveragePower: Bool
    private let dataCallbackInterval: Float64
    private let averagePowerCallbackInterval: TimeInterval
    private let sampleRate: Float64
    private let channel: UInt32
    private let bitsPerChannel: UInt32
    private let impact: Bool
    private let feedbackGenerator: UIImpactFeedbackGenerator
    private let timeLimit: TimeInterval //判断录音太短依据
    private let queue: DispatchQueue
    private let disposeBag = DisposeBag()
    private weak var delegate: RecordAudioDelegate?
    private weak var from: NavigatorFrom?
    private weak var managerDelegate: RecordTaskDelegate?

    private var pcmData: Data = Data()
    private var finishState: FinishState = .none
    private var startTime: TimeInterval = 0
    private var record: RecordServiceProtocol?
    private let finishCompletion: (() -> Void)
    private var isRecording: Bool {
        if let record {
            return record.isRecording
        }
        return false
    }

    init(userResolver: UserResolver,
         useUnitRecordService: Bool,
         useAveragePower: Bool,
         dataCallbackInterval: Float64,
         averagePowerCallbackInterval: TimeInterval,
         sampleRate: Float64,
         channel: UInt32,
         bitsPerChannel: UInt32,
         impact: Bool,
         taskID: String,
         from: NavigatorFrom?,
         feedbackGenerator: UIImpactFeedbackGenerator,
         timeLimit: TimeInterval,
         queue: DispatchQueue,
         delegate: RecordAudioDelegate,
         managerDelegate: RecordTaskDelegate,
         finishCompletion: @escaping (() -> Void)) {
        self.userResolver = userResolver
        self.useUnitRecordService = useUnitRecordService
        self.useAveragePower = useAveragePower
        self.dataCallbackInterval = dataCallbackInterval
        self.averagePowerCallbackInterval = averagePowerCallbackInterval
        self.sampleRate = sampleRate
        self.channel = channel
        self.bitsPerChannel = bitsPerChannel
        self.impact = impact
        self.taskID = taskID
        self.timeLimit = timeLimit
        self.queue = queue
        self.from = from
        self.feedbackGenerator = feedbackGenerator
        self.delegate = delegate
        self.managerDelegate = managerDelegate
        self.finishCompletion = finishCompletion
        self.finishState = .none
        Self.logger.info("Record Task init \(self)")
    }

    deinit {
        Self.logger.info("Record Task deinit \(self) \(taskID)")
    }

    func start() {
        Self.logger.info("task start() \(taskID)")
        startTime = CACurrentMediaTime()
        self.handleStateChange(state: .prepare)
        let observers: [Observable<Void>] = [self.lockObservable(), self.enterObservable(),
                                             self.hapticsObservable(), self.createRecord()]
        Observable.concat(observers).observeOn(MainScheduler.instance).subscribe(onError: { [weak self] error in
            guard let self, let taskError = error as? TaskError else { return }
            startHandleTaskError(taskError)
        }, onCompleted: { [weak self] in
            Self.logger.info("start() finish \(self?.taskID)")
            guard let self else { return }
            switch finishState {
            case .none:
                let endTime = CACurrentMediaTime()
                AudioRecordManager.setIdleTimer(disabled: true)
                handleStateChange(state: .start)
            default: break
            }
        }).disposed(by: disposeBag)
    }

    func stop() {
        Self.logger.info("task stop() \(taskID)")
        mainThread { [weak self] in
            guard let self else { return }
            finishState = .invokeStop
            if let record {
                let endTime = CACurrentMediaTime()
                if (endTime - self.startTime) < timeLimit || record.currentTime < timeLimit {
                    self.handleStateChange(state: .tooShort)
                    finishState = .failed
                    self.stopService(record: record, completion: finishCompletion)
                } else {
                    self.stopService(record: record, completion: finishCompletion)
                }
            } else {
                self.handleStateChange(state: .tooShort)
            }
        }
    }

    func cancel() {
        Self.logger.info("task cancel() \(taskID)")
        mainThread { [weak self] in
            guard let self else { return }
            finishState = .invokeCancel
            handleStateChange(state: .cancel)
            if let record {
                stopService(record: record, completion: finishCompletion)
            }
        }
    }

    func interruptNotificationBegan() {
        if self.isRecording {
            Self.logger.info("audio record handle audio session interrupt \(taskID)")
            delegate?.audioSessionInterruption()
        }
    }

    private func stopService(record: RecordServiceProtocol, completion: @escaping () -> Void) {
        record.stopRecord()
        Observable.concat([leaveObservable(), unlockObservable()])
            .subscribe(onError: { [weak self] error in
                guard let taskError = error as? TaskError else { return }
                Self.logger.error("stop error: \(taskError.rawValue) \(self?.taskID)")
            }, onCompleted: {
                AudioRecordManager.setIdleTimer(disabled: false)
                completion()
            }).disposed(by: disposeBag)
    }

    private func createRecord() -> Observable<Void> {
        return Single.create { [weak self] (single) -> Disposable in
            guard let self else {
                single(.error(TaskError.weakSelf))
                return Disposables.create()
            }
            guard self.finishState != .invokeStop, self.finishState != .invokeCancel else {
                Self.logger.info("start cancel \(taskID)")
                single(.error(TaskError.startCancel))
                return Disposables.create()
            }
            mainThread { [weak self] in
                guard let self else {
                    single(.error(TaskError.weakSelf))
                    return
                }
                var recorder: RecordServiceProtocol
                if self.useUnitRecordService {
                    let unitRecorder = UnitRecordService(
                        sampleRate: self.sampleRate,
                        channel: self.channel,
                        bitsPerChannel: self.bitsPerChannel
                    )
                    recorder = unitRecorder
                } else {
                    let queueRecorder = RecordService(
                        sampleRate: self.sampleRate,
                        channel: self.channel,
                        bitsPerChannel: self.bitsPerChannel
                    )
                    queueRecorder.useAveragePower = self.useAveragePower
                    queueRecorder.dataCallbackInterval = self.dataCallbackInterval
                    queueRecorder.averagePowerCallbackInterval = self.averagePowerCallbackInterval
                    recorder = queueRecorder
                }
                var result: OSStatus = noErr
                self.record = recorder
                Self.logger.info("create record finish \(taskID)")
                let success = recorder.startRecord(token: Token("LARK-PSDA-im_audio_start_record"), encoder: self, result: &result)
                if self.impact, #available(iOS 13.0, *) {
                    Self.logger.info("NewAudioRecord: really Impact \(taskID)")
                    self.feedbackGenerator.impactOccurred()
                }
                if success {
                    Self.logger.info("start finish \(taskID)")
                    single(.success(()))
                } else {
                    single(.error(TaskError.startFailed))
                }
            }
            return Disposables.create()
        }.asObservable()
    }

    private func hapticsObservable() -> Observable<Void> {
        return Single.create { [weak self] (single) -> Disposable in
            guard let self else {
                single(.error(TaskError.weakSelf))
                return Disposables.create()
            }
            guard impact else {
                single(.success(()))
                return Disposables.create()
            }
            if self.finishState != .invokeStop, self.finishState != .invokeCancel {
                if #available(iOS 13.0, *) {
                    DispatchQueue.global().async { [weak self] in
                        guard let self else { return }
                        Self.logger.info("NewAudioRecord: impact allow \(taskID)")
                        try? AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
                        Self.logger.info("haptics finish \(taskID)")
                        single(.success(()))
                    }
                } else {
                    mainThread { [weak self] in
                        guard let self else { return }
                        Self.logger.info("NewAudioRecord: invoke impact function \(taskID)")
                        feedbackGenerator.impactOccurred()
                        let time = 0.15
                        DispatchQueue.global().asyncAfter(deadline: .now() + time) {
                            single(.success(()))
                        }
                    }
                }
            } else {
                Self.logger.info("haptics cancel \(taskID)")
                single(.error(TaskError.hapticsCancel))
            }
            return Disposables.create()
        }.asObservable()
    }

    private func enterObservable() -> Observable<Void> {
        return Single.create { [weak self] (single) -> Disposable in
            guard let self else {
                single(.error(TaskError.weakSelf))
                return Disposables.create()
            }
            if self.finishState != .invokeStop, self.finishState != .invokeCancel {
                self.queue.async {
                    Self.logger.info("enter start")
                    if let resource = LarkMediaManager.shared.getMediaResource(for: .imRecord) {
                        resource.audioSession.enter(AudioSessionScenario.recordScenario, completion: {
                            Self.logger.info("enter finish")
                            single(.success(()))
                        })
                    } else {
                        single(.error(TaskError.enterFailed))
                    }
                }
            } else {
                Self.logger.info("enter cancel \(taskID)")
                single(.error(TaskError.enterCancel))
            }
            return Disposables.create()
        }.asObservable()
    }

    private func lockObservable() -> Observable<Void> {
        return Single.create { [weak self] (single) -> Disposable in
            guard let self else {
                single(.error(TaskError.weakSelf))
                return Disposables.create()
            }
            Self.logger.info("lock start \(taskID)")
            mainThread { [weak self] in
                guard let self else { return }
                if self.finishState != .invokeStop, self.finishState != .invokeCancel {
                    AudioMediaLockManager.shared.tryLock(userResolver: userResolver, from: self.from, callback: { result in
                        if result {
                            Self.logger.info("lock finish")
                            single(.success(()))
                        } else {
                            single(.error(TaskError.tryLockFailed))
                        }
                    }, interruptedCallback: { _ in
                        single(.error(TaskError.tryLockFailed))
                    })
                } else {
                    Self.logger.info("lock cancel \(taskID)")
                    single(.error(TaskError.lockCancel))
                }
            }
            return Disposables.create()
        }.asObservable()
    }

    private func leaveObservable() -> Observable<Void> {
        return Single.create { (single) -> Disposable in
            self.queue.async {
                if let resource = LarkMediaManager.shared.getMediaResource(for: .imRecord) {
                    resource.audioSession.leave(AudioSessionScenario.recordScenario)
                    Self.logger.info("leave finish")
                    single(.success(()))
                } else {
                    single(.error(TaskError.leaveFailed))
                }
            }
            return Disposables.create()
        }.asObservable()
    }

    private func unlockObservable() -> Observable<Void> {
        return Single.create { (single) -> Disposable in
            Self.logger.info("unlock start")
            AudioMediaLockManager.shared.unlock()
            Self.logger.info("unlock finish")
            single(.success(()))
            return Disposables.create()
        }.asObservable()
    }

    private func handleStateChange(state: AudioRecordState) {
        Self.logger.info("audio record state change \(state) \(taskID)")
        mainThread { [weak self] in
            guard let self else { return }
            Self.logger.info("NewAudioRecord: state \(state) \(taskID)")
            self.delegate?.audioRecordStateChange(state: state, taskID: self.taskID)
        }
    }

    private func startHandleTaskError(_ taskError: TaskError) {
        switch taskError {
        case .weakSelf:
            Self.logger.error("weak self freed \(taskID)")
        case .lockCancel:
            if finishState == .invokeCancel || finishState == .invokeStop {
                finishCompletion()
            }
        case .tryLockFailed:
            finishState = .failed
            handleStateChange(state: .failed(RecordError.tryLockFailed))
            finishCompletion()
        case .enterCancel:
            if finishState == .invokeCancel || finishState == .invokeStop {
                Observable.concat(self.unlockObservable().asObservable()).subscribe(onCompleted: { [weak self] in
                    self?.finishCompletion()
                }).disposed(by: self.disposeBag)
            }
        case .enterFailed:
            finishState = .failed
            handleStateChange(state: .failed(RecordError.startFailed))
            Observable.concat([unlockObservable().asObservable()]).subscribe(onCompleted: { [weak self] in
                self?.finishCompletion()
            }).disposed(by: self.disposeBag)
        case .hapticsCancel:
            if finishState == .invokeCancel || finishState == .invokeStop {
                Observable.concat([leaveObservable().asObservable(), unlockObservable().asObservable()]).subscribe(onCompleted: { [weak self] in
                    self?.finishCompletion()
                }).disposed(by: self.disposeBag)
            }
        case .startCancel:
            if finishState == .invokeCancel || finishState == .invokeStop {
                Observable.concat([leaveObservable().asObservable(), unlockObservable().asObservable()]).subscribe(onCompleted: { [weak self] in
                    self?.finishCompletion()
                }).disposed(by: self.disposeBag)
            }
        case .startFailed:
            finishState = .failed
            handleStateChange(state: .failed(RecordError.startFailed))
            if let record {
                stopService(record: record, completion: finishCompletion)
            }
        case .leaveFailed: break
        }
    }
}

extension RecordTask: RecordServiceDelegate {
    func recordServiceStart() {
        pcmData = Data()
    }

    func recordServiceStop() {
        if self.finishState == .invokeStop {
            if pcmData.isEmpty {
                Self.logger.error("record failed without any audioData  \(taskID)")
                self.handleStateChange(state: .failed(RecordError.dataEmpty))
                managerDelegate?.recordStopFailed()
            } else {
                let time = Double(pcmData.count) * Double(Data.Element.bitWidth) / Double(sampleRate) / Double(bitsPerChannel)
                let wavHeader = WavHeader(dataSize: Int32(pcmData.count), numChannels: Int16(self.channel), sampleRate: Int32(self.sampleRate), bitsPerSample: Int16(self.bitsPerChannel))
                var waveData = Data()
                waveData.append(wavHeader.toData())
                waveData.append(pcmData)
                self.finishState = .success
                self.handleStateChange(state: .success(waveData, time))
            }
        }
        pcmData.removeAll()
        self.startTime = 0
    }

    func onMicrophoneData(_ data: Data) {
        pcmData.append(data)
        self.delegate?.audioRecordStreamData(data: data)
    }

    func onPowerData(power: Float32) {
        mainThread { [weak self] in
            self?.delegate?.audioRecordUpdateMetra(power)
        }
    }
}
