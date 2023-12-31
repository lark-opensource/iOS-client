//
//  OPMediaPlayer.swift
//  OPPlugin
//
//  Created by zhysan on 2022/5/9.
//

import Foundation
import TTVideoEngine
import LKCommonsLogging
import SwiftUI
import LarkMedia
import OPSDK
import OPFoundation
import LarkOpenAPIModel
import LarkStorage

enum PlayState {
    case stopped
    case playing
    case paused
    case error
    case unknown
}

enum LoadState {
    case initializing
    case playable
    case stalled
    case error
    case unknown
}

protocol OPMediaPlayerDelegate: AnyObject  {
    func playerReadyToPlay(_ player: OPMediaPlayer)
    func playerDidFinishPlaying(_ player: OPMediaPlayer, error: Error?)
    func playerPlaybackStateDidChange(_ player: OPMediaPlayer, state: PlayState)
    func playerLoadStateDidChange(_ player: OPMediaPlayer, state: LoadState)
}

private extension TTVideoEnginePlaybackState {
    func toOPState() -> PlayState {
        switch self {
        case .stopped: return .stopped
        case .playing: return .playing
        case .paused: return .paused
        case .error: return .error
        @unknown default: return .unknown
        }
    }
}

private extension TTVideoEngineLoadState {
    func toOPState() -> LoadState {
        switch self {
        case .unknown: return .initializing
        case .playable: return .playable
        case .stalled: return .stalled
        case .error: return .error
        @unknown default: return .unknown
        }
    }
}

private struct Const {
    static let engineLogTag = "opplugin"
    static let engineLogSubTag = "bg_audio"
    
    static var engineCachePath: String {
        if LSFileSystem.isoPathEnable {
            return AbsPath.temporary.absoluteString.appendingPathComponent("com.lark.opplugin/BgAudio")
        }else {
            // lint:disable:next lark_storage_migrate_check
            return FileManager.default.temporaryDirectory.path.appendingPathComponent("com.lark.opplugin/BgAudio")
        }
    }
}

/// 这个类在小程序背景音频需求中实现，最初用作背景音频的音频播放器
/// 设计上预期是作为 TTVideoEngine 的上层封装，可用于小程序内部播放视频或音频等媒体资源
final class OPMediaPlayer: NSObject {
    
    // MARK: - public vars
    let uniqueID: OPAppUniqueID
    
    /// 播放速率
    var playbackRate: CGFloat {
        set {
            engine.playbackSpeed = newValue
        }
        get {
            engine.playbackSpeed
        }
    }

    /// 资源总时长，s
    var duration: TimeInterval {
        engine.duration
    }
    
    /// 当前播放时长，s
    var currentTime: TimeInterval {
        engine.currentPlaybackTime
    }
    
    /// 已缓冲时长，s
    var buffered: TimeInterval {
        engine.playableDuration
    }
    
    var playState: PlayState { engine.playbackState.toOPState() }
    
    /// 是否在 Seeking 中（只有 seeking = false 时，seekTo() 才有效）
    private(set) var seeking: Bool = false
    
    var wrapper: OPMediaMutexObserveWrapper?
    
    // MARK: - public funcs
    
    /// 准备播放
    func prepareToPlay() {
        engine.prepareToPlay()
    }
    
    
    /// 设置本地资源路径
    /// - Parameter path: 资源路径
    func setupLocalMedia(_ path: String) {
        engine.setLocalURL(path)
    }
    
    /// 设置远端资源 URL
    /// - Parameter url: 资源 URL
    func setupRemoteMedia(_ url: String) {
        engine.ls_setDirectURL(url, key: url.md5())
    }
    
    /// 设置起始播放时间
    /// - Parameter timestamp: 播放起始时间戳
    func setupStartTime(_ timestamp: TimeInterval) {
        engine.setOptionForKey(VEKKey.VEKKeyPlayerStartTime_CGFloat.rawValue, value: timestamp)
    }
    
    typealias OPMediaPlayerCompletion = (OpenAPIError?) -> Void
    
    /// 播放
    /// - discussion 因为背景音频的operateSync同步方法是设定为主线程调用的(可能考虑到有UI操作),
    /// 所以这里不能同步调用.
    /// 先提前同步返回, 再根据结果fireEvent.
    func play(completion: OPMediaPlayerCompletion?) {
        innerQueue.async {
            OPMediaMutex.tryLock(scene: .audioPlay, observer: self) { [weak self] result in
                guard let self = self else {
                    let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    completion?(error)
                    return
                }
                switch result {
                case .success(let resource):
                    resource.audioSession.enter(self.scenario)
                    self.engine.play()
                    completion?(nil)
                case .failure(let error):
                    let apiError = OpenAPIError(errno: OpenAPIInnerAudioErrno.innerAudioHigherPriorityFailed(errorString: error.errorInfo()))
                    completion?(apiError)
                }
            }
        }
    }
    
    /// 暂停
    func pause() {
        let scenario = self.scenario
        innerQueue.async { [weak self] in
            OPMediaMutex.leave(scenario: scenario, scene: .audioPlay, wrapper: self?.wrapper)
            self?.engine.pause()
        }
    }
    
    /// 停止
    func stop() {
        let scenario = self.scenario
        innerQueue.async { [weak self] in
            OPMediaMutex.leave(scenario: scenario, scene: .audioPlay, wrapper: self?.wrapper)
            OPMediaMutex.unlock(scene: .audioPlay, wrapper: self?.wrapper)
            self?.engine.stop()
        }
    }
    
    /// Seek 到指定时间
    /// - Parameter timestamp: 时间戳（秒）
    func seekTo(_ timestamp: TimeInterval, completionHandler: ((Bool) -> Void)?) {
        if playState == .stopped {
            setupStartTime(timestamp)
            completionHandler?(true)
            return
        }
        if seeking {
            completionHandler?(false)
            return
        }
        seeking = true
        engine.setCurrentPlaybackTime(timestamp) { [weak self] success in
            self?.seeking = false
            completionHandler?(success)
        }
    }
    
    // MARK: - life cycle
    
    init(uniqueID: OPAppUniqueID) {
        self.uniqueID = uniqueID
        innerQueue = DispatchQueue(label: "com.lark.plugin.bg")
    }
    
    deinit {
        engine.stop()
        engine.closeAysnc()
    }
    
    // MARK: - private vars
    
    let innerQueue: DispatchQueue
    weak var delegate: OPMediaPlayerDelegate?
    
    private lazy var engine: TTVideoEngine = {
        if !TTVideoEngine.ls_isStarted() {
            // 开启 Media Data Loader
            TTVideoEngine.ls_localServerConfigure().maxCacheSize = 300 * 1024 * 1024
            TTVideoEngine.ls_localServerConfigure().cachDirectory = Const.engineCachePath
            TTVideoEngine.ls_start()
            OPBGMLogger.info("player enable MDL, cache path: \(Const.engineCachePath)")
        }
        
        let ins = TTVideoEngine(ownPlayer: true)
        ins.delegate = self
        ins.setOptions([
            // 解决 seek 问题，参考：https://bytedance.feishu.cn/wiki/wikcnh3rzpY5KOtuGs2ChGZjUOg
            VEKKey.VEKKEYPlayerKeepFormatAlive_BOOL.rawValue as VEKKeyType : true,
            VEKKey.VEKKeyPlayerSeekEndEnabled_BOOL.rawValue as VEKKeyType : true,
            
            // 开启本地缓存（MDL）
            VEKKey.VEKKeyMedialoaderEnable_BOOL.rawValue as VEKKeyType: true,
            
            // 播放器 Tag 设置
            VEKKey.VEKKeyLogTag_NSString.rawValue as VEKKeyType: Const.engineLogTag,
            VEKKey.VEKKeyLogSubTag_NSString.rawValue as VEKKeyType: Const.engineLogSubTag,
        ])
        return ins
    }()
    
    private var scenario = AudioSessionScenario(
        "com.lark.op-bgm",
        category: .playback,
        policy: .longForm
    )
    
}

// MARK: - TTVideoEngineDelegate

extension OPMediaPlayer: TTVideoEngineDelegate {
    
    // MARK: - reuqired
    
    /// 用户手动停止
    func videoEngineUserStopped(_ videoEngine: TTVideoEngine) {
        OPBGMLogger.info("videoEngineUserStopped")
    }
    
    /// 播放结束
    func videoEngineDidFinish(_ videoEngine: TTVideoEngine, error: Error?) {
        OPBGMLogger.info("finish play, \(String(describing: error))")
        delegate?.playerDidFinishPlaying(self, error: error)
    }
    
    /// 播放异常结束
    func videoEngineDidFinish(_ videoEngine: TTVideoEngine, videoStatusException status: Int) {
        OPBGMLogger.warn("status exception: \(status)")
    }
    
    /// 播放器 Close 完成
    func videoEngineCloseAysncFinish(_ videoEngine: TTVideoEngine) {
        OPBGMLogger.info("videoEngineCloseAysncFinish")
    }
    
    // MARK: - optional
    
    /// 播放状态改变（停止、播放、暂停、播放失败）
    func videoEngine(_ videoEngine: TTVideoEngine, playbackStateDidChanged playbackState: TTVideoEnginePlaybackState) {
        OPBGMLogger.info("playbackState change: \(playbackState)")
        let state = playbackState.toOPState()
        delegate?.playerPlaybackStateDidChange(self, state: state)
    }
    
    /// 加载状态改变（初始状态、可播放、加载中、加载失败）
    func videoEngine(_ videoEngine: TTVideoEngine, loadStateDidChanged loadState: TTVideoEngineLoadState) {
        OPBGMLogger.info("loadState change: \(loadState)")
        delegate?.playerLoadStateDidChange(self, state: loadState.toOPState())
    }
    
    /// prepare 完成
    func videoEnginePrepared(_ videoEngine: TTVideoEngine) {
        OPBGMLogger.info("prepare finish")
    }
    
    /// 播放器可播放
    func videoEngineReady(toPlay videoEngine: TTVideoEngine) {
        OPBGMLogger.info("ready to play")
        delegate?.playerReadyToPlay(self)
    }
    
    /// 视频首帧
    func videoEngineReady(toDisPlay videoEngine: TTVideoEngine) {
        OPBGMLogger.info("ready to display")
    }
    
    /// 音频首帧
    func videoEngineAudioRendered(_ videoEngine: TTVideoEngine) {
        
    }
    
    /// 播放器重试中
    func videoEngine(_ videoEngine: TTVideoEngine, retryForError error: Error) {
        OPBGMLogger.info("retry for error: \(error)")
    }
}

// MARK: - OPMediaResourceInterruptionObserver

extension OPMediaPlayer: OPMediaResourceInterruptionObserver {
    @objc func mediaResourceWasInterrupted(by scene: String, msg: String?) {
        OPBGMLogger.info("OPMediaPlayer mediaResourceWasInterrupted by scene: \(scene), msg: \(msg ?? "")")
        pause()
    }
    
    @objc func mediaResourceInterruptionEnd(from scene: String) {
        OPBGMLogger.info("OPMediaPlayer mediaResourceInterruptionEnd from scene: \(scene)")
    }
}
