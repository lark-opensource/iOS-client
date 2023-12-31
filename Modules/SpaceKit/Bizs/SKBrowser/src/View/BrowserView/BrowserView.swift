//  Created by weidong fu on 4/2/2018.

/*!
 BrowserView负责配置Docs的请求（load)的信息（UA，Cookie, Infos）
 */
//swiftlint:disable file_length type_body_length

import Foundation
import WebKit
import SwiftyJSON
import Lottie
import SnapKit
import RxSwift
import SpaceInterface
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignFont
import UniverseDesignTheme
import UniverseDesignColor
import SKInfra
import LarkContainer


extension BrowserView: BrowserModelConfig {
    public var scrollProxy: EditorScrollViewProxy? { return scrollViewProxy }
    public var browserViewLifeCycleEvent: BrowserViewLifeCycle { return lifeCycleEvent }
    public var jsEngine: BrowserJSEngine { return self }
    @available(*, deprecated, message: "Disambiguate using hostBrowserInfo")
    public var browserInfo: BrowserViewDocsAttribute { return self }
    public var hostBrowserInfo: BrowserViewDocsAttribute { return self }
    public var requestAgent: BrowserRequestAgent { return self }
    public var shareAgent: BrowserViewShareAgent { return self }
    public var synchronizer: BrowserSynchronizer { return self }
    public var openRecorder: BrowserOpenRecorder { return self }
    public var feedInfo: BrowserFeedInfo { return self }
    public var loadingReporter: BrowserLoadingReporter? { return self.docsLoader }
    public var docsInfoUpateReporter: DocsInfoDidUpdateReporter { return self }
    public var permissionConfig: BrowserPermissionConfig { return self }
    public func setFullscreenScrollingEnabled(_ enabled: Bool) {
        delegate?.browserView(self, enableFullscreenScrolling: enabled)
    }
    public func setDocsShortcutCallback(_ callback: String) {
        shortcutCallback = callback
    }
    public func setDocsShortcut(_ info: [UIKeyCommand: String]) {
        delegate?.browserView(self, setKeyCommandsWith: info)
    }
    public func setClearDoneFinish(_ finish: Bool) {
        if canUpdateClearDoneState {
            webViewClearDone.value = finish
            DocsLogger.info("update webViewClearDone success")
        }
    }
}

extension BrowserView: BrowserUIConfig {
    public var displayConfig: BrowserViewDisplayConfig { return self }
    public var gestureProxy: EditorGestureProxy? { return  self.viewGestureProxy }
    public var hostView: UIView {
        return self
    }
    public var loadingAgent: BrowserLoadingAgent { return self }
    public var openDocAgent: BrowserOpenDocAgent { return self }
    public var bannerAgent: BannerItemAgent { return self }
    public var catalog: CatalogDisplayer? { return self.bizPlugin?.catalogAgent?.catalogDisplayer }
    public var commentPadDisplayer: CommentPadDisplayer? { return self }
    public var interfaceOrientation: UIInterfaceOrientation {
        return self.delegate?.browserViewCurrentOrientation(self) ?? .portrait
    }
    public var customTCDisplayConfig: CustomTopContainerDisplayConfig? {
        return self.delegate?.browserViewCustomTCDisplayConfig(self)
    }
}

public struct ExtraInfo {
    /// 目前仅用于埋点统计，来源入口模块
    var fromModule: String? = ""
    var fromSubmodule: String? = ""

    public init(fromModule: String? = "", fromSubmodule: String? = "") {
        self.fromModule = fromModule
        self.fromSubmodule = fromSubmodule
    }
}

public class BrowserView: UIView {
    public let userResolver: UserResolver // conform to `BrowserModelConfig`
    private let disposeBag = DisposeBag()
    fileprivate(set) var loadingView: UIView?
    weak var commentViewPad: UIView?
    public weak var commentViewPadBottomView: UIView?   // Bitable 容器底部的占位组件，适配 Comments 键盘弹出顶起
    var commentViewPresenting: Bool = false
    var commentViewDismissing: Bool = false
    public let commentViewAnimationDuration = TimeInterval(0.3) // 评论展开收起的动画时长
    let commentViewWidth: CGFloat = 300
    let disableCommentDelayFg: Bool = LKFeatureGating.disableCommentDelayFg
    var navigatorDidLoadEnd: Bool = false
    var applyPermissionView: SKApplyPermissionView?
    /// 约束操作请勿直接用editorView，而是要用editorWrapperView。(原因是防截图相关需求: chensi.123)
    public var editorView: DocsEditorViewProtocol { fatalError("needOverride") }
    /// editorView的superview，约束操作使用
    var editorWrapperView: UIView { viewCapturePreventer.contentView }
    private(set) lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        self.lifeCycleEvent.addObserver(preventer)
        preventer.notifyContainer = [.superView, .windowOrVC, .thisView]
        preventer.setAnalyticsFileInfoGetter(block: { [weak self] () -> (String?, String?) in
            let fileId = DocsTracker.encrypt(id: self?.docsInfo?.token ?? "")
            let fileType = self?.docsInfo?.inherentType.name ?? ""
            DocsLogger.info("ViewCapture Event: BrowserView fileId: \(fileId), fileType: \(fileType)")
            return (fileId, fileType)
        })
        return preventer
    }()
    var translateBtn: UIButton
    public weak var fabContainer: FABContainer?
    public var scrollViewProxy: EditorScrollViewProxy { fatalError("needOverride") }
    public private(set) var toolbarManagerProxy: DocsToolbarManagerProxy
    var viewGestureProxy: EditorGestureProxy { fatalError("needOverride") }
    public var docsLoader: DocsLoader? { fatalError("needOverride") }
    var scriptMessageHandlerNames: Set<String> = []
    public private(set) var jsServiceManager: DocsJSServicesManager!
    var viewManager: SpaceEditorViewManager?
    var loadingDelegate: SpaceEditorLoadingAbility? { return viewManager?.loadingManager }
    var openProgressManager: OpenProcessManager?
    public var uiResponder: BrowserUIResponder {
        return keyboardHandler
    }
    private var keyboardHandler: BrowserKeyboardHandler!

    public let lifeCycleEvent: BrowserViewLifeCycle
    let permissionManager = BrowserPermissionManager()
    // weak会导致reload时,vcFollowDelegate为nil。 VCFolowAPIIMP --weak--> DocsVC -> BrowserView -> VCFolowAPIIMP，不会造成循环引用
    // swiftlint:disable weak_delegate
    public var isInVideoConference: Bool { vcFollowDelegate != nil }
    /// 当前页面是否是群tab
    public var isInGroupTab: Bool { self.currentURL?.docs.isGroupTabUrl ?? false }
    /// clearDone通知是否可以更新从复用池里移除的标记
    public var canUpdateClearDoneState: Bool = false
    
    // MARK: - delegates
    public var vcFollowDelegate: BrowserVCFollowDelegate?
    public weak var docComponentDelegate: DocComponentHostDelegate?
    public weak var delegate: BrowserViewDelegate?
    public weak var navigationItemObserver: BrowserViewNavigationItemObserver?
    public private(set) weak var navigator: BrowserViewNavigator?
    private(set) weak var shareDelegate: DocsBrowserShareDelegate?
    private(set) weak var offlineDelegate: BrowserViewOfflineDelegate?
    // MARK: - status
    private var translateCanScroll = true
    public var isInCodeBlockScene: Bool = false
    private var didStartDrag = false
    private var startDragYpos: CGFloat = 0.0
    public var isShowComment: Bool = false
    public var isInForground: Bool = true
    // 特意给 MLeaksFinder 加的变量
    public var isInEditorPool: Bool = false
    public var poolIndex: Int = -1
    /// 群公告的id
    public private(set) var chatId: String?

    /// 记录当前外接键盘space点击的时间戳
    public var spacePressesBeginTimestamp: Int?

    /// 判断当前PopoverAt面板是否展示
    var _isPopoverAtFinderScene: Bool?

    /// 当前render是否是DarkMode
    public var isRenderDarkMode: Bool = false

    /// 记录是否正在展示申请权限页面
    public var isShowApplyPermissionView: Bool = false
    
    /// 权限被admin管控
    public var isPermssionAdminBlocked: Bool = false

    public var title: String? {
        didSet {
            navigationItemObserver?.titleDidChange(from: oldValue, to: title)
        }
    }
    public var trailingButtonItems: [SKBarButtonItem] = [] {
        didSet {
            DocsLogger.info("\(editorIdentity) trailingBarButtonItems did change to \(trailingButtonItems.count) items")
            navigationItemObserver?.trailingButtonBarItemsDidChange(from: oldValue, to: trailingButtonItems)
        }
    }
    public var rightBottomBtnItems: [UIButton]?
    private var _isHistoryPanelShow: Bool = false

    // MARK: - IPad Catalog
    weak var catalogSideViewPad: IPadCatalogSideView?
    var ipadCatalogDisplayInfo: IpadCatalogDisplayInfo?
    var ipadCatalogAlreadyDismiss: Bool = false // 用于避免滚动或者点击触发多次隐藏
    var ipadCatalogContainWidth: CGFloat {
        guard let info = ipadCatalogDisplayInfo, info.mode != .covered else {
            return 0
        }
        return info.width
    }

    var iconInfo: IconSelectionInfo?
    public var extraInfo: ExtraInfo?

    public var fileConfig: FileConfig?
    /// 工具栏快捷键回调
    var shortcutCallback: String = ""
    var bizPlugin: BrowserViewPlugin? //业务插件
    var lastViewWidth: CGFloat = 0

    deinit {
        DocsLogger.info("\(editorIdentity) BrowserView deinit")
    }

    // 在重用池则不检查内存泄漏
    // 不再重用池则监测
    @objc
    func willDealloc() -> Bool {
        return !isInEditorPool
    }

    // MARK: - inits
    override init(frame: CGRect) {
        fatalError("not inplement \(#function), call init(frame: CGRect, config: BrowserViewConfig)")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, config: BrowserViewConfig, userResolver: UserResolver) {
        self.userResolver = userResolver
        lifeCycleEvent = BrowserViewLifeCycle()
        translateBtn = UIButton()
        toolbarManagerProxy = DocsToolbarManagerProxyImpl()
        super.init(frame: .zero)
        keyboardHandler = BrowserKeyboardHandler(editorView: editorView)
        //不要随意调换顺序
        offlineDelegate = config.offlineDelegate
        shareDelegate = config.shareDelegate
        navigator = config.navigator
        //webview staff
        editorWrapperView.addSubview(editorView)
        editorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(editorWrapperView)
        editorWrapperView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(ipadCatalogContainWidth)
            make.right.top.bottom.equalToSuperview()
        }
        
        docsLoader?.updateClientInfo(config.clientInfos)
        editorView.setSKEditorConfigDelegate(docsLoader)

        self.backgroundColor = UDColor.bgBody
        jsServiceManager = DocsJSServicesManager(navigator: self, userResolver: self.userResolver)

        keyboardHandler.delegate = self
        keyboardHandler.listenKeyboardEvent()
        
        //other
        setupLifeCycleObservers()
        setupScrollViewObservers()
        if OpenAPI.docs.shouldShowFileOpenBasicInfo == true {
            openProgressManager = OpenProcessManager(lifeCycle: self.lifeCycleEvent, hostview: self.hostView, userResolver: self.userResolver)
        }
        setupSupplementaryItems()

        addFontSizeUpdatedObserver()
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(themeDidChanged), name: UDThemeManager.didChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(themeDidChanged), name: Notification.Name.DocsThemeChanged, object: nil)
        }
        
        //增加监听是否删除关联文档
        NotificationCenter.default.rx.notification(Notification.Name.Docs.deleteAssociateApp)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                guard let object = notification.object,
                      let deleteUrl = object as? String else {
                    DocsLogger.error("deleteAssociateApp notify error", component: LogComponents.associateApp)
                    return
                }
                //清除缓存的关联文档记录
                if self.fileConfig?.associateAppUrl == deleteUrl {
                    DocsLogger.info("deleteAssociateApp notify, delete url:\(deleteUrl)", component: LogComponents.associateApp)
                    self.fileConfig?.associateAppUrl = nil
                }
            })
            .disposed(by: disposeBag)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let currentViewWidth = self.frame.width
        if currentViewWidth > 0, lastViewWidth != currentViewWidth {
            lastViewWidth = currentViewWidth
        }
        lifeCycleEvent.browserDidLayoutSubviews()
    }

    private func setupSupplementaryItems() {
        guard let browserVC = currentBrowserVC else {
            DocsLogger.error("show translateBtn: BrowserVC is nil")
            return
        }
        // Translate Button
        addSubview(translateBtn)
        if SKDisplay.pad {
            translateBtn.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(20)
                make.left.greaterThanOrEqualTo(safeAreaLayoutGuide.snp.left).offset(16)
                make.right.lessThanOrEqualTo(safeAreaLayoutGuide.snp.right)
                make.height.equalTo(44)
            }
        } else {
            translateBtn.snp.makeConstraints { (make) in
                make.left.equalTo(browserVC.view.snp.left)
                make.right.equalTo(browserVC.view.snp.right)
                make.height.equalTo(48 + safeAreaInsets.bottom)
                make.bottom.equalToSuperview()
            }
        }
        translateBtn.isHidden = true
    }

    private func setupLifeCycleObservers() {
        guard let tmpDocsLoader = docsLoader else { return }
        lifeCycleEvent.addObserver(tmpDocsLoader)
        lifeCycleEvent.addObserver(jsServiceManager)
    }

    private func setupScrollViewObservers() {
        scrollViewProxy.addObserver(self)
    }

    private func setupBizPlugin(docsType: DocsType?) {
        guard let docsType = docsType else {
            return
        }
        if let bizPlugin = self.bizPlugin {
            if bizPlugin.supportDocsTypes.contains(docsType), bizPlugin.curDocsType == docsType {
                DocsLogger.info("[bizPlugin] docsType一致，可以复用")
                return
            } else {
                bizPlugin.unmount()
                self.bizPlugin = nil
                DocsLogger.info("[bizPlugin] 移除旧plugin")
            }
        }
        guard let pluginType = self.userResolver.docs.browserDependency?.getBrowserViewPluginType(docsType) else {
            return
        }
        DocsLogger.info("[bizPlugin] 创建新plugin-\(docsType)")
        self.bizPlugin = pluginType.init(self, docsType: docsType)
        self.bizPlugin?.mount()
    }

    // WARNING: 后续往这个方法添加代码，需要考虑重复调用是否会有问题，避免重复调用出现异常
    public func load(url: URL) {
        let fileType = getRealFileType(from: url)
        if checkDownloadFullPackageIfNeed(url: url, fileType: fileType) {
            //需要下载完整包
            DocsLogger.warning("need Download Full Package \(editorIdentity)", component: LogComponents.fileOpen)
            return
        }
        updateFileType(fileType: fileType)
        setupBizPlugin(docsType: fileType)
        jsServiceManager.registerServices(ui: self, model: self, fileType: fileType)
        fileConfig?.feedFromInfo?.record(.registerServices)
        lifeCycleEvent.browserWillLoad()
        DocsLogger.info("\(ObjectIdentifier(self)),browserView load url")
        docsLoader?.load(url: url)
        if fileType != nil {
            var config = SpaceEditorViewManagerConfig()
            config.hostView = self.hostView
            config.loadingAnimation = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
            config.statusViewDelegate = self
            config.bannerItemAgent = self
            config.identity = editorIdentity
            viewManager = SpaceEditorViewManager(config: config, delegate: self, userResolver: self.userResolver)
//            simulateJSMessage("biz.util.updateDocInfo", params: ["docsInfo": docsInfo as Any])
        }
        loadingDelegate?.updateLoadStatus(.justBegin, oldStatus: nil)
    }

    // 根据 url 获取文档的真实类型
    func getRealFileType(from url: URL) -> DocsType? {
        // jsServiceManager 需要根据单品类型加载对应的单品service，所以如果是wiki，需要获取wiki对应的单品类型进行加载
        var type = DocsUrlUtil.getFileType(from: url)
        let token = DocsUrlUtil.getFileToken(from: url) ?? ""
        let version: String? = url.queryParameters["wiki_version"]
        if type == .wiki {
            if let wikiInfo = self.userResolver.docs.browserDependency?.getWikiInfo(by: token, version: version) {
                type = wikiInfo.docsType
            } else {
                spaceAssertionFailure("cannot get wiki real type @peipei")
            }
        }
        if type == .sync {
            //同步块享受docx的待遇
            type = .docX
        }
        return type
    }
    
    func updateFileType(fileType: DocsType?) {
    }

    func checkDownloadFullPackageIfNeed(url: URL, fileType: DocsType?) -> Bool {
        return false
    }

    func removeSPView() {
        self.subviews.forEach { (subView) in
            if subView != editorWrapperView && subView != editorView && ( bizPlugin?.shouldHideView(subView) ?? true) {
                subView.isHidden = true
            }
        }
    }

    func clear() {
        DocsLogger.info("\(editorIdentity) clear called", component: LogComponents.fileOpen)
        if let token = docsInfo?.objToken {
            let rnDic = ["operation": "exitFromWebview", "body": token]
            RNManager.manager.sendSyncData(data: rnDic)
        }
        if #available(iOS 13, *) {
            UIMenuController.shared.hideMenu()
        } else {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
        canUpdateClearDoneState = true
        resetCommentView()
        resetCatalogSideView()
        permissionManager.clear()
        lifeCycleEvent.browserWillClear()
        title = nil
        setNavigation(titleInfo: nil, needDisPlayTag: false, tagValue: nil, iconInfo: nil, canRename: nil)
        trailingButtonItems = []
        isHistoryPanelShow = false
        rightBottomBtnItems = nil
        translateCanScroll = true
        isPopoverAtFinderScene = nil
        userActivity?.resignCurrent()
        viewManager?.clear()
        viewManager = nil
        chatId = nil
        spaceAssert(Thread.isMainThread)
        snp.removeConstraints()
        removeFromSuperview()
        fabContainer?.removeFromSuperview()
        fabContainer = nil
        self.bizPlugin?.clear()
        keyboardHandler.setTrigger(trigger: DocsKeyboardTrigger.editor.rawValue)
        PreloadStatistics.shared.clear(self.editorIdentity)

        if #available(iOS 13.0, *) {} else {
            //https://jira.bytedance.com/browse/SUITE-677236
            //在iOS12上，如果退出webview时realInputView不为nil，则再次重用webview时，打开文档会显示上次的键盘，所以这里退出的时候要将realInputView置nil
            self.uiResponder.inputAccessory.realInputView = nil
        }
    }

    public func browserViewControllerDidLoad() {
        lifeCycleEvent.browserViewControllerDidLoad()
        viewCapturePreventer.resetIfNetUnreachableWhenDocsViewDidLoad()
    }
    
    public func browserWillAppear() {
        lifeCycleEvent.browserWillAppear()
        updateTranslateBtn()
        notifyWillAppearForPermission()
    }

    public func browserDidAppear() {
        DocsLogger.info("\(editorIdentity) browserDidAppear")
        lifeCycleEvent.browserDidAppear()
        keyboardHandler.startMonitorKeyboard()
        setEditMenu()
    }

    public func browserWillDisappear() {
        lifeCycleEvent.browserWillDismiss()
        toolbarManagerProxy.removeToolBar() //browserView消失时会导致键盘失焦，统一将工具栏隐藏
    }

    public func browserDidDisappear() {
        DocsLogger.info("\(editorIdentity) browserDidDisappear")
        lifeCycleEvent.browserDidDisappear()
        keyboardHandler.stopMonitorKeyboard()
        notifyDidDisappearForPermission()
    }

    public func dismissChildController() {
        lifeCycleEvent.browserDidDismiss()
    }

    public func browserWillTransition(from: CGSize, to: CGSize) {
        lifeCycleEvent.browserWillTransition(from: from, to: to)
    }

    public func browserDidTransition(from: CGSize, to: CGSize) {
        lifeCycleEvent.browserDidTransition(from: from, to: to)
        adjustCommentViewLayout()
        updateCatalogSideView()
    }
    
    public func browserDidSplitModeChange() {
        lifeCycleEvent.browserDidSplitModeChange()
        adjustCommentViewLayout()
        updateCatalogSideView()
    }
    
    public func browserNavReceivedPopGesture() {
        lifeCycleEvent.browserNavReceivedPopGesture()
    }
    
    public func browserTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        lifeCycleEvent.browserTraitCollectionDidChange(previousTraitCollection)
    }
    
    ///为webview新增UIEditMenuInteraction，用于前端调用主动弹出气泡菜单
    private func setEditMenu() {
        guard #available(iOS 16.0, *) else { return }
        guard let type = docsInfo?.inherentType, UserScopeNoChangeFG.LJW.editMenuEnable else { return }
        if type.editMenuInteractionEnable {
            defer { self.disableSecondaryClick() }
            for item in editorView.interactions where item is UIEditMenuInteraction {
                return
            }
            let editMenuInteraction = UIEditMenuInteraction(delegate: DocsWebViewEditMenuManager.shared)
            editorView.addInteraction(editMenuInteraction)
        }
    }
    
    ///disable webView的右键手势
    public func disableSecondaryClick() {
        
    }

    // iPad进入or退出全屏
    public func browserChangeFullScreenMode(_ isFullsceenMode: Bool) {
        // handle catalog
        if let catalogSideViewPad = self.catalogSideViewPad, catalogSideViewPad.superview != nil, self.ipadCatalogDisplayInfo != nil {
            // 存在目录时直接更新
            updateCatalogSideView()
        } else {
            // 不存在目录时判断是否需要显示目录,历史记录展示的时候，不展示目录
            if SKDisplay.pad, let docsInfo = docsInfo, docsInfo.inherentType == .docX, isFullsceenMode, isHistoryPanelShow == false, !(customTCDisplayConfig?.customTopContainerShow() ?? false) {
                jsEngine.simulateJSMessage(DocsJSService.ipadCatalogDisplay.rawValue, params: ["autoShow": true])
            }
        }
    }

    @discardableResult
    public func setChatID(_ id: String?) -> BrowserView {
        self.chatId = id
        return self
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return uiResponder.resign()
    }

    public func onKeyboardChanged(_ isShow: Bool, innerHeight: CGFloat, trigger: String) {
        var lastTrigger = trigger
        if self.isInVideoConference,
           keyboardHandler.editorViewKeyboard?.displayType != .floating || isShow == true || keyboardHandler.editorViewKeyboard?.isHiding == false {
            guard let firstResponder = UIResponder.docsFirstResponder() as? UIView, firstResponder.isDescendant(of: self.editorView) else {
                return  //VCFollow下，只响应焦点在webview的键盘事件，因为VC的界面也会有其它输入框
            }
        }
        if self.isInCodeBlockScene {
            lastTrigger = DocsKeyboardTrigger.codeBlock.rawValue
        }
        let keyboardInfo = BrowserKeyboard(height: innerHeight, isShow: isShow, trigger: lastTrigger)
        lifeCycleEvent.browserKeyboardDidChange(keyboardInfo)
    }

    public func browserWillChangeOrientation(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        lifeCycleEvent.browserWillChangeOrientation(from: oldOrientation, to: newOrientation)
    }

    public func browserDidChangeOrientation(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        lifeCycleEvent.browserDidChangeOrientation(from: oldOrientation, to: newOrientation)
    }

    func modifyEditButtonProgress(_ progress: CGFloat, animated: Bool, force: Bool = false, completion: (() -> Void)? = nil) {
        self.bizPlugin?.editButtnAgent?.modifyEditButtonProgress(progress, animated: animated, force: force, completion: completion)
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        fatalError("子类实现")
    }
    
    public func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?) {
        skAssertionFailure("must override in subclass")
    }

    @objc
    public func hideLoadingIfNeed() {
    }

    public func didLoadEnd(error: Error?) {
        DocsLogger.info("navigatorDidLoadEnd:\(error)")
        self.navigatorDidLoadEnd = true
        makeCommentVisibleIfNeed()
        hideLoadingIfNeed()
    }
}

extension BrowserView: DocsInfoDidUpdateReporter {
    public func loaderDidUpdateDocsInfo(stage: DocsInfoUpdateStage, error: Error?) {
        switch stage {
        case .getWholeInfo:
            guard error == nil else { return }
            lifeCycleEvent.browserDidUpdateDocsInfo()
        case .getWikiInfo:
            docsLoader?.browserDidGetWikiInfo(error: error)
        }
        delegate?.browserViewDidUpdateDocsInfo(self)
    }

    public func loaderDidUpdateRealTokenAndType(info: DocsInfo) {
        delegate?.browserViewDidUpdateRealTokenAndType(info: info)
    }

}

// fontsizeChange
extension BrowserView {
    private func addFontSizeUpdatedObserver() {
        DocsLogger.info("BrowserView Util BaseFontSize Observer")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notifyBaseFontSizeUpdated),
            name: UDZoom.didChangeNotification,
            object: nil)
    }
    @objc
    private func notifyBaseFontSizeUpdated() {
        // 更新状态
        DocsLogger.info("BrowserView Util BaseFontSize didUpdated")
        let params: [String: Any] = ["size": UDZoom.currentZoom.name]
        callFunction(.baseFontSizeUpdated, params: params, completion: nil)
    }
    
    @objc
    private func themeDidChanged() {
        jsEngine.simulateJSMessage(DocsJSService.simulateUserInterfaceChanged.rawValue, params: [:])
    }
}

extension BrowserView: DocsStatusViewDelegate {
    func statusView(_ statusView: SpaceEditorLoadingAbility, didInvoke action: DocsStatusViewAction) {
        switch action {
        case .reload:
            docsLoader?.browserWillClear()
            // 如果代理需要替换成自己的loading
            if let shouldReplaceLoading = delegate?.browserViewShowCustomLoading(self), shouldReplaceLoading {
                // 不处理，由代理接管
            } else {
                docsLoader?.delayShowLoading()
            }
            docsLoader?.reload()
        }
    }

    var statusBrowserView: BrowserView? { self }
    
    func costomStateHostConfig() -> CustomStatusConfig? {
        delegate?.browserStateHostConfig(self)
    }
}

extension BrowserView: BrowserJSEngine {
    public func fetchServiceInstance<H>(_ service: H.Type) -> H? where H: JSServiceHandler {
        return jsServiceManager.fetchServiceInstance(service)
    }

    public func simulateJSMessage(_ msg: String, params: [String: Any]) {
        jsServiceManager.simulateJSMessage(msg, params: params)
    }

    public var isBusy: Bool {
        get { return jsServiceManager.isBusy }
        set { jsServiceManager.isBusy = newValue }
    }

    public var editorIdentity: String { return "\(ObjectIdentifier(self))" }
}

// MARK: - BrowserViewDocsAttribute
extension BrowserView: BrowserViewDocsAttribute {
    public var docsInfo: DocsInfo? { return docsLoader?.docsInfo }
    public var currentTrigger: String? { return toolbarManagerProxy.toobar?.currentTrigger }
    public var openSessionID: String? {
        get { return docsLoader?.openSessionID }
        set { docsLoader?.openSessionID = newValue }
    }
    public var currentURL: URL? {
        get { return docsLoader?.currentUrl }
        set { docsLoader?.currentUrl = newValue }
    }
    @objc
    public var loadedURL: URL? { return nil }
    public var loadStatus: LoadStatus { docsLoader?.loadStatus ?? .unknown }
    
}

// MARK: - BrowserViewUIDisplay
extension BrowserView: BrowserViewDisplayConfig {

    public func setNavigation(titleInfo: NavigationTitleInfo?, needDisPlayTag: Bool?, tagValue: String?,
                              iconInfo: IconSelectionInfo?, canRename: Bool?) {
        if let disPlay = needDisPlayTag, let value = tagValue {
            userResolver.docs.editorManager?.browserView(self, setNeedDisPlay: disPlay, tagValue: value)
        }
        self.title = titleInfo?.title
        delegate?.browserViewDidUpdateDocName(self, docName: titleInfo?.title)
        userResolver.docs.editorManager?.browserView(self, setTitleInfo: titleInfo)
        userResolver.docs.editorManager?.browserView(self, setAvatar: iconInfo)
        userResolver.docs.editorManager?.browserView(self, setCanRename: canRename)
    }

    public func setNavigation(title: String?) {
        self.title = title
        var titleInfo: NavigationTitleInfo?
        if let titleText = title {
            titleInfo = NavigationTitleInfo(title: titleText)
        }
        setNavigation(titleInfo: titleInfo,
                      needDisPlayTag: nil,
                      tagValue: nil,
                      iconInfo: nil,
                      canRename: nil)
    }

    public func setNavigation(secretTitle: String) {
        userResolver.docs.editorManager?.browserView(self, secretTitle: secretTitle)
    }

    public func setOfflineTipViewStatus(_ status: Bool) {
        viewManager?.setOfflineTipViewStatus(status)
    }

    public func setTitleBarStatus(_ status: Bool) {
        userResolver.docs.editorManager?.browserView(self, setTitleBarStatus: status)
    }

    public func setToggleSwipeGestureEnable(_ enable: Bool) {
        userResolver.docs.editorManager?.browserView(self, setToggleSwipeGestureEnable: enable)
    }

    public func setTitle(_ title: String, for objToken: String) {
        offlineDelegate?.browserView(self, setTitle: title, for: objToken)
        docsInfo?.title = title
        delegate?.browserViewDidUpdateDocName(self, docName: title)
    }

    //翻译按钮相关逻辑
    public var rightBottomButtonItems: [UIButton]? {
        get { return rightBottomBtnItems }
        set {
            rightBottomBtnItems = newValue
            self.translateBtn.isEnabled = true
            updateTranslateBtn()
        }
    }

    public var isEditButtonVisible: Bool {
        self.bizPlugin?.editButtnAgent?.isEditButtonVisible ?? false
    }
    
    public var isHistoryPanelShow: Bool {
        get { return _isHistoryPanelShow }
        set {
            _isHistoryPanelShow = newValue
        }
    }

    public var isEditingStatus: Bool {
        return keyboardHandler.keyboardIsShow
    }

    // 判断当前PopoverAt面板是否展示
    public var isPopoverAtFinderScene: Bool? {
        get { return _isPopoverAtFinderScene }
        set {
            _isPopoverAtFinderScene = newValue
        }
        
    }

    public var getCommentViewWidth: CGFloat {
        if commentViewPad == nil ||
            commentViewPad?.isHidden == true ||
            lastViewWidth < 500 {
            return 0
        } else {
            return self.commentViewWidth
        }
    }

    private func updateTranslateBtn() {
        //没有数据直接移除translateBtn
        guard let items: [UIButton] = self.rightBottomButtonItems else {
            self.translateBtn.removeFromSuperview()
            return
        }
        if self.translateBtn.isEnabled == true {
            let btn = items[0]
            self.translateBtn.removeFromSuperview()
            if btn.viewIdentifier == RightBottomBtnFeatureService.switchOrignal {
                self.translateBtn = btn
                self.setupSupplementaryItems()
                self.translateBtn.isHidden = false
                if let translateBtn = self.translateBtn as? BottomTranslateButton {
                    translateBtn.startAutoDismissTimer()
                }
            }
        }
    }

    public func showTranslateBtn() {
        guard self.translateBtn.superview != nil else { return }
        self.translateBtn.isEnabled = true
        if SKDisplay.pad {
            UIView.animate(withDuration: 0.3) {
                self.translateBtn.alpha = 1.0
            }
        } else {
            self.translateBtn.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview()
            })
            reloadTransLateBtn()
        }
        if let translateBtn = self.translateBtn as? BottomTranslateButton {
            translateBtn.startAutoDismissTimer()
        }
    }

    public func hideTranslateBtn() {
        guard self.translateBtn.superview != nil else { return }
        self.translateBtn.isEnabled = false
        if SKDisplay.pad {
            UIView.animate(withDuration: 0.3) {
                self.translateBtn.alpha = 0.0
            }
        } else {
            let height = self.translateBtn.bounds.height
            self.translateBtn.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview().offset(height)
            })
            reloadTransLateBtn()
        }
        if let translateBtn = self.translateBtn as? BottomTranslateButton {
            translateBtn.cancelAutoDismissTimer()
        }
    }

    public func handleDeleteEvent() {
        delegate?.browserViewHandleDeleteEvent(self)
    }
    
    public func handleDeleteRecoverEvent() {
        delegate?.browserViewHandleDeleteRecoverEvent(self)
    }

    ///处理密钥删除事件
    public func handleKeyDeleteEvent() {
        delegate?.browserViewHandleKeyDeleteEvent(self)
    }
    
    public func handleNotFoundEvent() {
        delegate?.browserViewHandleNotFoundEvent(self)
    }

    @objc
    private func reloadTransLateBtn() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.translateBtn.superview?.layoutIfNeeded()
        }, completion: nil)
    }

    public func setOrientation(_ orientation: UIInterfaceOrientation) {
        delegate?.browserView(self, shouldChange: orientation)
    }

    /// 设置编辑按钮是否可见
    public func setEditButtonVisible(_ visible: Bool) {
        self.bizPlugin?.editButtnAgent?.setEditButtonVisible(visible)
    }

    public func modifyEditButtonBottomOffset(height: CGFloat) {
        self.bizPlugin?.editButtnAgent?.modifyEditButtonBottomOffset(height: height)
    }

    public func toggleEditMode() {
        delegate?.browserViewShouldToggleEditMode(self)
    }

    public func setCompleteButtonVisible(_ visible: Bool) {
        delegate?.browserView(self, shouldChangeCompleteButtonInvisible: !visible)
    }

    public func setNavBarFixedShowing(_ isFixed: Bool) {
        DocsLogger.info("setNavBarFixedShowing: \(isFixed)")
        delegate?.browserView(self, setTopContainerState: isFixed ? .fixedShowing : .normal)
    }

    public func setIpadCatalogState(isOpen: Bool) {
        delegate?.browserView(self, shouldChangeCatalogButtonState: isOpen)
    }

    public func obtianIPadCatalogState() -> Bool {
        return delegate?.browserVIewIPadCatalogState(self) ?? false
    }
    
    public func getWebViewCoverHeight() -> CGFloat {
        return delegate?.browserViewTitleBarCoverHeight(self) ?? 0
    }

    /// CodeBlock设置状态
    public func setCodeBlockSceneStatus(_ isInCodeBlockScene: Bool) {
        self.isInCodeBlockScene = isInCodeBlockScene
    }

    public func rerenderWebview(with reloadUrl: URL?) {
        var url: URL?
        if let reloadUrl {
            let reloadToken = DocsUrlUtil.getFileToken(from: reloadUrl)
            if reloadToken == docsInfo?.token || reloadToken == docsInfo?.objToken || reloadToken == docsInfo?.urlToken {
                //只接受token一致的reload
                url = reloadUrl
            } else {
                spaceAssertionFailure("reload url is unsupported")
                return
            }
        }
        DocsLogger.info("rerenderWebview")
        lifeCycleEvent.browserWillRerender()
        docsLoader?.removeContentIfNeed()
        docsLoader?.reload(with: url)
    }
    
    public func setShowTemplateTag(_ showTemplateTag: Bool) {
        userResolver.docs.editorManager?.browserView(self, setTemplate: showTemplateTag)
    }
    
    public func setFullScreenModeButtonEnable(_ enable: Bool) {
        navigationItemObserver?.fullScreenButtonBarItemDidChangeState(isEnable: enable)
    }
    
    public func canShowDeleteVersionEmptyView(_ show: Bool) {
        delegate?.canShowDeleteVersionEmptyView(show)
    }
    
    /// 设置外显目录是否显示
    public func setCatalogueBanner(visible: Bool) {
        delegate?.setCatalogueBanner(visible: visible)
    }
    
    /// 设置外显目录
    public func setCatalogueBanner(catalogueBannerData: SKCatalogueBannerData?, callback: SKCatalogueBannerViewCallback?) {
        delegate?.setCatalogueBanner(catalogueBannerData: catalogueBannerData, callback: callback)
    }
    
    public func showBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?) {
        delegate?.browserViewShowBitableAdvancedPermissionsSettingVC(data: data, listener: listener)
    }
    
    public func refresh() {
        delegate?.browserViewHandleRefreshEvent(self)
    }
}

// MARK: - BrowserRequestAgent
extension BrowserView: BrowserRequestAgent {
    public var requestHeader: [String: String] { return docsLoader?.netRequestHeaders ?? ["": ""] }
    public var currentUrl: URL? { return docsLoader?.currentUrl }

    public func clearPreloadStatus() {
        guard let webLoader = docsLoader as? WebLoader else {
            DocsLogger.info("webLoader is nil")
            return
        }
        webLoader.updateMainFrameStatus(PreloadStatus())
    }

    public func addPreloadType(_ type: String) {
        guard let webLoader = docsLoader as? WebLoader else {
            DocsLogger.info("webLoader is nil. addPreloadType fail \(type)")
            return
        }

        webLoader.preloadStatus.value.addType(type)

        if webLoader.preloadStatus.value.hasComplete {
            preloadEndTimeStamp = Date().timeIntervalSince1970
        }
    }
    public func notifyPreloadHtmlReady(preloadTypes: [String]) {
        guard let webLoader = docsLoader as? WebLoader else {
            return
        }
        webLoader.updatePreloadHtmlReadyStatus(preloadTypes: preloadTypes)
    }
}

// MARK: - BrowserOpenDocAgent
extension BrowserView: BrowserOpenDocAgent {
    public func didBeginEdit() {
        lifeCycleEvent.browserDidBeginEdit()
    }
}

// MARK: - BrowserSynchronizer
extension BrowserView: BrowserSynchronizer {
    public func didSync(with objToken: String, type: DocsType) {
        offlineDelegate?.browserView(self, didSyncWithObjToken: objToken, type: type)
    }

    public func setNeedSync(_ shouldSync: Bool, for objToken: String, type: DocsType) {
        offlineDelegate?.browserView(self, setNeedSync: shouldSync, for: objToken, type: type)
    }
}

extension BrowserView: BrowserLoadingAgent {
    public func startLoadingAnimation() {
        loadingDelegate?.showLoadingIndicator()
    }

    public func stopLoadingAnimation() {
        lifeCycleEvent.browserDidHideLoading()
        loadingDelegate?.hideLoadingIndicator(completion: {})
    }

    public func showLoading() {
        UIView.performWithoutAnimation { [self] in
            if loadingView == nil {
                let loadingView = SKLoadingView(backgroundAlpha: 1.0)
                addSubview(loadingView)
                loadingView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                self.loadingView = loadingView
            }
            self.loadingView?.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_5000, execute: { [weak self] in
            self?.hideLoading()
        })
    }

    public func hideLoading() {
        DispatchQueue.main.async(execute: {
            self.loadingView?.removeFromSuperview()
            self.loadingView = nil
        })
    }
}


extension BrowserView: BrowserViewShareAgent {
    public func browserViewRequestShareAccessory() -> UIView? {
        return shareDelegate?.browserViewRequestShareAccessory(self)
    }
}

extension BrowserView: BrowserOpenRecorder {
    public func appendInfo(_ info: @autoclosure () -> String ) {
        openProgressManager?.appendInfo(info())
    }
}

extension BrowserView {
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (_, reachable) in
            DispatchQueue.main.async { [weak self] in
                self?.viewManager?.networkReachableDidChange(reachable)
            }
        }
    }
}

extension BrowserView: BrowserKeyboardHandlerDelegate {

}

extension BrowserView: EditorScrollViewObserver {

    public func editorViewScrollViewWillBeginDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        didStartDrag = true
        startDragYpos = editorViewScrollViewProxy.contentOffset.y
    }

    public func editorViewScrollViewWillEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        bottomTranslateDisplayLogic(contentYOffset: editorViewScrollViewProxy.contentOffset.y)
    }

    public func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        bottomTranslateDisplayLogic(contentYOffset: editorViewScrollViewProxy.contentOffset.y)
        jsEngine.simulateJSMessage(DocsJSService.utilShowMenu.rawValue, params: ["dismiss": true])
    }

    public func editorViewScrollViewDidEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, willDecelerate decelerate: Bool) {
        bottomTranslateDisplayLogic(contentYOffset: editorViewScrollViewProxy.contentOffset.y)
    }

    //判断翻译按钮的展示逻辑。向上滚动时展示，向下滚动时隐藏
    private func bottomTranslateDisplayLogic(contentYOffset: CGFloat) {
        if didStartDrag == false { return }
        if translateCanScroll == false { return }
        didStartDrag = false
        if contentYOffset < 0 {
            return
        }
        if contentYOffset >= startDragYpos {
            hideTranslateBtn()
        } else { showTranslateBtn() }
    }

    private static var oldContentOffsetKey: UInt8 = 0
    var oldContentOffset: CGPoint {
        get { return objc_getAssociatedObject(self, &BrowserView.oldContentOffsetKey) as? CGPoint ?? CGPoint.zero }
        set { objc_setAssociatedObject(self, &BrowserView.oldContentOffsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - 展示一个item
extension BrowserView: BannerItemAgent {
    public func requestShowItem(_ item: BannerItem) {
        delegate?.browserView(self, shouldShowBanner: item)
    }

    public func requestHideItem(_ item: BannerItem) {
        delegate?.browserView(self, shouldHideBanner: item)
    }

    public func requestChangeItemVisibility(to toHidden: Bool) {
        delegate?.browserView(self, shouldChangeBannerInvisible: toHidden)
    }
}

extension BrowserView: BrowserFeedInfo {
    public func markMessagesRead(_ params: [String: Any]) {
        userResolver.docs.editorManager?.browserView(self, markFeedMessagesRead: params)
    }

    public func markFeedCardShortcut(isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?) {
        delegate?.browserView(self,
                              markFeedCardShortcut: isAdd,
                              success: success,
                              failure: failure)
    }
    public func needShowFeedCardShortcut(channel: Int) -> Bool {
         let returnFalse = { () -> Bool in
            DocsLogger.info("[FeedShortcut] Delegate 为空")
            spaceAssertionFailure("Delegate 为空")
            return false
        }
        return delegate?.browserView(self, needShowFeedCardShortcut: channel) ?? returnFalse()
    }
    public func isFeedCardShortcut() -> Bool {
        let returnFalse = { () -> Bool in
            DocsLogger.info("[FeedShortcut] Delegate 为空")
            spaceAssertionFailure("Delegate 为空")
            return false
        }
        return delegate?.browserViewIsFeedCardShortcut(self) ?? returnFalse()
    }
}

// MARK: - CatalogManager管理indicator
extension BrowserView {
    public func showIndicator(show: Bool) {
        bizPlugin?.catalogAgent?.showCatalogIndicator(show: show)
    }
}

extension BrowserView {
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if #available(iOS 13.4, *) {
            //keyCode UIKeyboardHIDUsage仅支持iOS13.4以上系统版本
            if presses.first?.key?.keyCode == .keyboardSpacebar {
                self.spacePressesBeginTimestamp = Int(Date().timeIntervalSince1970 * 1000)
            } else if presses.first?.key?.keyCode == .keyboardTab, _isPopoverAtFinderScene ?? false {
                // 这种情况下直接吞掉该事件，交由At面板
                jsEngine.simulateJSMessage(DocsJSService.utilAtFinderReceiveTabAction.rawValue, params: [:])
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
}
