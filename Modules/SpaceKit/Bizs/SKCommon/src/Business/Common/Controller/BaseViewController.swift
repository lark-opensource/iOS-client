//  Created by weidong fu on 5/12/2017.

/*!
 负责统一处理大小自定义导航样式
 提供默认返回按钮
 */
// swiftlint:disable file_length

import RxSwift
import Foundation
import LarkSplitViewController
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import LarkTraitCollection
import SKUIKit
import SKResource
import SKFoundation
import LarkSceneManager
import UniverseDesignToast
import SKInfra

open class BaseViewController: UIViewController {

    public var safeArea: UIEdgeInsets {
        return view.window?.safeAreaInsets ?? .zero
    }

    public var statusBarStyle: UIStatusBarStyle = .default

    // MARK: UI Widget

    public lazy var statusBar = StatusBarView().construct { $0.backgroundColor = UDColor.bgBody }

    private var loadingView: UIView?

    final public lazy var navigationBar: SKNavigationBar = SKNavigationBar()

    public let watermarkConfig = WatermarkViewConfig()

    /// if catalog is shown in webview on iPad, default value = false
    public var isShowCatalogItem: Bool = false
    
    public var showTemporary: Bool = false

    lazy var defaultBlankView: EmptyListPlaceholderView = {
        let view = EmptyListPlaceholderView(frame: CGRect.zero)
        view.backgroundColor = UDColor.bgBody
        view.addSubview(self.defaultBlankViewMaskButton)
        self.defaultBlankViewMaskButton.snp.makeConstraints({ (make) in
            make.center.equalTo(view)
            make.height.equalToSuperview().multipliedBy(0.5)
            make.width.equalToSuperview()
        })
        return view
    }()

    public lazy var backBarButtonItem = SKBarButtonItem(image: UDIcon.leftOutlined,
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(backBarButtonItemAction))
        .construct { it in
            it.id = .back
        }

    public lazy var closeButtonItem = SKBarButtonItem(image: UDIcon.closeOutlined,
                                                      style: .plain,
                                                      target: self,
                                                      action: #selector(closeButtonItemAction))
        .construct { it in
            it.id = .close
        }

    public var fsModeItem: SKBarButtonItem {
        let image = inFullScreenMode
        ? LarkSplitViewController.Resources.leaveFullScreen
        : LarkSplitViewController.Resources.enterFullScreen
        _fsModeItem.image = image
        return _fsModeItem
    }

    private lazy var _fsModeItem = SKBarButtonItem(image: nil,
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(fullscreenButtonItemAction))
        .construct { $0.id = .fullScreenMode }

    open private(set) lazy var showInNewSceneItem = {
        let button = SceneButtonItem(clickCallBack: { [weak self] (_) in
            self?.showInNewSceneItemAction()
        }, sceneKey: "Docs", sceneId: getURL())
        button.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(24)
        }
        let sceneItem = SKBarButtonItem(customView: button)
        return sceneItem
    }()

    public lazy var catalogDisplayItem = SKBarButtonItem(image: UDIcon.tableGroupOutlined,
                                                         style: .plain,
                                                         target: self,
                                                         action: #selector(catalogDisplayButtonItemAction))
        .construct { it in
            it.id = .catalog
        }

    public lazy var doneButtonItem: SKBarButtonItem = {
        let item: SKBarButtonItem
        if SKDisplay.pad {
            item = SKBarButtonItem(title: BundleI18n.SKResource.CreationMobile_Docs_iPad_EditDone_Button,
                                   style: .plain,
                                   target: self,
                                   action: #selector(onDoneBarButtonClick))
        } else {
            item = SKBarButtonItem(image: BundleResources.SKResource.Common.Icon.icon_done_outlined,
                                   style: .plain,
                                   target: self,
                                   action: #selector(onDoneBarButtonClick))
        }
        item.id = .done
        item.foregroundColorMapping = SKBarButton.primaryColorMapping
        return item
    }()

    open override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }

    open override var title: String? {
        didSet {
            navigationBar.title = title
        }
    }

    /// 是否委托其他地方主动进行 navigationBarView 的事件的埋点
    ///
    /// 1. 对于 containerVC 和 contentVC 都是 `BaseViewController` 的情况，container 和 content 都会走一遍 viewDidLoad，所以会上报两次。
    /// 所以采用这个方法来避免在 contentVC 上再次上报（导航栏本身是由 container 管理的，所以应该是 container 负责上报导航栏 view 事件）
    ///
    /// 2. BrowserViewController 这种需要走网络请求拿 docsInfo 的也需要 override true，
    /// 且需要在取到数据后主动调用 `logNavBarEvent` 方法，这样才能上报正确的 module、file_id 等参数
    open var isLoggingNavigationBarViewDelegated: Bool { false }

    /// 用于收集 CCM 场景公参，子类按需重写
    /// 目前导航栏的 view 和 左边按钮 click 事件用到了这里
    open var commonTrackParams: [String: String] { [:] }

    /// 设置为true时，需要重写retryLoadData方法，用户在没有网络时，点击空白页中间会触发这个方法
    var isBlankDidClickRetryToLoadData: Bool = false

    lazy var defaultBlankViewMaskButton: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(defaultBlankViewMaskButtonAction), for: .touchUpInside)
        return btn
    }()

    open var canShowInNewScene: Bool {
        guard SceneManager.shared.supportsMultipleScenes else { return false }                          // FG
        guard #available(iOS 13.0, *), SKDisplay.pad else { return false }
        guard let scene = currentScene()?.sceneInfo else { return false }                               // 是否在某个scene上面
        guard let self = self as? SceneProvider, self.isSupportedShowNewScene else { return false }     // 是否是可在辅助scene打开的VC
        if scene.isMainScene() {
            return true                                                                                 // 主scene都可以带多窗口能力
        } else {
            return hasBackPage                                                                          // 辅助scene二级页面可以带多窗口能力
        }
    }

    var canShowCloseScene: Bool {
        guard SceneManager.shared.supportsMultipleScenes else { return false }                          // FG
        guard #available(iOS 13.0, *), SKDisplay.pad else { return false }
        guard let scene = currentScene()?.sceneInfo else { return false }                               // 是否在某个scene上面
        // AI 会话会强制一些不支持 newScene 的页面用 Scene 打开，所以关闭 Scene 的按钮需要去掉是否支持 newScene 的判断
        // guard let self = self as? SceneProvider, self.isSupportedShowNewScene else { return false }     // 是否是可在辅助scene打开的VC
        return !scene.isMainScene() && !hasBackPage && presentingViewController == nil                  // 辅助scene的一级页面可被关闭
    }
    
    var canShowCloseButton: Bool {
        // 仅 temporary 一级页面可被关闭
        let show = SKDisplay.pad && self.isTemporaryChild && !hasBackPage
        return show || canShowCloseScene
    }

    /// loadView创建BaseView时默认frame，子类非特殊情况不要ovveride
    open var baseViewFrame: CGRect {
        .zero
    }

    open override func loadView() {
        view = BaseView(frame: self.baseViewFrame)
        view.addSubview(statusBar)
        statusBar.snp.makeConstraints { it in
            it.top.leading.trailing.equalToSuperview()
            it.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        view.addSubview(self.navigationBar)
        navigationBar.frame.size.width = view.frame.width
        watermarkConfig.add(to: view)
        navigationBar.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        view.backgroundColor = UDColor.bgBody
        view.clipsToBounds = true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        updateNavBarHeightIfNeeded() // 在 viewDidLoad 里面是取不到 view.window 的，所以里面的部分设置无效，需要在后面 viewWillTransition 和 viewSafeAreaInsetsDidChange 再次刷新
        setupFullscreenMode()
        refreshLeftBarButtons()
        if !isLoggingNavigationBarViewDelegated {
            logNavBarEvent(.navigationBarView, click: nil, target: nil)
        }
        guard let sceneProvider = self as? SceneProvider else { return }
        let url = DocsUrlUtil.url(type: sceneProvider.objType,
                                  token: sceneProvider.objToken,
                                  originUrl: sceneProvider.currentURL)
        let scene = Scene.docs.scene(url.absoluteString,
                                     title: sceneProvider.docsTitle,
                                     sceneSourceID: self.currentSceneID(),
                                     objToken: sceneProvider.objToken,
                                     docsType: sceneProvider.objType,
                                     createWay: .windowClick,
                                     userInfo: sceneProvider.userInfo)
        self.sceneTargetContentIdentifier = scene.targetContentIdentifier
    }

    private func setupFullscreenMode() {
        self.supportSecondaryOnly = canShowFullscreenItem
        // 全屏手势是否可用取决于全屏功能是否可用、VC 是否禁用手势、CCM手势FG开关
        self.supportSecondaryPanGesture = canShowFullscreenItem
            && fullscreenGestureEnabled
        self.keyCommandToFullScreen = canShowFullscreenItem
            && fullscreenShortcutEnabled
        // 展示全屏按钮埋点
        if self.supportSecondaryOnly && self.willShowFullscreen {
            LarkSplitViewController.Tracker.trackFullScreenItemShow(scene: self.bizType.name,
                                                                    isFold: !inFullScreenMode)
        }
    }

    open func popNeedAnimated() -> Bool {
        return true
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        DocsLogger.info("\(String(describing: type(of: self))) viewWillAppear")
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        DocsLogger.info("\(String(describing: type(of: self))) viewWillDisappear")
        super.viewWillDisappear(animated)
        self.hideLoading()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshLeftBarButtons()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        DocsLogger.info("\(String(describing: type(of: self))) viewDidDisappear")
        super.viewDidDisappear(animated)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let olderSize = view.frame.size
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [self] (_) in
            // 以 formSheet 样式 present / R 视图的场景下，导航栏需要增大高度
            updateNavBarHeightIfNeeded()
            refreshLeftBarButtons()
            navigationBar.layoutIfNeeded()
            viewDidTransition(from: olderSize, to: size)
        }
    }
    
    open override func splitVCSplitModeChange(split: SplitViewController) {
        super.splitVCSplitModeChange(split: split)
        DocsLogger.info("splitVCSplitModeChange, mode:\(split.splitMode.rawValue)")
        updateNavBarHeightIfNeeded()
        refreshLeftBarButtons()
        navigationBar.layoutIfNeeded()
        viewDidSplitModeChange()
    }

    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        refreshLeftBarButtons()
        updateNavBarHeightIfNeeded()
    }

    /// 点击导航栏返回按钮前的回调
    open func viewWillBackToPreviousPage() {}

    open func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
    }
    
    open func viewDidSplitModeChange() {
    }

    open func updateNavBarHeightIfNeeded() {
        // 子类已重写这个函数，修改这里需要注意一下子类是否也要修改
        if self.modalPresentationStyle == .formSheet {
            self.navigationBar.sizeType = .formSheet
        } else if let navigationController = self.navigationController,
                  navigationController.modalPresentationStyle == .formSheet {
            self.navigationBar.sizeType = .formSheet
        } else if let window = self.view.window,
                  window.lkTraitCollection.horizontalSizeClass == .regular,
                  window.lkTraitCollection.verticalSizeClass == .regular {
            self.navigationBar.sizeType = .primary
        } else { // 不是 formSheet、去不到 view 的 window 的时候会 fallback 到这里
            self.navigationBar.sizeType = .secondary
        }
    }

    open func refreshLeftBarButtons() {
        let shouldShowDoneItem = canShowDoneItem
        let shouldShowFullscreenItem = willShowFullscreen && canShowFullscreenItem

        var shouldShowBackItem = true
        if !canShowBackItem || shouldShowDoneItem {
            shouldShowBackItem = false
        } else {
            shouldShowBackItem = hasBackPage
        }

        var itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems

        if shouldShowFullscreenItem {
            if !itemComponents.contains(fsModeItem) {
                itemComponents.insert(fsModeItem, at: 0)
            }
        } else {
            itemComponents.removeAll(where: { $0 == fsModeItem })
        }

        if canShowInNewScene {
            if !itemComponents.contains(showInNewSceneItem) {
                itemComponents.insert(showInNewSceneItem, at: 0)
            }
        } else {
            itemComponents.removeAll(where: { $0 == showInNewSceneItem })
        }

        if shouldShowBackItem, !itemComponents.contains(backBarButtonItem) {
            itemComponents.insert(backBarButtonItem, at: 0)
        } else if !shouldShowBackItem, itemComponents.contains(backBarButtonItem) {
            itemComponents.removeAll(where: { $0 == backBarButtonItem })
        }

        if canShowCloseButton {
            if !itemComponents.contains(closeButtonItem) {
                itemComponents.insert(closeButtonItem, at: 0)
            }
        }

        /// on iPad, default at the end
        if canShowCatalogItem, !itemComponents.contains(catalogDisplayItem) {
            itemComponents.append(catalogDisplayItem)
        } else if !canShowCatalogItem, itemComponents.contains(catalogDisplayItem) {
            itemComponents.removeAll(where: { $0 == catalogDisplayItem })
        }

        let sortedList: [SKBarButtonItem: Int] = [backBarButtonItem: 1, closeButtonItem: 2, doneButtonItem: 3, fsModeItem: 4, showInNewSceneItem: 5, catalogDisplayItem: 6]

        itemComponents.sort { return sortedList[$0] ?? 6 < sortedList[$1] ?? 7 }

        navigationBar.leadingBarButtonItems = itemComponents
    }

    /// 隐藏自定义导航栏
    open func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? TimeInterval(UINavigationController.hideShowBarDuration) : 0) { [self] in
            navigationBar.isHidden = hidden
        }
    }

    open var canShowBackItem: Bool {
        return true
    }

    open var canShowFullscreenItem: Bool {
        return false
    }

    /// 全屏手势是否启用，仅在 canShowFullscreenItem 为 true 的场景下才有意义
    open var fullscreenGestureEnabled: Bool {
        return true
    }

    /// 全屏键盘快捷键是否启用，仅在 canShowFullscreenItem 为 true 的场景下才有意义
    open var fullscreenShortcutEnabled: Bool {
        return true
    }

    /// Only show fs button while R-mode
    open var willShowFullscreen: Bool {
        guard let lkSplitViewController = lkSplitViewController else {
            return false
        }
        return SKDisplay.pad && !lkSplitViewController.isCollapsed
    }

    open var canShowDoneItem: Bool {
        return false
    }

    /// on iPad,BaseViewController will show Catalog Button
    open var canShowCatalogItem: Bool {
        return false
    }

    /// 导航栏 view 和 左边按钮 click 事件会调用该方法
    open func logNavBarEvent(_ event: DocsTracker.EventType,
                             click: String? = nil,
                             target: String? = "none",
                             extraParam: [String: String]? = nil) {
        var params = commonTrackParams
        params["click"] = click
        params["target"] = target
        params.merge(other: extraParam)
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }
    
    open func keyboardWillHide() {}
    
    open func setToPortraitIfNeeded() {
        DocsLogger.info("currentOrientation: isLandscape \(UIDevice.current.orientation.isLandscape), \(LKDeviceOrientation.isLandscape())")
        // UIDevice.current.orientation.isPortrait 这个方法在 iOS16.3 拿不到正确的值
        guard LKDeviceOrientation.isLandscape() && SKDisplay.phone else { return }
        guard let naviStackVCs = self.navigationController?.viewControllers else { return }
        // 找出上一层级的 VC 判断是否支持横屏
        let lastVCIndex = naviStackVCs.endIndex - 2
        guard lastVCIndex >= 0 else { return }
        let lastVC = naviStackVCs[lastVCIndex]
        let supportedOrientation = lastVC.supportedInterfaceOrientations
        if supportedOrientation == .portrait {
            DocsLogger.info("set to portrait")
            LKDeviceOrientation.setOritation(UIDeviceOrientation.portrait)
        }
    }
}

extension BaseViewController {
    public final class StatusBarView: UIView {}

    private class BaseView: UIView {
        override func addSubview(_ view: UIView) {
            super.addSubview(view)
            if let navBar = self.subviews.first(where: { $0 is SKNavigationBar }) {
                self.bringSubviewToFront(navBar)
            }
            if let statusBar = self.subviews.first(where: { $0 is StatusBarView }) {
                self.bringSubviewToFront(statusBar)
            }
        }
    }

    enum Const {
        static let animationDuration = TimeInterval(UINavigationController.hideShowBarDuration)
        static let animationDurationInMilliseconds = Int(UINavigationController.hideShowBarDuration * 1000.0)
    }

    public func animateIfNeeded(_ shouldAnimate: Bool, animation: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if shouldAnimate {
            UIView.animate(withDuration: Const.animationDuration, animations: animation, completion: completion)
        } else {
            animation()
            completion?(true)
        }
    }

    @objc
    open func closeButtonItemAction() {
        if canShowCloseScene {
            view.endEditing(true)
            SceneManager.shared.deactive(from: self)
        } else {
            back(canEmpty: true)
        }
        logNavBarEvent(.navigationBarClick, click: "close")
    }

    @objc
    open func backBarButtonItemAction() {
        viewWillBackToPreviousPage()
        back()
        logNavBarEvent(.navigationBarClick, click: "back")
    }

    @objc
    open func fullscreenButtonItemAction() {
        guard SKDisplay.pad, let lkSplitVC = lkSplitViewController else { return }
        logNavBarEvent(.navigationBarClick, click: inFullScreenMode ? "normal_screen" : "full_screen")
        lkSplitVC.updateSplitMode(inFullScreenMode ? .twoBesideSecondary : .secondaryOnly, animated: true)
        
        LarkSplitViewController.Tracker.trackFullScreenItemClick(scene: self.bizType.name,
                                                                 isFold: !inFullScreenMode)
    }

    public func getURL() -> String {
        guard let sceneProvider = self as? SceneProvider else { return "" }
        view.endEditing(true)
        var url = DocsUrlUtil.url(type: sceneProvider.objType,
                                  token: sceneProvider.objToken,
                                  originUrl: sceneProvider.currentURL)
        if let version = sceneProvider.version {
            url = url.docs.addOrChangeQuery(parameters: ["edition_id": version])
        }
        return url.absoluteString
    }

    @objc
    open func showInNewSceneItemAction() {
        guard let sceneProvider = self as? SceneProvider else { return }
        view.endEditing(true)
        var url = DocsUrlUtil.url(type: sceneProvider.objType,
                                  token: sceneProvider.objToken,
                                  originUrl: sceneProvider.currentURL)
        if let version = sceneProvider.version {
            url = url.docs.addOrChangeQuery(parameters: ["edition_id": version])
        }
        let scene = Scene.docs.scene(getURL(),
                                     title: sceneProvider.docsTitle,
                                     sceneSourceID: self.currentSceneID(),
                                     objToken: sceneProvider.objToken,
                                     docsType: sceneProvider.objType,
                                     createWay: .windowClick,
                                     userInfo: sceneProvider.userInfo)
        // 更新当前controller的sceneTargetContentIdentifier，防止离线创建导致一开始url跟真实url不一致，最终分屏后未退出当前controller的bug
        self.sceneTargetContentIdentifier = scene.targetContentIdentifier
        let toastDisplayView: UIView = self.view.window ?? self.view
        SceneManager.shared.active(scene: scene, from: self) { (_, error) in
            if let error = error {
                DocsLogger.error("baseVC new scene error\(error)")
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_iPad_SplitScreenNotSupported_Toast,
                                    on: toastDisplayView)
            }
        }
        logNavBarEvent(.navigationBarClick, click: "open_in_new_window", target: "ccm_docs_page_view")
    }

    @objc
    open func catalogDisplayButtonItemAction() {
        self.isShowCatalogItem = !self.isShowCatalogItem
        setCatalogDisplayButtonStatus(isSelected: self.isShowCatalogItem)
    }

    public func setCatalogDisplayButtonStatus(isSelected: Bool) {
        catalogDisplayItem.isInSelection = isSelected
        logNavBarEvent(.navigationBarClick, click: "catalog")
    }

    @objc
    open func onDoneBarButtonClick() {
        logNavBarEvent(.navigationBarClick, click: "done")
    }
    
    /// 退出当前页面
    /// - Parameter canEmpty: iPad 模式下是否可以pop到兜底页
    /// - 使用说明:
    ///   iPad默认是不给pop到兜底页，当VC栈中只剩下最后一个时，调用navigationController.popViewController(animated: true)是并没有用的。
    ///   目前canEmpty为true的场景只有在文档详情页中删除这种场景。
    ///   如果在iPad中你想要pop且回退到兜底页，和@qiupei沟通是否是符合预期的。
    @objc
    open func back(canEmpty: Bool = false) {
        if useNewBackLogic() {
            new_back(canEmpty: canEmpty)
        } else {
            old_back(canEmpty: canEmpty)
        }
    }

    private func useNewBackLogic() -> Bool {
        let enable = SettingConfig.ios17CompatibleConfig?.fixNavibackIssue
        DocsLogger.info("fixNavibackIssue:\(enable)")
        if #available(iOS 17.0, *), enable == true {
            return true
        }
        return false
    }
    
    private func old_back(canEmpty: Bool) {
        DocsLogger.info("\(String(describing: type(of: self))) back called")
        if let navigationController = self.navigationController {
            if canEmpty, SKDisplay.pad {
                self.lkSplitViewController?.popTopViewController(animated: true)
            } else {
                navigationController.popViewController(animated: popNeedAnimated())
            }
            if self.presentingViewController != nil {
                dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func new_back(canEmpty: Bool) {
        DocsLogger.info("\(String(describing: type(of: self))) back called")
        if let navigationController = self.navigationController {
            let didPop: Bool // 发生了pop行为
            if canEmpty, SKDisplay.pad {
                self.lkSplitViewController?.popTopViewController(animated: true)
                didPop = false
            } else {
                let popedvc = navigationController.popViewController(animated: popNeedAnimated())
                didPop = (popedvc != nil)
            }
            if didPop == false, self.presentingViewController != nil {
                dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    open func hasBackPageIgnorParent() -> Bool {
        guard let navi = navigationController else { return false }
        // 自己已经不是第一级页面
        if let index = navi.realViewControllers.firstIndex(of: self),
            index > 0 {
            return true
        }
        return false
    }
}

extension BaseViewController {

    /// 显示loading
    /// - Parameter duration: 展示时长，默认5s；如果传0s的话，就一直loading，需要手动hideLoading()
    /// - Parameter isBehindNavBar: 是否视图层级在 navbar 之下（被 navigation bar 盖住）
    public func showLoading(hostView: UIView? = nil,
                            duration: Double = 5.0,
                            isBehindNavBar: Bool = false,
                            backgroundAlpha: CGFloat = 0.9) {
        if loadingView == nil {
            let loadingView = SKLoadingView(backgroundAlpha: backgroundAlpha)
            if isBehindNavBar {
                view.insertSubview(loadingView, belowSubview: navigationBar)
            } else {
                view.addSubview(loadingView)
                view.bringSubviewToFront(loadingView)
            }
            if let hostView = hostView {
                loadingView.snp.makeConstraints { (make) in
                    make.edges.equalTo(hostView)
                }
            } else {
                loadingView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
            
            self.loadingView = loadingView
        }
        self.loadingView?.isHidden = false

        if duration > 0 {
            let ms = duration * 1000
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(ms)), execute: { [weak self] in
                self?.hideLoading()
            })
        }
    }

    public func hideLoading() {
        DispatchQueue.main.async(execute: {
            self.loadingView?.removeFromSuperview()
            self.loadingView = nil
        })
    }
}

extension BaseViewController {
    open override var shouldAutorotate: Bool {
        return true
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension BaseViewController {
    @objc
    func defaultBlankViewMaskButtonAction() {
        if isBlankDidClickRetryToLoadData {
            retryLoadData()
        }
    }

    @objc
    func retryLoadData() {}
}

extension BaseViewController: SKNaviBarProvider {
    public var skNaviBar: SKNaviBarCompatible? { navigationBar }
}
