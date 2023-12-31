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
import LarkSDKInterface
import LarkSendMessage
import LarkContainer

final class NewRecordViewModel: UserResolverWrapper {

    private enum FinishStyle {
        case finish
        case cancel
        case recognition
    }

    @ScopedInjectedLazy var audioRecordManager: AudioRecordManager?

    fileprivate static let logger = Logger.log(NewRecordViewModel.self, category: "LarkAudio")

    weak var delegate: AudioRecordViewModelDelegate?

    private var uploadIdBlock: () -> String
    private var audioRecognizeService: AudioRecognizeService?
    private var opusStreamUtil: OpusStreamUtil?
    private var hadFinish: Bool = false
    private var bufferData: Data = Data()

    private let queue = DispatchQueue(label: "audio.record.view.model", qos: .userInitiated)

    private var uploadID: String = ""
    private var seqID: Int32 = 0

    var isRecording: Bool {
        return state != .normal
    }
    fileprivate(set) var state: AudioState = .normal {
        didSet {
            self.delegate?.audioRecordUpdateState(state: state)
        }
    }
    private var finishStyle: FinishStyle = .finish

    private var timer: CADisplayLink?

    let userResolver: UserResolver
    init(
        userResolver: UserResolver,
        audioRecognizeService: AudioRecognizeService?,
        uploadIdBlock: @escaping () -> String) {
        self.userResolver = userResolver
        self.uploadIdBlock = uploadIdBlock
        self.audioRecognizeService = audioRecognizeService
    }

    deinit {
        if self.audioRecordManager?.delegate === self {
            AudioRecordManager.logger.info("cancel when deinit in audio record")
            self.audioRecordManager?.delegate = nil
            self.audioRecordManager?.cancelRrcordIfNeeded()
        } else {
            AudioRecordManager.logger.info("deinit AudioRecordViewModel")
        }
    }

    func startRecordAudio() {
        self.startRecord(recognition: false, useAveragePower: true)
    }

    private func startRecord(recognition: Bool, useAveragePower: Bool = false) {
        AudioTracker.trackLongpressAudioKeyboard(from: .audioMenu)
        if self.isRecording { return }
        self.uploadID = self.uploadIdBlock()
        self.delegate?.audioRecordWillStart(uploadID: self.uploadID)
        self.seqID = 1
        guard let manager = self.audioRecordManager else { return }
        self.opusStreamUtil = OpusUtil.streamCodec(
            channelCount: Int32(manager.channel),
            sampleRate: Int32(manager.sampleRate),
            bitPerSample: Int32(manager.bitsPerChannel))
        self.bufferData.removeAll()
        self.hadFinish = false
        self.finishStyle = recognition ? .recognition : .finish
        self.audioRecordManager?.delegate = self
        self.state = .prepare
        self.audioRecordManager?.startRecord(
            useAveragePower: useAveragePower,
            averagePowerCallbackInterval: 0.05
        ) { [weak self] result in
            guard let self = self else { return }
            if result {
                self.timer = CADisplayLink(target: self, selector: #selector(Self.updateRecordLengthLimit))
                self.timer?.preferredFramesPerSecond = 30
                self.timer?.add(to: RunLoop.main, forMode: .default)
                NewRecordViewModel.logger.info("start recognition", additionalData: ["uploadid": self.uploadID])
            } else {
                if self.state != .normal {
                    self.state = .normal
                    self.hadFinish = true
                    self.delegate?.audioRecordStartFailed(uploadID: self.uploadID)
                    NewRecordViewModel.logger.error("start recognition failed", additionalData: ["uploadid": self.uploadID])
                }
            }
        }
    }

    func endRecord() {
        NewRecordViewModel.logger.info("end Record", additionalData: ["uploadid": self.uploadID])

        if self.isRecording {
            self.audioRecordManager?.stopRecord()
            self.timer?.invalidate()
        }
    }

    func cancelRecord() {
        NewRecordViewModel.logger.info("cancel Record", additionalData: ["uploadid": self.uploadID])

        if self.isRecording {
            self.finishStyle = .cancel
            self.audioRecordManager?.cancelRrcord()
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

extension NewRecordViewModel {
    fileprivate func handleUpdateMetra(_ metra: Float) {
        self.delegate?.audioRecordUpdateRecordVoice(power: metra)
    }

    fileprivate func handleRecordCancel() {
        self.state = .normal
        self.finishStyle = .cancel
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: Data(), isFinish: true, callback: nil)
        }
        self.delegate?.audioRecordDidCancel(uploadID: self.uploadID)
    }

    fileprivate func handleRecordFailed() {
        self.state = .normal
        self.hadFinish = true
        self.finishStyle = .cancel
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: Data(), isFinish: true, callback: nil)
        }
        self.delegate?.audioRecordStartFailed(uploadID: self.uploadID)
    }

    fileprivate func handleRecordTooShort() {
        self.state = .normal
        self.finishStyle = .cancel
        if !self.uploadID.isEmpty {
            self.handleRecordStreamData(data: Data(), isFinish: true, callback: nil)
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

        if uploadID.isEmpty {
            self.state = .normal
            // 原始发语音消息逻辑
            self.delegate?.audioRecordFinish(
                AudioDataInfo(
                    data: pcmdata,
                    length: recordTime,
                    type: .pcm,
                    uploadID: uploadID
                )
            )
        } else {
            self.state = .normal

            // 发送语音最后一片
            self.handleRecordStreamData(data: Data(), isFinish: true, callback: { error in
                if let error = error {
                    NewRecordViewModel.logger.error("audio record callback failed", error: error)
                }
            })

            // 新的发语音消息逻辑
            self.delegate?.audioRecordFinish(uploadID: uploadID, duration: recordTime)
        }
    }

    fileprivate func handleRecordStreamData(data: Data, isFinish: Bool, callback: ((Error?) -> Void)?) {
        if isFinish {
            NewRecordViewModel.logger.info("handle record finish", additionalData: ["uploadid": self.uploadID])
        }
        self.queue.async {
            if isFinish {
                NewRecordViewModel.logger.info("handle record finish in queue", additionalData: ["uploadid": self.uploadID])
            }
            let opusData = self.opusStreamUtil?.encodePcmData(data, isEnd: isFinish) ?? Data()
            self.bufferData.append(opusData)
            if self.bufferData.count > 2 * 1024 || isFinish {
                self.handleRecordStreamDataInQueue(
                    opusData: self.bufferData,
                    isFinish: isFinish,
                    callback: callback)
                self.bufferData.removeAll()
            }
            /// clean opus util when record finish
            if isFinish {
                self.opusStreamUtil = nil
            }
        }
    }

    fileprivate func handleRecordStreamDataInQueue(opusData: Data, isFinish: Bool, callback: ((Error?) -> Void)?) {
        if self.hadFinish {
            return
        }
        let sequenceId = self.seqID
        self.seqID += 1
        if isFinish {
            self.hadFinish = true
        }
        let state: AudioRecognizeState
        NewRecordViewModel.logger.info(
            "audio seqid \(self.seqID) sequenceId \(sequenceId) data_len \(opusData.count)"
        )
        if isFinish {
            switch self.finishStyle {
            case .finish:
                state = .uploadFinish(opusData)
            case .cancel:
                state = .cancel
            case .recognition:
                state = .recognizeFinish(opusData)
            }
        } else {
            if self.finishStyle == .recognition {
                state = .recognizeData(opusData)
            } else {
                state = .data(opusData)
            }
        }
        self.audioRecognizeService?
            .updateAudioState(
                uploadID: self.uploadID,
                sequenceId: sequenceId,
                state: state,
                callback: callback)
    }
}

extension NewRecordViewModel: RecordAudioDelegate {

    func audioRecordUpdateMetra(_ metra: Float) {
        self.handleUpdateMetra(metra)
    }

    func audioRecordStateChange(state: AudioRecordState) {
        NewRecordViewModel.logger.info("audio record state change", additionalData: ["state": "\(state)"])
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
            self.handleRecordStreamData(data: data, isFinish: false, callback: nil)
        }
    }
}
