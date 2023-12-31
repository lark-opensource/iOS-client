//
//  AudioPlayerManager.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/5/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import RxSwift
import LKCommonsLogging
import LarkMedia
import LarkSensitivityControl

/// Audio Data
public enum AudioData {
    /// Data type
    case data(Data)
    /// FilePath Type
    case path(URL)
}

/// 播放方式
public enum PlayerOutputType {
    /// 耳机播放
    case earPhone
    /// 扬声器播放
    case speaker
    /// 不设置播放方式
    case unknown
}

/// 音频播放状态
public enum AudioPlayingStatus {
    //// 播放默认状态 string 代表上次播放结束的 key
    case `default`(String?)
    //// 正在播放
    case playing(AudioProgress)
    //// 暂停播放
    case pause(AudioProgress)
}

/// 音频播放进度
public struct AudioProgress {
    /// 唯一key
    public let key: String
    public let authToken: String?
    /// 当前时间
    public let current: TimeInterval
    /// 音频长度
    public let duration: TimeInterval

    /// 初始化方法
    public init(key: String, authToken: String?, current: TimeInterval, duration: TimeInterval) {
        self.key = key
        self.authToken = authToken
        self.current = current
        self.duration = duration
    }
}

public final class AudioPlayService: NSObject {

    fileprivate typealias AudioSessionInfo = (
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    )

    static let logger = Logger.log(AudioPlayService.self, category: "Module.Audio")

    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()

    fileprivate var outputSubject: PublishSubject<PlayerOutputType> = PublishSubject<PlayerOutputType>()
    public var outputSignal: Observable<PlayerOutputType> {
        return outputSubject.asObservable().distinctUntilChanged().observeOn(MainScheduler.asyncInstance)
    }

    fileprivate var statusSubject: PublishSubject<AudioPlayingStatus> = PublishSubject<AudioPlayingStatus>()
    public var statusSignal: Observable<AudioPlayingStatus> { return statusSubject.asObservable().observeOn(MainScheduler.asyncInstance) }

    fileprivate var finishSubject: PublishSubject<Void> = PublishSubject<Void>()
    /// 自动播放完成信号
    public var finishSignal: Observable<Void> { return finishSubject.asObservable().observeOn(MainScheduler.asyncInstance) }

    fileprivate var progressTimerDisposeBag = DisposeBag()

    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var playingAudioData: AudioData?
    fileprivate var lastAudioKey: String?

    fileprivate var currentOutputType: PlayerOutputType = .unknown

    public var status: AudioPlayingStatus {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.currentStatus
    }

    private var currentStatus: AudioPlayingStatus {
        switch _status {
        case .playing:
            if self.audioPlayer == nil ||
                !self.audioPlayer!.isPlaying {

                // 存在自动播放完成，但是还没有回调的情况，做特殊判断
                if self.audioPlayer?.currentTime != 0 {
                    AudioPlayService.logger.warn("播放状态与 audio player 不相同")
                    assertionFailure("播放状态与 audio player 不相同")
                }
                return .default(nil)
            }
        default:
            break
        }

        return _status
    }

    private var _status: AudioPlayingStatus = .default(nil) {
        didSet {
            statusSubject.onNext(_status)
        }
    }

    public var isPlaying: Bool {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self._isPlaying
    }

    fileprivate var _isPlaying: Bool {
        if case .playing(_) = self.currentStatus {
            return true
        }
        return false
    }

    public var isPaused: Bool {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self._isPaused
    }

    fileprivate var _isPaused: Bool {
        if case .pause(_) = self.currentStatus {
            return true
        }
        return false
    }

    /// 代表正在播放中的 key, 无播放和暂停的时候为 nil
    public var playingKey: String? {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self._playingProgress?.key
    }

    fileprivate var _playingProgress: AudioProgress? {
        if case let .playing(progress) = self.currentStatus {
            return progress
        }
        return nil
    }

    /// 当前的音频 key， 代表播放或者暂停的key
    public var currentAudioProgress: AudioProgress? {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self._currentAudioProgress
    }

    fileprivate var _currentAudioProgress: AudioProgress? {
        var audioProgress: AudioProgress?
        switch self.currentStatus {
        case let .playing(progress):
            audioProgress = progress
        case let .pause(progress):
            audioProgress = progress
        default:
            break
        }

        if let progress = audioProgress, !progress.key.isEmpty {
            return progress
        }
        return nil
    }

    /// 当前 progress
    public var currentProgress: AudioProgress? {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self._currentProgress
    }

    fileprivate var _currentProgress: AudioProgress? {
        switch self.currentStatus {
        case let .playing(progress):
            return progress
        case let .pause(progress):
            return progress
        default:
            return nil
        }
    }

    /// current audio session scenario
    fileprivate var currentSessionScenario: AudioSessionScenario?

    private let queue = DispatchQueue(label: "audio.play.service.queue", qos: .userInteractive)
    private lazy var scheduler = {
        return SerialDispatchQueueScheduler(
            queue: self.queue,
            internalSerialQueueName: self.queue.label)
    }()

    // 隐私管控 token
    static let sensitivityToken = Token(withIdentifier: "LARK-PSDA-Audio_Play_Update_Proximity")
    let changeOutputRouteByExternal: Bool
    public init(changeOutputRouteByExternal: Bool) {
        self.changeOutputRouteByExternal = changeOutputRouteByExternal
        super.init()
        pthread_rwlock_init(&self.rwlock, nil)
        setupNotifications()
    }

    fileprivate func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterrupt(notification:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sensorStateChange),
            name: UIDevice.proximityStateDidChangeNotification,
            object: nil
        )
    }

    fileprivate func exchangeAudioOutputRouteWith(type: PlayerOutputType) {
        self.currentOutputType = type
        self.outputSubject.onNext(type)
        if !changeOutputRouteByExternal {
            self.updateAudioSessionIfNeeded(type: type)
        }
    }

    fileprivate func audioSessionInfo(type: PlayerOutputType) -> AudioSessionInfo {
        switch type {
        case .speaker:
            return (.playback, .default, [])
        case .earPhone:
            return (.playAndRecord, .default, [.allowBluetooth, .allowBluetoothA2DP])
        case .unknown:
            return (
                AVAudioSession.sharedInstance().category,
                AVAudioSession.sharedInstance().mode,
                AVAudioSession.sharedInstance().categoryOptions
            )
        }
    }

    public func updateAudioSessionIfNeeded(type: PlayerOutputType) {
        let scenario = self.getAudioSessionScenario(type: type)
        if audioSessionNeedUpdate(scenario: scenario) {
            self.entryAudioSession(scenario: scenario)
        }
    }

    /// check need update audio session, if current scenario is nil, return false, if current not equal to scenario, return true
    /// - Parameter scenario: audio session info
    fileprivate func audioSessionNeedUpdate(scenario: AudioSessionScenario) -> Bool {
        guard let currentSessionScenario = self.currentSessionScenario else {
            return false
        }
        return scenario != currentSessionScenario
    }

    fileprivate func getAudioSessionScenario(type: PlayerOutputType) -> AudioSessionScenario {
        let name = "audio.play.service"
        let info = self.audioSessionInfo(type: type)
        return AudioSessionScenario(
            name,
            category: info.category,
            mode: info.mode,
            options: info.options
        )
    }

    fileprivate func startProximityMonitering() {
        doInMainThread {
            do {
                try DeviceInfoEntry.setProximityMonitoringEnabled(
                    forToken: Self.sensitivityToken,
                    device: UIDevice.current,
                    isEnabled: true)
            } catch {
                Self.logger.warn("Could not setProximityMonitoringEnabled by LarkSensitivityControl API, use model name as fallback.")
            }
        }
    }

    fileprivate func stopProximityMonitering() {
        doInMainThread {
            do {
                try DeviceInfoEntry.setProximityMonitoringEnabled(
                    forToken: Self.sensitivityToken,
                    device: UIDevice.current,
                    isEnabled: false)
            } catch {
                Self.logger.warn("Could not setProximityMonitoringEnabled by LarkSensitivityControl API, use model name as fallback.")
            }
        }
    }

    fileprivate func getProximityState() -> Bool {
        do {
            return try DeviceInfoEntry.proximityState(
                forToken: Self.sensitivityToken,
                device: UIDevice.current)
        } catch {
            Self.logger.warn("Could not proximityState by LarkSensitivityControl API, use model name as fallback.")
            return false
        }
    }

    fileprivate func doInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)

        UIDevice.current.isProximityMonitoringEnabled = false
        pthread_rwlock_destroy(&self.rwlock)
    }
}

extension AudioPlayService {
    @objc
    fileprivate func handleInterrupt(notification: Notification) {
        self.queue.async { [weak self] in
            self?.handleInterruptInQueue(notification: notification)
        }
    }

    fileprivate func handleInterruptInQueue(notification: Notification) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        if !self._isPlaying { return }
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        if type == .began {
            self.innerStopPlayingAudio()
        }
    }

    @objc
    fileprivate func handleRouteChange(notification: Notification) {
        self.queue.async { [weak self] in
            self?.handleRouteChangeInQueue(notification: notification)
        }
    }

    fileprivate func handleRouteChangeInQueue(notification: Notification) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        if !self._isPlaying { return }
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                /// 插入耳机操作
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                    /// 拔出耳机操作
                    innerStopPlayingAudio()
                }
            }
        default: ()
        }
    }

    @objc
    fileprivate func sensorStateChange() {
        self.queue.async { [weak self] in
            self?.sensorStateChangeInQueue()
        }
    }

    fileprivate func sensorStateChangeInQueue() {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        if !self._isPlaying { return }
        if self.getProximityState() {
            Self.logger.info("Close to mobile phone")
            exchangeAudioOutputRouteWith(type: .earPhone)
        } else {
            Self.logger.info("Stay away from mobile phones")
            exchangeAudioOutputRouteWith(type: .speaker)
        }
    }

    /// 做音频播放一些准备工作
    ///
    /// - Parameters:
    ///   - key: 音频 key
    ///   - authToken: 消息链接场景需要使用previewID做鉴权
    ///   - output: 音频播放方式
    ///   - play: 是否播放音频，如果是 true 立刻播放音频
    fileprivate func prepareAudioWith(key: String, authToken: String?, output: PlayerOutputType, play: Bool) {
        if self.prepareStartPlayAudio(output: output) {
            self.lastAudioKey = key
            self.audioPlayer?.delegate = self
            if !play {
                self.updateAudioPlayPauseStatus(key: key, authToken: authToken, play: false)
                self.audioPlayer?.pause()
            } else {
                AudioPlayService.logger.info("prepareAudioWithKey: \(key) output: \(output)")
                startProximityMonitering()
                exchangeAudioOutputRouteWith(type: output)
                innerSetAudioSessionActive(true)

                self.audioPlayer?.play()
                self.updateAudioPlayPauseStatus(key: key, authToken: authToken, play: true)

                /// 开始播放之后监听进度
                self.progressTimerDisposeBag = DisposeBag()
                Observable<Int>
                    .interval(
                        .milliseconds(100),
                        scheduler: self.scheduler).subscribe(onNext: { [weak self] (_) in
                            guard let `self` = self else { return }
                            pthread_rwlock_wrlock(&self.rwlock)
                            defer { pthread_rwlock_unlock(&self.rwlock) }

                            if let progress = self._playingProgress {
                                self.updateAudioPlayPauseStatus(key: progress.key, authToken: progress.authToken, play: true)
                            }
                        }
                    )
                    .disposed(by: self.progressTimerDisposeBag)
            }
        }
    }

    fileprivate func prepareStartPlayAudio(output: PlayerOutputType) -> Bool {
        if let audioPlayer = audioPlayer, audioPlayer.prepareToPlay() {
            return true
        }
        AudioPlayService.logger.error("audio player prepare failed")
        return false
    }

    /// 设置 audio session active
    public func setAudioSessionActive(_ isActive: Bool) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        self.innerSetAudioSessionActive(isActive)
    }

    fileprivate func innerSetAudioSessionActive(_ isActive: Bool) {
        if isActive {
            self.entryAudioSession(scenario: self.getAudioSessionScenario(type: self.currentOutputType))
        } else {
            self.leaveAudioSession()
        }
        setIdleTimer(disabled: isActive)
    }

    /// entry audio scenario, if current is not nil and don't equal to scenario, leave it first
    /// - Parameter scenario: audio session info
    fileprivate func entryAudioSession(scenario: AudioSessionScenario) {
        guard let resource = LarkMediaManager.shared.getMediaResource(for: .imPlay) else {
            return
        }
        if let currentSessionScenario = self.currentSessionScenario {
            if currentSessionScenario == scenario {
                return
            }
            resource.audioSession.leave(currentSessionScenario)
        }
        Self.logger.info("audio session enter: \(scenario)")
        resource.audioSession.enter(scenario)
        self.currentSessionScenario = scenario
    }

    /// leave current audio session scenario
    fileprivate func leaveAudioSession() {
        Self.logger.info("leaveAudioSession1")
        if let currentSessionScenario = self.currentSessionScenario {
            self.currentSessionScenario = nil
            Self.logger.info("leaveAudioSession2")
            if MediaMutexScene.imPlay.isActive,
               let resource = LarkMediaManager.shared.getMediaResource(for: .imPlay) {
                Self.logger.info("leave Scenario")
               resource.audioSession.leave(currentSessionScenario)
            }
        }
    }

    fileprivate func setIdleTimer(disabled: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }
}

extension AudioPlayService {

    /// 播放音频data
    ///
    ///
    /// - Parameters:
    ///   - filePath: 音频本地文件
    ///   - playerType: 播放方式
    ///   - audioKey: audio key
    ///   - authToken: 消息链接场景需要使用previewID鉴权
    ///   - continueWhenPause: 如果当前正在播放相同的音频，是否继续播放， 如果为 true，则继续播放， 如果为 false， 则重新加载音频
    @discardableResult
    public func playAudioWith(
        data: Data,
        playerType: PlayerOutputType,
        audioKey: String,
        authToken: String?,
        continueWhenPause: Bool = true) -> Error? {
        return self.loadAudioWith(
            data: .data(data),
            playerType: playerType,
            audioKey: audioKey,
            authToken: authToken,
            continueWhenPause: continueWhenPause
        )
    }

    /// 播放本地音频
    ///
    ///
    /// - Parameters:
    ///   - filePath: 音频本地文件
    ///   - playerType: 播放方式
    ///   - audioKey: audio key
    ///   - continueWhenPause: 如果当前正在播放相同的音频，是否继续播放， 如果为 true，则继续播放， 如果为 false， 则重新加载音频
    @discardableResult
    public func playAudioWith(
        filePath: String,
        playerType: PlayerOutputType,
        audioKey: String,
        authToken: String?,
        continueWhenPause: Bool = true) -> Error? {

        guard let fileURL = URL(string: filePath) else {
            AudioPlayService.logger.error("file path is wrong")
            return AudioError.fileInvalid
        }

        return self.loadAudioWith(
            data: .path(fileURL),
            playerType: playerType,
            audioKey: audioKey,
            authToken: authToken,
            continueWhenPause: continueWhenPause
        )
    }

    /// 加载本地音频
    ///
    ///
    /// - Parameters:
    ///   - filePath: 音频本地文件
    ///   - playerType: 播放方式
    ///   - audioKey: audio key
    ///   - continueWhenPause: 如果当前正在播放相同的音频，是否继续播放， 如果为 true，则继续播放， 如果为 false， 则重新加载音频
    ///   - play: 是否播放，如果为 true，直接播放，如果为 false 只加载音频 不播放
    @discardableResult
    public func loadAudioWith(
        data: AudioData,
        playerType: PlayerOutputType,
        audioKey: String,
        authToken: String?,
        continueWhenPause: Bool = true,
        play: Bool = true) -> Error? {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        do {
            ///  重新继续播放 pause 音频 比重新初始化数据
            if self._currentAudioProgress?.key != audioKey || !self._isPaused || !continueWhenPause {

                AudioPlayService.logger.info("加载音频数据 data: \(data) playerType: \(playerType) audioKey: \(audioKey) continueWhenPause: \(continueWhenPause) play: \(play)")
                playingAudioData = data
                /// 使用 data 初始化 audio player
                self.innerStopPlayingAudio()
                switch data {
                case .data(let data):
                    try audioPlayer = AVAudioPlayer(data: data)
                case .path(let fileURL):
                    try audioPlayer = AVAudioPlayer(contentsOf: fileURL)
                }
                AudioPlayService.logger.info(
                    "audio player init success",
                    additionalData: ["audioKey": audioKey]
                )
            }
            prepareAudioWith(key: audioKey, authToken: authToken, output: playerType, play: play)
        } catch {
            self.innerStopPlayingAudio()
            AudioPlayService.logger.error("audio player create with data error", error: error)
            return AudioError.systemError(error)
        }
        return nil
    }

    /// 继续播放暂停的音频
    /// from, 可以设置从哪个时间点继续播放
    public func continuePlay(audioKey: String, authToken: String?, lastPlayerType: PlayerOutputType, from: TimeInterval? = nil) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        if self._currentAudioProgress?.key == audioKey, self._isPaused {
            if let audioPlayer = self.audioPlayer,
                let from = from {
                audioPlayer.currentTime = min(from, audioPlayer.duration - 0.01)
            }
            var output = lastPlayerType
            if output == .unknown {
                if self.getProximityState() {
                    output = .earPhone
                } else {
                    output = .speaker
                }
            }
            AudioPlayService.logger.info("继续播放音频 audioKey: \(audioKey) lastPlayerType: \(lastPlayerType) output: \(output)")
            prepareAudioWith(key: audioKey, authToken: authToken, output: output, play: true)

            /// 经过多线程无验证，设置 currentTime 有可能导致 audioplayer 无法播放
            /// 这里做一个兼容 fix
            if let audioPlayer = self.audioPlayer, !audioPlayer.isPlaying {
                self._status = .pause(AudioProgress(key: audioKey, authToken: authToken, current: audioPlayer.currentTime, duration: audioPlayer.duration))
                AudioPlayService.logger.warn(
                    "audio player stop after continue",
                    additionalData: [
                        "audioKey": audioKey
                    ]
                )
            }

            AudioPlayService.logger.info(
                "audio player contione",
                additionalData: [
                    "audioKey": audioKey
                ]
            )
        }
    }

    /// 更新进度
    public func update(currentTime: TimeInterval) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        guard let currentAudioProgress = self._currentAudioProgress, let player = self.audioPlayer else {
            return
        }

        /// 避免超出最大进度, 减去0.01是避免出现音频重头播放的问题
        var isPlaying = self._isPlaying
        player.currentTime = min(currentTime, player.duration - 0.01)

        /// 多线程测试发现，偶现有时设置完 currentTime 之后， audio player 停止播放，且无法立刻恢复
        /// 这里需要兼容这个问题
        if !player.isPlaying && isPlaying {
            self._status = .pause(AudioProgress(
                key: currentAudioProgress.key,
                authToken: currentAudioProgress.authToken,
                current: player.currentTime,
                duration: player.duration
            ))
            isPlaying = false
            AudioPlayService.logger.warn(
                "audio player stop after update",
                additionalData: [
                    "audioKey": currentAudioProgress.key,
                    "currentTime": "\(currentTime)"
                ]
            )
        }
        self.updateAudioPlayPauseStatus(key: currentAudioProgress.key, authToken: currentAudioProgress.authToken, play: isPlaying)

        AudioPlayService.logger.info(
            "audio player update",
            additionalData: [
                "audioKey": currentAudioProgress.key,
                "currentTime": "\(currentTime)"
            ]
        )
    }

    /// 暂停播放音频
    public func pauseAudioPlayer() {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }

        if !self._isPlaying { return }

        /// 取消进度监听
        progressTimerDisposeBag = DisposeBag()

        /// 修改状态
        let currentAudioKey = self._currentAudioProgress?.key ?? ""
        self.updateAudioPlayPauseStatus(key: currentAudioKey, authToken: self._currentAudioProgress?.authToken, play: false)

        /// 暂停音频
        if let player = self.audioPlayer {
            player.pause()
        }

        /// 恢复设备设置
        innerSetAudioSessionActive(false)
        stopProximityMonitering()

        AudioPlayService.logger.info(
            "audio player pause",
            additionalData: ["audioKey": currentAudioKey]
        )
    }

    /// 停止播放音频
    public func stopPlayingAudio() {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        self.innerStopPlayingAudio()
    }

    fileprivate func innerStopPlayingAudio() {
        Self.logger.info("innerStopPlayingAudio")
        /// 取消进度监听
        progressTimerDisposeBag = DisposeBag()

        /// 设置状态
        let currentAudioKey = self._currentAudioProgress?.key ?? ""
        self._status = .default(self.lastAudioKey)

        /// 停止播放音频
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
        }

        /// 重置音频数据
        audioPlayer = nil
        playingAudioData = nil

        /// 恢复设备设置
        innerSetAudioSessionActive(false)
        stopProximityMonitering()

        if !currentAudioKey.isEmpty {
            AudioPlayService.logger.info(
                "audio player stop",
                additionalData: ["audioKey": currentAudioKey]
            )
        }
    }

    /// 判断音频是否正在播放中
    public func playingAudioWith(key: String) -> Bool {
        return self.playingKey == key
    }

    /// 当前的播放进度
    fileprivate func playProgress() -> (TimeInterval, TimeInterval)? {
        guard self._isPlaying || self._isPaused else { return nil }
        guard let player = self.audioPlayer else { return nil }
        return (player.currentTime, player.duration)
    }

    /// 刷新当前 播放/暂停 状态
    fileprivate func updateAudioPlayPauseStatus(key: String, authToken: String?, play: Bool) {
        let currentAudioKey = key
        let (current, duration) = self.playProgress() ?? (0, 0)
        if play {
            self._status = .playing(AudioProgress(key: currentAudioKey, authToken: authToken, current: current, duration: duration))
        } else {
            self._status = .pause(AudioProgress(key: currentAudioKey, authToken: authToken, current: current, duration: duration))
        }
    }
}

extension AudioPlayService: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            pthread_rwlock_wrlock(&self.rwlock)
            defer { pthread_rwlock_unlock(&self.rwlock) }

            AudioPlayService.logger.info(
                "audio play finished",
                additionalData: ["audioKey": self._currentAudioProgress?.key ?? ""])
            /// 自动播放完成发出 finish 信号
            self.innerStopPlayingAudio()
            self.finishSubject.onNext(())
        }
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.queue.async {
            pthread_rwlock_rdlock(&self.rwlock)
            defer { pthread_rwlock_unlock(&self.rwlock) }

            AudioPlayService.logger.error(
                "audio play error",
                additionalData: ["audioKey": self._currentAudioProgress?.key ?? ""],
                error: error)
        }
    }
}
