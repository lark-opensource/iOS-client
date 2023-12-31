//
//  AudioActionsService.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/15.
//

import UIKit
import Foundation
import LarkAudio
import LarkModel
import LKCommonsLogging
import RxSwift
import Swinject
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import RustPB

typealias AudiosProvider = () -> [AudioPlayable]

public final class AudioActionsService {
    static var logger = Logger.log(AudioActionsService.self, category: "lark.chat.play.audio")

    var dataProvider: AudiosProvider?
    var showStatusView: Bool = false
    var shouldPlayContinuously: Bool = false
    private var audioPlayMediator: AudioPlayMediator?
    private weak var targetVC: UIViewController?
    private let currentChatterId: String
    private var messageAPI: MessageAPI?
    private let needPutRead: Bool
    private let showNewTips: Bool

    init(
        messageAPI: MessageAPI?,
        audioPlayMediator: AudioPlayMediator?,
        currentChatterId: String,
        targetVC: UIViewController,
        needPutRead: Bool,
        showNewTips: Bool) {
        self.audioPlayMediator = audioPlayMediator
        self.currentChatterId = currentChatterId
        self.messageAPI = messageAPI
        self.targetVC = targetVC
        self.needPutRead = needPutRead
        self.showNewTips = showNewTips
        observeAudioPlayingStatus()
    }

    private var isFirstPlay = true
    private var lastPlayAudioKey = ""
    private let disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "audio.actions.queue", qos: .userInteractive)

    /// 播放语音,自动进行连播
    func playAudio(model: Message, status: AudioPlayMediatorStatus? = nil, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
        self.queue.async {
            self.playAudioInQueue(model: model, status: status, downloadFileScene: downloadFileScene)
        }
    }

    private func playAudioInQueue(model: Message, status: AudioPlayMediatorStatus?, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
        guard let audioContent = model.content as? AudioContent, let audioPlayMediator = audioPlayMediator else {
            return
        }
        AudioActionsService.logger.info("触发播放音频 status: \(status)")
        var isPlayAudio: Bool = false
        // 设置指定播放状态
        if let status = status {
            switch status {
            case .playing:
                isPlayAudio = true
            case .pause, .default, .loading:
                break
            @unknown default:
                assert(false, "new value")
                break
            }
            AudioActionsService.logger.info("update current audio state \(status)")
            audioPlayMediator.updateStatus(status)
        }
            // 默认播放、暂停逻辑
        else {
            AudioActionsService.logger.info("没有status isplaying: \(audioPlayMediator.isPlaying(key: audioContent.key)) key: \(audioContent.key)")
            // 如果音频已经播放 暂停播放
            if audioPlayMediator.isPlaying(key: audioContent.key) {
                audioPlayMediator.pausePlayingAudio()
                AudioActionsService.logger.info("pause audio key \(audioContent.key) time \(audioContent.duration)")
                return
            }
            AudioActionsService.logger.info("play audio key \(audioContent.key) time \(audioContent.duration)")

            isPlayAudio = true

            var audioKeys: [AudioKey] = []

            let (_, index) = self.findAudioViewModelProps(audioContent.key)
            guard let currentIdx = index else {
                AudioActionsService.logger.error(
                    "not find audio in data source",
                    additionalData: ["key": audioContent.key])
                return assertionFailure("not find audio in data source")
            }
            audioKeys.append(
                .init(
                    audioContent.key,
                    audioContent.authToken,
                    [
                        "audio_length": audioContent.duration,
                        "message_id": model.id,
                        "resource_key": audioContent.key
                    ]
                )
            )

            let isFromMe = (currentChatterId == model.fromId)
            if shouldPlayContinuously, !isFromMe, !model.meRead {
                audioKeys.append(contentsOf: self.findContinuouslyPlayedAudio(start: currentIdx))
            }
            AudioActionsService.logger.info("已经收集好了keys，准备播放 keys: \(audioKeys)")
            audioPlayMediator.playAudioWith(keys: audioKeys, downloadFileScene: downloadFileScene, from: self.targetVC)
        }

        // 1.如果不是播放 不需要显示提示
        // 2.外界制定不显示
        guard isPlayAudio && showStatusView else { return }

        /// 音量过低显示提示
        if let targetVC = self.targetVC, audioPlayMediator.volume == 0.0 {
            DispatchQueue.main.async { [weak self] in
                if self?.showNewTips ?? false {
                    AudioPlayUtil.showPlayStatusOnView(targetVC.view, status: .audioLowVolume)
                    return
                }
                AudioPlayStatusView.showAudioPlayStatusOnView(targetVC.view, status: .audioLowVolume)
            }
            return
        }

        if showNewTips {
            if let targetVC = self.targetVC, audioPlayMediator.outputType == .earPhone {
                DispatchQueue.main.async {
                    AudioPlayUtil.showPlayStatusOnView(targetVC.view, status: .audioEarPhone)
                }
            }
            return
        }

        /// 第一次播放显示提示信息
        if let targetVC = self.targetVC, self.isFirstPlay {
            DispatchQueue.main.async {
                self.isFirstPlay = false
                switch audioPlayMediator.outputType {
                case .earPhone:
                    AudioPlayStatusView.showAudioPlayStatusOnView(targetVC.view, status: .audioEarPhone)
                case .speaker:
                    AudioPlayStatusView.showAudioPlayStatusOnView(targetVC.view, status: .audioSpeaker)
                case .unknown:
                    break
                @unknown default:
                    assert(false, "new value")
                    break
                }
            }
        }
    }

    /// 监听语音的播放状态
    private func observeAudioPlayingStatus() {
        let audioPlayMediator = self.audioPlayMediator
        audioPlayMediator?.statusSignal.subscribe(onNext: { [weak self] (playingStatus) in
            guard let `self` = self else {
                return
            }

            switch playingStatus {
            case let .playing(progress):
                let (currentAudioVM, _) = self.findAudioViewModelProps(progress.key)
                if let audioVM = currentAudioVM {
                    audioVM.state = playingStatus
                    //todo: 此处用progress == 0作为判断依据不是很好。后面相关流程需要梳理、调整下，比如有开始播放收敛的入口(点击+自动)、或是明确的起始状态
                    if !audioVM.meRead, progress.current == 0 {
                        self.putMeRead(audioVM: audioVM)
                    }
                }

                if self.lastPlayAudioKey == progress.key { return }
                let (lastAudioVM, _) = self.findAudioViewModelProps(self.lastPlayAudioKey)
                if let audioVM = lastAudioVM {
                    audioVM.state = .default(nil)
                }
                self.lastPlayAudioKey = progress.key
            case let .default(key):
                let (currentAudioVM, _) = self.findAudioViewModelProps(key ?? "")
                if let audioVM = currentAudioVM {
                    audioVM.state = playingStatus
                }
                self.lastPlayAudioKey = ""
            case let .pause(progress):
                let (currentAudioVM, _) = self.findAudioViewModelProps(progress.key)
                if let audioVM = currentAudioVM {
                    audioVM.state = playingStatus
                }
                if self.lastPlayAudioKey == progress.key { return }
                let (lastAudioVM, _) = self.findAudioViewModelProps(self.lastPlayAudioKey)
                if let audioVM = lastAudioVM {
                    audioVM.state = .default(nil)
                }
                self.lastPlayAudioKey = progress.key
            case let .loading(key):
                let (currentAudioVM, _) = self.findAudioViewModelProps(key)
                if let audioVM = currentAudioVM {
                    audioVM.state = playingStatus
                }

                if self.lastPlayAudioKey == key { return }
                let (lastAudioVM, _) = self.findAudioViewModelProps(self.lastPlayAudioKey)
                if let audioVM = lastAudioVM {
                    audioVM.state = .default(nil)
                }
                self.lastPlayAudioKey = key
            @unknown default:
                assert(false, "new value")
                break
            }
        }).disposed(by: self.disposeBag)
    }

    private func findAudioViewModelProps(_ key: String) -> (AudioPlayable?, Int?) {
        guard let audios = dataProvider?() else { return (nil, nil) }
        let index = audios.firstIndex { (cellVM) -> Bool in
            /// if play audio when audio is not uploaded, the audio key is messageCid
            /// so if want find audio, check both audioKey and messageCid
            return cellVM.audioKey == key || cellVM.messageCid == key
        }
        guard let idx = index else {
            return (nil, nil)
        }
        return (audios[idx], idx)
    }

    /// 查找可连续播放的语音
    private func findContinuouslyPlayedAudio(start: Int) -> [AudioKey] {
        guard let audios = dataProvider?() else { return [] }
        var audioKeys: [AudioKey] = []
        let nextIdx = start + 1
        for i in nextIdx..<audios.count {
            let audio = audios[i]
            if !audio.meRead, currentChatterId != audio.fromId {
                audioKeys.append(
                    AudioKey(
                        audio.audioKey,
                        audio.authToken,
                        [
                            "audio_length": audio.audioLength,
                            "message_id": audio.messageId,
                            "resource_key": audio.audioKey
                        ]
                    )
                )
            } else {
                break
            }
        }
        return audioKeys
    }

    private func putMeRead(audioVM: AudioPlayable) {
        guard needPutRead else {
            return
        }
        messageAPI?
            .putReadMessages(
                channel: audioVM.channel,
                messageIds: [audioVM.messageId],
                maxPosition: audioVM.position,
                maxPositionBadgeCount: audioVM.positionBadgeCount
        )
    }
}
