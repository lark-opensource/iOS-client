//
//  RecordAudioKeyboardViewModel.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/6/3.
//

import Foundation
import AVFoundation
import SnapKit
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkUIKit
import EditTextView
import LarkLocalizations
import LarkFoundation
import UniverseDesignToast
import LarkAudioKit
import LarkModel
import LarkSDKInterface
import RustPB
import LarkFeatureGating
import LarkSetting
import LarkContainer

final class NewAudioWithTextRecordViewModel: UserResolverWrapper {

    fileprivate static let logger = Logger.log(NewAudioWithTextRecordViewModel.self, category: "LarkAudio")

    weak var delegate: AudioWithTextRecordViewModelDelegate?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?
    @ScopedInjectedLazy var audioRecordManager: AudioRecordManager?

    private(set) var audioRecognizeService: AudioRecognizeService?
    private var opusStreamUtil: OpusStreamUtil?
    private var hadFinish: Bool = false
    private var bufferData: Data = Data()

    private let queue = DispatchQueue(label: "audio.record.text.view.model", qos: .userInitiated)

    var uploadID: String = ""
    var hasResult: PublishSubject<Bool> = PublishSubject<Bool>()
    var hasFinshed: PublishSubject<Bool> = PublishSubject<Bool>()
    lazy var netErrorOptimizeEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "ai.asr.opt.no_network")
    private var failedUploadIDDict: [String: String] = [:]

    private var seqID: Int32 = 0
    private var speechLocale: String = AudioKeyboardDataService.generateLocaleIdentifier(lang: LanguageManager.currentLanguage)

    var isRecording: Bool {
        return state != .normal
    }
    fileprivate(set) var state: AudioState = .normal {
        didSet {
            self.delegate?.audioRecordUpdateState(state: state)
        }
    }

    private var timer: CADisplayLink?

    private let from: AudioTracker.From

    private var disposeBag = DisposeBag()
    let userResolver: UserResolver
    init(userResolver: UserResolver, audioRecognizeService: AudioRecognizeService?, from: AudioTracker.From) {
        self.userResolver = userResolver
        self.audioRecognizeService = audioRecognizeService
        self.from = from
    }

    deinit {
        if self.audioRecordManager?.delegate === self {
            AudioRecordManager.logger.info("cancel when deinit in audio with text")
            self.audioRecordManager?.delegate = nil
            self.audioRecordManager?.cancelRrcordIfNeeded()
        } else {
            AudioRecordManager.logger.info("deinit AudioWithTextRecordViewModel")
        }
    }

    func startRecognition(language: Lang, useAveragePower: Bool = false) {
        if self.isRecording { return }
        self.speechLocale = AudioKeyboardDataService.generateLocaleIdentifier(lang: language)
        self.uploadID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        self.delegate?.audioRecordWillStart(uploadID: self.uploadID)
        self.seqID = 1
        self.hadFinish = false
        guard let manager = self.audioRecordManager else { return }
        self.opusStreamUtil = OpusUtil.streamCodec(
            channelCount: Int32(manager.channel),
            sampleRate: Int32(manager.sampleRate),
            bitPerSample: Int32(manager.bitsPerChannel),
            frameCountPerOggPage: 2)
        self.bufferData.removeAll()
        self.audioRecordManager?.delegate = self
        self.state = .prepare
        self.handleRecordStreamData(data: Data(), action: .begin, callback: nil)

        self.audioRecordManager?.startRecord(
            useAveragePower: useAveragePower,
            dataCallbackInterval: 0.05,
            averagePowerCallbackInterval: 0.05
        ) { [weak self] result in
            guard let self = self else { return }
            if result {
                self.timer = CADisplayLink(target: self, selector: #selector(Self.updateRecordLengthLimit))
                self.timer?.preferredFramesPerSecond = 30
                self.timer?.add(to: RunLoop.main, forMode: .default)
                NewAudioWithTextRecordViewModel.logger.info("start recognition", additionalData: ["uploadid": self.uploadID])
            } else {
                if self.state != .normal {
                    self.state = .normal
                    self.hadFinish = true
                    self.delegate?.audioRecordStartFailed(uploadID: self.uploadID)
                    NewAudioWithTextRecordViewModel.logger.error("start recognition failed", additionalData: ["uploadid": self.uploadID])
                }
            }
        }
    }

    func endRecord() {
        NewAudioWithTextRecordViewModel.logger.info("end record", additionalData: ["uploadid": self.uploadID])
        if self.isRecording {
            self.audioRecordManager?.stopRecord()
            self.timer?.invalidate()
        }
    }

    @objc
    fileprivate func updateRecordLengthLimit() {
        if !self.isRecording {
            self.timer?.invalidate()
            return
        }
        self.delegate?.audioRecordUpdateRecordTime(time: self.audioRecordManager?.currentTime ?? 0)
    }
}

extension NewAudioWithTextRecordViewModel {
    fileprivate func handleUpdateMetra(_ metra: Float) {
        AudioReciableTracker.shared.audioRecognitionReceivePower(sessionID: self.uploadID, power: metra)
        self.delegate?.audioRecordUpdateRecordVoice(power: metra)
    }

    fileprivate func handleRecordCancel() {
        self.state = .normal
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: Data(), action: .end, callback: nil)
        }
        self.delegate?.audioRecordDidCancel(uploadID: self.uploadID)
    }

    fileprivate func handleRecordFailed() {
        self.state = .normal
        self.hadFinish = true
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: Data(), action: .end, callback: nil)
        }
        self.delegate?.audioRecordStartFailed(uploadID: self.uploadID)
    }

    fileprivate func handleRecordTooShort() {
        self.state = .normal
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: Data(), action: .end, callback: nil)
        }
        self.delegate?.audioRecordDidTooShort(uploadID: self.uploadID)
    }

    fileprivate func handleDevicePrepareToRecord() {
        self.state = .prepare
    }

    fileprivate func handleStartRecord() {
        self.state = .recording
        self.delegate?.audioRecordDidStart(uploadID: self.uploadID)
    }

    fileprivate func handleRecordSuccess(pcmdata: Data, recordTime: TimeInterval) {
        let uploadID = self.uploadID
        self.state = .normal
        self.handleRecordStreamData(data: Data(), action: .end, callback: { error in
            if let error = error {
                NewAudioWithTextRecordViewModel.logger.error("audio recognize callback failed", error: error)
            }
        })
        self.delegate?.audioRecordFinish(uploadID: uploadID, audioData: pcmdata, duration: recordTime)
    }

    fileprivate func handleRecordStreamData(
        data: Data,
        action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action,
        callback: ((Error?) -> Void)?) {

        if action != .unknown {
            NewAudioWithTextRecordViewModel.logger.info("handle record data", additionalData: ["uploadid": self.uploadID, "action": "\(action)"])
        }
        self.queue.async {
            if action != .unknown {
                NewAudioWithTextRecordViewModel.logger.info("handle record data in queue", additionalData: ["uploadid": self.uploadID, "action": "\(action)"])
            }
            let isFinish = action == .end
            let opusData = self.opusStreamUtil?.encodePcmData(data, isEnd: isFinish) ?? Data()
            self.bufferData.append(opusData)

            /// if bufferData > 200 byte,  send one audio speech request, about 10 times per second
            if self.bufferData.count > 200 || action != .unknown {
                let uploadID = self.uploadID
                self.handleRecordStreamDataInQueue(
                    opusData: self.bufferData,
                    action: action,
                    callback: { [weak self] error in
                        callback?(error)

                        // 如果发生错误提示报错
                        guard let `self` = self, let error = error else { return }
                        if self.uploadID == uploadID &&
                            self.failedUploadIDDict[uploadID] == nil &&
                            !uploadID.isEmpty {
                            self.failedUploadIDDict[uploadID] = uploadID
                            self.delegate?.audioRecordError(uploadID: uploadID, error: error)
                        }
                    })
                self.bufferData.removeAll()
            }
            /// clean opus util when record finish
            if isFinish {
                self.opusStreamUtil = nil
            }
        }
    }

    fileprivate func handleRecordStreamDataInQueue(
        opusData: Data,
        action: RustPB.Im_V1_SendSpeechRecognitionRequest.Action,
        callback: ((Error?) -> Void)?
        ) {
        if self.hadFinish {
            return
        }
        let uploadID = self.uploadID
        let sequenceId = self.seqID
        self.seqID += 1
            NewAudioWithTextRecordViewModel.logger.info(
            "audio seqid \(self.seqID) sequenceId \(sequenceId) data_len \(opusData.count)"
        )
        if action == .end {
            self.hadFinish = true
            audioTracker?.asrSendEndPacket(sessionId: uploadID)
        }
        let from = self.from
        self.audioRecognizeService?.speechRecognition(
            uploadID: uploadID,
            sequenceId: sequenceId,
            audioData: opusData,
            action: action,
            speechLocale: self.speechLocale,
            uploadAudio: userResolver.fg.staticFeatureGatingValue(with: "messenger.audiowithtext.recognition.and.upload"),
            callback: { [weak self] (result, error) in
                guard let self = self else { return }
                if error == nil,
                    let result = result,
                    result.uploadID == self.uploadID {
                    if result.finish {
                        self.hasFinshed.onNext(true)
                        self.audioTracker?.asrReceiveEndResponse(sessionId: uploadID, isSuccess: true)
                    }
                    if !result.text.isEmpty {
                        self.hasResult.onNext(true)
                    }
                    AudioTracker.trackSpeechToText(hasResult: !result.text.isEmpty, from: from)
                } else {
                    self.audioTracker?.asrReceiveEndResponse(sessionId: uploadID, isSuccess: false)
                }
                if !self.userResolver.fg.staticFeatureGatingValue(with: "messenger.audio.technology.new.design") {
                    if let result = result, result.uploadID == self.uploadID,
                       (result.finish || error != nil) {
                        self.uploadID = ""
                    }
                }
                callback?(error)
            })
    }

}

extension NewAudioWithTextRecordViewModel: RecordAudioDelegate {

    func audioRecordUpdateMetra(_ metra: Float) {
        self.handleUpdateMetra(metra)
    }

    func audioRecordStateChange(state: AudioRecordState) {
        NewAudioWithTextRecordViewModel.logger.info("audio record state change", additionalData: ["state": "\(state)"])
        switch state {
        case .cancel:
            self.handleRecordCancel()
        case .failed:
            self.handleRecordFailed()
        case .tooShort:
            self.handleRecordTooShort()
        case let .success(data, duration):
            self.handleRecordSuccess(pcmdata: data, recordTime: duration)
        case .prepare:
            self.handleDevicePrepareToRecord()
        case .start:
            self.handleStartRecord()
        }
    }

    func audioRecordStreamData(data: Data) {
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: data, action: .unknown, callback: nil)
        }
    }
}
