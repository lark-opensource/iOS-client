//
//  AudioAndTextViewModel.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import RxSwift
import RxCocoa
import Foundation
import EENavigator
import LarkAudioKit
import LarkContainer
import LarkSendMessage
import LarkSDKInterface
import LarkLocalizations
import LarkMessengerInterface

// viewModel实现，view调用
protocol InAudioAndTextAbstractViewModelByView {
    var viewDelegate: InAudioAndTextAbstractViewByViewModel? { get set }
    var keyboard: AudioSendMessageDelegate? { get set }
    var isRecording: Bool { get }
    func startRecord(language: Lang, from: NavigatorFrom?)
    func end()
    func reset()
    func cancel()
    func sendText(str: String)
    func sendAudio()
    func sendAll(str: String)
}

// 语音加文字
typealias AbstractAudioAndTextViewModel = IMRecordServiceDelegate & InAudioAndTextAbstractViewModelByView & KeyboardProvider

final class AudioAndTextViewModel: UserResolverWrapper, AbstractAudioAndTextViewModel {
    enum Cons {
        static let dataCallbackInterval: Float64 = 0.05
        static let averagePowerCallbackInterval: Double = 0.05
    }

    let userResolver: UserResolver
    weak var keyboard: AudioSendMessageDelegate?
    weak var viewDelegate: InAudioAndTextAbstractViewByViewModel?
    private var voiceService: IMRecordService

    // 一次录音结束，需要清理
    private var lastResult: AudioRecognizeResult?
    private var audioDisposeBag = DisposeBag()
    private var audioData = Data()
    private var audioLength: TimeInterval = 0

    init(userResolver: UserResolver, chatID: String, keyboard: AudioSendMessageDelegate?) {
        self.userResolver = userResolver
        self.keyboard = keyboard
        voiceService = IMRecordServiceImpl(userResolver: userResolver, chatID: chatID, consumptionState: .uploadAndRecognize)
        voiceService.delegate = self
    }

    private func observeResult() {
        audioDisposeBag = DisposeBag()
        voiceService.result?.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] result in
            guard let self, result.uploadID == self.voiceService.currentRecognizeId else { return }
            if let lastResult = self.lastResult, !result.finish, lastResult.text == result.text, lastResult.diffIndexSlice == result.diffIndexSlice { return }
            self.viewDelegate?.updateTextResult(text: result.text, finish: result.finish, diffIndexSlice: result.diffIndexSlice)
            self.lastResult = result
        }).disposed(by: audioDisposeBag)
    }
}

// InAudioAndTextAbstractViewModelByView
// MARK: view 调用
extension AudioAndTextViewModel {
    var isRecording: Bool { voiceService.isRecording }

    func startRecord(language: Lang, from: NavigatorFrom?) {
        voiceService.startRecord(useAveragePower: true, dataCallbackInterval: Cons.dataCallbackInterval,
                                 averagePowerCallbackInterval: Cons.averagePowerCallbackInterval, language: language, from: from)
        observeResult()
        AudioTracker.imChatVoiceMsgClick(click: .holdToTalk, viewType: .audioWithText)
    }

    func end() {
        voiceService.stop()
    }

    func cancel() {
        voiceService.cancel()
        AudioTracker.imChatVoiceMsgClick(click: .empty, viewType: .audioWithText)
    }

    func sendText(str: String) {
        keyboard?.audioSendTextMessage(str: str)
        AudioTracker.imChatVoiceMsgClick(click: .onlyText, viewType: .audioWithText)
    }

    func sendAudio() {
        guard let opusData = OpusUtil.encode_wav_data(audioData) else { return }
        let audioInfo = AudioDataInfo(
            data: opusData,
            length: audioLength,
            type: .opus,
            uploadID: voiceService.currentUploadId
        )
        keyboard?.audiokeybordSendMessage(audioInfo)
        AudioTracker.imChatVoiceMsgClick(click: .onlyVoice, viewType: .audioWithText)
    }

    func sendAll(str: String) {
        guard let opusData = OpusUtil.encode_wav_data(audioData) else { return }
        let audioInfo = AudioDataInfo(data: opusData, length: audioLength, type: .opus, text: str, uploadID: voiceService.currentUploadId)
        keyboard?.audiokeybordSendMessage(audioInfo)
        AudioTracker.imChatVoiceMsgClick(click: .send, viewType: .audioWithText)
    }

    // 界面变成 idle 状态会被调用
    func reset() {
        lastResult = nil
        audioDisposeBag = DisposeBag()
        audioData = Data()
        audioLength = 0
    }
}

// IMRecordServiceDelegate
// MARK: 回调给 View
extension AudioAndTextViewModel {
    func PCMData(data: Data) { }

    func decibel(power: Float) {
        viewDelegate?.updateDecibel(decibel: power)
    }

    func stateChange(state: AudioRecordState) {
        switch state {
        case .cancel: break
        case .start: break
        case .tooShort: break
        case .prepare: break
        case .failed(_): break
        case .success(let data, let length):
            audioData = data
            audioLength = length
        }
        viewDelegate?.updateState(state: state)
    }

    func recordTime(time: TimeInterval) {
        viewDelegate?.updateTime(time: time)
    }

    func audioSessionInterruption() {
        viewDelegate?.audioSessionInterruption()
    }
}

// KeyboardProvider
// MARK: keyboard调用
extension AudioAndTextViewModel {
    func cleanMaskView() { }
    func trackAudioRecognizeIfNeeded() { }
    func cleanAudioRecognizeState() { }
}
