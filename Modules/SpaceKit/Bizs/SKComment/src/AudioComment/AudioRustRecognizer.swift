//
//  AudioRecognizeService.swift
//  SpaceKit
//
//  Created by maxiao on 2019/4/16.
//  Copyright © 2019 ByteDance. All rights reserved.
// swiftlint:disable function_parameter_count

import RxSwift
import RustPB
import LarkRustClient
import LarkLocalizations
import LarkAudioKit
import SKFoundation

struct APIError {
    var type: APIError.TypeEnum
    var code: Int32
    var displayMessage: String
    var serverMessage: String

    init(code: Int32, displayMessage: String, serverMessage: String) {
        self.code = code
        self.displayMessage = displayMessage
        self.serverMessage = serverMessage
        self.type = TypeEnum(code, message: displayMessage)
    }

    init(type: APIError.TypeEnum) {
        self.code = 0
        self.displayMessage = ""
        self.serverMessage = ""
        self.type = type
    }
}

extension APIError {
    enum TypeEnum {
        case unknowError
        case recognitionWithEmptyResult

        init(_ errorCode: Int32, message: String) {
            switch errorCode {
            case 5_029: self = .recognitionWithEmptyResult
            default: self = .unknowError
            }
        }
    }
}

struct AudioRecognizeResult {
    public var uploadID: String
    public var seqID: Int32
    public var text: String
    public var finish: Bool
    public var diffIndexSlice: [Int32]

    public init(
        uploadID: String,
        seqID: Int32,
        text: String,
        finish: Bool,
        diffIndexSlice: [Int32] = []) {
        self.uploadID = uploadID
        self.seqID = seqID
        self.text = text
        self.finish = finish
        self.diffIndexSlice = diffIndexSlice
    }
}

protocol AudioRecognizeViewModelDelegate: AnyObject {
    func audioRecordUpdateRecordTime(time: TimeInterval)
    func audioRecordUpdateRecordVoice(power: Float)
    func audioRecordUpdateState(state: AudioRecognizeService.State)

    func audioRecordFinish(uploadID: String)
    func audioRecordWillStart(uploadID: String)
    func audioRecordDidStart(uploadID: String)
    func audioRecordDidCancel(uploadID: String)
    func audioRecordDidTooShort(uploadID: String)

    func audioRecordError(uploadID: String, error: Error)
}

protocol AudioRecognizeFacade {
    var result: Observable<AudioRecognizeResult> { get }

    func startRecognizing(language: Lang, useAveragePower: Bool)

    func endRecord()

    func cancelRecord()
}

class AudioRecognizeService: AudioRecognizeFacade {

    enum State {
        case normal             // 未录音
        case prepare            // 准备中
        case recording          // 录音中
    }

    private let audioAPI: AudioAPI
    private let disposeBag: DisposeBag = DisposeBag()

    weak var delegate: AudioRecognizeViewModelDelegate?
    
    var resultSubject: ReplaySubject<AudioRecognizeResult> = ReplaySubject<AudioRecognizeResult>.create(bufferSize: 1)
    var result: Observable<AudioRecognizeResult> { return resultSubject.asObserver() }

    private var lastResult: AudioRecognizeResult?

    private var lastRecognizeUploadID: String?
    private var lastRecognizeTime: TimeInterval = 0

    private let queue = DispatchQueue(label: "doc.audioRecognizeService", qos: .userInitiated)

    private var uploadID: String = "" {
        didSet {
            DocsLogger.info("[LarkMedia] uploadID did set to [\(uploadID)]", component: LogComponents.comment)
        }
    }
    private var failedUploadIDDict: [String: String] = [:]
    private var seqID: Int32 = 0
    private var hadFinish: Bool = false
    private var bufferData: Data = Data()

    private var speechLocale: String = LanguageManager.currentLanguage.localeIdentifier

    private var audioRecorder: AudioRecorder = AudioRecorder()
    private var opusStreamUtil: OpusStreamUtil?
    
    private var timer: CADisplayLink?
    
    private(set)  var state: State = .normal {
        didSet {
            self.delegate?.audioRecordUpdateState(state: state)
        }
    }
    
    var isRecording: Bool {
        return state != .normal
    }

    init(audioAPI: AudioAPI) {
        self.audioAPI = audioAPI
    }

    deinit {
        if !(audioRecorder.hasFinished || audioRecorder.hasCanceled) {
            audioRecorder.cancelRecord()
        }
    }

    func startRecognizing(language: Lang, useAveragePower: Bool = false) {
        speechLocale = language.localeIdentifier
        uploadID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        DocsLogger.info("[LarkMedia] init uploadID: \(uploadID)", component: LogComponents.comment)
        seqID = 1
        audioRecorder.delegate = self
        opusStreamUtil = OpusUtil.streamCodec(
            channelCount: Int32(audioRecorder.defaultRecordConfig.channel),
            sampleRate: Int32(audioRecorder.defaultRecordConfig.sampleRate),
            bitPerSample: Int32(audioRecorder.defaultRecordConfig.bitsPerChannel),
            frameCountPerOggPage: 2)
        hadFinish = false
        bufferData.removeAll()
        state = .prepare
        handleRecordStreamData(data: Data(), action: .begin, callback: nil)
        audioRecorder.startRecord()
        timer = CADisplayLink(target: self, selector: #selector(updateRecordLengthLimit))
        timer?.preferredFramesPerSecond = 30
        timer?.add(to: RunLoop.main, forMode: .default)
    }

    func endRecord() {
        if isRecording {
            audioRecorder.stopRecord()
            timer?.invalidate()
        }
    }

    func cancelRecord() {
        if isRecording {
            audioRecorder.cancelRecord()
            timer?.invalidate()
        }
    }

    @objc
    fileprivate func updateRecordLengthLimit() {
        if !isRecording {
            timer?.invalidate()
            return
        }
        self.delegate?.audioRecordUpdateRecordTime(time: audioRecorder.currentTime)
    }

    func speechRecognition(
        uploadID: String,
        sequenceId: Int32,
        audioData: Data,
        action: SendSpeechRecognitionRequest.Action,
        speechLocale: String,
        callback: ((AudioRecognizeResult?, Error?) -> Void)?) {
        lastRecognizeUploadID = uploadID
        lastRecognizeTime = Date().timeIntervalSince1970

        let deviceLocale: String = LanguageManager.currentLanguage.localeIdentifier

        audioAPI.speechRecognition(
            uploadID: uploadID,
            audioData: audioData,
            sequenceId: sequenceId,
            deviceLocale: deviceLocale.lowercased(),
            speechLocale: speechLocale.lowercased(),
            action: action,
            audioRate: 16_000,
            audioFormat: "opus",
            shouldDiffResult: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                var recognizeResult: AudioRecognizeResult?
                if response.isAvailable {
                    let result = AudioRecognizeResult(
                        uploadID: response.sourceID,
                        seqID: response.sequenceID,
                        text: response.result,
                        finish: response.isEnd,
                        diffIndexSlice: response.diffIndexSlice
                    )
                    DocsLogger.info("[LarkMedia] speechRecognition result:\(response.result)", component: LogComponents.comment)
                    self?.receiveAudioRecognizeResult(result: result, recognizeFailed: false)
                    if result.finish {
                        self?.cleanLastRecognizeUploadID(uploadID: response.sourceID)
                    }
                    recognizeResult = result
                } else {
                    DocsLogger.info("[LarkMedia] speechRecognition isAvailable false", component: LogComponents.comment)
                }
                callback?(recognizeResult, nil)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                DocsLogger.info("[LarkMedia] speechRecognition error:\(error)", component: LogComponents.comment)
                DocsLogger.info("speech recognitio data failed. uploadID: \(uploadID), seqID: \(sequenceId) error: \(error)")

                let result = AudioRecognizeResult(uploadID: uploadID, seqID: sequenceId, text: "", finish: true)
                self.receiveAudioRecognizeResult(result: result, recognizeFailed: true)
                callback?(result, error)
                self.cleanLastRecognizeUploadID(uploadID: uploadID)
            }).disposed(by: self.disposeBag)
    }

    func receiveAudioRecognizeResult(result: AudioRecognizeResult, recognizeFailed: Bool) {

        let sendResult = { (result: AudioRecognizeResult) in
            self.lastResult = result
            self.resultSubject.onNext(result)
        }

        var result = result
        // 第一次收到识别结果
        guard let last = self.lastResult else {
            sendResult(result)
            return
        }

        // 收到不同的识别结果
        if last.uploadID != result.uploadID {
            sendResult(result)
            return
        }

        // 如果新收到的结果不是最新的 则不发通知
        if last.finish ||
            last.seqID > result.seqID && !result.finish {
            return
        }

        // 识别错误继续使用上一次的结果
        if recognizeFailed {
            result.text = last.text
        }

        sendResult(result)
    }

    func cleanLastRecognizeUploadID(uploadID: String) {
        if uploadID == self.lastRecognizeUploadID {
            self.lastRecognizeUploadID = nil
        }
    }

    fileprivate func handleRecordStreamData(data: Data,
                                            action: SendSpeechRecognitionRequest.Action,
                                            callback: ((Error?) -> Void)?) {
        queue.async {
            let isFinish = action == .end
            let opusData = self.opusStreamUtil?.encodePcmData(data, isEnd: isFinish) ?? Data()
            self.bufferData.append(opusData)
            DocsLogger.info("[LarkMedia] bufferData size: \(self.bufferData.count)", component: LogComponents.comment)
            if self.bufferData.count > 200 || action != .unknown {
                let uploadID = self.uploadID
                self.handleRecordStreamDataInQueue(
                    opusData: self.bufferData,
                    action: action,
                    callback: { [weak self] error in
                        callback?(error)
                        // 如果发生错误提示报错
                        guard let self = self, let error = error else { return }
                        if self.uploadID == uploadID &&
                            self.failedUploadIDDict[uploadID] == nil &&
                            !uploadID.isEmpty {
                            self.failedUploadIDDict[uploadID] = uploadID
                            self.delegate?.audioRecordError(uploadID: uploadID, error: error)
                        }
                    })
                self.bufferData.removeAll()
            } else {
                DocsLogger.info("[LarkMedia] handle fail action:\(action) count:\(self.bufferData.count)", component: LogComponents.comment)
            }

            if isFinish {
                self.opusStreamUtil = nil
            }
        }
    }

    fileprivate func handleRecordStreamDataInQueue(
        opusData: Data,
        action: SendSpeechRecognitionRequest.Action,
        callback: ((Error?) -> Void)?
    ) {
        if self.hadFinish {
            return
        }
        let sequenceId = self.seqID
        self.seqID += 1
        let uploadID = self.uploadID
        if action == .end {
            self.hadFinish = true
            DocsLogger.info("[LarkMedia] uploadID set to empty", component: LogComponents.comment)
            self.uploadID = ""
        }

        speechRecognition(
            uploadID: uploadID,
            sequenceId: sequenceId,
            audioData: opusData,
            action: action,
            speechLocale: self.speechLocale,
            callback: { (result, error) in
                if error == nil,
                    let result = result,
                    result.finish {
                }
                callback?(error)
            })
    }
}

extension AudioRecognizeService {

    func handleRecordCancel() {
        DocsLogger.info("[LarkMedia] handleRecordCancel", component: LogComponents.comment)
        state = .normal
        if !uploadID.isEmpty {
            handleRecordStreamData(data: Data(), action: .end, callback: nil)
        }
        delegate?.audioRecordDidCancel(uploadID: uploadID)
    }

    func handleRecordTooShort() {
        DocsLogger.info("[LarkMedia] recordTooShort", component: LogComponents.comment)
        state = .normal
        if !uploadID.isEmpty {
            handleRecordStreamData(data: Data(), action: .end, callback: nil)
        }
        delegate?.audioRecordDidCancel(uploadID: uploadID)
    }

    func handleRecordSuccess(pcmdata: Data, recordTime: TimeInterval) {
        DocsLogger.info("[LarkMedia] recordSuccess size: \(pcmdata.count)", component: LogComponents.comment)
        state = .normal
        delegate?.audioRecordFinish(uploadID: uploadID)
        handleRecordStreamData(data: Data(), action: .end, callback: { error in
            if let error = error {
                DocsLogger.info("audio recognize callback failed error:\(error)")
            }
        })
    }

    func handleDevicePrepareToRecord() {
        state = .prepare
    }

    func handleStartRecord() {
        state = .recording
        delegate?.audioRecordDidStart(uploadID: uploadID)
    }
}

extension AudioRecognizeService: AudioRecorderDelegate {
    func audioRecorder(_ audioRecorder: AudioRecorder,
                       didChanged state: AudioRecorder.AudioRecordState) {
        DocsLogger.info("[LarkMedia] audioRecorder state:\(state)", component: LogComponents.comment)
        switch state {
        case .cancel, .failed:
            DocsLogger.info("[LarkMedia] audioRecorder state cancel or failed", component: LogComponents.comment)
            handleRecordCancel()
        case .tooShort:
            handleRecordTooShort()
        case let .success(_, pcmData, duration):
            handleRecordSuccess(pcmdata: pcmData, recordTime: duration)
        case .prepare:
            handleDevicePrepareToRecord()
        case .start:
            handleStartRecord()
        }
    }

    func audioRecorder(_ audioRecorder: AudioRecorder,
                       didReceived data: Data) {
        DocsLogger.info("[LarkMedia] didReceived audio data:\(data.count) uploadID:\(uploadID)", component: LogComponents.comment)
        if !uploadID.isEmpty {
            handleRecordStreamData(data: data, action: .unknown, callback: nil)
        }
    }

    func audioRecorder(_ audioRecorder: AudioRecorder,
                       didReceived powerData: Float32) {
        delegate?.audioRecordUpdateRecordVoice(power: powerData)
    }
}
