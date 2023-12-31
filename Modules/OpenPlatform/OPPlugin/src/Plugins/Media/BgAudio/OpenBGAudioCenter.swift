//
//  OPBGAudioCenter.swift
//  OPPlugin
//
//  Created by zhysan on 2022/5/19.
//


import EENavigator
import HTTProtocol
import LarkSuspendable
import LarkOpenPluginManager
import LKCommonsLogging
import OPPluginManagerAdapter
import UniverseDesignIcon
import LarkOpenAPIModel
import TTMicroApp

let kBGMSuspendKey = "com.open-platform.bg-audio"

enum OpenBGAudioEvent: String {
    static let OpenBGAudioEventName = "onBgAudioStateChange"
    /// 监听背景音频进入可播放状态事件。 但不保证后面可以流畅播放
    case canplay
    
    /// 监听背景音频自然播放结束事件
    case ended
    
    /// 监听背景音频播放错误事件
    case error
    
    /// 监听用户在系统音乐播放面板点击下一曲事件（仅iOS）
    case next
    
    /// 监听背景音频暂停事件
    case pause
    
    /// 监听背景音频播放事件
    case play
    
    /// 监听用户在系统音乐播放面板点击上一曲事件（仅iOS）
    case prev
    
    /// 监听背景音频完成跳转操作事件
    case seeked
    
    /// 监听背景音频开始跳转操作事件
    case seeking
    
    /// 监听背景音频停止事件
    case stop
    
    /// 监听背景音频播放进度更新事件，只有小程序在前台时会回调
    /// 这个是 JSSDK 自己处理，客户端不回传
    // case onTimeUpdate
    
    /// 监听音频加载中事件。当音频因为数据不足，需要停下来加载时会触发
    case waiting
    
    var stateData: [AnyHashable: Any] {
        ["state": rawValue]
    }
}

protocol OpenBGAudioCenterListener: AnyObject {
    func handleEvent(_ event: OpenBGAudioEvent, data: [AnyHashable: Any]?)
    func handleEvent(_ event: OpenBGAudioEvent)
}


extension OPAPIParamOperateBgAudio {
    func toBGAudioOperate() -> OpenBGAudioPlayer.OpenBGAudioOperate {
        switch operationType {
        case .play:
            return .play
        case .pause:
            return .pause
        case .stop:
            return .stop
        case .seek:
            if let time = currentTime {
                return .seek(time / 1000)
            } else {
                return .seek(nil)
            }
        }
    }
}

extension OpenBGAudioCenter: OpenBGAudioPlayerDelegate {
    
    func audioPlayer(_ audioPlayer: OpenBGAudioPlayer, playStateDidChange state: OpenBGAudioPlayer.OpenBGAudioPlayerPlayState) {
    
        let uniqueID = audioPlayer.uniqueID
        
        guard let apiContext = findAudio(uniqueID: uniqueID)?.apiContext else {
            // 绝不可能事件，不过还是记录下
            OPBGMLogger.error("playStateDidChange findAudio error uniqueID: \(uniqueID)")
            return
        }
        
        apiContext.apiTrace.info("OpenPluginBgAudio playStateDidChange state: \(state) uniqueID: \(uniqueID)")
        let isPlaying = state == .play
        
        // play 情况下，要保活该小程序
        uniqueID.isEnableAutoDestroy = !isPlaying
        apiContext.apiTrace.info("OpenPluginBgAudio playStateDidChange, isAutoRelease: \(!isPlaying) uniqueID: \(uniqueID)")
        
        // 如果不再播放，且在后台，则要启动自动回收计时
        if !isPlaying && !isHostForeground(uniqueID: uniqueID) {
            apiContext.apiTrace.info("OpenPluginBgAudio playStateDidChange, ready to release, uniqueID: \(uniqueID)")
            BDPWarmBootManager.shared().startTimerToReleaseView(with: uniqueID)
        }
        
        // 如果已经停止，则释放全部音频资源
        if state == .stop || state == .error {
            apiContext.apiTrace.info("OpenPluginBgAudio playStateDidChange did stop uniqueID: \(uniqueID)")
            closeAndRelease()
        }
        
        // 只处理当前的音频音频对象
        if currentAudio != audioPlayer {
            apiContext.apiTrace.info("OpenPluginBgAudio playStateDidChange isEnterBackgroud uniqueID: \(uniqueID)")
            return
        }
        
        suspendVC?.updatePlayingState(isPlaying)
        suspendMiniView.animate(isPlaying)
    }
}

final class OpenBGAudioCenter: NSObject {
    
    static let shared = OpenBGAudioCenter()
    
    /// 浮窗点击时弹出的播放控制器
    private var suspendVC: OpenBGAudioController? = nil
    
    /// 浮窗 View
    private lazy var suspendMiniView = OpenBGMediaSuspendView(frame: .zero)
    
    /// 小程序正在跳转的当前页面路径 todo wangfei 确认下要不要隔离
    private var currentPage: OpenPluginHostPageURL?
    
    /// 当前正在播放的音频实例，按照 app 维度做隔离
    private weak var currentAudio: OpenBGAudioPlayer? {
        willSet {
            // 绑定新的实例时，会将原本的进行暂停处理
            if currentAudio?.playState == .playing {
                if let _ = newValue {
                    currentAudio?.operate(.pause)
                    currentAudio?.cleanRemoteCommandCenter()
                }
            }
        }
    }
    
    
    private lazy var audioPlayers: Set<OpenBGAudioPlayer> = []
    
    /// 注册音频播放实例
    func register(audio: OpenBGAudioPlayer) {
        audio.apiContext.apiTrace.info("OpenPluginBgAudio register, uniqueID: \(audio.uniqueID)")
        audioPlayers.insert(audio)
    }
    
    /// 解绑音频播放实例
    func unregister(uniqueID: OPAppUniqueID?) {
        OPBGMLogger.info("unregister, uniqueID: \(uniqueID)")
        if let audioPlayer = findAudio(uniqueID: uniqueID) {
            audioPlayer.apiContext.apiTrace.info("OpenPluginBgAudio unregister uniqueID: \(audioPlayer.uniqueID)")
            if currentAudio == audioPlayer {
                audioPlayer.apiContext.apiTrace.info("OpenPluginBgAudio currentAudio unregister uniqueID: \(audioPlayer.uniqueID)")
                closeAndRelease()
            }
            audioPlayers.remove(audioPlayer)
        }
        
    }
    
    private func unregisterAll() {
        audioPlayers.removeAll()
    }
    
    /// 获取音频实例
    private func findAudio(uniqueID: OPAppUniqueID?) -> OpenBGAudioPlayer? {
        if let uniqueID = uniqueID {
            return audioPlayers.first { $0.uniqueID == uniqueID }
        } else {
            return nil
        }
    }
    
    // MARK: - APIs
    
    // 绑定音频数据，app 维度隔离
    func setState(_ srcData: OPAPIParamSetBgAudioState, apiContext: OpenAPIContext, listener: OpenBGAudioCenterListener) {
        apiContext.apiTrace.info("OpenPluginBgAudio setState, data: \(srcData)")
        if let audio = findAudio(uniqueID: apiContext.uniqueID) {
            apiContext.apiTrace.info("OpenPluginBgAudio setState, data: \(srcData), uniqueID: \(audio.uniqueID)")
            if audio.srcData.src == srcData.src {
                // 资源路径如果相同的话，就啥也不干
                // 这里其实不算 error，一定程度符合预期，所以用个 warning
                apiContext.apiTrace.warn("OpenPluginBgAudio setState duplicate, data: \(srcData)")
                return
            }
            audio.srcData = srcData
            setState(audio: audio, apiContext: apiContext)
        } else {
            guard let uniqueID = apiContext.uniqueID else { return }
            let audio = OpenBGAudioPlayer(uniqueID: uniqueID,
                                          apiContext: apiContext,
                                          srcData: srcData,
                                          listener: listener,
                                          delegate: self)
            register(audio: audio)
            apiContext.apiTrace.info("OpenPluginBgAudio setState register, data: \(srcData), uniqueID: \(audio.uniqueID)")
            setState(audio: audio, apiContext: apiContext)
        }
    }
    
    private func setState(audio: OpenBGAudioPlayer, apiContext: OpenAPIContext) {
        audio.bindData(apiContext: apiContext)
    }
    
    // 获取播放状态，app 维度隔离
    func getState(apiContext: OpenAPIContext) throws -> OPAPIResultGetBgAudioState {
        guard let audio = findAudio(uniqueID: apiContext.uniqueID) else {
            throw OpenAPIError(errno: OpenAPIBGAudioErrno.noneAudio)
        }
        // 这里调用会十分频繁，所以就不留 log 了
        return audio.getState()
    }
    
    // 播放控制
    func operate(_ operation: OPAPIParamOperateBgAudio, apiContext: OpenAPIContext) throws {
        guard let audio = findAudio(uniqueID: apiContext.uniqueID)  else {
            throw OpenAPIError(errno: OpenAPIBGAudioErrno.noneAudio)
        }
        
        if operation.operationType == .play && currentAudio != audio {
            audio.apiContext.apiTrace.info("OpenPluginBgAudio replace audio from \(currentAudio?.uniqueID) to \(audio.uniqueID)")
            // 第二个程序进来了
            currentAudio = audio
            currentPage = audio.pageURL
            if isSuspendViewShow() {
                removeFromSuspend()
            }
        }
        audio.operate(operation.toBGAudioOperate())
    }
    
    func appEnterBackground() {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio appEnterBackground")
        if currentAudio?.playState == .playing {
            addToSuspend()
        }
    }
    
    func appEnterForeground() {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio appEnterForeground")
        // 进入前台时，如果正在播放且当前页面并不是播放页面，则添加浮窗，wangfei todo 隔离
        if currentAudio?.playState == .playing && currentPage != currentAudio?.pageURL {
            addToSuspend()
        } else {
            removeFromSuspend()
        }
    }
    
    func onHostPageChanged(url: OpenPluginHostPageURL, apiContext: OpenAPIContext) {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio onHostPageChanged, crrentURL: \(currentPage) url: \(url)")
        // 即将离开音频播控页
        if ((currentPage != url && currentPage == currentAudio?.pageURL)) {
            if currentAudio?.playState == .playing {
                addToSuspend()
            } else {
                removeFromSuspend()
            }
        }
        
        // 进入音频播控页，则关闭浮窗
        if currentAudio?.pageURL == url {
            removeFromSuspend()
        }
                
        currentPage = url
    }

    private func isSuspendViewShow() -> Bool {
        SuspendManager.shared.customView(forKey: kBGMSuspendKey) != nil
    }
    
    private func addToSuspend() {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio suspend if needed")

        if isSuspendViewShow() {
            currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio suspend already")
            return
        }
        
        guard let currentAudio = currentAudio else {
            currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio suspend ignore because currentAudio is nil")
            return
        }
                
        currentAudio.apiContext.apiTrace.info("OpenPluginBgAudio suspend start")
        OpenBGAudioTracker.windowDidShow(apiContext: currentAudio.apiContext)
        
        suspendMiniView.animate(currentAudio.playState == .playing)
        suspendMiniView.iconView.image = currentAudio.coverImage
        
        SuspendManager.shared.addCustomView(
            suspendMiniView,
            size: CGSize(width: 64, height: 72),
            forKey: kBGMSuspendKey
        ) { [unowned self] in
            self.currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio tap handler invoke")
            self.toBgController()
            self.removeFromSuspend()
            if let currentAudio = self.currentAudio {
                OpenBGAudioTracker.windowDidClick(apiContext: currentAudio.apiContext)
            }
        }

    }
    
    private func removeFromSuspend() {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio removeFromSuspend")
        SuspendManager.shared.removeCustomView(forKey: kBGMSuspendKey)
    }
    
    private func isHostForeground(uniqueID: OPAppUniqueID) -> Bool {
        BDPCommonManager.shared().getCommonWith(uniqueID)?.isForeground ?? false
    }

    private func toBgController() {
        guard let from = Navigator.shared.mainSceneTopMost else { // Global
            currentAudio?.apiContext.apiTrace.error("OpenPluginBgAudio vc show fail: main scene top most nil")
            return
        }
        if let currentDataModel = currentAudio {
            currentDataModel.apiContext.apiTrace.info("OpenPluginBgAudio navi to control vc, from: \(from)")
            let vc = OpenBGAudioController()
            vc.delegate = self
            vc.modalPresentationStyle = .overCurrentContext
            vc.updateMediaInfo(title: currentDataModel.title, icon: currentDataModel.coverImage)
            vc.updatePlayingState(currentDataModel.playState == .playing)
            Navigator.shared.present(vc, from: from) // Global
            suspendVC = vc
        }
    }
}


// MARK: - OpenBGAudioControllerDelegate
extension OpenBGAudioCenter: OpenBGAudioControllerDelegate {
    // 播放控制器页面暂停被点击
    func viewController(_ vc: OpenBGAudioController, onPlay: Bool) {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio viewController onPlay: \(onPlay)")
        
        if let current = currentAudio {
            let playEvent: OpenBGAudioTracker.WindowPlayControlEvent.PlayControlValue = onPlay ? .continue : .stop
            OpenBGAudioTracker.windowPlayControl(apiContext: current.apiContext, controlEvent: .playControl(playEvent))
        }
        
        if onPlay {
            currentAudio?.operate(.play)
        } else {
            currentAudio?.operate(.pause)
        }
    }
    
    // 播放控制器页面关闭被点击
    func viewControllerClose(_ vc: OpenBGAudioController, byCloseBtn: Bool) {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio viewController onClose by Btn: \(byCloseBtn)")
        vc.dismiss(animated: true)
        if byCloseBtn {
            if let currentAudio = currentAudio {
                currentAudio.operate(.stop)
                OpenBGAudioTracker.windowPlayControl(apiContext: currentAudio.apiContext, controlEvent: .close)
            }
        } else {
            addToSuspend()
        }
    }
    
    // 清理释放相关资源
    private func closeAndRelease() {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio closeAndRelease")
        executeOnMainQueueAsync {
            self.suspendMiniView.animate(false)
            self.removeFromSuspend()
            self.suspendVC?.dismiss(animated: false)
            self.suspendVC = nil
        }
        
    }
    
    // 播放控制器页面标题被点击
    func viewControllerOnDetail(_ vc: OpenBGAudioController) {
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio viewController onDetail")
        if let currentAudio = currentAudio {
            OpenBGAudioTracker.windowPlayControl(apiContext: currentAudio.apiContext, controlEvent: .title)
        }
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            guard let currentAudio = self.currentAudio, let url = currentAudio.routeURL else {
                return
            }
            self.currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio viewController dismissed")
            // 无脑加一次，为了防止小程序 route 后还是当前页导致浮窗消失，如果 route 完目标页是播放页会自行消失的
            self.addToSuspend()
            self.route(toURL: url, uniqueID: currentAudio.uniqueID)
        }
    }
    
    // 跳转到目标 url，这里主要是点击外面音频控制器的标题跳转
    private func route(toURL url: URL, uniqueID: OPAppUniqueID) {
        let from = Navigator.shared.mainSceneTopMost // Global
        guard let routerPlugin = BDPTimorClient.shared().routerPlugin.sharedPlugin() as? BDPRouterPluginDelegate else {
            return
        }
        let result = routerPlugin.bdp_openSchema?(with: url, uniqueID: uniqueID, appType: uniqueID.appType, external: false, from: from, whiteListChecker: nil)
        
        currentAudio?.apiContext.apiTrace.info("OpenPluginBgAudio openSchema end, result \(result)")
    }
    
    func viewControllerRequestTimeInfo(_ vc: OpenBGAudioController) -> (current: TimeInterval, total: TimeInterval) {
        let state = currentAudio?.getState()
        let currentTime = state?.currentTime ?? 0
        let duration = state?.duration ?? 0
        return (currentTime / 1000, duration / 1000)
    }
}


