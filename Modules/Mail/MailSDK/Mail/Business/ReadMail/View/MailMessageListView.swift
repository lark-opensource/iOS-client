//
//  MailMessageListView.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/2/19.
//

import Foundation
import WebKit
import LarkFoundation
import SnapKit
import RxSwift
import UniverseDesignColor
import LKCommonsLogging
import LarkWebviewNativeComponent
import LarkWebViewContainer
import ThreadSafeDataStructure

// Image load monitor delegate
protocol MailMessageListImageMonitorDelegate: AnyObject {
    // 请求被拦截
    func onWebViewStartURLSchemeTask(with urlString: String?)
    // 准备开始下载
    func onWebViewSetUpURLSchemeTask(with urlString: String, fromCache: Bool)
    // 开始下载
    func onWebViewImageDownloading(with urlString: String)
    // 完成下载任务
    func onWebViewFinishImageDownloading(with urlString: String, dataLength: Int, finishWithDrive: Bool, downloadType: MailImageDownloadType)
    // 下载任务失败
    func onWebViewImageDownloadFailed(with urlString: String, finishWithDrive: Bool, downloadType: MailImageDownloadType, errorInfo: APMErrorInfo?)
}

struct MessageWebViewTimeMonitor {
    var loadURLTimestamp = 0
    var jsStartTimestamp = 0
    var domLoadedTimestamp = 0
    var initUIEndTimestamp = 0
    var initEndTimestamp = 0
    var domReadyTimestamp = 0
    var renderFirstFrameTimestamp = 0
    var bodyHTMLLength = 0
    var stage: MailAPMEvent.NewMessageListLoaded.MessageLoadStage? = nil

    var loadHTMLCost: Int {
        jsStartTimestamp - loadURLTimestamp
    }

    var parseHTMLCosT: Int {
        domLoadedTimestamp - jsStartTimestamp
    }

    var jsHandleCost: Int {
        initUIEndTimestamp - domLoadedTimestamp
    }

    var firstScaleCost: Int {
        initEndTimestamp - initUIEndTimestamp
    }

    var renderHTMLCost: Int {
        domReadyTimestamp - loadURLTimestamp
    }

    var renderAllCost: Int {
        initEndTimestamp - loadURLTimestamp
    }

    var firstFrameCost: Int {
        renderFirstFrameTimestamp - loadURLTimestamp
    }

    mutating func reset() {
        loadURLTimestamp = 0
        jsStartTimestamp = 0
        domLoadedTimestamp = 0
        initUIEndTimestamp = 0
        initEndTimestamp = 0
        domReadyTimestamp = 0
        renderFirstFrameTimestamp = 0
        bodyHTMLLength = 0
        stage = nil
    }
}


class MailMessageListViewsPool {
    private static var pool = [MailMessageListView]()
    static var threadTerminatedCountDict = [String: Int]()
    static var decidePolicyParamDic:[String: [String: Any]] = [:]
    static let fpsOpt = FeatureManager.open(.mailFPSOpt, openInMailClient: true)
    static func reset() {
        MailLogger.info("MailMessageListViewsPool reset count \(pool.count)")
        for v in pool where v.superview as? UIWindow != nil {
            /// 将window上预加载的读信页去除，避免泄露
            v.removeFromSuperview()
        }
        pool.removeAll()
        decidePolicyParamDic.removeAll()
    }

    static func getWebViewFromPool(threadId: String) -> (WKWebView & MailBaseWebViewAble)? {
        return pool.first(where: { $0.identifier == threadId })?.webview
    }

    static func getViewFor(threadId: String, isFullReadMessage: Bool, controller: MailMessageListController?, provider: MailSharedServicesProvider, isFeed: Bool = false) -> MailMessageListView {
        let messageView: MailMessageListView
        MailLogger.info("MailMessageListViewsPool getViewFor \(threadId)")
        if isFullReadMessage {
            MailLogger.info("MailMessageListViewsPool isFullReadMessage")
            messageView = MailMessageListView(provider: provider)
        } else if let sameIdView = pool.first(where: { ($0.identifier == threadId || $0.identifier == nil) && ($0.superview == nil || $0.controller == nil || $0.controller == controller ) }) {
            MailLogger.info("MailMessageListViewsPool sameIdView")
            messageView = sameIdView
        } else if pool.count < 3 {
            MailLogger.info("MailMessageListViewsPool count < 3")
            messageView = addNewView(provider: provider, isFeed: isFeed)
        } else if let canReusedView = pool.filter({ $0.superview == nil || $0.isHidden == true }).sorted(by: { $0.useTimeStamp < $1.useTimeStamp }).first {
            MailLogger.info("MailMessageListViewsPool canReusedView")
            messageView = canReusedView
        } else {
            MailLogger.info("MailMessageListViewsPool addNewView")
            messageView = addNewView(provider: provider)
        }
        messageView.isHidden = false
        return messageView
    }

    private static var businessWindow: UIWindow? {
        return UIApplication.shared.windows.first {
            $0.rootViewController != nil && $0.windowLevel == .normal
        }
    }

    static func preload(provider: MailSharedServicesProvider) {
        if pool.count == 0 {
            let preloadView = addNewView(provider: provider)
            if let w = businessWindow {
                let width = w.bounds.width
                preloadView.frame = CGRect(x: -width, y: 0, width: width, height: 1)
                MailLogger.info("preload addSubview")
                w.addSubview(preloadView)
            } else {
                MailLogger.info("preload not addSubview")
            }
        }
    }

    private static func addNewView(provider: MailSharedServicesProvider, isFeed: Bool = false) -> MailMessageListView {
        let mListView = MailMessageListView(provider: provider, isFeed: isFeed)
        pool.append(mListView)
        return mListView
    }
}

protocol MailMessageListViewDelegate: AnyObject {
    func webViewOnDomReady()
    func titleLabelsTapped()
    func flagTapped()
    func notSpamTapped()
    func bannerTermsAction()
    func bannerSupportAction()
    func didClickStrangerReply(status: Bool)
    func avatarClickHandler(mailAddress: MailAddress)
}

class MailMessageListView: UIView, WKNavigationDelegate {
    static let logger = Logger.log(MailMessageListView.self, category: "Module.MailMessageListView")

    var isHtmlLoaded = false
    var lastStartLoadingTime: TimeInterval?

    
    private(set) var isFeed = false
    
    private(set) var isDomReady = false {
        didSet {
            bottomOperateBar.isHidden = (isDomReady && !isFeed) ? false : true
            backgroundColor = (isDomReady && !isFeed) ? domReadyBackgroundColor : webview.backgroundColor
        }
    }

    private var isFirstFrameRendered = false
    private var domReadyBackgroundColor: UIColor? = UDColor.readMsgListBG
    private let bottomBarDefaultHeight: CGFloat = 56

    private lazy var bottomOperateBar: BottomOperationBarProtocol & UIView = {
        return BottomOperationBar(actionItems: [], showHeaderLine: true, guideService: provider.provider.guideServiceProvider, isFeed: isFeed)
    }()

    private lazy var loadingView: MailMessageListLoadingView = {
        let loading = MailMessageListLoadingView()
        loading.isHidden = true
        return loading
    }()

    private lazy var strangerHeaderView: MailMsgStrangerHeaderView = {
        let strangerHeaderView = MailMsgStrangerHeaderView()
        strangerHeaderView.delegate = self
        strangerHeaderView.avatarDelegate = self
        return strangerHeaderView
    }()
    private let strangerHeaderViewHeight: CGFloat = 64

    /// webview 初次创建，没有渲染内容
    fileprivate var isWebViewCleaned = true
    /// WebView正在cleanContent
    private var isCleaningWebView = false
    private var htmlAndBaseURLToRender: (String, URL?)?

    var identifier: String? {
        get {
            return webview.identifier
        }
        set {
            webview.identifier = newValue
            useTimeStamp = Date().timeIntervalSince1970
        }
    }

    var useTimeStamp: TimeInterval = Date().timeIntervalSince1970

    weak var webDelegate: WKNavigationDelegate? {
        didSet {
            webview.navigationDelegate = webDelegate
        }
    }

    weak var controller: MailMessageListController? {
        didSet {
            webview.uiDelegate = controller
        }
    }

    let webview: (WKWebView & MailBaseWebViewAble)
    var titleView: MailReadTitleView?
    private var preTitleView: MailReadTitleView?
    private var observation: NSKeyValueObservation?

    private var bottomBarHeightConstraint: Constraint?
    let webViewScrollHandler = MailWebViewScrollHandler()
    private var isActivelyScrolling = false
    private var lastContentOffsetY: CGFloat = 0
    private var lastJSCostTime: Double?

    private(set) weak var viewModel: MailMessageListPageViewModel? {
        didSet {
            updateStrangerHeaderIfNeeded()
        }
    }
    weak var delegate: MailMessageListViewDelegate?

    private var searchBtnDisposeBag = DisposeBag()
    private(set) var isRendering = false

    var searchRightButton: UIButton? {
        return bottomOperateBar.searchRightButton
    }
    var searchLeftButton: UIButton? {
        return bottomOperateBar.searchLeftButton
    }

    private var mailActionItemsBlock: (() -> [MailActionItem])?
    private var nativeComponentManager: MailMessageNativeComponentManager

    private var timeMonitor = MessageWebViewTimeMonitor()

    // 重复下载图片相关打点
    private var imageFileTokens = Set<String>()
    private var affectedDownloadImgCount: Int = 0
    private var repeatDownloadCount: Int = 0
    private var totalDownloadCount: Int = 0
    private var repeatDownloadSize: Int64 = 0
    private var totalDownloadSize: Int64 = 0
    private var downloadedURLImgTokens = ThreadSafeDataStructure.SafeDictionary<String, String>(synchronization: .readWriteLock)
    private var downloadingURLImgTokens = ThreadSafeDataStructure.SafeDictionary<String, String>(synchronization: .readWriteLock)
    private lazy var cidRegex = try? NSRegularExpression(pattern: "cid:([^>\"]+)_(\\S+)", options: .caseInsensitive)

    let provider: MailSharedServicesProvider
    var atInfos: [Any]? = nil
    var addressChanged: Bool = false
    let disposeBag = DisposeBag()

    init(provider: MailSharedServicesProvider, isFeed: Bool = false) {
        self.provider = provider
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.userContentController = WKUserContentController()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
//        self.webview.scrollView.bounces = false
        self.nativeComponentManager = MailMessageNativeComponentManager()
        self.webview = MailWebViewSchemeManager.makeDefaultNewWebView(config: config, provider: provider, nativeComponentManager: self.nativeComponentManager)
        super.init(frame: .zero)
        nativeComponentManager.delegate = self
        self.isFeed = isFeed
        setupViews(isFeed: isFeed)
        titleView?.delegate = self
        webview.navigationDelegate = self
        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_ADDRESS_NAME_CHANGE)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] noti in
               guard let `self` = self else { return }
                self.addressChanged = true
            }).disposed(by: self.disposeBag)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTestView = super.hitTest(point, with: event)
        /// hittest时处理一下scrollView，避免用户图片下载完成前，无法正常滑动
        if let scrollView = hitTestView as? UIScrollView {
            webViewScrollHandler.handleWKScrollView(scrollView)
        }
        return hitTestView
    }

    func updateStrangerHeaderIfNeeded() {
        let inStrangerMode = viewModel?.labelId == Mail_LabelId_Stranger && provider.featureManager.open(.stranger, openInMailClient: false)
        if inStrangerMode {
            insertSubview(strangerHeaderView, belowSubview: loadingView)
            strangerHeaderView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(MailTitleNaviBar.navBarHeight)
                make.height.equalTo(strangerHeaderViewHeight)
            }
            setupViews(bottomBarHeight: inStrangerMode ? 0 : bottomBarDefaultHeight)
        } else {
            strangerHeaderView.removeFromSuperview()
        }
    }

    private func setupViews(isFeed: Bool) {
        initWebView()
        addSubview(webview)
        if !isFeed {
            addSubview(bottomOperateBar)
            setupViews(bottomBarHeight: bottomBarDefaultHeight)
        }
        addSubview(loadingView)

        webview.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            if !isFeed {
                make.bottom.equalTo(bottomOperateBar.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundColor = .clear
    }

    private func initWebView() {
        webview.initJSBridge()
        webview.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        if provider.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) {
            webview.backgroundColor = UDColor.readMsgListBG
        } else {
            webview.backgroundColor = UIColor.ud.bgBase.alwaysLight
        }
        webview.scrollView.contentInsetAdjustmentBehavior = .never
        webview.scrollView.contentInset = .zero
        webview.isOpaque = false
        webview.allowsLinkPreview = true
        webview.scrollView.delegate = self
        webview.modelProvider = { [weak self] in
            return self
        }
    }

    func prepareForReuse() {
        self.atInfos?.removeAll()
        viewModel?.imageMonitor.clear()
        showLoading(false)
        logRepeatImageDownload()
        timeMonitor.reset()
    }

    func showLoading(_ show: Bool, delay: TimeInterval = 1) {
        #if DEBUG
        // delayload 不展示loading，方便调试WebView
        if MailKVStore(space: .global, mSpace: .global).bool(forKey: MailDebugViewController.kMailDelayLoadTemplate) == true {
            return
        }
        #endif
        if !show {
            lastStartLoadingTime = nil
            loadingView.isHidden = true
            loadingView.alpha = 0.0
        } else {
            lastStartLoadingTime = Date().timeIntervalSince1970
            loadingView.alpha = 1.0
            loadingView.showLoading(delay: delay)
        }
    }

    func viewWillTransition(to size: CGSize) {
        if let newHeight = titleView?.sizeToFit(with: size).height {
            updateJSHeaderHeight(newHeight, completion: nil)
        }
    }

    func updateJSHeaderHeight(_ height: CGFloat, completion: (() -> Void)?) {
        self.evaluateJavaScript("window.updateHeaderHeight('\(height)')") { _, e in
            completion?()
        }
    }

    func handleWebScrollViews() {
        webViewScrollHandler.handleWebView(webview)
    }

    func onDomReady(_ domReady: Bool, costTime: Double? = nil) {
        isDomReady = domReady
        if isDomReady {
            isRendering = false
            delegate?.webViewOnDomReady()
            if let messageEvent = viewModel?.messageEvent {
                if let costTime = costTime ?? lastJSCostTime {
                    lastJSCostTime = nil
                    messageEvent.endParams.append(MailAPMEvent.MessageListLoaded.CommonParam.scriptHandleTime(costTime))
                }
                if let renderStartTime = messageEvent.renderStartTime {
                    let time = (Date().timeIntervalSince1970 - renderStartTime) * 1000
                    messageEvent.endParams.append(MailAPMEvent.MessageListLoaded.CommonParam.totalRenderTime(time))
                }
                if let userStartTime = messageEvent.actualStartTime {
                    let time = (Date().timeIntervalSince1970 - userStartTime) * 1000
                    messageEvent.endParams.append(MailAPMEvent.MessageListLoaded.CommonParam.userTotalTime(time))
                }
            } else {
                lastJSCostTime = costTime
            }
            if let threadId = viewModel?.threadId {
                controller?.onDomReady(threadId: threadId)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.viewModel?.labelId == Mail_LabelId_Stranger && self.provider.featureManager.open(.stranger, openInMailClient: false) {
                    self.updateStrangerActionItems(self.mailActionItemsBlock?() ?? [], mailItem: self.viewModel?.mailItem)
                } else {
                    if !isFeed {
                        self.updateBottomActionItems(self.mailActionItemsBlock?() ?? [])
                    }
                }
            }
        }
    }

    func postMessageLoadEvent(isUserLeave: Bool = false) {
        typealias CommonParams = MailAPMEvent.NewMessageListLoaded.CommonParam
        if let timeEvent = viewModel?.newMessageTimeEvent {
            timeMonitor.stage.map { timeEvent.stage = $0 }
            let isInBackground = UIApplication.shared.applicationState == .background
            if let userVisible = viewModel?.newMessageTimeEvent?.userVisibleTime,
               let start = viewModel?.newMessageTimeEvent?.actualStartTime {
                let startTime = Int(start * 1000)
                let userVisibleTime = Int(userVisible * 1000)
                let currentTime = Int(Date().timeIntervalSince1970) * 1000
                let waitHTMLCost = max(timeMonitor.loadURLTimestamp, currentTime) - userVisibleTime
                timeEvent.commonParams.append(CommonParams.waitHTMLCost(waitHTMLCost))
                let userWaitingCost = max(timeMonitor.domReadyTimestamp, currentTime) - max(startTime, userVisibleTime)
                timeEvent.commonParams.append(CommonParams.userWaitingCost(userWaitingCost))
                let totalCost = max(timeMonitor.domReadyTimestamp, currentTime) - startTime
                timeEvent.commonParams.append(CommonParams.timeTotalCost(totalCost))
            }
            timeEvent.commonParams.append(CommonParams.isInBackground(isInBackground))
            timeEvent.commonParams.append(CommonParams.bodyHTMLLength(timeMonitor.bodyHTMLLength))
            timeEvent.commonParams.append(CommonParams.webviewLoadHTMLCost(timeMonitor.loadHTMLCost))
            timeEvent.commonParams.append(CommonParams.webviewParseHTMLCost(timeMonitor.parseHTMLCosT))
            timeEvent.commonParams.append(CommonParams.scriptHandleTime(timeMonitor.jsHandleCost))
            timeEvent.commonParams.append(CommonParams.firstScaleCost(timeMonitor.firstScaleCost))
            timeEvent.commonParams.append(CommonParams.renderHTMLCost(timeMonitor.renderHTMLCost))
            timeEvent.commonParams.append(CommonParams.renderAllCost(timeMonitor.renderAllCost))
            timeEvent.commonParams.append(CommonParams.renderFirstFrameCost(timeMonitor.firstFrameCost))
            if isDomReady || !isUserLeave {
                timeEvent.commonParams.append(CommonParams.isUserLeaveBlank(false))
                timeEvent.commonParams.append(CommonParams.mailStatus("success"))
            } else {
                timeEvent.commonParams.append(CommonParams.userLeaveBlockStage(timeEvent.stage.rawValue))
                timeEvent.commonParams.append(CommonParams.isUserLeaveBlank(true))
                timeEvent.commonParams.append(CommonParams.mailStatus("cancel"))
            }
            timeEvent.postEnd()
        }
    }

    func feedMode(_ show: Bool) {
        
    }

    func toggleSearchMode(_ show: Bool) {
        bottomOperateBar.toggleSearchMode(show)

        if show {
            // 避免重复subscribe
            searchBtnDisposeBag = DisposeBag()
            searchRightButton?.rx.tap.share().subscribe(onNext: { [weak self] (_) in
                self?.controller?.view.endEditing(true)
                self?.controller?.realViewModel.search.changeSearchRetIndex(indexDis: 1)
            }).disposed(by: searchBtnDisposeBag)
            searchLeftButton?.rx.tap.share().subscribe(onNext: { [weak self] (_) in
                self?.controller?.view.endEditing(true)
                self?.controller?.realViewModel.search.changeSearchRetIndex(indexDis: -1)
            }).disposed(by: searchBtnDisposeBag)
        }

        updateBottomOperationBarHeight()
    }

    private func setupViews(bottomBarHeight: CGFloat) {
        webview.snp.remakeConstraints { (make) in
            let inStrangerMode = viewModel?.labelId == Mail_LabelId_Stranger && provider.featureManager.open(.stranger, openInMailClient: false)
            make.top.equalToSuperview().offset(inStrangerMode ? strangerHeaderViewHeight : 0)
            make.left.right.equalToSuperview()
            var inset = webview.scrollView.contentInset
            if bottomBarHeight == 0 {
                inset.bottom = safeAreaInsets.bottom
                make.bottom.equalToSuperview()
            } else {
                inset.bottom = 0
                if !isFeed {
                    make.bottom.equalTo(bottomOperateBar.snp.top)
                } else {
                    make.bottom.equalToSuperview()
                }
            }
            webview.scrollView.contentInset = inset
        }
        if !isFeed {
            bottomOperateBar.layer.masksToBounds = bottomBarHeight == 0
            bottomOperateBar.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
                make.height.equalTo(bottomBarHeight)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        MailLogger.info("MailMessageListView deinit \(viewModel?.threadId ?? "")")
        logRepeatImageDownload()
        webview.deinitJSBridge()
    }

    private func loadHTMLString(_ html: String, baseURL: URL?) {
        isWebViewCleaned = false
        timeMonitor.stage = .webview_load_html
        timeMonitor.loadURLTimestamp = Int(Date().timeIntervalSince1970 * 1000)
        timeMonitor.bodyHTMLLength = html.count
        if provider.featureManager.open(.interceptWebViewHttp),
           controller?.realViewModel.templateRender.template.isRemoteFile == false,
           let domain = ProviderManager.default.commonSettingProvider?.stringValue(key: "templateDomain"),
           var path = baseURL?.relativePath {
            MailLogger.info("Try to use custom schema and domain when loading template file")
            if path.last != "/" {
                path.append("/")
            }
            if let url = URL(string: "\(MailCustomScheme.template.rawValue)://\(domain)\(path)") {
                webview.loadHTMLString(html, baseURL: url)
                MailLogger.info("Replace schema and domain when loading template file, domain: \(domain), path: \(path)")
            } else {
                webview.loadHTMLString(html, baseURL: baseURL)
                MailLogger.error("Failed to init URL with custom schema and path")
            }
        } else {
            webview.loadHTMLString(html, baseURL: baseURL)
        }
        if let threadId = identifier {
            controller?.startLoadHtml(threadId: threadId)
        }
    }

    private func cleanContent(complete: (() -> Void)?) {
        isCleaningWebView = true
        bottomOperateBar.isHidden = true
        MailMessageListController.logStartTime(name: "cleanContent")
        evaluateJavaScript("document.body.innerHTML=''", completionHandler: { [weak self] (_, error) in
            if let error = error {
                MailLogger.error("cleanContent error \(error)")
            }
            self?.isCleaningWebView = false
            MailMessageListController.logStartTime(name: "cleanContent finish")
            complete?()
        })
    }
    
    private func loadToRenderHTMLString() {
        guard let htmlAndBaseURLToRender = htmlAndBaseURLToRender else {
            return
        }
        loadHTMLString(htmlAndBaseURLToRender.0, baseURL: htmlAndBaseURLToRender.1)
        self.htmlAndBaseURLToRender = nil
    }
    
    private func renderHTMLString(_ html: String, baseURL: URL?) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            MailLogger.info("MailMessageListView renderHTMLString id \(self.identifier ?? ""), isCleaned \(self.isWebViewCleaned), cleaning \(self.isCleaningWebView)")
            self.htmlAndBaseURLToRender = (html, baseURL)
            if self.isWebViewCleaned {
                self.loadToRenderHTMLString()
            } else if self.isCleaningWebView {
                // 已更新 htmlAndBaseURLToRender，等待WebView清除内容后加载即可
            } else {
                // WebView没清除，先清除WebView，在渲染
                self.cleanContent { [weak self] in
                    self?.loadToRenderHTMLString()
                }
            }
        }
    }

    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        webview.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    func updateBottomActionItems(_ mailActionItems: [MailActionItem]) {
        bottomOperateBar.updateActionItems(mailActionItems)
        updateBottomOperationBarHeight()
    }

    func updateStrangerActionItems(_ mailActionItems: [MailActionItem], mailItem: MailItem?) {
        strangerHeaderView.updateActionItemsForStranger(mailActionItems, mailItem: mailItem)
    }

    private func updateBottomOperationBarHeight() {
        let mailActionItemsCount = bottomOperateBar.actionItemsCount
        // 没有底部栏时，需要处理高度和样式
        let bottomBarHeight: CGFloat
        if (mailActionItemsCount > 0 || bottomOperateBar.isInSearchMode) && !isFeed {
            bottomBarHeight = bottomBarDefaultHeight
            domReadyBackgroundColor = UIColor.ud.bgBody
        } else {
            bottomBarHeight = 0
            domReadyBackgroundColor = webview.backgroundColor
        }
        if isDomReady {
            backgroundColor = domReadyBackgroundColor
        }
        setupViews(bottomBarHeight: bottomBarHeight)
    }

    func render(by viewModel: MailMessageListPageViewModel?,
                webDelegate: WKNavigationDelegate?,
                controller: MailMessageListController?,
                superContainer: UIView?,
                mailActionItemsBlock: @escaping (() -> [MailActionItem]),
                baseURL: URL?,
                delegate: MailMessageListViewDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
        isActivelyScrolling = false
        lastContentOffsetY = 0
        webview.weakRef.superContainer = superContainer
        self.mailActionItemsBlock = mailActionItemsBlock
        self.webDelegate = webDelegate
        self.controller = controller
        var isReuse = false
        if identifier != viewModel?.threadId {
            isHtmlLoaded = false
            isDomReady = false
            isRendering = false
            isFirstFrameRendered = false
            isReuse = true
        }
        viewModel?.newMessageTimeEvent?.commonParams.append(MailAPMEvent.NewMessageListLoaded.CommonParam.isReuseWebView(isReuse))
        identifier = viewModel?.threadId
        
        viewModel?.messageEvent?.renderStartTime = Date().timeIntervalSince1970

        if let viewModel = viewModel {
            let openNativeRender: Bool = {
                if provider.featureManager.open(.stranger, openInMailClient: false) {
                    return (controller?.fromLabel ?? "") != Mail_LabelId_Stranger
                } else {
                    return true
                }
            }()
            if let controller = controller, MailMessageListTemplateRender.enableNativeRender, openNativeRender {
                if let titleView = titleView {
                    var cover: MailReadTitleViewConfig.CoverImageInfo? = nil
                    if let info = viewModel.mailSubjectCover() {
                        cover = MailReadTitleViewConfig.CoverImageInfo(subjectCover: info)
                    }
                    let fromLabelID = MsgListLabelHelper.resetFromLabelIfNeeded(controller.fromLabel, msgLabels: viewModel.messageLabels)
                    let config = MailReadTitleViewConfig(title: viewModel.displaySubject,
                                                         fromLabel: fromLabelID,
                                                         labels: viewModel.labels ?? [],
                                                         isExternal: viewModel.mailItem?.isExternal == true,
                                                         translatedInfo: nil,
                                                         coverImageInfo: cover,
                                                         spamMailTip: viewModel.spamMailTip,
                                                         needBanner: viewModel.needBanner,
                                                         keyword: viewModel.keyword,
                                                         subjects: viewModel.subjects)
                    if MailMessageListViewsPool.fpsOpt {
                        if titleView.config != config {
                            titleView.updateUI(config: config)
                        }
                    } else {
                        titleView.updateUI(config: config)
                    }
                } else if !viewModel.displaySubject.isEmpty {
                    let containerWidth = bounds.width > 0 ? bounds.width : (superview?.bounds.width ?? UIScreen.main.bounds.width)
                    let nativeTitleView = nativeTitleView(from: viewModel)
                    nativeTitleView.frame = CGRect(x: 0, y: MailMessageNavBar.navBarHeight, width: containerWidth, height: nativeTitleView.desiredSize.height)
                    if viewModel.enableFirstScreenOptimize {
                        // 有标题时才直接addSubview
                        addSubview(nativeTitleView)
                    }
                    self.titleView = nativeTitleView
                }
            }

            if let bodyHtml = viewModel.bodyHtml {
                if !isDomReady {
                    if !isRendering {
                        isRendering = true
                        renderHTMLString(bodyHtml, baseURL: baseURL)
                    } else {
                        MailMessageListController.logger.debug("thread is rendering \(identifier ?? "")")
                    }
                } else {
                    onDomReady(true)
                }
                if isFirstFrameRendered {
                    asyncRunInMainThread { [weak self] in
                        self?.postMessageLoadEvent()
                    }
                }
            }
        }
    }

    func updateTitle(_ title: String,
                     translatedInfo: MailReadTitleViewConfig.TranslatedTitleInfo?,
                     labels: [MailClientLabel], fromLabel: String, flagged: Bool, isExternal: Bool,
                     subjectCover: MailSubjectCover?,
                     spamMailTip: String,
                     needBanner: Bool,
                     keyword: String = "", subjects: [String] = []) {
        var cover: MailReadTitleViewConfig.CoverImageInfo? = nil
        if let info = subjectCover {
            cover = MailReadTitleViewConfig.CoverImageInfo(subjectCover: info)
        }
        let config = MailReadTitleViewConfig(title: title,
                                             fromLabel: fromLabel,
                                             labels: labels,
                                             isExternal: isExternal,
                                             translatedInfo: translatedInfo,
                                             coverImageInfo: cover,
                                             spamMailTip: spamMailTip,
                                             needBanner: needBanner,
                                             keyword: keyword, subjects: subjects)
        titleView?.updateUI(config: config)
    }

    func updateTitleLabels(_ labels: [MailClientLabel], fromLabel: String, flagged: Bool, isExternal: Bool, hideFlag: Bool) {
        titleView?.updateLabels(labels, fromLabel: fromLabel, isExternal: isExternal)
    }

    private func handleScrollHideNavBar(scrollView: UIScrollView) {
        /// 只有 1. iPad, 2. 内容足够，可滚动时，才进行titleBar隐藏交互
        guard !Display.pad,
              scrollView.contentSize.height > scrollView.bounds.height,
              scrollView === webview.scrollView,
              let controller = controller,
              !controller.isInSearchMode,
              controller.fromLabel != Mail_LabelId_Stranger else {
            self.controller?.setNavBarHidden(false, animated: false)
            return
        }
        if isActivelyScrolling && scrollView.isDecelerating && (scrollView.contentOffset.y + scrollView.bounds.height) > scrollView.contentSize.height {
            // bounce back
            isActivelyScrolling = false
        }
        if isActivelyScrolling {
            let distance = scrollView.contentOffset.y - lastContentOffsetY
            if distance > 0.1 && scrollView.contentOffset.y > controller.webViewContentInsetTop {
                controller.setNavBarHidden(true, animated: true)
            } else if distance < -0.1 {
                controller.setNavBarHidden(false, animated: true)
            }
        }
        lastContentOffsetY = scrollView.contentOffset.y
    }

    func trackWebViewProcessTerminate(isPreload: Bool) {
        var logParams = [String: Any]()
        logParams["isPreload"] = isPreload ? 1 : 0
        logParams["isCurrent"] = (controller?.viewModel.threadId != nil && controller?.viewModel.threadId == webview.identifier) ? 1 : 0
        logParams["isRender"] = isRendering ? 1 : 0
        logParams["isDomready"] = isDomReady ? 1 : 0
        logParams["isHtmlloaded"] = isHtmlLoaded ? 1 : 0
        logParams["threadID"] = webview.identifier

        let isBackground: Int
        switch UIApplication.shared.applicationState {
        case .active:
            isBackground = 0
        case .background, .inactive:
            isBackground = 1
        @unknown default:
            isBackground = 0
        }
        logParams["isBackground"] = isBackground
        MailTracker.log(event: "mail_readmailprocess_terminate_dev", params: logParams)
        MailMessageListController.logger.info("mail_readmailprocess_terminate_dev, \(logParams)")
    }
}

extension MailMessageListView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isActivelyScrolling = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.viewModel?.feedCardId == "" {
            handleScrollHideNavBar(scrollView: scrollView)
        }
        strangerHeaderView.setBottomBorderIsHidden(scrollView.contentOffset.y < strangerHeaderViewHeight)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isActivelyScrolling = false
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isActivelyScrolling = false
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        controller?.setNavBarHidden(false, animated: false)
        return true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        controller?.setNavBarHidden(false, animated: false)
        strangerHeaderView.setBottomBorderIsHidden(true)
    }
}

extension MailMessageListView: MailWebviewJavaScriptDelegate {
    func invoke(webView: WKWebView, params: [String: Any]) {
        guard let method = params["method"] as? String,
              let args = params["args"] as? [String: Any] else {
            MailMessageListView.logger.warn("调用参数不对", additionalData: ["params": "\(params)"])
            return
        }
        guard let methodType = MailMessageListJSMessageType(rawValue: method) else {
            MailMessageListView.logger.error("未找到对应方法", additionalData: ["method": method])
            return
        }

        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            var methodHandled: Bool = true
            switch methodType {
            case .popoverDidClose:
                self.titleView?.showingPopover = false
                self.titleView?.updateNativeTitleUI(searchKey: nil, locateIdx: nil)
                self.titleView?.dismissCoverTitleBackground()
            case .imageOnLoad:
                if let src = args["src"] as? String,
                    let timestamp = args["timestamp"] as? Int,
                    let realThreadID = self.viewModel?.threadId {
                    MailLogger.info("imageOnLoad for \(realThreadID)")
                    self.viewModel?.imageMonitor.handleImageOnLoad(src: src, timestamp: timestamp,
                                                                   isCurrent: self.controller?.viewModel.threadId == realThreadID)
                }
            case .imageOnError:
                if let src = args["src"] as? String, let timestamp = args["timestamp"] as? Int, let realThreadID = self.viewModel?.threadId {
                    MailLogger.info("imageOnError for \(realThreadID)")
                    self.viewModel?.imageMonitor.handleImageOnError(src: src, timestamp: timestamp, isCurrent: self.controller?.viewModel.threadId == realThreadID)
                }
            case .imageStartLoad:
                if let src = args["src"] as? String,
                    let timestamp = args["timestamp"] as? Int,
                    let realThreadID = self.viewModel?.threadId {
                    MailLogger.info("imageStartLoad for \(realThreadID)")
                    if let viewModel = self.viewModel {
                        let isBlocked = args["isBlocked"] as? Bool ?? false
                        let domContentLoadedTime = args["domContentLoadedTime"] as? Int
                        viewModel.imageMonitor.handleImageStartLoad(src: src, timestamp: timestamp,
                                                                    isBlocked: isBlocked,
                                                                    domContentLoadedTime: domContentLoadedTime,
                                                                    isRead: viewModel.originalIsRead,
                                                                    from: self.controller?.statInfo.from.rawValue ?? "")
                    }
                }
            case .imageLoadingOnScreen:
                if let src = args["src"] as? String {
                    if let currentID = self.controller?.viewModel.threadId, let realThreadID = self.viewModel?.threadId, currentID == realThreadID {
                        MailLogger.info("imageLoadingOnScreen for \(realThreadID), with currentDisplay \(currentID)")
                        self.viewModel?.imageMonitor.handleImageLoadingOnScreen(src: src)
                    }
                }
            case .domReady:
                let jsCostTime = args["jsCostTime"] as? Double
                self.onDomReady(true, costTime: jsCostTime)
                self.timeMonitor.stage = .dom_ready
                self.timeMonitor.domReadyTimestamp = Int(Date().timeIntervalSince1970 * 1000)
            case .callbackJsLifecycle:
                guard let stage = args["lifecycle"] as? String,
                      let timings = args["timings"] as? [String: Int] else {
                    return
                }
                if stage == "domContentLoaded" {
                    timings["js_start"].map { self.timeMonitor.jsStartTimestamp = $0 }
                    timings["dom_content_loaded"].map { self.timeMonitor.domLoadedTimestamp = $0 }
                    self.viewModel?.newMessageTimeEvent?.stage = .js_handle
                } else if stage == "initUIEnd" {
                    timings["init_ui_end"].map { self.timeMonitor.initUIEndTimestamp = $0 }
                    self.viewModel?.newMessageTimeEvent?.stage = .js_first_scale
                } else if stage == "initEnd" {
                    timings["init_end"].map { self.timeMonitor.initEndTimestamp = $0 }
                } else if stage == "firstContentRendered" {
                    timings["first_content_rendered"].map { self.timeMonitor.renderFirstFrameTimestamp = $0 }
                    isFirstFrameRendered = true
                    asyncRunInMainThread { [weak self] in
                        self?.postMessageLoadEvent()
                    }
                }
            case .atUserInfos:
                guard let infoArray = args["infoArray"] as? [Any] else {
                    return
                }
                if let infos = self.atInfos {
                    self.atInfos = infos + infoArray
                } else {
                    self.atInfos = infoArray
                }
            default:
                methodHandled = false
            }
            if !methodHandled {
                self.controller?.invoke(webView: self.webview, method: methodType, args: args)
            }
        }
    }
}

extension MailMessageListView: MailReadTitleViewDelegate {
    var imageService: MailImageService? {
        provider.imageService
    }

    var configurationProvider: ConfigurationProxy? {
        provider.provider.configurationProvider
    }

    func nativeTitleViewDidInsert() {
        if let newHeight = titleView?.sizeToFit(with: CGSize(width: webview.bounds.width, height: .greatestFiniteMagnitude)).height {
            updateJSHeaderHeight(newHeight, completion: nil)
        }

        if titleView?.superview == self {
            titleView?.removeFromSuperview()
        }

        if preTitleView?.superview == self {
            print("&&&&Debug preTitleView?.removeFromSuperview()")
            preTitleView?.removeFromSuperview()
        }
        preTitleView = nil
    }

    func titleLabelsTapped() {
        delegate?.titleLabelsTapped()
    }

    func flagTapped() {
        delegate?.flagTapped()
    }

    func desiredHeightChanged(_ newHeight: CGFloat, completion: (() -> Void)?) {
        updateJSHeaderHeight(newHeight, completion: completion)
    }

    func notSpamTapped() {
        delegate?.notSpamTapped()
    }

    func bannerTermsAction() {
        delegate?.bannerTermsAction()
    }

    func bannerSupportAction() {
        delegate?.bannerSupportAction()
    }

    func scrollTo(_ rect: CGRect) {
        webview.scrollView.scrollRectToVisible(rect, animated: true)
    }

    func subjectTap(_ showPopover: Bool, customText: String?, popverTitle: String) {
        var subject = (viewModel?.subject ?? "").cleanEscapeCharacter()
        if let cus = customText {
            subject = cus.cleanEscapeCharacter()
        }
        let popverTitle = popverTitle.cleanEscapeCharacter()
        let show = showPopover ? 1 : 0
        evaluateJavaScript("window.togglePopover(\(show), '\(subject)', '\(popverTitle)')")
    }

    func nativeTitleView(from viewModel: MailMessageListPageViewModel) -> MailReadTitleView {
        let containerWidth = bounds.width > 0 ? bounds.width : (superview?.bounds.width ?? UIScreen.main.bounds.width)
        var cover: MailReadTitleViewConfig.CoverImageInfo? = nil
        if let info = viewModel.mailSubjectCover() {
            cover = MailReadTitleViewConfig.CoverImageInfo(subjectCover: info)
        }
        let fromLabelID: String = {
            if viewModel.labelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM,
               let folder = MailTagDataManager.shared.getFolderModel(viewModel.labels?.map({ $0.id }) ?? []),
               folder.id == Mail_LabelId_Spam {
                let spamMsgCount = viewModel.messageLabels.values.filter({ $0 == Mail_LabelId_Spam }).count
                return spamMsgCount > 0 ? folder.id : viewModel.labelId
            } else {
                return viewModel.labelId
            }
        }()
        let config = MailReadTitleViewConfig(title: viewModel.displaySubject,
                                             fromLabel: fromLabelID,
                                             labels: viewModel.labels ?? [],
                                             isExternal: viewModel.mailItem?.isExternal == true,
                                             translatedInfo: nil,
                                             coverImageInfo: cover,
                                             spamMailTip: viewModel.spamMailTip,
                                             needBanner: viewModel.needBanner,
                                             keyword: viewModel.keyword,
                                             subjects: viewModel.subjects)
        return MailReadTitleView(config: config, containerWidth: containerWidth, delegate: self)
    }

    func subjectDidCopy() {
        guard let oldest = viewModel?.mailItem?.oldestMessage else { return }
        controller?.handleCopyContents(messageIDs: [oldest.message.id])
    }
}

extension MailMessageListView: MailMessageNativeComponentManagerDelegate {
    var profileRouter: ProfileRouter? {
        provider.profileRouter
    }

    var currentTenantID: String {
        provider.user.tenantID
    }

    func showAddressSheet(address: String, sourceView: UIView) {
        let rect = self.convert(sourceView.frame, from: sourceView)
        controller?.showAddressActions(address: address, popoverFrame: rect)
    }

    func didSaveMailContact() {
        controller?.handleSaveContactResult(true)
    }

    func mailTitleView() -> MailReadTitleView? {
        if let titleView = self.titleView {
            if let viewModel = viewModel, preTitleView == nil {
                let webTitleView = nativeTitleView(from: viewModel)
                preTitleView = titleView
                self.titleView = webTitleView
            }
        }
        return self.titleView
    }
}

extension MailMessageListView: MailMessageListImageMonitorDelegate {
    func onWebViewStartURLSchemeTask(with urlString: String?) {
        if let urlString = urlString {
            viewModel?.imageMonitor.handleNativeInterceptDownload(src: urlString)
        }
    }

    func onWebViewSetUpURLSchemeTask(with urlString: String, fromCache: Bool) {
        viewModel?.imageMonitor.handleNativePrepareToDownload(src: urlString, fromCache: fromCache)
    }

    func onWebViewImageDownloading(with urlString: String) {
        viewModel?.imageMonitor.handleNativeDownloading(src: urlString)
    }

    func onWebViewFinishImageDownloading(with urlString: String, dataLength: Int, finishWithDrive: Bool, downloadType: MailImageDownloadType) {
        viewModel?.imageMonitor.handleNativeFinishDownload(src: urlString, finishWithDrive: finishWithDrive, downloadType: downloadType)
        viewModel?.imageMonitor.handleNativeDataSent(src: urlString, dataLength: dataLength)
        downloadImgSuccessHandler(url: urlString)
    }

    func onWebViewImageDownloadFailed(with urlString: String, finishWithDrive: Bool, downloadType: MailImageDownloadType, errorInfo: APMErrorInfo?) {
        viewModel?.imageMonitor.handleImageLoadFailed(src: urlString, finishWithDrive: finishWithDrive, downloadType: downloadType, errorInfo: errorInfo)
    }
}

extension MailMessageListView: MailStrangerManageDelegate, MailMsgStrangerHeaderDelegate {
    func didClickStrangerReply(status: Bool) {
        delegate?.didClickStrangerReply(status: status)
    }

    func avatarClickHandler(mailAddress: MailAddress) {
        delegate?.avatarClickHandler(mailAddress: mailAddress)
    }
}

extension MailMessageListView {
    func downloadProgessHandler(url: String?) {
        guard let url = url, downloadingURLImgTokens[url] == nil, downloadedURLImgTokens[url] == nil else {
            // 已经正在下载，或者已经完成了，不需要处理
            return
        }

        guard let token = imageService?.htmlAdapter.getTokenFromSrc(url), token.count > 0 else { return }

        var shouldLog = false
        for (_, token) in downloadingURLImgTokens.getImmutableCopy() {
            if downloadedURLImgTokens.first(where: { $0.value == token })?.value != nil {
                // 有重复图片正在下载, 影响了图片下载
                shouldLog = true
                break
            }
        }
        downloadingURLImgTokens[url] = token
        if shouldLog {
            affectedDownloadImgCount += 1
        }
    }

    func extractCid(from url: String?) -> String? {
        if let cidRegex = cidRegex, let url = url {
            let firstMatch = cidRegex.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.utf16.count))
            if let result = firstMatch, result.numberOfRanges >= 3 {
                let cidRange = result.range(at: 1)
                let cid = (url as NSString).substring(with: cidRange)
                return cid
            }
        }
        return nil
    }

    func startDownloadCidImage(url: String?) {
        if let cidRegex = cidRegex, let url = url {
            let firstMatch = cidRegex.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.utf16.count))
            if let result = firstMatch, result.numberOfRanges >= 3 {
                let cidRange = result.range(at: 1)
                let msgIdRange = result.range(at: 2)
                let cid = (url as NSString).substring(with: cidRange)
                let msgId = (url as NSString).substring(with: msgIdRange)
                if let image = viewModel?.mailItem?.messageItems.first(where: { $0.message.id == msgId })?.message.images.first(where: { $0.cid == cid }) {
                    if imageFileTokens.contains(image.fileToken) {
                        // 重复下载
                        repeatDownloadCount += 1
                        repeatDownloadSize += image.imageSize
                    }
                    totalDownloadCount += 1
                    totalDownloadSize += image.imageSize
                    imageFileTokens.insert(image.fileToken)
                }
            }
        }
    }

    func startDownloadTokenImage(token: String, result: MailImageTokenRequsetResult) {
        guard let mailItem = viewModel?.mailItem else {
            return
        }
        var imageItem: MailClientDraftImage?
        for item in mailItem.messageItems {
            for image in item.message.images where image.fileToken == token {
                imageItem = image
                break
            }
        }
        // token的情况
        if let image = imageItem {
            if result == .network {
                if imageFileTokens.contains(image.fileToken) {
                    repeatDownloadCount += 1
                    repeatDownloadSize += image.imageSize
                }
                totalDownloadCount += 1
                imageFileTokens.insert(image.fileToken)
            }
        }
    }

    func downloadImgSuccessHandler(url: String?) {
        if MailMessageListViewsPool.fpsOpt {
            DispatchQueue.global().async { [weak self] in
                guard let `self` = self else { return }
                guard let url = url, let token = self.imageService?.htmlAdapter.getTokenFromSrc(url), !token.isEmpty else { return }
                self.downloadedURLImgTokens[url] = token
                self.downloadingURLImgTokens[url] = nil
            }
        } else {
            guard let url = url, let token = self.imageService?.htmlAdapter.getTokenFromSrc(url), !token.isEmpty else { return }
            self.downloadedURLImgTokens[url] = token
            self.downloadingURLImgTokens[url] = nil
        }
    }

    private func logRepeatImageDownload() {
        if imageFileTokens.count > 0 {
            let params: [String: Any] = ["repeat_download": repeatDownloadCount > 0 ? 1 : 0,
                                          "repeat_download_count": repeatDownloadCount,
                                          "repeat_download_size": repeatDownloadSize,
                                          "download_count": totalDownloadCount,
                                          "download_size": totalDownloadSize,
                                          "download_count_affected_by_repeat_image": affectedDownloadImgCount]
            MailTracker.log(event: "email_message_list_download_image", params: params)
        }
        imageFileTokens.removeAll()
        downloadedURLImgTokens.removeAll()
        downloadingURLImgTokens.removeAll()
        repeatDownloadCount = 0
        repeatDownloadSize = 0
        totalDownloadCount = 0
        totalDownloadSize = 0
        affectedDownloadImgCount = 0
    }
}
