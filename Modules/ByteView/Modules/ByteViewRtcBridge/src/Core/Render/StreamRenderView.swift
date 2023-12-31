//
//  StreamRenderView.swift
//  ByteView
//
//  Created by liujianlong on 2021/1/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewRTCRenderer

public protocol StreamRenderViewListener: AnyObject {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool)
    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?)
    func streamRenderViewDidChangeStreamKey(_ renderView: StreamRenderView, streamKey: RtcStreamKey?)
}

public extension StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {}
    func streamRenderViewDidChangeVideoFrameSize(_ renderView: StreamRenderView, size: CGSize?) {}
    func streamRenderViewDidChangeStreamKey(_ renderView: StreamRenderView, streamKey: RtcStreamKey?) {}
}

public final class StreamRenderView: UIView {
    public private(set) var streamKey: RtcStreamKey? {
        didSet {
            if streamKey != oldValue {
                setNeedsLayout()
                updateSceneUpdateObserver()
            }
        }
    }

    @RwAtomic
    public private(set) var isRendering: Bool = false

    @RwAtomic
    public var isVideoMirrored: Bool = true {
        // 应用层面是否开启镜像
        didSet {
            Logger.renderView.info("didSet isVideoMirrored \(isVideoMirrored), oldValue = \(oldValue)")
            if self.isVideoMirrored != oldValue {
                self.renderProxy?.isRenderMirrorEnabled = self.isLocalRenderMirrorEnabled && self.isVideoMirrored
            }
        }
    }

    @RwAtomic
    public var isLocalRenderMirrorEnabled: Bool = true {
        // RenderView是否支持镜像, 默认支持
        didSet {
            if isLocalRenderMirrorEnabled != oldValue {
                self.renderProxy?.isRenderMirrorEnabled = self.isLocalRenderMirrorEnabled && self.isVideoMirrored
            }
        }
    }

    /// 是否将本地竖屏视频流裁剪为 1:1 渲染
    /// 默认值为 true
    /// 1v1 VideoCall CallOut 页面, Webinar 直播主播页面，需要设置为 false，以显示完整的 9:16 视频
    public var cropLocalPortraitTo1x1: Bool = true {
        didSet {
            guard cropLocalPortraitTo1x1 != oldValue else {
                return
            }
            // 需要在订阅视频流之前完成设置
            assert(!checkSubscribeCondition())
        }
    }

    public var multiResSubscribeConfig: MultiResSubscribeConfig? {
        didSet {
            if self.multiResSubscribeConfig != oldValue && self.multiResSubscribeConfig != nil {
                self.updateSubscribeConfig()
            }
        }
    }

    public let videoContentLayoutGuide = UILayoutGuide()
    public private(set) var videoFrameSize: CGSize?
    public var renderMode: ByteViewRenderMode = .renderModeAuto {
        didSet {
            if renderMode != oldValue {
                setNeedsLayout()
                updateForceCrop1x1()
            }
        }
    }

    @RwAtomic
    private var isSipOrRoom: Bool = false

    private var renderProxy: StreamRenderer?
    private var diagnosticStamp: Int = Int.random(in: 0...Int.max)

    private let listeners = Listeners<StreamRenderViewListener>()
    private var renderingCallbacks = [((Bool) -> Void)]()

    private var forceCrop1x1: VideoStreamForceCrop1x1Mode = .none
    private var subscribeConfig: VideoSubscribeConfig = VideoSubscribeConfig(res: 480, fps: 30)

    private(set) var videoView: UIView?
    private weak var debugView: StreamDebugView?

    #if RTCBRIDGE_HAS_SDK
    private let rtc: RtcVideoStream = VideoStreamManager.shared
    #else
    private let rtc: RtcVideoStream = MockRtcVideoStream()
    #endif

    private lazy var videoContentTopCst = videoContentLayoutGuide.topAnchor.constraint(equalTo: self.topAnchor)
    private lazy var videoContentBottomCst = videoContentLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    private lazy var videoContentLeftCst = videoContentLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor)
    private lazy var videoContentRightCst = videoContentLayoutGuide.rightAnchor.constraint(equalTo: self.rightAnchor)

    private(set) var interfaceOrientation: UIInterfaceOrientation = .portrait
    private(set) var isExternalDisplay: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addLayoutGuide(videoContentLayoutGuide)
        videoContentTopCst.isActive = true
        videoContentLeftCst.isActive = true
        videoContentRightCst.isActive = true
        videoContentBottomCst.isActive = true

        setupAppActiveObserver()
        Logger.renderView.info("init \(self.description)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Logger.renderView.info("deinit \(self.description)")
        NotificationCenter.default.removeObserver(self)
        // 视图销毁时将stream的priority设置为默认
        if checkSubscribeCondition(), let key = self.streamKey {
            assertionFailure()
            self.updatePriority(.low)
            self.unsubscribeStream(key, reason: "deinit")
        }
    }

    func setupAppActiveObserver() {
        self.appIsActive = UIApplication.shared.applicationState != .background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    private func updateSceneUpdateObserver() {
        guard let streamKey = self.streamKey, streamKey == .local else {
            NotificationCenter.default.removeObserver(self, name: VCNotification.didUpdateWindowSceneNotification, object: nil)
            return
        }
        handleWindowSceneLayoutContextUpdated()
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowSceneLayoutContextUpdated),
                                               name: VCNotification.didUpdateWindowSceneNotification,
                                               object: nil)
    }

    @objc private func handleWindowSceneLayoutContextUpdated() {
        if #available(iOS 13.0, *) {
            if let scene = self.videoView?.window?.windowScene {
                self.interfaceOrientation = scene.interfaceOrientation
                self.isExternalDisplay = scene.screen != .main
                return
            }
        }
        self.interfaceOrientation = UIApplication.shared.statusBarOrientation
        if let window = self.window {
            self.isExternalDisplay = window.screen != .main
        } else {
            self.isExternalDisplay = false
        }
    }

    @objc func willEnterForeground() {
        appIsActive = true
    }

    @objc func didEnterBackground() {
        appIsActive = false
    }

    private var maxVideoPixelSize: CGFloat = 4096.0
    private var screenScale: CGFloat { self.window?.screen.scale ?? (self.traitCollection.displayScale > 0 ? self.traitCollection.displayScale : 1.0) }

    // nolint: long_function, cyclomatic_complexity
    public override func layoutSubviews() {
        guard Thread.isMainThread else {
            assertionFailure("layoutSubviews in background thread")
            return
        }
        super.layoutSubviews()
        guard let videoView = self.videoView, var videoSize = self.videoFrameSize, videoSize.width >= 1 && videoSize.height >= 1,
              self.bounds.width >= 1 && self.bounds.height >= 1 else {
            return
        }
        let contentScaleFactor: CGFloat = self.screenScale
        videoSize.width /= contentScaleFactor
        videoSize.height /= contentScaleFactor
        var videoRatio = videoSize.width / videoSize.height
        let viewRatio = self.bounds.width / self.bounds.height

        enum DrawMode {
            case aspectFit
            case aspectFill
        }

        let drawMode: DrawMode
        switch renderMode {
        case .renderModeFit:
            drawMode = .aspectFit
        case .renderModeHidden:
            drawMode = .aspectFill
        case .renderModeAuto:
            if videoRatio > 1.0 && viewRatio > 1.0
                || videoRatio < 1.0 && viewRatio < 1.0 {
                // 视频流 和 view 朝向相同
                drawMode = .aspectFill
            } else {
                drawMode = .aspectFit
            }
        case .renderModeFill16x9:
            if abs(videoRatio - 16.0/9.0) < 0.01 {
                drawMode = .aspectFill
            } else {
                drawMode = .aspectFit
            }
        case .renderModeFit1x1:
            if abs(videoRatio - 1.0) < 0.01 {
                drawMode = .aspectFit
            } else {
                drawMode = .aspectFill
            }
        case .renderModePadPortraitFloating:
            drawMode = .aspectFit
        case .renderModePadGallery:
            // 具体规则见: https://bytedance.feishu.cn/docx/doxcnkL5Kt6OP0UNL26fyi5nvoc
            if let key = self.streamKey, key.isLocal {
               drawMode = .aspectFit
            } else {
                if videoRatio > 1.0 || viewRatio <= 1.25 {
                    drawMode = .aspectFill
                } else {
                    drawMode = .aspectFit
                }
            }
        }

        let videoViewWidth: CGFloat
        let videoViewHeight: CGFloat
        switch drawMode {
        case .aspectFill:
            if videoRatio > viewRatio {
                videoViewWidth = self.bounds.height * videoRatio
                videoViewHeight = self.bounds.height
            } else {
                videoViewWidth = self.bounds.width
                videoViewHeight = self.bounds.width / videoRatio
            }
        case .aspectFit:
            if videoRatio > viewRatio {
                videoViewWidth = self.bounds.width
                videoViewHeight = self.bounds.width / videoRatio
            } else {
                videoViewWidth = self.bounds.height * videoRatio
                videoViewHeight = self.bounds.height
            }
        }
        let videoViewFrame = CGRect(x: (self.bounds.width - videoViewWidth) * 0.5,
                                    y: (self.bounds.height - videoViewHeight) * 0.5,
                                    width: videoViewWidth,
                                    height: videoViewHeight)

        self.videoContentTopCst.constant = videoViewFrame.minY - self.bounds.minY
        self.videoContentBottomCst.constant = videoViewFrame.maxY - self.bounds.maxY
        self.videoContentLeftCst.constant = videoViewFrame.minX - self.bounds.minX
        self.videoContentRightCst.constant = videoViewFrame.maxX - self.bounds.maxX

        let videoPixelSize = max(videoViewWidth, videoViewHeight) * contentScaleFactor
        if videoPixelSize > self.maxVideoPixelSize {
            Logger.renderView.warn("drawable dimension \(videoPixelSize) exceeds \(self.maxVideoPixelSize)")
            let scale = videoPixelSize / self.maxVideoPixelSize
            if let animation = self.layer.animation(forKey: "bounds.size") {
                CATransaction.begin()
                CATransaction.setAnimationDuration(animation.duration)
                CATransaction.setAnimationTimingFunction(animation.timingFunction)
                videoView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                videoView.bounds = CGRect(origin: .zero,
                                          size: CGSize(width: videoViewWidth / scale, height: videoViewHeight / scale))
                videoView.layer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
                CATransaction.commit()
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                videoView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                videoView.bounds = CGRect(origin: .zero,
                                          size: CGSize(width: videoViewWidth / scale, height: videoViewHeight / scale))
                videoView.layer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
                CATransaction.commit()
            }
        } else {
            if rendererType == .metalLayer {
                videoView.layer.setAffineTransform(.identity)
            }
            videoView.frame = self.pixelAlignedRect(for: videoViewFrame)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let cfg = self.multiResSubscribeConfig, cfg.respectViewSize {
                self.updateSubscribeConfig()
            }
        }
    }

    private func updateForceCrop1x1() {
        guard let key = self.streamKey else { return }
        let forceCrop1x1: VideoStreamForceCrop1x1Mode
        if key.isLocal {
            forceCrop1x1 = .none
        } else if self.renderMode == .renderModePadGallery {
            forceCrop1x1 = .cropHeight
        } else if self.renderMode == .renderModePadPortraitFloating {
            forceCrop1x1 = .alwaysCrop
        } else {
            forceCrop1x1 = .none
        }
        if forceCrop1x1 != self.forceCrop1x1 {
            self.forceCrop1x1 = forceCrop1x1
            self.renderProxy?.forceCrop1x1 = forceCrop1x1
        }
    }

    private func updateSubscribeConfig() {
        assert(Thread.isMainThread)
        guard let multiResConfig = self.multiResSubscribeConfig else {
            assert(self.streamKey == nil || self.streamKey == .local)
            return
        }
        var cfg = multiResConfig.normal
        if self.isSipOrRoom, let sipOrRoomCfg = multiResConfig.sipOrRoom {
            cfg = sipOrRoomCfg
        }
        var subscribeConfig = self.subscribeConfig
        subscribeConfig.res = cfg.res
        subscribeConfig.fps = cfg.fps
        subscribeConfig.videoSubBaseLine = RtcSubscribeVideoBaseline(goodVideoPixelBaseline: cfg.goodRes, goodVideoFpsBaseline: cfg.goodFps, badVideoPixelBaseline: cfg.badRes, badVideoFpsBaseline: cfg.badFps)
        if multiResConfig.respectViewSize, self.bounds.width >= 1.0, self.bounds.height >= 1.0 {
            subscribeConfig.res = min(subscribeConfig.res,
                                  Int(self.bounds.width * screenScale * CGFloat(multiResConfig.viewSizeScale)),
                                  Int(self.bounds.height * screenScale * CGFloat(multiResConfig.viewSizeScale)))
        }
        if self.subscribeConfig != subscribeConfig {
            self.subscribeConfig = subscribeConfig
            if let key = self.streamKey, let renderer = self.renderProxy {
                renderer.subscribeConfig = subscribeConfig
                self.rtc.setSubscribeConfig(subscribeConfig, for: key, renderer: renderer)
            }
        }
    }

    private func pixelAlignedRect(for rect: CGRect) -> CGRect {
        let scale = self.screenScale
        let reverseScale = 1.0 / scale
        let alignedRect = rect.applying(CGAffineTransform(scaleX: scale, y: scale)).integral
            .applying(CGAffineTransform(scaleX: reverseScale, y: reverseScale))
        assert(
            abs(alignedRect.minY - rect.minY) <= 1.0
            && abs(alignedRect.maxY - rect.maxY) <= 1.0
            && abs(alignedRect.minX - rect.minX) <= 1.0
            && abs(alignedRect.maxX - rect.maxX) <= 1.0
        )
        return alignedRect
    }

    private func subscribeStream(_ key: RtcStreamKey) {
        if let renderer = self.renderProxy {
            self.rtc.subscribe(key: key, renderer: renderer)
        } else {
            assertionFailure("renderProxy is nil")
        }
        checkSubscribeTimeout(for: key)
    }

    private func unsubscribeStream(_ key: RtcStreamKey, reason: String) {
        if let renderer = self.renderProxy {
            self.rtc.unsubscribe(key: key, delay: unsubscribeDelay, renderer: renderer, reason: reason)
        } else {
            assertionFailure("renderProxy is nil")
        }
    }

    private func checkSubscribeCondition() -> Bool {
        guard let streamKey = self.streamKey else {
            return false
        }
        return (appIsActive || shouldIgnoreAppState)
        && isCellVisible
        && isAttachedToWindow
        && (!self.isVoiceMode || streamKey.isLocal || streamKey.isScreen)
    }

    private func updateSubscription(reason: @autoclosure () -> String, action: () -> Void) {
        let prevShouldSub = checkSubscribeCondition()
        action()
        let curShouldSub = checkSubscribeCondition()
        if prevShouldSub == curShouldSub {
            return
        }

        if prevShouldSub, let key = self.streamKey {
            self.unsubscribeStream(key, reason: reason())
        }

        self.resetRenderProxy()

        if curShouldSub, let key = self.streamKey {
            self.subscribeStream(key)
        }
    }

    /// PIP 模式 APP 在后台时也需要订阅渲染视频流
    private var _shouldIgnoreAppState: Bool = false
    public var shouldIgnoreAppState: Bool {
        get {
            _shouldIgnoreAppState
        }
        set {
            guard _shouldIgnoreAppState != newValue else {
                return
            }
            updateSubscription(reason: "ignoreAppState \(newValue)") {
                _shouldIgnoreAppState = newValue
            }
        }
    }

    public var rendererType: ByteViewRendererType = .metalLayer {
        didSet {
            guard rendererType != oldValue else {
                return
            }
            Logger.renderView.info("rendererType change: \(rendererType)")
            // 需要在订阅视频流之前完成设置
            assert(!checkSubscribeCondition())
        }
    }

    /// PIP模式缓存复用ByteViewSampleBufferLayerView，减少卡死
    public var sampleBufferRenderView: ByteViewRenderView?

    /// 应用进入后台时需要取消订阅视频流
    private var _appIsActive: Bool = UIApplication.shared.applicationState != .background
    public var appIsActive: Bool {
        get {
            _appIsActive
        }

        set {
            guard newValue != _appIsActive else {
                return
            }
            updateSubscription(reason: "AppIsActive: \(newValue)") {
                _appIsActive = newValue
            }
        }
    }

    /// 判断 StreamRenderView 是否被加入视图层级。
    /// 如果不在视图层级中，不需要订阅视频流。
    private var _isAttachedToWindow: Bool = false
    public var unsubscribeDelay: TimeInterval?
    public var isAttachedToWindow: Bool {
        get {
            _isAttachedToWindow
        }

        set {
            guard _isAttachedToWindow != newValue else {
                return
            }
            updateSubscription(reason: "AttachToWindow: \(newValue)") {
                _isAttachedToWindow = newValue
            }
        }
    }

    /// StreamRenderView 在 UICollectionView 中，需要额外考虑 `willDisplayCell` 事件，决定是否订阅视频流
    /// isCellVisible 初始值为 true, 不影响订阅条件判定
    private var _isCellVisible = true
    public var isCellVisible: Bool {
        get {
            _isCellVisible
        }

        set {
            guard _isCellVisible != newValue else {
                return
            }
            updateSubscription(reason: "CellVisible \(newValue)") {
                _isCellVisible = newValue
            }
        }
    }

    private var _isVoiceMode: Bool = false
    public var isVoiceMode: Bool {
        get { _isVoiceMode }
        set {
            guard _isVoiceMode != newValue else {
                return
            }
            updateSubscription(reason: "VoiceModeChange \(newValue)") {
                _isVoiceMode = newValue
            }
        }
    }

    public func setStreamKey(_ newKey: RtcStreamKey?, isSipOrRoom: Bool = false) {
        Logger.renderView.info("\(self) setStreamKey(\(newKey?.description ?? "<nil>"))")
        guard newKey != self.streamKey else {
            if self.isSipOrRoom != isSipOrRoom {
                self.isSipOrRoom = isSipOrRoom
                updateSubscribeConfig()
                updatePriority()
            }
            return
        }

        var oldKey: RtcStreamKey?
        if checkSubscribeCondition() {
            oldKey = self.streamKey
        }

        self.streamKey = newKey
        updateForceCrop1x1()

        if let unsubKey = oldKey {
            self.unsubscribeStream(unsubKey, reason: "SubOtherStream")
        }

        self.resetRenderProxy()

        if let newKey = newKey, checkSubscribeCondition() {
            self.subscribeStream(newKey)
        }
        self.updatePriority()
        self.listeners.forEach { $0.streamRenderViewDidChangeStreamKey(self, streamKey: newKey) }
    }

    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if let screen = newWindow?.screen {
            self.maxVideoPixelSize = max(screen.nativeBounds.width, screen.nativeBounds.height, 4096.0)
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        let isAttachedToWindow = self.window != nil
        handleMoveToWindowEvent(isAttachedToWindow: isAttachedToWindow)
    }

    private func updatePriority(_ priority: RtcRemoteUserPriority? = nil) {
        guard let streamKey = self.streamKey else {
            return
        }
        if streamKey.isLocal {
            return
        }
        let computedPriority: RtcRemoteUserPriority
        if let priority = priority {
            computedPriority = priority
        } else if self.isSipOrRoom, let priority = self.multiResSubscribeConfig?.sipOrRoomPriority {
            computedPriority = priority.rtcPriority
        } else if let priority = self.multiResSubscribeConfig?.priority {
            computedPriority = priority.rtcPriority
        } else {
            computedPriority = .low
        }
        self.rtc.setPriority(computedPriority, for: streamKey)
    }

    // 优化视图结构调整时，isAttachedToWindow 事件处理
    // - isAttachedToWindow: false -> true, 立即处理
    // - isAttachedToWindow: true -> false, 在下一个 runloop 中延迟处理，避免视图闪烁
    private var pendingIsAttachedToWindow: Bool?
    private func handleMoveToWindowEvent(isAttachedToWindow: Bool) {
        assert(Thread.isMainThread)
        if pendingIsAttachedToWindow != nil {
            pendingIsAttachedToWindow = isAttachedToWindow
            return
        }

        if self.isAttachedToWindow == isAttachedToWindow {
            return
        }

        if !self.isAttachedToWindow {
            self.isAttachedToWindow = isAttachedToWindow
        } else {
            pendingIsAttachedToWindow = isAttachedToWindow
            DispatchQueue.main.async {
                assert(self.pendingIsAttachedToWindow != nil)
                if let pendingIsAttachedToWindow = self.pendingIsAttachedToWindow {
                    self.isAttachedToWindow = pendingIsAttachedToWindow
                    self.pendingIsAttachedToWindow = nil
                }
            }
        }
    }

    // NOTE: 调用方需要确保已经取消订阅
    private func resetRenderProxy() {
        if let oldRenderProxy = self.renderProxy {
            oldRenderProxy.onRenderPaused()
            oldRenderProxy.delegate = nil
            oldRenderProxy.frameReceiver = nil
            self.renderProxy = nil
        }

        if let streamKey = self.streamKey {
            let renderProxy = StreamRenderer(rendererType: self.rendererType,
                                             parentInfo: self.description, streamKey: streamKey,
                                             isRenderMirrorEnabled: self.isLocalRenderMirrorEnabled && self.isVideoMirrored,
                                             cropLocalPortraitTo1x1: self.cropLocalPortraitTo1x1,
                                             subscribeConfig: self.subscribeConfig, forceCrop1x1: self.forceCrop1x1)
            self.renderProxy = renderProxy
            renderProxy.delegate = self
        }
    }

    private lazy var addressInfo = "\(Unmanaged.passUnretained(self).toOpaque())"
    public override var description: String {
        return "StreamRenderView<\(addressInfo)>\(streamKey?.description ?? "<nil>")"
    }

    private static let subscribeTimeoutInterval: DispatchTimeInterval = .seconds(12)
    private func checkSubscribeTimeout(for key: RtcStreamKey) {
        diagnosticStamp &+= 1
        if key.isLocal { return }
        let stamp = diagnosticStamp
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.subscribeTimeoutInterval) { [weak self] in
            guard let self = self, self.diagnosticStamp == stamp, self.streamKey == key else { return }
            if !self.isRendering && self.checkSubscribeCondition() {
                self.rtc.diagnoseSubscribeTimeout(for: key)
            }
        }
    }

    private func addDebugViewIfNeeded() -> StreamDebugView {
        if let view = self.debugView { return view }
        let debugView = StreamDebugView()
        self.debugView = debugView
        addSubview(debugView)
        debugView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        debugView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        debugView.bindToRenderView(self)
        return debugView
    }

    func readFPS() -> Int? {
        renderProxy?.readFPS()
    }
}

extension StreamRenderView: StreamRendererDelegate {
    func setRendering(_ isRendering: Bool) {
        if self.isRendering != isRendering {
            Logger.renderView.info("\(self): isRendering changed to \(isRendering)")
            self.isRendering = isRendering
            self.listeners.forEach { $0.streamRenderViewDidChangeRendering(self, isRendering: isRendering) }
            self.renderingCallbacks.forEach { cb in
                cb(isRendering)
            }
        }
    }

    func setVideoFrameSize(_ size: CGSize?) {
        if self.videoFrameSize != size {
            self.videoFrameSize = size
            self.setNeedsLayout()
            self.listeners.forEach { $0.streamRenderViewDidChangeVideoFrameSize(self, size: size) }
        }
    }

    func setVideoView(_ videoView: UIView?) {
        if let oldView = self.videoView {
            oldView.removeFromSuperview()
            self.videoView = nil
        }
        if let view = videoView {
            self.videoView = view
            self.insertSubview(view, at: 0)
            self.layoutIfNeeded()

            if #available(iOS 13.0, *) {
                if let scene = self.videoView?.window?.windowScene {
                    self.interfaceOrientation = scene.interfaceOrientation
                    self.isExternalDisplay = scene.screen != UIScreen.main
                    return
                }
            }
            self.interfaceOrientation = UIApplication.shared.statusBarOrientation
            self.isExternalDisplay = false
        } else {
            self.setRendering(false)
        }
    }

    public func createRenderImage() -> UIImage? {
        renderProxy?.createImage()
    }
}

public extension StreamRenderView {
    // 用于埋点, gallery, share_screen, full_screen, floating_window
    var layoutType: String? {
        get { subscribeConfig.extraInfo.layoutType }
        set { subscribeConfig.extraInfo.layoutType = newValue }
    }
    // 用于埋点, 对应宫格流样式一屏的宫格数量
    var viewCount: Int? {
        get { subscribeConfig.extraInfo.viewCount }
        set { subscribeConfig.extraInfo.viewCount = newValue }
    }
    // 用于埋点, 是否为宫格流样式中的小视图
    var isMini: Bool? {
        get { subscribeConfig.extraInfo.isMini }
        set { subscribeConfig.extraInfo.isMini = newValue }
    }

    func addListener(_ listener: StreamRenderViewListener) {
        self.listeners.addListener(listener)
    }

    func addRenderingCallback(_ callback: @escaping (Bool) -> Void) {
        self.renderingCallbacks.append(callback)
        callback(self.isRendering)
    }

    func removeListener(_ listener: StreamRenderViewListener) {
        self.listeners.removeListener(listener)
    }

    func showFps(_ shouldShow: Bool) {
        Util.runInMainThread { [weak self] in
            self?.addDebugViewIfNeeded().showFps(shouldShow)
        }
    }

    func showCodec(_ shouldShow: Bool) {
        Util.runInMainThread { [weak self] in
            self?.addDebugViewIfNeeded().showCodec(shouldShow)
        }
    }
}

private extension MultiResSubscribeConfig.Priority {
    var rtcPriority: RtcRemoteUserPriority {
       switch self {
       case .high:
           return .high
       case .medium:
           return .medium
       case .low:
           return .low
       }
    }
}

extension Logger {
    static let renderView = getLogger("RenderView")
}
