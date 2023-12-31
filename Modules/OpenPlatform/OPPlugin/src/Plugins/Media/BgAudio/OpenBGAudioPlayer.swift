//
//  OpenBGAudioPlayer.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/7/28.
//

import BDWebImage
import LarkOpenPluginManager
import MediaPlayer
import OPSDK
import OPPluginManagerAdapter
import TTMicroApp
import LarkOpenAPIModel

protocol OpenBGAudioPlayerDelegate: AnyObject {
    func audioPlayer(_ audioPlayer: OpenBGAudioPlayer, playStateDidChange state: OpenBGAudioPlayer.OpenBGAudioPlayerPlayState)
}

final class OpenBGAudioPlayer: NSObject, OPMediaPlayerDelegate {

    enum OpenBGAudioOperate: Equatable, CustomStringConvertible {
        var description: String {
            switch self {
            case .play:
                return "play"
            case .pause:
                return "pause"
            case .stop:
                return "stop"
            case .seek(let optional):
                return "seek \(optional ?? 0)"
            case .next:
                return "next"
            case .prev:
                return "prev"
            }
        }
        
        case play
        case pause
        case stop
        case seek(TimeInterval?)
        case next
        case prev
    }
    /// todo 改下名字？
    enum OpenBGAudioPlayerPlayState: Equatable, CustomStringConvertible {
        var description: String {
            switch self {
            case .play:
                return "play"
            case .pause:
                return "pause"
            case .stop:
                return "stop"
            case .error:
                return "error"
            }
        }
        
        case play
        case pause
        case stop
        case error
    }
    
    private let player: OPMediaPlayer
    
    let apiContext: OpenAPIContext
    
    var srcData: OPAPIParamSetBgAudioState
    
    var pageURL: OpenPluginHostPageURL?
    var coverImage: UIImage?
    var routeURL: URL?
    
    var task: BDPTask? {
        BDPTaskManager.shared().getTaskWith(player.uniqueID)
    }
    
    var common: BDPCommon? {
        BDPCommonManager.shared().getCommonWith(player.uniqueID)
    }
    
    var trace: OPTrace {
        apiContext.apiTrace
    }
    var title: String? {
        if let title = srcData.title {
            if title.isEmpty {
                return common?.model.name
            } else {
                return title
            }
        } else {
            return common?.model.name
        }

    }
    
    var uniqueID: OPAppUniqueID {
        player.uniqueID
    }
    
    var playState: PlayState {
        player.playState
    }
    fileprivate weak var listener: OpenBGAudioCenterListener?
    
    // 目前内部单例，不会释放，所以 unowned 处理
    fileprivate unowned var delegate: OpenBGAudioPlayerDelegate
    
    private var forceStop = false
    
    init(uniqueID: OPAppUniqueID, apiContext: OpenAPIContext, srcData: OPAPIParamSetBgAudioState, listener: OpenBGAudioCenterListener?, delegate: OpenBGAudioPlayerDelegate) {
        self.srcData = srcData
        self.listener = listener
        self.player = OPMediaPlayer(uniqueID: uniqueID)
        self.delegate = delegate
        self.apiContext = apiContext
        
        super.init()
        
        setup()
        addOOMObserver()
    }
    
    
    func setup() {
        player.delegate = self
        if let page = task?.currentPage {
            pageURL = OpenPluginHostPageURL(path: page.path, absoluteString: page.absoluteString, query: page.queryString, uniqueID: uniqueID)
        }
        
        let appIcon = common?.model.icon ?? ""
        let imageURL = URL(string: srcData.coverImgUrl ?? "") ?? .init(string: appIcon)
        if let url = imageURL {
            BDWebImageManager.shared().requestImage(url, options: []) { [weak self] (_, image, _, error,_)  in
                self?.coverImage = image
            }
        }
        
        let audioPage = srcData.audioPage as? [String : Any] ?? [:]
        let uniqueID = player.uniqueID
        let options = BDPSchemaCodecOptions()
        options.appID = uniqueID.appID
        options.versionType = uniqueID.versionType
        options.path = audioPage["path"] as? String
        options.query = audioPage["query"] as? NSMutableDictionary ?? .init()
        
        trace.info("OpenPluginBgAudio \(options.appID) \(options.versionType) \(options.path) \(options.query)")
        
        routeURL = try? BDPSchemaCodec.schemaURL(from: options)
        trace.info("OpenPluginBgAudio setup \(routeURL)")
    }
    
    func playerReadyToPlay(_ player: OPMediaPlayer) {
        trace.info("OpenPluginBgAudio playerReadyToPlay")
    }
    
    func playerDidFinishPlaying(_ player: OPMediaPlayer, error: Error?) {
        trace.info("OpenPluginBgAudio playerDidFinishPlaying \(error)")
        listener?.handleEvent(.ended)
    }
    
    private func addOOMObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onReceiveMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    @objc
    private func onReceiveMemoryWarning() {
        guard !forceStop else {
            return
        }
        apiContext.apiTrace.info("OpenPluginBgAudio onReceiveMemoryWarning and force stop")
        player.stop()
        playerPlaybackStateDidChange(self.player, state: .error)
        forceStop = true
    }
    
    // MARK: OPMediaPlayerDelegate
    func playerPlaybackStateDidChange(_ player: OPMediaPlayer, state: PlayState) {
        guard !forceStop else {
            return
        }
        
        updateNowPlayingInfo()
        
        switch state {
        case .stopped:
            delegate.audioPlayer(self, playStateDidChange: .stop)
            cleanRemoteCommandCenter()
            listener?.handleEvent(.stop)
        case .playing:
            delegate.audioPlayer(self, playStateDidChange: .play)
            setupRemoteCommandCenter()
            listener?.handleEvent(.play)
        case .paused:
            delegate.audioPlayer(self, playStateDidChange: .pause)
            listener?.handleEvent(.pause)
        case .error:
            delegate.audioPlayer(self, playStateDidChange: .error)
            cleanRemoteCommandCenter()
            listener?.handleEvent(.error)
        case .unknown: break;
        }
    }
    
    func playerLoadStateDidChange(_ player: OPMediaPlayer, state: LoadState) {
        switch state {
        case .initializing:
            break
        case .playable:
            listener?.handleEvent(.canplay)
        case .stalled:
            listener?.handleEvent(.waiting)
        case .error:
            listener?.handleEvent(.error)
        case .unknown: break
        }
    }
    
    // MARK: API
    func getState() -> OPAPIResultGetBgAudioState {
        let state = OPAPIResultGetBgAudioState()
        state.src = srcData.src
        state.playbackRate = srcData.playbackRate
        state.title = srcData.title
        state.coverImgUrl = srcData.coverImgUrl
        state.audioPage = srcData.audioPage
        state.duration = player.duration * 1000
        state.currentTime = player.currentTime * 1000
        state.paused = (player.playState != .playing)
        state.buffered = player.buffered
        return state
    }
    
    func operate(_ operation: OpenBGAudioOperate) {
        trace.info("OpenPluginBgAudio operate \(operation)")
        
        // 避免重复调用播放
        if player.playState == .playing && operation == .play {
            return
        }
        
        forceStop = false // 用户重新操作, 清空强制关闭状态
        switch operation {
        case .play:
            player.play { [weak self] error in
                if error != nil {
                    self?.listener?.handleEvent(.error)
                }
            }
        case .pause:
            player.pause()
        case .stop:
            player.stop()
        case .seek(let currentTime):
            if let ts = currentTime {
                listener?.handleEvent(.seeking)
                player.seekTo(ts) { success in
                    self.updateNowPlayingInfo()
                    self.listener?.handleEvent(.seeked)
                }
            } else {
                trace.error("OpenPluginBgAudio no timestamp data for seek operation")
            }
        case .next:
            listener?.handleEvent(.next)
        case .prev:
            listener?.handleEvent(.prev)
        }
    }
    
    
    /// 绑定数据
    /// 该方法会 throw 沙盒异常
    func bindData(apiContext: OpenAPIContext) {
        guard let src = srcData.src else {
            return
        }
        
        player.setupRemoteMedia(src)

        if let startTime = srcData.startTime {
            // ms to s
            player.setupStartTime(startTime / 1000)
        }
   
        player.playbackRate = srcData.playbackRate
        player.prepareToPlay()
    }
    
    func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.stopCommand.isEnabled = true
        center.skipForwardCommand.isEnabled = true
        center.skipBackwardCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.playCommand.addTarget(self, action: #selector(onPlay(_:)))
        center.pauseCommand.addTarget(self, action: #selector(onPause(_:)))
        center.stopCommand.addTarget(self, action: #selector(onStop(_:)))
        
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget(self, action: #selector(onSkipForward(_:)))
        
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget(self, action: #selector(onSkipBackward(_:)))
        
        center.changePlaybackPositionCommand.addTarget(self, action: #selector(onSeek(_:)))
    }
    
    /// 清除锁屏面板设置
    func cleanRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(self)
        center.pauseCommand.removeTarget(self)
        center.stopCommand.removeTarget(self)
        center.skipForwardCommand.removeTarget(self)
        center.skipBackwardCommand.removeTarget(self)
        center.changePlaybackPositionCommand.removeTarget(self)
    }
    @objc
    private func onPlay(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        trace.info("OpenPluginBgAudio remote command on play")
        operate(.play)
        return .success
    }

    @objc
    private func onPause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        trace.info("OpenPluginBgAudio remote command on pause")
        operate(.pause)
        return .success
    }
    
    @objc
    private func onStop(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        trace.info("OpenPluginBgAudio remote command on stop")
        operate(.stop)
        return .success
    }

    @objc
    private func onSeek(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let seconds = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime ?? 0
        trace.info("OpenPluginBgAudio remote command on seek: \(seconds)")
        operate(.seek(seconds))
        return .success
    }

    @objc
    private func onSkipForward(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 0
        let expectTime = player.currentTime + interval
        trace.info("OpenPluginBgAudio remote command on skip forward \(expectTime)")
        operate(.seek(expectTime))
        return .success
    }
    
    @objc
    private func onSkipBackward(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? 0
        let expectTime = player.currentTime - interval
        trace.info("OpenPluginBgAudio remote command on skip backward \(expectTime)")
        operate(.seek(expectTime))
        return .success
    }

    /// 更新锁屏面板中的播放信息
    func updateNowPlayingInfo() {
        DispatchQueue.main.async {
            var info: [String: Any] = [:]
            info[MPMediaItemPropertyTitle] = self.title ?? ""
            info[MPMediaItemPropertyPlaybackDuration] = self.player.duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
            info[MPNowPlayingInfoPropertyPlaybackRate] = self.player.playbackRate
            if let coverImage = self.coverImage {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: coverImage.size, requestHandler: { _ in
                    return coverImage
                })
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    
    // 以 uniqueID 作为唯一标识
    override var hash : Int {
        return uniqueID.hash
    }
    
    deinit {
        cleanRemoteCommandCenter()
        trace.info("OpenPluginBgAudio OpenBGAudioPlayer deinit")
    }
    
}

 

