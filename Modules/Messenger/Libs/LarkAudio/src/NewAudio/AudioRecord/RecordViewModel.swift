//
//  RecordViewModel.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/15.
//

import RxSwift
import RxCocoa
import Foundation
import LarkContainer
import LarkSDKInterface
import LarkLocalizations
import LarkMessengerInterface
import LarkSendMessage
import AVFAudio
import EENavigator

// viewModel实现，view调用
protocol InRecordAbstractViewModelByView {
    var viewDelegate: InRecordAbstractViewByViewModel? { get set }
    var keyboard: AudioSendMessageDelegate? { get set }
    var isRecording: Bool { get }
    func startRecord(from: NavigatorFrom?)
    func end() // stop + send
    func cancel()
}

// VM实现，keyboard调用
protocol KeyboardProvider: AudioRecordPanelProtocol {
    var keyboard: AudioSendMessageDelegate? { get set }
}

// 录音
typealias AbstractRecordViewModel = IMRecordServiceDelegate & InRecordAbstractViewModelByView & KeyboardProvider

final class RecordViewModel: AbstractRecordViewModel, UserResolverWrapper {
    enum Cons {
        static let dataCallbackInterval: Float64 = 0.1
        static let averagePowerCallbackInterval: Double = 0.05
    }
    let userResolver: UserResolver
    weak var keyboard: AudioSendMessageDelegate?
    weak var viewDelegate: InRecordAbstractViewByViewModel?
    private var voiceService: IMRecordService
    private let supportStreamUpLoad: Bool

    /// - Parameters:
    ///   - userResolver: 容器
    ///   - notVTT: not voice to Text. 不支持语音转文字
    ///   - chatID: chat.id
    init(userResolver: UserResolver, supportStreamUpLoad: Bool, chatID: String, keyboard: AudioSendMessageDelegate?) {
        self.userResolver = userResolver
        self.supportStreamUpLoad = supportStreamUpLoad
        self.keyboard = keyboard
        voiceService = IMRecordServiceImpl(userResolver: userResolver, chatID: chatID, consumptionState: .upload(canUpload: supportStreamUpLoad))
        voiceService.delegate = self
    }
}

// MARK: InRecordAbstractViewModelByView
extension RecordViewModel {
    var isRecording: Bool { voiceService.isRecording }
    func startRecord(from: NavigatorFrom?) {
        voiceService.startRecord(useAveragePower: true, dataCallbackInterval: Cons.dataCallbackInterval,
                                 averagePowerCallbackInterval: Cons.averagePowerCallbackInterval, language: nil, from: from)
        AudioTracker.imChatVoiceMsgClick(click: .holdToTalk, viewType: .audio)
    }
    func end() {
        // stop 硬件
        voiceService.stop()
    }
    func cancel() {
        // stop 硬件
        voiceService.cancel()
    }
}

// MARK: IMRecordServiceDelegate
extension RecordViewModel {
    func PCMData(data: Data) { }

    func decibel(power: Float) {
        viewDelegate?.updateDecibel(decibel: power)
    }

    func stateChange(state: AudioRecordState) {
        switch state {
        case .cancel:
            break
        case .failed:
            break
        case .tooShort:
            break
        case let .success(data, duration):
            // sendAudio
            if !supportStreamUpLoad || voiceService.currentUploadId.isEmpty {
                keyboard?.audiokeybordSendMessage(AudioDataInfo(data: data, length: duration, type: .pcm, uploadID: ""))
            } else {
                keyboard?.audiokeybordSendMessage(audioInfo: StreamAudioInfo(uploadID: voiceService.currentUploadId, length: duration))
            }
        case .prepare: break
        case .start: break
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
// MARK: KeyboardProvider
// VM实现，keyboard调用
extension RecordViewModel {
    func cleanMaskView() { }
    func trackAudioRecognizeIfNeeded() { }
    func cleanAudioRecognizeState() { }
}
