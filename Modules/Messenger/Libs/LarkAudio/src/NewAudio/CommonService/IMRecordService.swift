//
//  IMRecordService.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/15.
//

import RustPB
import RxSwift
import Foundation
import EENavigator
import LarkContainer
import LarkAudioKit
import LKCommonsLogging
import LarkSDKInterface
import LarkLocalizations
import LarkMessengerInterface

/// 数据生产
protocol IMRecordService {
    var isRecording: Bool { get }
    var currentUploadId: String { get }
    var currentRecognizeId: String { get }
    var delegate: IMRecordServiceDelegate? { get set }
    var result: Observable<AudioRecognizeResult>? { get }
    func startRecord(useAveragePower: Bool, dataCallbackInterval: Float64, averagePowerCallbackInterval: TimeInterval, language: Lang?, from: NavigatorFrom?)
    func stop()
    func cancel()
}

/// 数据消费
protocol IMRecordServiceDelegate: AnyObject {
    func PCMData(data: Data)
    func decibel(power: Float)
    func stateChange(state: AudioRecordState)
    func recordTime(time: TimeInterval)
    func audioSessionInterruption()
}

// 和具体业务场景无关，只是「调用硬件」和「SDK 交互」
final class IMRecordServiceImpl: UserResolverWrapper {
    enum ConsumptionState {
        case uploadAndRecognize
        case recognize
        case upload(canUpload: Bool)
    }

    enum State {
        case normal     // 未录音
        case prepare    // 准备中
        case recording  // 录音中
    }

    private enum FinishStyle {
        case finish
        case cancel
    }

    enum Cons {
        static let uploadOggPage: Int32 = 50
        static let recognizeOggPage: Int32 = 2
        static let uploadAndRecognizeOggPage: Int32 = 2
        static let timerFramesPerSecond: Int = 30
    }

    weak var delegate: IMRecordServiceDelegate?
    let userResolver: UserResolver
    private let chatID: String
    @ScopedInjectedLazy private var audioAPI: AudioAPI?
    @ScopedInjectedLazy private var resourceAPI: ResourceAPI?
    @ScopedInjectedLazy private var audioPlayMediator: AudioPlayMediator?
    @ScopedInjectedLazy private var audioRecordManager: NewAudioRecordManager?
    @ScopedInjectedLazy private var audioRecognizeService: AudioRecognizeService?
    private static let logger = Logger.log(IMRecordService.self, category: "im.record.service")

    private(set) var state: State = .normal
    private let consumptionState: ConsumptionState
    private var opusStreamUtil: OpusStreamUtil?
    private var timer: CADisplayLink?
    private var hadFinish: Bool = false
    private var currentTaskID: String = UUID().uuidString

    // 录音用的参数
    private let recordQueue = DispatchQueue(label: "audio.record.view.model", qos: .userInitiated)
    private var uploadID: String = ""
    private var seqRecordID: Int32 = 0
    private var finishStyle: FinishStyle = .finish

    // 转文字用的参数
    private let recognizeQueue = DispatchQueue(label: "audio.Recognize.view.model", qos: .userInitiated)
    private var recognizeID: String = ""
    private var seqRecognizeID: Int32 = 0
    private var speechLocale: String = AudioKeyboardDataService.generateLocaleIdentifier(lang: LanguageManager.currentLanguage)

    // buffer相关参数
    private var bufferData: Data = Data()
    private let bufferLimit: Int
    private let oggPage: Int32

    init(userResolver: UserResolver, chatID: String, consumptionState: ConsumptionState) {
        self.chatID = chatID
        self.userResolver = userResolver
        self.consumptionState = consumptionState
        switch consumptionState {
        case .uploadAndRecognize:
            bufferLimit = 200
            oggPage = Cons.uploadAndRecognizeOggPage
        case .recognize:
            bufferLimit = 200
            oggPage = Cons.recognizeOggPage
        case .upload:
            bufferLimit = 2 * 1024
            oggPage = Cons.uploadOggPage
        }
        self.audioRecognizeService?.bindChatId(chatId: chatID)
    }

    deinit {
        audioRecordManager?.stopRecord(taskID: currentTaskID)
        Self.logger.info("deinit AudioRecognizeViewModel")
    }

    @objc
    private func updateRecordLengthLimit() {
        if !self.isRecording {
            timer?.invalidate()
            return
        }
        self.delegate?.recordTime(time: self.audioRecordManager?.currentTime ?? 0)
    }

    private func getUploadID() -> String {
        if case let .upload(canUpload: canUpload) = consumptionState, canUpload {
            return (try? self.resourceAPI?.fetchUploadID(chatID: chatID, language: RecognizeLanguageManager.shared.recognitionLanguage)) ?? ""
        }
        return ""
    }

    private func getRecognizeID() -> String {
        if case .upload = consumptionState {
            return ""
        }
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private func recognizeStreamData(data: Data, action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action) {
        if case .upload(canUpload: _) = consumptionState { return }
        self.recognizeQueue.async {
            if action != .unknown { Self.logger.info("handle record data in queue", additionalData: ["uploadid": self.recognizeID, "action": "\(action)"]) }
            let isFinish = action == .end
            let opusData = self.opusStreamUtil?.encodePcmData(data, isEnd: isFinish) ?? Data()
            self.bufferData.append(opusData)
            if self.bufferData.count > self.bufferLimit || action != .unknown {
                self.recognizeStreamDataInQueue(opusData: self.bufferData, action: action)
                self.bufferData.removeAll()
            }
            if isFinish {
                self.opusStreamUtil = nil
            }
        }
    }

    private func recognizeStreamDataInQueue(opusData: Data,
                                    action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action) {
        if self.hadFinish { return }
        var uploadAudio: Bool = false
        if case .uploadAndRecognize = consumptionState { uploadAudio = true }
        let sequenceId = self.seqRecognizeID
        self.seqRecognizeID += 1
        if action == .end { self.hadFinish = true }
        Self.logger.info("audio seqid \(self.seqRecognizeID) sequenceId \(sequenceId) data_len \(opusData.count)")
        self.audioRecognizeService?.speechRecognition(
            uploadID: recognizeID,
            sequenceId: sequenceId,
            audioData: opusData,
            action: action,
            speechLocale: self.speechLocale,
            uploadAudio: uploadAudio,
            callback: { _, error  in
                if let error {
                    Self.logger.error("audio record callback failed", error: error)
                }
            })
    }

    private func uploadStreamData(data: Data, isFinish: Bool, callback: ((Error?) -> Void)?) {
        guard case let .upload(canUpload: canUpload) = consumptionState, canUpload else { return }
        self.recordQueue.async {[weak self] in
            guard let self else { return }

            let opusData = self.opusStreamUtil?.encodePcmData(data, isEnd: isFinish) ?? Data()
            self.bufferData.append(opusData)
            if self.bufferData.count > self.bufferLimit || isFinish {
                self.uploadStreamDataInQueue(opusData: self.bufferData, isFinish: isFinish, callback: callback)
                self.bufferData.removeAll()
            }
            if isFinish {
                self.opusStreamUtil = nil
            }
        }
    }

    private func uploadStreamDataInQueue(opusData: Data, isFinish: Bool, callback: ((Error?) -> Void)?) {
        if self.hadFinish { return }
        let sequenceId = self.seqRecordID
        self.seqRecordID += 1
        if isFinish { self.hadFinish = true }
        let state: AudioRecognizeState
        if isFinish {
            switch self.finishStyle {
            case .finish:
                state = .uploadFinish(opusData)
            case .cancel:
                state = .cancel
            }
        } else {
            state = .data(opusData)
        }
        self.audioRecognizeService?.updateAudioState(uploadID: self.uploadID,
                                                     sequenceId: sequenceId,
                                                     state: state,
                                                     callback: { error in
            if let error { Self.logger.error("audio record callback failed", error: error) }
            callback?(error)
        })
    }
}

extension IMRecordServiceImpl: IMRecordService {
    var isRecording: Bool { state != .normal }
    var currentUploadId: String {
        self.uploadID
    }

    var currentRecognizeId: String {
        self.recognizeID
    }

    var result: Observable<AudioRecognizeResult>? {
        return audioRecognizeService?.result
    }

    func startRecord(useAveragePower: Bool, dataCallbackInterval: Float64, averagePowerCallbackInterval: TimeInterval, language: Lang?, from: NavigatorFrom?) {
        if self.isRecording { return }
        self.uploadID = getUploadID()
        self.recognizeID = getRecognizeID()
        self.speechLocale = AudioKeyboardDataService.generateLocaleIdentifier(lang: language ?? LanguageManager.currentLanguage)
        self.seqRecordID = 1
        self.seqRecognizeID = 1
        let id = UUID().uuidString
        currentTaskID = id
        self.bufferData.removeAll()
        self.hadFinish = false
        self.finishStyle = .finish
        self.state = .prepare
        guard let manager = audioRecordManager else { return }
        self.opusStreamUtil = OpusUtil.streamCodec(channelCount: Int32(manager.channel),
                                                    sampleRate: Int32(manager.sampleRate),
                                                    bitPerSample: Int32(manager.bitsPerChannel),
                                                    frameCountPerOggPage: oggPage)
        self.recognizeStreamData(data: Data(), action: .begin)
        manager.startRecord(delegate: self, from: from, useAveragePower: useAveragePower, dataCallbackInterval: dataCallbackInterval, averagePowerCallbackInterval: averagePowerCallbackInterval,
                            taskID: id)
    }

    func stop() {
        if self.isRecording {
            Self.logger.info("end record", additionalData: ["uploadid": self.uploadID])
            self.audioRecordManager?.stopRecord(taskID: currentTaskID)
            self.timer?.invalidate()
        }
    }

    func cancel() {
        if self.isRecording {
            Self.logger.info("cancel Record", additionalData: ["uploadid": self.uploadID])
            self.finishStyle = .cancel
            self.audioRecordManager?.cancelRecord(taskID: currentTaskID)
            self.timer?.invalidate()
        } else {
            Self.logger.info("abort upload audio", additionalData: ["uploadid": self.uploadID])
            if case .uploadAndRecognize = consumptionState {
                audioAPI?.abortUploadAudio(uploadID: uploadID).subscribe()
            }
        }
    }
}

extension IMRecordServiceImpl: RecordAudioDelegate {
    func audioRecordUpdateMetra(_ metra: Float) {
        delegate?.decibel(power: metra)
    }

    func audioRecordStreamData(data: Data) {
        delegate?.PCMData(data: data)
        self.recognizeStreamData(data: data, action: .unknown)
        self.uploadStreamData(data: data, isFinish: false, callback: nil)
    }

    func audioRecordStateChange(state: AudioRecordState) {
        Self.logger.info("audio record state change", additionalData: ["state": "\(state)", "id": "\(currentTaskID)"])
        switch state {
        case .cancel:
            self.state = .normal
            self.finishStyle = .cancel
            self.recognizeStreamData(data: Data(), action: .end)
            self.uploadStreamData(data: Data(), isFinish: true, callback: nil)
        case .failed:
            self.state = .normal
            self.hadFinish = true
            self.finishStyle = .cancel
            self.recognizeStreamData(data: Data(), action: .end)
            self.uploadStreamData(data: Data(), isFinish: true, callback: nil)
        case .tooShort:
            self.state = .normal
            self.finishStyle = .cancel
            self.recognizeStreamData(data: Data(), action: .end)
            self.uploadStreamData(data: Data(), isFinish: true, callback: nil)
        case .success:
            self.state = .normal
            self.recognizeStreamData(data: Data(), action: .end)
            self.uploadStreamData(data: Data(), isFinish: true, callback: nil)
        case .prepare:
            self.state = .prepare
        case .start:
            self.state = .recording
            audioPlayMediator?.syncStopPlayingAudio()
        }
        delegate?.stateChange(state: state)
    }

    func audioRecordStateChange(state: AudioRecordState, taskID: String) {
        guard taskID == currentTaskID else {
            Self.logger.error("state change is failed")
            return
        }
        audioRecordStateChange(state: state)
        if case .start = state {
            self.timer = CADisplayLink(target: self, selector: #selector(Self.updateRecordLengthLimit))
            self.timer?.preferredFramesPerSecond = Cons.timerFramesPerSecond
            self.timer?.add(to: RunLoop.main, forMode: .default)
            Self.logger.info("start recognition", additionalData: ["uploadid": self.uploadID, "recognizeid": self.recognizeID])
        }
    }

    func audioSessionInterruption() {
        delegate?.audioSessionInterruption()
    }
}
