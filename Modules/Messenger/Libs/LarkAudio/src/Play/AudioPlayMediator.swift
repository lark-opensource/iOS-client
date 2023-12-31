//
//  AudioPlayMediator.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/5/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import RxSwift
import LKCommonsLogging
import LarkAudioKit
import LarkMessengerInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import LarkMedia
import EENavigator
import UniverseDesignDialog
import LarkSDKInterface
import LarkContainer

enum AudioPlaybackType {
    /// 连播
    case continuous
    /// 单播
    case unicast
}

struct AudioFetchingInfo {
    var key: AudioKey?
    var callback: ((Error?) -> Void)?
    var play: Bool = false
}

final class AudioPlayMediatorImpl: AudioPlayMediator {
    static let logger = Logger.log(AudioPlayMediatorImpl.self, category: "Module.Audio")

    var outputType: PlayerOutputType = .speaker

    /// Observable

    var outputSignal: Observable<PlayerOutputType> { return playService.outputSignal }

    fileprivate var statusSubject: PublishSubject<AudioPlayMediatorStatus> = PublishSubject<AudioPlayMediatorStatus>()
    public var statusSignal: Observable<AudioPlayMediatorStatus> { return statusSubject.asObservable().observeOn(MainScheduler.asyncInstance)
    }

    fileprivate var playbackType: AudioPlaybackType = .unicast
    fileprivate let playService: AudioPlayService
    /// 连播状态
    fileprivate var audioKey: [AudioKey] = []
    fileprivate var currentPlayIndex: Int = 0

    /// 播放过程中输出改变
    fileprivate var exchangedOutput: PlayerOutputType? {
        didSet {
            // 在扬声器模式下，贴近/远离应该改变输出方式。在听筒模式下，贴近/远离不改变输出方式
            // https://bytedance.larkoffice.com/docx/RpiDd1mQ0oFJotxy13lcz4cInfe
            guard userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.playby.improvements"),
            let exchangedOutput, exchangedOutput != oldValue else { return }
            if outputType == .speaker {
                playService.updateAudioSessionIfNeeded(type: exchangedOutput)
            }
        }
    }

    /// 正在获取资源的信息
    fileprivate var fetchingInfo: SafeAtomic<AudioFetchingInfo> = AudioFetchingInfo() + .readWriteLock
    /// 与资源下载相关
    fileprivate var downloadFileScene: Media_V1_DownloadFileScene?

    fileprivate weak var playFrom: NavigatorFrom?

    var isPlaying: Bool {
        return self.playService.isPlaying
    }

    var status: AudioPlayMediatorStatus = .default(nil) {
        didSet {
            self.statusSubject.onNext(self.status)
        }
    }

    var volume: Float {
        return AVAudioSession.sharedInstance().outputVolume
    }

    let disposeBag = DisposeBag()

    private let audioResourceService: AudioResourceService

    private let playQueue = DispatchQueue(
        label: "audio.mediator.play.queue",
        qos: .userInteractive
    )

    let userResolver: UserResolver

    init(userResolver: UserResolver, audioResourceService: AudioResourceService) {
        self.userResolver = userResolver
        self.audioResourceService = audioResourceService
        self.playService = AudioPlayService(changeOutputRouteByExternal: userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.playby.improvements"))

        playService.outputSignal.subscribe(onNext: { [weak self] (type) in
            self?.exchangedOutput = type
        }).disposed(by: self.disposeBag)

        playService.finishSignal.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            if self.playbackType == .continuous {
                /// 连播间隙0.6s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: { [weak self] in
                    self?.playAudioInTurns()
                })
            } else {
                self.playService.setAudioSessionActive(false)
            }
        }).disposed(by: self.disposeBag)

        playService.statusSignal.subscribe(onNext: { [weak self] (status) in
            guard let `self` = self else { return }
            var needUnlock = false
            switch status {
            case let .default(key):
                if case let .playing(progress) = self.status, progress.key == key {
                    needUnlock = true
                }
                self.status = .default(key)
            case let .playing(progress):
                self.status = .playing(progress)
            case let .pause(progress):
                needUnlock = true
                self.status = .pause(progress)
            @unknown default:
                needUnlock = true
                self.status = .default(nil)
            }
            if needUnlock {
                LarkMediaManager.shared.unlock(scene: .imPlay)
            }
        }).disposed(by: self.disposeBag)
    }

    /**
     根据语音 keys 播放

     - parameter keys:   一组key, 可以单独一个
     */
    func playAudioWith(keys: [AudioKey], downloadFileScene: RustPB.Media_V1_DownloadFileScene?, from: NavigatorFrom?) {
        self.downloadFileScene = downloadFileScene
        self.playFrom = from
        if !keys.isEmpty {
            AudioPlayMediatorImpl.logger.info("keys 不为空")
            playbackType = (keys.count > 1) ? .continuous : .unicast
            cancelAudioPlayingInTurn()
            switch playbackType {
            case .continuous:
                audioKey = keys
            default:
                break
            }
            tryPlayAudioByKey(keys[0])
        } else {
            stopPlayingAudio()
            AudioPlayMediatorImpl.logger.warn("audio keys is empty")
            assertionFailure("audio keys array should not empty!")
        }
    }

    // 更新音频状态
    func updateStatus(_ status: AudioPlayMediatorStatus) {
        switch status {
        case .default:
            self.stopPlayingAudio()
        case let .playing(progress):
            // 如果拖动到底，直接stop
            if progress.current == progress.duration {
                self.stopPlayingAudio()
                return
            }
            if self.fetchingInfo.value.key?.key == progress.key,
               let audioKey = self.fetchingInfo.value.key {
                // 更新获取资源后的 callback
                AudioPlayMediatorImpl.logger.info("updateStatus .playing 更新资源")
                self.tryPlayAudioByKey(audioKey) { [weak self] (error) in
                    if error != nil {
                        self?.playService.update(currentTime: progress.current)
                    }
                }
            } else if playService.currentAudioProgress?.key != progress.key {
                // 如果与之前播放的不同 先停掉之前的音频
                AudioPlayMediatorImpl.logger.info("updateStatus .playing 如果与之前播放的不同 先停掉之前的音频")
                self.stopPlayingAudio()
                self.tryPlayAudioByKey(.init(progress.key, progress.authToken)) { [weak self] (error) in
                    if error != nil {
                        self?.playService.update(currentTime: progress.current)
                    }
                }
            } else {
                // 如果是暂停就继续播放
                if playService.isPlaying {
                    AudioPlayMediatorImpl.logger.info("updateStatus .playing 更新进度")
                    playService.update(currentTime: progress.current)
                } else {
                    AudioPlayMediatorImpl.logger.info("updateStatus .playing 继续播放")
                    if userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.playby.improvements") {
                        LarkMediaManager.shared.tryLock(scene: .imPlay, options: .mixWithOthers) { [weak self] result in
                            guard let self else { return }
                            switch result {
                            case .success:
                                playService.continuePlay(audioKey: progress.key, authToken: progress.authToken, lastPlayerType: (exchangedOutput ?? .unknown), from: progress.current)
                            case .failure(let error):
                                AudioPlayMediatorImpl.logger.error("AudioPlayMediatorImpl try Lock failed \(error)")
                                if case let MediaMutexError.occupiedByOther(_, msg) = error, let msg {
                                    self.showMediaLockAlert(msg: msg)
                                }
                            }
                        }
                    } else {
                        playService.continuePlay(audioKey: progress.key, authToken: progress.authToken, lastPlayerType: (exchangedOutput ?? .unknown), from: progress.current)
                    }
                }
            }
        case let .pause(progress):
            if self.fetchingInfo.value.key?.key == progress.key,
               let audioKey = self.fetchingInfo.value.key {
                AudioPlayMediatorImpl.logger.info("updateStatus .pause 更新资源")
                // 更新获取资源后的 callback
                self.tryPlayAudioByKey(audioKey, play: false) { [weak self] (error) in
                    if error != nil {
                        self?.playService.update(currentTime: progress.current)
                    }
                }
            } else if playService.currentAudioProgress?.key != progress.key {
                // 如果与之前播放的不同 先停掉之前的音频
                AudioPlayMediatorImpl.logger.info("updateStatus .pause 如果与之前播放的不同 先停掉之前的音频")
                self.stopPlayingAudio()
                self.tryPlayAudioByKey(.init(progress.key, progress.authToken), play: false) { [weak self] (error) in
                    if error != nil {
                        self?.playService.update(currentTime: progress.current)
                    }
                }
            } else {
                AudioPlayMediatorImpl.logger.info("updateStatus .pause 暂停音频")
                // 如果正在播放就先暂停
                if !playService.isPaused {
                    self.pausePlayingAudio()
                }
                playService.update(currentTime: progress.current)
            }
        case .loading:
            assertionFailure("不可以手动设置 loading")
        @unknown default:
            self.stopPlayingAudio()
        }
    }

    func stopPlayingAudio() {
        cancelAudioPlayingInTurn()
        self.fetchingInfo.value = AudioFetchingInfo()
        self.playQueue.async { [weak self] in
            self?.playService.stopPlayingAudio()
        }
    }

    func syncStopPlayingAudio() {
        cancelAudioPlayingInTurn()
        fetchingInfo.value = AudioFetchingInfo()
        self.playService.stopPlayingAudio()
    }

    func pausePlayingAudio() {
        self.playQueue.async { [weak self] in
            self?.playService.pauseAudioPlayer()
        }
    }

    func isPlaying(key: String) -> Bool {
        return playService.playingAudioWith(key: key)
    }

    fileprivate func cancelAudioPlayingInTurn() {
        audioKey.removeAll()
        currentPlayIndex = 0
        exchangedOutput = nil
    }

    fileprivate func playAudioInTurns() {
        currentPlayIndex += 1
        if currentPlayIndex < audioKey.count {
            if playbackType == .continuous {
                tryPlayAudioByKey(audioKey[currentPlayIndex])
            }
        } else {
            playService.setAudioSessionActive(false)
            cancelAudioPlayingInTurn()
        }
    }

    fileprivate func tryPlayAudioByKey(_ key: AudioKey, play: Bool = true, callback: ((Error?) -> Void)? = nil) {
        AudioPlayMediatorImpl.logger.info("AudioPlayMediatorImpl try Lock")
        let result: MediaMutexCompletion = LarkMediaManager.shared.tryLock(scene: .imPlay, options: .mixWithOthers, observer: self)
        switch result {
        case .success:
            self.playAudioByKey(key, play: play, callback: { error in
                if error != nil {
                    LarkMediaManager.shared.unlock(scene: .imPlay)
                }
                callback?(error)
            })
        case .failure(let error):
            AudioPlayMediatorImpl.logger.error("AudioPlayMediatorImpl try Lock failed \(error)")
            if case let MediaMutexError.occupiedByOther(context) = error {
                if let msg = context.1 {
                    self.showMediaLockAlert(msg: msg)
                }
                callback?(error)
            } else {
                self.playAudioByKey(key, play: play, callback: { error in
                    if error != nil {
                        LarkMediaManager.shared.unlock(scene: .imPlay)
                    }
                    callback?(error)
                })
            }
        }
    }

    fileprivate func playAudioByKey(_ key: AudioKey, play: Bool = true, callback: ((Error?) -> Void)? = nil) {

        // 添加 fetchingAudioKey 避免重复获取资源,同时更新 callback
        if self.fetchingInfo.value.key == key {
            self.fetchingInfo.value.callback = callback
            self.fetchingInfo.value.play = play
            AudioPlayMediatorImpl.logger.info("update fetch audio", additionalData: ["key": self.fetchingInfo.value.key?.key ?? ""])
            return
        }
        self.fetchingInfo.value = AudioFetchingInfo(key: key, callback: callback, play: play)
        AudioPlayMediatorImpl.logger.info("start fetch audio resource", additionalData: ["key": self.fetchingInfo.value.key?.key ?? ""])
        let startTime = Date().timeIntervalSince1970
        let trackerKey = AudioReciableTracker.shared.audioPlayStart()
        let downloaded = self.audioResourceService.resourceDownloaded(key: key.key)
        if !downloaded {
            self.status = .loading(key.key)
        }
        audioResourceService.fetch(key: key.key, authToken: key.authToken, downloadFileScene: downloadFileScene) { [weak self] (error, audioResource) in
            let downloadTime = Date().timeIntervalSince1970
            let downloadCost = downloadTime - startTime
            let playAudioBlock = { [weak self] in
                guard let `self` = self else { return }
                // 获取资源结束 判断/重置fetching 状态
                if self.fetchingInfo.value.key != key { return }
                let play = self.fetchingInfo.value.play
                let callback = self.fetchingInfo.value.callback
                self.fetchingInfo.value = AudioFetchingInfo()

                guard let audioResource = audioResource, error == nil else {
                    AudioPlayMediatorImpl.logger.error("获取语音数据失败", error: error)
                    AudioReciableTracker.shared.audioPlayError(downloadFiled: true, extraInfo: key.info)

                    DispatchQueue.main.async {
                        if let window = UIApplication.shared.keyWindow {
                            if let apiError = error?.underlyingError as? APIError {
                                switch apiError.type {
                                case .staticResourceDeletedByAdmin:
                                    UDToast.showFailure(with: BundleI18n.LarkAudio.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                                    return
                                default:
                                    break
                                }
                            }
                            UDToast.showFailure(with: BundleI18n.LarkAudio.Lark_Video_CantDownloadTryAgain, on: window)
                        }
                    }
                    callback?(error)
                    return
                }
                AudioPlayMediatorImpl.logger.info(
                    "start fetch audio resource success",
                    additionalData: ["key": key.key]
                )
                let error = self.playAudioWith(data: audioResource.data, key: key.key, authToken: key.authToken, play: play)
                if error != nil {
                    AudioPlayMediatorImpl.logger.info("拉取语音资源失败 \(self.fetchingInfo.value.key?.key ?? "")")
                    AudioReciableTracker.shared.audioPlayError(downloadFiled: false, extraInfo: key.info)
                } else {
                    AudioReciableTracker.shared.audioPlayEnd(key: trackerKey, downloadCost: downloadCost, extraInfo: key.info)
                }
                callback?(error)
            }

            self?.playQueue.async {
                playAudioBlock()
            }
        }
    }

    fileprivate func playAudioWith(data: Data, key: String, authToken: String?, play: Bool) -> Error? {
        /// 如果切换了输出方式, 则按照新切换的播放, 否则按照原来设置的播放
        let playerType = userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.playby.improvements") ? getPlayType() : (exchangedOutput ?? outputType)
        Self.logger.info("playerType: \(playerType)")
        return playService.loadAudioWith(
            data: .data(data),
            playerType: playerType,
            audioKey: key,
            authToken: authToken,
            continueWhenPause: true,
            play: play
        )
    }

    private func getPlayType() -> PlayerOutputType {
        let playerType: PlayerOutputType
        if outputType == .earPhone {
            playerType = outputType
        } else {
            playerType = exchangedOutput ?? outputType
        }
        return playerType
    }

    private static func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    weak var lastAlertDialog: UDDialog?

    func showMediaLockAlert(msg: String) {
        Self.execInMainThread { [weak self] in
            guard let self = self else { return }
            guard let window = self.playFrom ?? UIApplication.shared.windows.first else {
                AudioPlayMediatorImpl.logger.error("cannot find window")
                return
            }
            if self.lastAlertDialog != nil {
                return
            }
            let dialog = UDDialog()
            dialog.setContent(text: msg)
            dialog.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            self.lastAlertDialog = dialog
            self.userResolver.navigator.present(dialog, from: window)
        }
    }
}

extension AudioPlayMediatorImpl: MediaResourceInterruptionObserver {

    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        self.syncStopPlayingAudio()
    }

    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
    }
}
