//
//  AudioToTextViewModel.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import RxSwift
import RxCocoa
import LarkModel
import Foundation
import EENavigator
import LarkContainer
import LarkSDKInterface
import LarkLocalizations
import LarkMessengerInterface

// 语音转文字
typealias AbstractAudioToTextViewModel = IMRecordServiceDelegate & InAudioToTextAbstractViewModelByView & KeyboardProvider

// 语音转文字。viewModel 实现，view 调用
protocol InAudioToTextAbstractViewModelByView {
    var chat: Chat { get }
    var isRecording: Bool { get }
    var viewDelegate: InAudioToTextAbstractViewByViewModel? { get set }
    var keyboard: AudioSendMessageDelegate? { get set }
    func startRecord(language: Lang, from: NavigatorFrom?)
    func end() // stop
    func sendText()
    func cancel()
    func reset()
}

final class AudioToTextViewModel: UserResolverWrapper, AbstractAudioToTextViewModel {
    enum Cons {
        static let dataCallbackInterval: Float64 = 0.05
        static let averagePowerCallbackInterval: Double = 0.1
    }
    let userResolver: UserResolver
    let chat: Chat
    weak var keyboard: AudioSendMessageDelegate?
    weak var viewDelegate: InAudioToTextAbstractViewByViewModel?
    private var voiceService: IMRecordService

    // 一次录音结束，需要清理
    private var lastResult: AudioRecognizeResult?
    private var audioDisposeBag = DisposeBag()
    init(userResolver: UserResolver, chat: Chat, keyboard: AudioSendMessageDelegate?) {
        self.userResolver = userResolver
        self.chat = chat
        self.keyboard = keyboard
        voiceService = IMRecordServiceImpl(userResolver: userResolver, chatID: chat.id, consumptionState: .recognize)
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

// MARK: IMRecordServiceDelegate
extension AudioToTextViewModel {
    func PCMData(data: Data) { }

    func decibel(power: Float) {
        viewDelegate?.updateDecibel(decibel: power)
    }

    func recordTime(time: TimeInterval) { }

    func stateChange(state: AudioRecordState) {
        viewDelegate?.updateState(state: state)
    }

    func audioSessionInterruption() {
        viewDelegate?.audioSessionInterruption()
    }
}

// MARK: InAudioToTextAbstractViewModelByView
// vm 实现，view 调用
extension AudioToTextViewModel {
    var isRecording: Bool { voiceService.isRecording }

    func startRecord(language: Lang, from: NavigatorFrom?) {
        voiceService.startRecord(useAveragePower: false, dataCallbackInterval: Cons.dataCallbackInterval,
                                 averagePowerCallbackInterval: Cons.averagePowerCallbackInterval, language: language, from: from)
        observeResult()
        AudioTracker.imChatVoiceMsgClick(click: .holdToTalk, viewType: .text)
    }

    func end() {
        voiceService.stop()
    }

    func sendText() {
        keyboard?.sendMessageWhenRecognition()
        AudioTracker.imChatVoiceMsgClick(click: .send, viewType: .text)
    }

    func cancel() {
        if let keyboardView = keyboard?.audiokeybordPanelView() {
            keyboardView.attributedString = NSMutableAttributedString(string: "")
        }
        AudioTracker.imChatVoiceMsgClick(click: .empty, viewType: .text)
    }

    func reset() {
        audioDisposeBag = DisposeBag()
        lastResult = nil
    }
}

// MARK: KeyboardProvider
// VM实现，keyboard调用
extension AudioToTextViewModel {
    func cleanMaskView() { }
    func trackAudioRecognizeIfNeeded() { }
    func cleanAudioRecognizeState() { }
}
