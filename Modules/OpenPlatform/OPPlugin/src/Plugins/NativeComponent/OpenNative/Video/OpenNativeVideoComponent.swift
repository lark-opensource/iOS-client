//
//  OpenNativeVideoComponent.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/4/8.
//

import Foundation
import OPPluginManagerAdapter
import LarkWebviewNativeComponent
import LKCommonsLogging
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSetting
import TTVideoEngine
import OPPluginBiz

final class OpenNativeVideoComponent: OpenPluginNativeComponent, BDPVideoPlayerControlProtocol {
    public static let logger = Logger.oplog(OpenNativeVideoComponent.self, category: "LarkWebviewNativeComponent")
    // 组件标签名字
    override class func nativeComponentName() -> String {
        return "video"
    }
    
    var videoView: (UIView & BDPVideoViewDelegate)?
    var cacheParams: [AnyHashable: Any]?
    
    override var needListenAppPageStatus: Bool { true }
    
    override init() {
        super.init()
        register()
    }
    
    // 组件插入接收，返回view
    override func insert(params: [AnyHashable: Any], trace: OPTrace) -> UIView? {
        guard let engine = webView as? BDPWebView else {
            // 限定BDPWebView范围
            Self.logger.error("webView is not kind of BDPWebView")
            return nil
        }
        
        trace.info("insertVideoPlw ayer start")
        
        let model = OpenNativeVideoParams.init(with: params)
        cacheParams = params
        process(uniqueID: engine.uniqueID, model: model, trace: trace, type: .insert)
        
        let videoViewModel = transform(with: model, uniqueID: engine.uniqueID)
        let videoView = OPPluginBizFactory.videoPlayer(model: videoViewModel, componentID: componentID)
        
        videoView.delegate = self
        guard videoView.isKind(of: UIView.self) else {
            trace.error("video component is not UIView")
            return nil
        }
        
        self.videoView = videoView
        trace.info("insertVideoPlayer end")
        return videoView
    }

    // 组件更新
    override func update(nativeView: UIView?, params: [AnyHashable: Any], trace: OPTrace) {
        guard let engine = webView as? BDPWebView else {
            // 限定BDPWebView范围
            Self.logger.error("webView is not kind of BDPWebView")
            return
        }
        
        trace.info("updateVideoPlayer start")
        
        guard let videoView = videoView else {
            trace.error("video component is not UIView")
            return
        }
        
        var resultParams = params
        if let cacheParams = cacheParams {
            resultParams.merge(cacheParams) { new, cache in new }
        }
        
        let model = OpenNativeVideoParams.init(with: resultParams)
        cacheParams = resultParams
        process(uniqueID: engine.uniqueID, model: model, trace: trace, type: .insert)
        
        let videoViewModel = transform(with: model, uniqueID: engine.uniqueID)
        videoView.update(with: videoViewModel)
        
        trace.info("updateVideoPlayer end")
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        Self.logger.info("viewDidAppear")
        videoView?.viewDidAppear?()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        Self.logger.info("viewWillDisappear")
        videoView?.viewWillDisappear?()
    }
    
    // MARK: - API Register
    enum VideoDispatchActionType: String {
        case seek
        case play
        case pause
        case stop
        case requestFullScreen
        case exitFullScreen
        case playbackRate
    }
    
    private func register() {
        registerHandler(for: VideoDispatchActionType.seek.rawValue, paramsType: OpenNativeVideoSeekParams.self) { [weak self] params, _, callback in
            self?.videoView?.seek?(params.data, completion: { success in
                if (success) {
                    callback(.success(data: nil))
                } else {
                    let error = OpenAPIError(errno: OpenNativeVideoDispatchActionErrno.internalError)
                    callback(.failure(error: error))
                }
            })
        }
        
        registerHandler(for: VideoDispatchActionType.play.rawValue) { [weak self] _, _, _ in
            self?.videoView?.play?()
        }
        
        registerHandler(for: VideoDispatchActionType.pause.rawValue) { [weak self] _, _, _ in
            self?.videoView?.pause?()
        }
        
        registerHandler(for: VideoDispatchActionType.stop.rawValue) { [weak self] _, _, _ in
            self?.videoView?.stop?()
        }
        
        registerHandler(for: VideoDispatchActionType.requestFullScreen.rawValue) { [weak self] _, _, _ in
            self?.videoView?.enterFullScreen?()
        }
        
        registerHandler(for: VideoDispatchActionType.exitFullScreen.rawValue) { [weak self] _, _, _ in
            self?.videoView?.exitFullScreen?()
        }
        
        registerHandler(for: VideoDispatchActionType.playbackRate.rawValue, paramsType: OpenNativeVideoPlaybackRateParams.self) { [weak self] params, _, _ in
            self?.videoView?.setPlaybackRate?(params.rate)
        }
    }
    
    // MARK: - BDPVideoPlayerControlProtocol
    func bdp_videoPlayerStateChange(_ state: BDPVideoPlayerState, videoPlayer: (UIView & BDPVideoViewDelegate)!) {
        guard let engine = webView as? BDPWebView else {
            // 限定BDPWebView范围
            Self.logger.error("webView is not kind of BDPWebView")
            return
        }
        let trace = OPTraceService.default().generateTrace(withParent: engine.trace, bizName: "nativeComponentAction")
        trace.info("bdp_videoPlayerStateChangeStart:\(state)")
        
        guard let videoPlayer = videoPlayer else {
            trace.error("videoPlayer is nil")
            return
        }
        
        switch state {
        case .finished:
            onVideoEnded()
        case .playing:
            onVideoPlay()
        case .paused, .break:
            onVideoPause()
        case .timeUpdate:
            onVideoTimeUpdate(params: OpenNativeVideoTimeUpdateResult(currentTime: videoPlayer.currentTime, duration: videoPlayer.duration))
        case .fullScreenChange:
            onVideoFullScreenChange(params: OpenNativeVideoFullScreenChangeResult(fullScreen: videoPlayer.fullScreen, direction: OpenNativeVideoDirection(rawValue: videoPlayer.direction)))
        case .waiting:
            onVideoWaiting()
        case .seekComplete:
            onVideoSeekComplete(params: OpenNativeVideoSeekCompleteResult(currentTime: videoPlayer.currentTime, duration: videoPlayer.duration))
        case .loadedMetaData:
            onVideoLoadedMetadata(params: OpenNativeVideoLoadedMetaDataResult(width: videoPlayer.videoWidth, height: videoPlayer.videoHeight, duration: videoPlayer.duration))
        case .playbackRateChange:
            onVideoPlaybackRateChange(params: OpenNativeVideoPlaybackRateChangeResult(playbackRate: videoPlayer.playbackSpeed))
        case .muteChange:
            onVideoMuteChange(params: OpenNativeVideoMuteChangeResult(isMuted: videoPlayer.muted))
        default:
            break
        }
    }
    
    func bdp_videoControlsToggle(_ show: Bool) {
        onVideoControlsToggle(params: OpenNativeVideoControlsToggleResult(show: show))
    }
    
    func bdp_videoUserAction(_ action: BDPVideoUserAction, value: Bool) {
        var tag: OpenNativeVideoUserAction
        switch action {
        case .play:
            tag = .play
        case .centerPlay:
            tag = .centerplay
        case .fullscreen:
            tag = .fullscreen
        case .mute:
            tag = .mute
        case .retry:
            tag = .retry
        case .back:
            tag = .back
        default:
            return
        }
        if action == .retry || action == .back {
            onVideoUserAction(params: OpenNativeVideoUserActionResult(tag: tag))
        } else {
            onVideoUserAction(params: OpenNativeVideoUserActionResult(tag: tag, value: value))
        }
    }
    
    func bdp_videoError(_ error: Error?) {
        guard let error = error else {
            return
        }
        let videoErr = error.toVideoErrno()
        onErrorFire(videoErr)
    }
    
    func bdp_videoErrorString(_ errorInfo: String) {
        onErrorFire(OpenAPIInnerAudioErrno.innerAudioHigherPriorityFailed(errorString: errorInfo))
    }
    
    private func onErrorFire(_ videoErr: OpenAPIErrnoProtocol) {
        onVideoError(params: OpenNativeVideoErrorResult(errno: videoErr.errno(), errString: videoErr.errString))
        Self.logger.info("video component error, errno: \(videoErr.errno()), errStr: \(videoErr.errString)")
    }
    
    // MARK: - Private
    private func transform(with params: OpenNativeVideoParams, uniqueID: OPAppUniqueID) -> BDPVideoViewModel {
        let model = BDPVideoViewModel()
        model.hide = params.style?.hide ?? false
        model.autoplay = params.autoplay
        model.loop = params.loop
        model.frame = CGRectMake(CGFloat(params.style?.left ?? 0), CGFloat(params.style?.top ?? 0), CGFloat(params.style?.width ?? 0), CGFloat(params.style?.height ?? 0))
        model.data = params.data
        model.filePath = params.filePath
        model.poster = OPPathTransformHelper.buildURL(path: params.poster, uniqueID: uniqueID, tag: "videoComponent")
        model.initialTime = CGFloat(params.initialTime)
        model.duration = 0
        model.objectFit = params.objectFit.rawValue
        model.cacheDir = params.cacheDir
        model.encryptToken = params.encryptToken
        model.muted = params.muted
        model.controls = params.controls
        model.showFullscreenBtn = params.showFullscreenBtn
        model.showPlayBtn = params.showPlayBtn
        model.playBtnPosition = params.playBtnPosition.rawValue
        model.autoFullscreen = params.autoFullscreen
        model.showMuteBtn = params.showMuteBtn
        model.direction = params.direction as NSNumber
        model.header = OpenNativeComponentUtils.checkAndConvertVideoHeader(header: params.header)
        model.showProgress = params.showProgress
        model.title = params.title
        model.showBottomProgress = params.showBottomProgress
        model.showScreenLockButton = params.showScreenLockButton
        model.showSnapshotButton = params.showSnapshotButton
        model.showRateButton = params.showRateButton
        model.enableProgressGesture = params.enableProgressGesture
        model.enablePlayGesture = params.enablePlayGesture
        model.autoPauseIfOutsideScreen = params.autoPauseIfOutsideScreen
        return model
    }
    
    enum APIType: String {
        case insert
        case update
    }
    
    private func process(uniqueID: OPAppUniqueID, model: OpenNativeVideoParams, trace: OPTrace, type: APIType) {
        if (type == .insert) {
            /// cacheDir 老逻辑也是类似的做法，如果因为前置流程或者 tmp 本身为空导致设置了空，会有问题吗？保持一致先把完整日志打上。
            let common = BDPCommonManager.shared()?.getCommonWith(uniqueID)
            let tmpPath = common?.sandbox?.privateTmpPath()
            model.cacheDir = tmpPath ?? ""
            trace.info("setup cache dir", additionalData: [
                "hasCommon": "\(common != nil)",
                "hasSandbox": "\(common?.sandbox != nil)",
                "hasTmpPath": "\(tmpPath != nil)"
            ])
        }
        
        /// FileSystem 不应该包含处理 http/https 等链接，这里为了兼容需要分开处理。
        
        if model.filePath.hasPrefix("https") || model.filePath.hasPrefix("http") {
            // do nothing
        } else {
            do {
                let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: trace, tag: "videoComponent")
                let file = try FileObject(rawValue: model.filePath)

                /// 现在暂时使用兼容接口传递。
                /// BDPVideoViewModel 继承了 JSONModel，filePath 无法直接改造为 OPFileOject。
                /// 这个 viewmodel 本身的设计和使用已经不适应这个时代了，但是旧版 API 还在使用 JSONModel 的能力。
                /// 后续需要先改造 viewModel，再将收敛后的文件能力改造到 viewModel 上，业务使用不感知。
                let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)

                /// 原逻辑需要使用 file:// 域能力
                model.filePath = URL(fileURLWithPath: systemFilePath).absoluteString
            /// 以前的逻辑所有处理的错误都是打了一句错误日志，并没有在 API 上返回错误，这里将这些错误暴露出来，属于新增错误。
            /// 对于 commonManager，common，storageModule 等失败场景，应当返回失败。
            /// 对于 filePath 拿不到或者拿到不可用的场景，就算放过它执行下去，能正常播放吗？
            } catch let error {
                model.filePath = ""
                Self.logger.error("filePath decode error", error: error)
            }
        }
        
        // ⚠️该组件为同层渲染组件，SuperView 为 WKScrollView (WKWebView 解析网页生成的层级节点)
        // WKScrollView 的 [x, y] 为真实的 style.top, style.left
        // 因此该组件 View 相对于父 View 位置应设为 [0, 0]
        model.style?.top = 0
        model.style?.left = 0
    }
}

// MARK: - OPVideoViewDelegate
extension OpenNativeVideoComponent {
    
    enum VideoComponentEventType: String {
        case onVideoPlay
        case onVideoPause
        case onVideoEnded
        case onVideoTimeUpdate
        case onVideoFullScreenChange
        case onVideoWaiting
        case onVideoSeekComplete
        case onVideoError
        case onVideoLoadedMetadata
        case onVideoControlsToggle
        case onVideoUserAction
        case onVideoPlaybackRateChange
        case onVideoMuteChange
    }
    
    func onVideoPlay() {
        fireVideoEvent(event: .onVideoPlay, params: .init())
    }
    
    func onVideoPause() {
        fireVideoEvent(event: .onVideoPause, params: .init())
    }
    
    func onVideoEnded() {
        fireVideoEvent(event: .onVideoEnded, params: .init())
    }
    
    func onVideoTimeUpdate(params: OpenNativeVideoTimeUpdateResult) {
        fireVideoEvent(event: .onVideoTimeUpdate, params: params)
    }
    
    func onVideoFullScreenChange(params: OpenNativeVideoFullScreenChangeResult) {
        fireVideoEvent(event: .onVideoFullScreenChange, params: params)
    }
    
    func onVideoWaiting() {
        fireVideoEvent(event: .onVideoWaiting, params: .init())
    }
    
    func onVideoSeekComplete(params: OpenNativeVideoSeekCompleteResult) {
        fireVideoEvent(event: .onVideoSeekComplete, params: params)
    }
    
    func onVideoError(params: OpenNativeVideoErrorResult) {
        fireVideoEvent(event: .onVideoError, params: params)
    }
    
    func onVideoLoadedMetadata(params: OpenNativeVideoLoadedMetaDataResult) {
        fireVideoEvent(event: .onVideoLoadedMetadata, params: params)
    }
    
    func onVideoControlsToggle(params: OpenNativeVideoControlsToggleResult) {
        fireVideoEvent(event: .onVideoControlsToggle, params: params)
    }
    
    func onVideoUserAction(params: OpenNativeVideoUserActionResult) {
        fireVideoEvent(event: .onVideoUserAction, params: params)
    }
    
    func onVideoPlaybackRateChange(params: OpenNativeVideoPlaybackRateChangeResult) {
        fireVideoEvent(event: .onVideoPlaybackRateChange, params: params)
    }
    
    func onVideoMuteChange(params: OpenNativeVideoMuteChangeResult) {
        fireVideoEvent(event: .onVideoMuteChange, params: params)
    }
    
    private func fireVideoEvent(event: VideoComponentEventType, params: OpenComponentBaseResult) {
        Self.logger.info("fireVideoEvent, event: \(event), params: \(params)")
        fireEvent(event: event.rawValue, params: params.toJSONDict())
    }
}

fileprivate extension Error {
    func toVideoErrno() -> OpenNativeVideoErrno {
        if isTTVideoEngineSrcInvalid() {
            return .fireEvent(.videoSrcInvalid)
        } else if isTTVideoEngineRequestError() {
            return .fireEvent(.videoRequestFailed)
        } else if isTTVideoEngineDNSError() {
            return .fireEvent(.videoDnsLookupFailed)
        } else if isTTVideoEngineError() {
            return .fireEvent(.videoEngineError)
        } else if TTVideoEngineIsNetworkError(_code) {
            return .fireEvent(.videoNetworkError)
        }
        return .commonInternalError
    }
}
