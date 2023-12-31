//
//  InlineAIContentView.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/5.
//

import Foundation
import UIKit
import UniverseDesignColor
import RxSwift
import RxRelay
import WebKit
import LarkWebViewContainer
import LarkLocalizations
import UniverseDesignTheme
import LarkExtensions

struct AIContentData {
    var content: String
    var extra: [String: Any]?
    var theme: String
    var conversationId: String
    var taskId: String
    var isFinish: Bool
}

protocol InlineAIViewPanGestureDelegate: AnyObject {
    func panGestureRecognizerDidReceive(_ gestureRecognizer: UIPanGestureRecognizer, in view: UIView)
    func panGestureRecognizerDidFinish(_ gestureRecognizer: UIPanGestureRecognizer, in view: UIView)
}

class InlineAIContentView: InlineAIItemBaseView, WKUIDelegate, UIGestureRecognizerDelegate {
    
    var showHeight = 10000.0
    var isWebViewTerminated = false
    var termianteCount = 0
    var lastCotentData: AIContentData?
    
    weak var gestureDelegate: InlineAIViewPanGestureDelegate?

    var findScrollViewWork: DispatchWorkItem?
    weak var contentScrollView: UIScrollView?
    
    var contentHeight: CGFloat?

    var panGestureStageHeight: CGFloat?
    
    var panGestureIsWorking = false

    var disposeBag = DisposeBag()
    
    var canAutolayout: Bool = false
    
    private var settings: InlineAISettings?

    private lazy var imageListView: InlineAIImageListView = {
        var listView = InlineAIImageListView()
        listView.eventRelay.bind(to: self.eventRelay).disposed(by: self.disposeBag)
        listView.aiPanelView = self.aiPanelView
        return listView
    }()
    
    enum Mode {
        case customView
        case webView
        case image
    }
    
    var mode: Mode = .webView
    
    var supportSelfAdaption: Bool {
        return mode != .customView
    }

    var webAPIHandler: InlineAIWebAPIHandler?
    // 内容展示，larkWebView
    private lazy var contentView: InlineAIWebView = {
        var webViewConfig = WKWebViewConfiguration()
        if (settings?.urlSchemeHandleEnable ?? false) {
            webViewConfig = InlineAIWebView.setupConfiguration(origin: webViewConfig)
        }
        let webView = InlineAIWebView(frame: .zero, configuration: webViewConfig, parentTrace: nil, webviewDelegate: nil)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.contentView?.backgroundColor = webCustomBgColor ?? UDColor.bgFloat
        webView.scrollView.backgroundColor = webCustomBgColor ?? UDColor.bgFloat
        webView.scrollView.bounces = false
        webView.backgroundColor = webCustomBgColor ?? UDColor.bgFloat
        webView.renderDelegate = self
        return webView
    }()
    
    private var customContentView: UIView?
    
    private var panGesture: UIPanGestureRecognizer?
    
    private var webCustomBgColor: UIColor?

    /// 初始化
    /// - Parameters:
    ///   - customContentView: 业务方自定义的容器视图
    ///   - webCustomBgColor: 业务方使用组件内webview，自定义其背景色
    ///   - fullHeightMode: false: 只有生成内容的区域才可触发选区操作;  true: 整个容器都可触发选区操作(目前的场景是IM语音, 生成内容高度小于容器时)
    ///   - settings: 配置项
    convenience init(customContentView: UIView?,
                     webCustomBgColor: UIColor? = nil,
                     fullHeightMode: Bool = false,
                     settings: InlineAISettings? = nil) {
        self.init(frame: .zero)
        self.settings = settings
        self.webCustomBgColor = webCustomBgColor
        self.customContentView = customContentView
        if let customView = customContentView {
            self.mode = .customView
            addSubview(customView)
            customView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview().inset(5)
            }
            customView.backgroundColor = UDColor.bgFloat
        } else {
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            webAPIHandler = InlineAIWebAPIHandler(webView: contentView, delegate: self)
            webAPIHandler?.register()
            contentView.lkwBridge.registerBridge()
            loadLocalResources(webCustomBgColor: webCustomBgColor, fullHeightMode: fullHeightMode)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(gesture:)))
            panGesture.delegate = self
            addGestureRecognizer(panGesture)
            self.panGesture = panGesture
        }
    }
    
    func getCurrentTheme() -> String {
        guard #available(iOS 13.0, *) else {
            return "light"
        }
        let currntTheme = UDThemeManager.getRealUserInterfaceStyle()
        if currntTheme == .dark {
            return "dark"
        }
        return "light"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func preload() {
        if let contentData = self.lastCotentData {
            updateContent(contentData.content, extra: contentData.extra, theme: getCurrentTheme(), conversationId: contentData.conversationId, taskId: contentData.taskId, isFinish: contentData.isFinish)
        } else {
            updateContent("", extra: nil, theme: getCurrentTheme(), conversationId: "", taskId: "", isFinish: false)
        }
    }
    
    
    deinit {
        LarkInlineAILogger.info("InlineAIContentView deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var show: Bool {
        willSet {
            if newValue == false, newValue != self.show {
                reloadContent()
            }
        }
        didSet {
            self.isHidden = !show
        }
    }
    
    func getDisplayHeight() -> CGFloat {
        guard canAutolayout, supportSelfAdaption else {
            return showHeight
        }
        if mode == .image, imageListView.getDispalyHeight() > 0 {
            return imageListView.getDispalyHeight()
        }
        return contentHeight ?? 0
    }
    
    func disableAutolayout() {
        self.canAutolayout = false
        self.contentHeight = nil
    }
    
    func enableAutolayout() {
        self.canAutolayout = true
        self.contentHeight = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        LarkInlineAILogger.info("[web] layoutSubviews")
        guard mode != .customView else { return }
        contentView.contentView?.backgroundColor = webCustomBgColor ?? UDColor.bgFloat
        contentView.scrollView.backgroundColor = webCustomBgColor ?? UDColor.bgFloat
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc
    func panGestureAction(gesture: UIPanGestureRecognizer) {
        guard let scrollView = self.contentScrollView else {
            self.gestureDelegate?.panGestureRecognizerDidReceive(gesture, in: self)
            return
        }
        
        if scrollView.contentOffset.y < 0 {
            scrollView.setContentOffset(.zero, animated: false)
            scrollView.isScrollEnabled = false
        }
        var isScrollEnabled = scrollView.isScrollEnabled
        if scrollView.contentSize.height <= scrollView.frame.size.height {
            isScrollEnabled = false
        }
        switch gesture.state {
        case .began, .changed:
            panGestureIsWorking = true
            if scrollView.contentOffset.y <= 0 || !isScrollEnabled {
                self.gestureDelegate?.panGestureRecognizerDidReceive(gesture, in: self)
            }
        case .ended, .cancelled, .failed:
            if !isScrollEnabled {
                self.gestureDelegate?.panGestureRecognizerDidReceive(gesture, in: self)
            } else {
                self.gestureDelegate?.panGestureRecognizerDidFinish(gesture, in: self)
            }
            scrollView.isScrollEnabled = true
            panGestureIsWorking = false
        default:
            break
        }
    }

    func disableListContentPanGesture() {
        if let panGesture = panGesture {
            self.removeGestureRecognizer(panGesture)
        }
        panGesture = nil
    }
}

extension InlineAIContentView {
    func updateContent(_ content: String, extra: [String: Any]?,  theme: String, conversationId: String, taskId: String, isFinish: Bool) {
        guard mode != .customView else { return }
        if contentView.superview == nil {
            if self.mode == .image {
                imageListView.removeFromSuperview()
            }
            self.mode = .webView
            contentView.snp.removeConstraints()
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        contentView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(5)
        }
        self.lastCotentData = AIContentData(content: content, extra: extra, theme: theme, conversationId: conversationId, taskId: taskId, isFinish: isFinish)
        if let service = webAPIHandler?.getServiceInstance(InlineAIShowContentJSService.self) as? InlineAIShowContentJSService {
            LarkInlineAILogger.info("[web] udpateContent theme: \(theme) conversationId:\(conversationId) taskId:\(taskId)")
            service.showContent(content: content, extra: extra, theme: theme, conversationId: conversationId, taskId: taskId, isFinish: isFinish)
        } else {
            LarkInlineAILogger.info("[web] udpateContent fail conversationId:\(conversationId) taskId:\(taskId)")
        }
    }
    
    func updateImage(imageModels: [InlineAICheckableModel]) {
        guard mode != .customView else { return }
        if imageListView.superview == nil {
            if self.mode == .webView {
                contentView.removeFromSuperview()
            }
            self.mode = .image
            imageListView.snp.removeConstraints()
            addSubview(imageListView)
            imageListView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(8)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        imageListView.update(models: imageModels)
        self.contentScrollView = imageListView.collectionView
    }
    
    func updateImageCheckbox(imageModels: [InlineAICheckableModel]) {
        imageListView.updateImageCheckbox(models: imageModels)
    }
    
    func setFileNamePathsDict(_ dict: [String: String]) {
        contentView.setFileNamePathsDict(dict)
    }
    
    func setWebContentViewOpaque(_ isOpaque: Bool) {
        contentView.isOpaque = isOpaque
    }
}


// MARK: - webview interface
extension InlineAIContentView {
    
    func reloadContent() {
        guard mode == .webView else { return }
        LarkInlineAILogger.info("reload ContentView")
        contentView.reload()
    }

    private func loadLocalResources(webCustomBgColor: UIColor?, fullHeightMode: Bool) {
        guard mode != .customView else { return }
        if var templateURL = InlineAIPackageBussiness.getRoadsterHtmlPath() {
            let baseUrl = templateURL.deletingLastPathComponent()
            contentView.setCustomBackgroundColor(webCustomBgColor)
            
            let locale = LanguageManager.currentLanguage.rawValue.replacingOccurrences(of: "_", with: "-")
            var queryKeyValues: [String: String] = [:]
            queryKeyValues["ios"] = "1"
            queryKeyValues["locale"] = locale
            queryKeyValues["padding"] = getWebviewPaddingParam()
            if let color = webCustomBgColor {
                queryKeyValues["bgColor"] = color.hexString
            }
            if fullHeightMode {
                queryKeyValues["mode"] = "fullscreen"
            }
            templateURL = templateURL.lf.appendPercentEncodedQuery(queryKeyValues)
            contentView.loadFileURL(templateURL, allowingReadAccessTo: baseUrl)
            LarkInlineAILogger.info("load URL, querys:\(queryKeyValues)")
        } else {
            LarkInlineAILogger.error("[web] loadLocalResources fail")
        }
    }
    
    private func getWebviewPaddingParam() -> String {
        let padding = InlineAIMainPanelView.PanelLayout.webviewPadding
        let top = Int(padding.top)
        let left = Int(padding.left)
        let bottom = Int(padding.bottom)
        let right = Int(padding.right)
        return "\(top),\(left),\(bottom),\(right)" // 顺序是与前端约定好的
    }
}

// MARK: - WKNavigationDelegate
extension InlineAIContentView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isWebViewTerminated = false
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        LarkInlineAILogger.error("[web] AIContentView DidTerminate")
        isWebViewTerminated = true
        LarkInlineAITracker.trackWebViewTerminate(count: termianteCount, isBackground: UIApplication.shared.applicationState == .background, isVisible: self.show)
        termianteCount += 1
        reloadContent()
        DispatchQueue.main.async {
            if let lastData = self.lastCotentData {
                LarkInlineAILogger.info("[web] reload last content Data")
                self.updateContent(lastData.content, extra: lastData.extra, theme: lastData.theme, conversationId: lastData.conversationId, taskId: lastData.taskId, isFinish: lastData.isFinish)
            } else {
                LarkInlineAILogger.error("[web] last content Data is nil")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        LarkInlineAILogger.info("[web] AIContentView didFinish")
        
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        LarkInlineAILogger.error("[web] AIContentView load fail error:\(error)")
        LarkInlineAITracker.trackWebViewFail(error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        LarkInlineAILogger.error("[web] AIContentView didFailProvisionalNavigation error:\(error)")
        LarkInlineAITracker.trackWebViewFail(error: error)
    }
}


extension InlineAIContentView: UIScrollViewDelegate, InlineAIWebViewDelegate {
    
    func contentDidRenderComplete(with contentHeight: CGFloat?) {
        findScrollViewWork?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.attachWebScrollView(index: "0", tryCount: 0) { [weak self] scrollView in
                guard let self = self else { return }
                if let contentScrollView = scrollView {
                    self.contentScrollView = contentScrollView
                } else {
                    self.contentScrollView = self.contentView.scrollView
                }
                // 不能直接设置scrollView delegate：delegate已经由私有类WKScrollingNodeScrollViewDelegate接管
            }
        }
        findScrollViewWork = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: item)
        if let height = contentHeight {
            self.contentHeight = height
            LarkInlineAILogger.debug("contentRenderEnd height:\(height)")
            self.eventRelay.accept(.contentRenderEnd)
        } else {
            LarkInlineAILogger.debug("contentRenderEnd height is nil")
        }
    }
}


// MARK: scrollview getter
extension InlineAIContentView {
    func attachWebScrollView(index: String, tryCount: Int, completion: (@escaping (UIScrollView?) -> Void)) {
        var count = tryCount
        let scroll = findScrollViews(view: contentView.scrollView, index: index)
        if scroll != nil {
            LarkInlineAILogger.info("find web scrollView count:\(count)")
            completion(scroll)
        } else if count < 5 {
            // stupid code. retry :P
            count += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .nanoseconds(count * 4 * 1000000)) { [weak self] in
                self?.attachWebScrollView(index: index, tryCount: count, completion: completion)
            }
        } else {
            LarkInlineAILogger.error("can not find web scrollView")
            completion(nil)
        }
    }
    
    func findScrollViews(view: UIView, index: String) -> UIScrollView? {
        if let scroll = view as? UIScrollView, view != self.contentView.scrollView {
            return scroll
        }
        
        for subview in view.subviews {
            if let ret = findScrollViews(view: subview, index: index) {
                return ret
            }
        }
        return nil
    }
    
}


extension InlineAIContentView: AIWebAPIHandlerDelegate {
    
    func handle(_ event: InlineAIEvent) {
        if case .panGestureRecognizerEnable(let enabled) = event {
            self.panGesture?.isEnabled = enabled
        }
        eventRelay.accept(event)
    }
}
