//
//  EditorsPool+Reuse.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2022/11/29.
//

import SKFoundation
import SKCommon
import SKResource
import SKUIKit
import EENavigator
import SpaceInterface
import SKInfra

// MARK: - extension of BrowserView for reuse
extension BrowserView: DocReusableItem {
    public var webViewClearDone: ObserableWrapper<Bool> {
        get {
            guard let value = objc_getAssociatedObject(self, &BrowserView.webViewClearDoneKey) as? ObserableWrapper<Bool> else {
                return ObserableWrapper<Bool>(false)
            }
            return value
        }
        set { objc_setAssociatedObject(self, &BrowserView.webViewClearDoneKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    public var preloadStatus: ObserableWrapper<PreloadStatus> {
        guard let webLoader = docsLoader as? WebLoader else {
            return ObserableWrapper<PreloadStatus>(PreloadStatus())
        }
        return webLoader.preloadStatus
    }

    public var webviewHasBeenTerminated: ObserableWrapper<Bool> {
        guard let webLoader = docsLoader as? WebLoader else {
            return ObserableWrapper<Bool>(false)
        }
        return webLoader.webviewHasBeenTerminated
    }

    private static var usedCounterKey: UInt8 = 0
    /// 被使用的次数
    public var usedCounter: Int {
        get {
            guard let value = objc_getAssociatedObject(self, &BrowserView.usedCounterKey) as? Int else {
                return 0
            }
            return value
        }
        set { objc_setAssociatedObject(self, &BrowserView.usedCounterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func increaseUseCount() {
        usedCounter += 1
    }
    
    public func prepareForReuse() {
        self.removePadCommentView()
        self.lifeCycleEvent.removeNotificationObserver()
        self.canUpdateClearDoneState = false
        self.viewCapturePreventer.reset() // 恢复为默认的防护状态，避免复用导致停留在上次的状态
    }

    private static var attachUserIdKey: String = "BrowserView.AttachUserId.Key"
    private static var webViewClearDoneKey: ObserableWrapper<Bool> = ObserableWrapper<Bool>(false)
    
    /// DocsWebView与UserId 绑定
    public var attachUserId: String? {
        get { return objc_getAssociatedObject(self, &BrowserView.attachUserIdKey) as? String }
        set { objc_setAssociatedObject(self, &BrowserView.attachUserIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var preloadStartTimeKey: UInt8 = 0
    /// 预加载启动的时刻
    public var preloadStartTimeStamp: TimeInterval {
        get { return objc_getAssociatedObject(self, &BrowserView.preloadStartTimeKey) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &BrowserView.preloadStartTimeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var preloadEndTimeKey: UInt8 = 0
    /// 预加载成功的时刻
    public var preloadEndTimeStamp: TimeInterval {
        get { return objc_getAssociatedObject(self, &BrowserView.preloadEndTimeKey) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &BrowserView.preloadEndTimeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var webviewStartLoadUrlTimeKey: UInt8 = 0
    /// webview开始loadUrl的时刻
    public var webviewStartLoadUrlTimeStamp: TimeInterval {
        get { return objc_getAssociatedObject(self, &BrowserView.webviewStartLoadUrlTimeKey) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &BrowserView.webviewStartLoadUrlTimeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    public var reuseState: String {
        guard let webLoader = docsLoader as? WebLoader else {
            return ["editor": "\(self.editorIdentity)"].description
        }
        return  ["editor": "\(self.editorIdentity)",
                 "mainFrameReady": webLoader.preloadStatus.value as Any,
                 "webviewHasBeenTerminated": webLoader.webviewHasBeenTerminated.value as Any,
                 "usedCounter": self.usedCounter,
                 "check_rsp_in_open": webLoader.hasCheckResponsiveInOpen].description
    }
    
    public var isResponsive: Bool { self.jsServiceManager.isResponsive }
    
    public var isInViewHierarchy: Bool { self.window != nil }
    
    public var isInVCFollow: Bool {
        docsLoader?.docsInfo?.isInVideoConference ?? false
    }
        
    public var isLoadingStatus: Bool {
        docsLoader?.loadStatus.isLoading ?? false
    }
    
    public var isLoadSuccess: Bool {
        docsLoader?.loadStatus.isSuccess ?? false
    }

    /// 加到视图层级上，加快预加载速度
    public func addToViewHierarchy() -> Self {
        let screenSize = SKDisplay.activeWindowBounds.size
        let width = min(screenSize.width, screenSize.height) //初始的时候size都为竖屏情况，防止横屏时初始化width变成大值
        let navHeight = CGFloat(44)
        let height = max(screenSize.width, screenSize.height) - navHeight - (userResolver.navigator.mainSceneWindow?.safeAreaInsets.top ?? 0)
        let view = UIView(frame: CGRect(origin: CGPoint(x: -20, y: 20), size: CGSize(width: width, height: height)))
        view.clipsToBounds = true // 避免 webview 内容透出范围
        view.isHidden = true
        view.addSubview(self)
        self.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        userResolver.navigator.mainSceneWindow?.addSubview(view)
        return self
    }
    
    public func attachToWindow() {
        let view = UIView(frame: CGRect(origin: CGPoint(x: -20, y: 20), size: self.frame.size))
        view.clipsToBounds = true // 避免 webview 内容透出范围
        view.isHidden = true
        view.addSubview(self)
        userResolver.navigator.mainSceneWindow?.addSubview(view)
    }

    public func removeFromViewHierarchy(_ removeSuperView: Bool) {
        if removeSuperView {
            self.superview?.removeFromSuperview()
        }
        self.removeFromSuperview()
    }

    public func canReuse(for type: DocsType = .doc) -> Bool {
        guard let webLoader = docsLoader as? WebLoader else { return false }
        //代理模式下，支持模版复用，不判断hasPreload
        if OpenAPI.docs.isAgentRepeatModuleEnable {
            return !webLoader.webviewHasBeenTerminated.value
        }
        
        return webLoader.preloadStatus.value.hasPreload(type)
        && !webLoader.webviewHasBeenTerminated.value  //发生过termintate不能复用
        && !webLoader.hasCheckResponsiveInOpen        //发生疑似卡死检测不能复用
    }

    @discardableResult
    public func preload() -> Self {
        var url = DocsUrlUtil.mainFrameTemplateURL()
        if OpenAPI.offlineConfig.protocolEnable {
            DocsLogger.info("protocolEnable enter exchange schema", component: LogComponents.fileOpen)
            url = DocsUrlUtil.changeUrl(url, schemeTo: DocSourceURLProtocolService.scheme)
        }
        webviewStartLoadUrlTimeStamp = Date().timeIntervalSince1970
        let rootId = SKTracing.shared.startRootSpan(spanName: SKBrowserTrace.openBrowser)
        SKTracing.shared.endSpan(spanName: SKBrowserTrace.openBrowser,
                                 rootSpanId: rootId,
                                 params: ["startFromPreload": true],
                                 component: LogComponents.fileOpen)
        self.docsLoader?.tracingContext = TracingContext(rootId: rootId)
        load(url: url)
        DocsLogger.info("\(self.editorIdentity) start preload,\(url.absoluteString)", component: LogComponents.fileOpen)
        PreloadStatistics.shared.startRecordPreload("\(self.editorIdentity)")
        return self
    }
}
