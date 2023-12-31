//
//  VersionsContainerViewController.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2022/9/12.
//

import UIKit
import SKFoundation
import SnapKit
import RxSwift
import RxCocoa
import SKUIKit
import SKCommon
import SKResource
import LarkSuspendable
import LarkTab
import UniverseDesignLoading
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignToast
import EENavigator
import SpaceInterface
import LarkQuickLaunchInterface

public final class VersionsContainerViewController: BaseViewController, VersionParentVCProtocol, VersionFailViewProtocol {
    private(set) weak var lastChildVC: UIViewController?
    private var viewModel: VersionContainerViewModel
    private var lastDisplayVersionToken: String = ""
    private var lastDisplaySourceToken: String = ""
    private lazy var loadingView = DocsUDLoadingImageView()
    private lazy var failTipsView: VersionFailView = VersionFailView(frame: .zero)
    //主导航PagePreservable缓存协议使用
    public var pageScene: LarkQuickLaunchInterface.PageKeeperScene = .normal
    
    public init(viewModel: VersionContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("VersionContainerViewController - deinit")
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.lastChildVC?.supportedInterfaceOrientations ?? .allButUpsideDown
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.statusBar.alpha = 0
        setupViewModel()
    }
    public override var prefersStatusBarHidden: Bool {
        guard let vc = lastChildVC else {
            return false
        }
        return vc.prefersStatusBarHidden
    }
    
    public override var canShowFullscreenItem: Bool { true }
    
    // BrowserViewController 作为子vc必须调用didMove to,不然会你内存泄漏
    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        lastChildVC?.didMove(toParent: parent)
    }

    private func setupViewModel() {
        viewModel.bindState = {[weak self] state in
            guard let `self` = self else { return }
            switch state {
            case .prepare:
                DocsLogger.info("version prepare to load", component: LogComponents.version)
                self.beginLoading()
            case let .success(info):
                DocsLogger.info("version display success", component: LogComponents.version)
                self.displayIfNeed(displayInfo: info)
                self.endLoading()
            case .failed(let error):
                DocsLogger.info("version show failed", component: LogComponents.version)
                self.showFailed(error: error)
                self.endLoading()
            }
        }
        DocsLogger.info("start loadVersionInfo", component: LogComponents.version)
        viewModel.loadVersionInfo()
    }
    
    func displayIfNeed(displayInfo: (sourceToken: String, versionToken: String, version: String)) {
        if lastDisplayVersionToken == displayInfo.versionToken, lastDisplaySourceToken == displayInfo.sourceToken {
            DocsLogger.warning("display the same version", component: LogComponents.version)
            return
        }
        setupBrowser()
        lastDisplayVersionToken = displayInfo.versionToken
        lastDisplaySourceToken = displayInfo.sourceToken
    }
    
    func setupBrowser() {
        setNavigationBarHidden(true, animated: false)
        guard let vc = generateSubVC() else {
            return
        }
        setChangeSubVCDelegateIfNeed(vc)
        setupChildViewController(initialzer: vc)
    }
    
    func generateSubVC() -> UIViewController? {
        guard let type = DocsType(url: self.viewModel.versionURL) else {
            spaceAssertionFailure("version failed to initailize browser")
            return nil
        }
        let url = self.viewModel.versionURL
        if let fatory = SKRouter.shared.getFactory(with: type),
           let vc = fatory(url, self.viewModel.params, type) {
            return vc
        } else {
            spaceAssertionFailure("version failed to initailize browser")
            return SKRouter.shared.defaultRouterView(url)
        }
    }
    
    private func beginLoading() {
        view.addSubview(loadingView)
        loadingView.isHidden = false
        loadingView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(self.navigationBar.snp.bottom)
        }
    }

    private func endLoading() {
        loadingView.isHidden = true
        loadingView.removeFromSuperview()
    }
    
    func setupChildViewController(initialzer: UIViewController) {
        removeChildVC()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            let childViewController = initialzer
            self.addChild(childViewController)
            self.view.addSubview(childViewController.view)
            childViewController.didMove(toParent: self)
            self.makeConstraints(for: childViewController.view)
            self.lastChildVC = childViewController
            self.fixRotationIfNeed()
        }
    }
    
    private func showFailed(error: VersionErrorCode) {
        if failTipsView.superview == nil {
            view.addSubview(failTipsView)
            failTipsView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
            }
            failTipsView.didTap = {[weak self] error in
                self?.failDidTap(error: error)
            }
        }
        failTipsView.failDelegate = self
        failTipsView.showFail(error: error)
        failTipsView.isHidden = false
        view.bringSubviewToFront(failTipsView)
        setNavigationBarHidden(false, animated: false)
    }

    private func failDidTap(error: VersionErrorCode?) {
        guard let err = error else {
            DocsLogger.info("No error Info")
            return
        }
        hideFailed()
        beginLoading()
        viewModel.loadVersionInfo()
    }
    private func hideFailed() {
        failTipsView.removeFromSuperview()
        failTipsView.isHidden = true
    }
    
    private func makeConstraints(for view: UIView) {
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func removeChildVC() {
        if let childVC = lastChildVC {
            childVC.willMove(toParent: nil)
            childVC.view.removeFromSuperview()
            childVC.removeFromParent()
        }
    }
    
    private func fixRotationIfNeed() {
        // 只在 iPhone 上处理
        guard SKDisplay.phone else { return }
        let supportedOrientations = supportedInterfaceOrientations
        let currentOrientation = UIApplication.shared.statusBarOrientation
        // 只处理当前横屏的场景
        guard currentOrientation.isLandscape else { return }
        if supportedOrientations.contains(.landscapeLeft) || supportedOrientations.contains(.landscapeRight) {
            return
        }
        // 当前横屏，但 childVC 并不支持横屏，需要转回竖屏
        LKDeviceOrientation.setOritation(UIDeviceOrientation.portrait)
    }
    
    private func setChangeSubVCDelegateIfNeed(_ vc: UIViewController) {
        guard let broserVC = vc as? BrowserViewController else {
            return
        }
        broserVC.parentDelegate = self
    }
    
    public func didChangeVersionTo(item: SKCommon.DocsVersionItemData, from: FromSource?) {
        if var components = URLComponents(string: self.viewModel.versionURL.absoluteString) {
            components.query = nil // 移除所有参数
            if let finalUrl = components.string {
                if let vurl = URL(string: finalUrl) { // 版本需要增加参数
                    let sourceURL = vurl.docs.addQuery(parameters: ["edition_id": item.version, "versionfrom": from?.rawValue ?? "unknown"])
                    let params = self.viewModel.params
                    let userResolver = self.viewModel.userResolver
                    self.viewModel = VersionContainerViewModel(url: sourceURL, params: params, userResolver: userResolver, addInner: false)
                    setupViewModel()
                }
            }
        }
    }
}

// 兼容跳转时判断是否是同一个页面
extension VersionsContainerViewController: BrowserControllable {

   public var browerEditor: BrowserView? {
       guard let vc = lastChildVC as? BrowserViewController else {
           return nil
       }
       return vc.editor
   }

   public func updateUrl(_ url: URL) {
       // do nothing
       DocsLogger.info("versoin container call updateURL", component: LogComponents.version)
   }

   public func setDismissDelegate(_ newDelegate: BrowserViewControllerDelegate?) {
       // do nothing
       DocsLogger.info("versoin container call setDismissDelegate", component: LogComponents.version)
   }

   public func setToggleSwipeGestureEnable(_ enable: Bool) {
       // do nothing
       DocsLogger.info("versoin container call setToggleSwipeGestureEnable", component: LogComponents.version)
   }
    
   public func setLandscapeStrategyWhenAppear(_ enable: Bool) {
       // do nothing
       DocsLogger.info("versoin container call setLandscapeStrategyWhenAppear", component: LogComponents.version)
   }
    
}

extension VersionsContainerViewController: SceneProvider {
    public var objToken: String {
        viewModel.parentToken ?? ""
    }

    public var objType: DocsType {
        viewModel.docType ?? .unknownDefaultType
    }

    public var docsTitle: String? {
        let vc = lastChildVC as? BrowserViewController
        return vc?.displayTitle
    }

    public var isSupportedShowNewScene: Bool {
        true
    }
    
    public var userInfo: [String: String] {
        return [:]
    }

    public var currentURL: URL? { nil }
    
    public var version: String? {
        return viewModel.version
    }
}

extension VersionsContainerViewController: ViewControllerSuspendable {
    /// 页面的唯一 ID，由页面自己实现
    ///
    /// - 同样 ID 的页面只允许收入到浮窗一次，如果该属性被实现为 ID 恒定，则不可重复收入浮窗，
    /// 如果该属性被实现为 ID 变化（如自增），则可以重复收入多个相同页面。
    public var suspendID: String {
        return (self.viewModel.parentToken ?? "") + (self.viewModel.version ?? "")
    }
    /// 悬浮窗展开显示的图标
    public var suspendIcon: UIImage? {
        guard let vc = lastChildVC as? ViewControllerSuspendable else {
            return UDIcon.fileRoundUnknowColorful
        }
        return vc.suspendIcon
    }
    /// 悬浮窗展开显示的标题
    public var suspendTitle: String {
        guard let vc = lastChildVC as? BrowserViewController, !vc.displayTitle.isEmpty else {
            return self.viewModel.docType?.untitledString ?? BundleI18n.SKResource.Doc_Facade_UntitledDocument
        }
        return vc.displayTitle
    }
    /// EENavigator 路由系统中的 URL
    ///
    /// 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面。
    public var suspendURL: String {
        return viewModel.urlForSuspendable
    }
    /// EENavigator 路由系统中的页面参数，用于恢复页面状态
    /// 注意1. 记得添加from参数，由于目前只有CCM这边用到这个参数就没收敛到多任务框架中👀
    /// 注意2. 如果需要添加其他参数记得使用 ["infos":  Any]，因为胶水层只会放回参数里面的infos
    public var suspendParams: [String: AnyCodable] {
        return ["from": "tasklist"]
    }
    /// 多任务列表分组
    public var suspendGroup: SuspendGroup {
        return .document
    }
    /// 页面是否支持热恢复，ps：暂时只需要冷恢复，后续会支持热恢复
    public var isWarmStartEnabled: Bool {
        return false
    }
    /// 是否页面关闭后可重用（默认 true）
    public var isViewControllerRecoverable: Bool {
        return false
    }
    /// 埋点统计所使用的类型名称
    public var analyticsTypeName: String {
        guard let vc = lastChildVC as? BrowserViewController, let docsInfo = vc.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return ""
        }
        return docsInfo.type.fileTypeForSta
    }
    
    public var prefersForcePush: Bool? {
        return true
    }
}

extension VersionsContainerViewController {
    public func didClickPrimaryButton() {
        if var components = URLComponents(string: self.viewModel.versionURL.absoluteString) {
            components.query = nil // 移除所有参数
            let finalUrl = components.string
            if finalUrl != nil, let sourceURL = URL(string: finalUrl!) {
                var browser = self.viewModel.userResolver.docs.editorManager?.currentEditor
                if let broserVC = self.lastChildVC as? BrowserViewController {
                    browser = broserVC.editor
                }
                guard let browser = browser else { return }
                _ = self.viewModel.userResolver.docs.editorManager?.requiresOpen(browser, url: sourceURL)
            }
        }
    }
}

/// 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension VersionsContainerViewController: TabContainable {

    /// 页面的唯一 ID，由页面的业务方自己实现
    ///
    /// - 同样 ID 的页面只允许收入到导航栏一次
    /// - 如果该属性被实现为 ID 恒定，SDK 在数据采集的时候会去重
    /// - 如果该属性被实现为 ID 变化（如自增），则会被 SDK 当成不同的页面采集到缓存，展现上就是在导航栏上出现多个这样的页面
    /// - 举个🌰
    /// - IM 业务：传入 ChatId 作为唯一 ID
    /// - CCM 业务：传入 objToken 作为唯一 ID
    /// - OpenPlatform（小程序 & 网页应用） 业务：传入应用的 uniqueID 作为唯一 ID
    /// - Web（网页） 业务：传入页面的 url 作为唯一 ID（为防止url过长，sdk 处理的时候会 md5 一下，业务方无感知
    public var tabID: String {
        suspendID
    }

    /// 页面所属业务应用 ID，例如：网页应用的：cli_123455
    ///
    /// - 如果 BizType == WEB_APP 的话 SDK 会用这个 BizID 来给 app_id 赋值
    ///
    /// 目前有些业务，例如开平的网页应用（BizType == WEB_APP），tabID 是传 url 来做唯一区分的
    /// 但是不同的 url 可能对应的应用 ID（BizID）是一样的，所以用这个字段来额外存储
    ///
    /// 所以这边就有一个特化逻辑：
    /// if(BizType == WEB_APP) { uniqueId = BizType + tabID, app_id = BizID}
    /// else { uniqueId = BizType+ tabID, app_id = tabID}
    public var tabBizID: String {
        return ""
    }

    /// 页面所属业务类型
    ///
    /// - SDK 需要这个业务类型来拼接 uniqueId
    ///
    /// 现有类型：
    /// - CCM：文档
    /// - MINI_APP：开放平台：小程序
    /// - WEB_APP ：开放平台：网页应用
    /// - MEEGO：开放平台：Meego
    /// - WEB：自定义H5网页
    public var tabBizType: CustomBizType {
        return .CCM
    }

    public var docInfoSubType: Int {
        return viewModel.docType?.rawValue ?? -1
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    public var tabIcon: CustomTabIcon {
        guard let vc = lastChildVC as? TabContainable else {
            return .iconName(.fileRoundUnknowColorful)
        }
        return vc.tabIcon
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题（最近使用列表里面也使用同样的标题）
    public var tabTitle: String {
        suspendTitle
    }

    /// 页面的 URL 或者 AppLink，路由系统 EENavigator 会使用该 URL 进行页面跳转
    ///
    /// - 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面
    /// - 对于Web（网页） 业务的话，这个值可能和 tabID 一样
    public var tabURL: String {
        suspendURL
    }
    
    /// EENavigator 路由系统中的页面参数，用于恢复页面状态
    ///
    /// - 作为 EENavigator 的 push 页面时的 context 参数传入
    /// - 可用来保存恢复页面状态的必要信息，导航框架只负责保存这些信息，如何使用这些信息来恢复页面状态需要接入方自己实现
    /// - *TabAnyCodable* 为 Any 类型的 Codable 简单封装
    public var tabURLParams: [String : TabAnyCodable] {
        return ["from": "tasklist"]
    }
    
    /// 埋点统计所使用的类型名称
    ///
    /// 现有类型：
    /// - private 单聊
    /// - secret 密聊
    /// - group 群聊
    /// - circle 话题群
    /// - topic 话题
    /// - bot 机器人
    /// - doc 文档
    /// - sheet 数据表格
    /// - mindnote 思维导图
    /// - slide 演示文稿
    /// - wiki 知识库
    /// - file 外部文件
    /// - web 网页
    /// - gadget 小程序
    public var tabAnalyticsTypeName: String {
        return "doc"
    }
}

//新的缓存逻辑  setting //
extension VersionsContainerViewController: PagePreservable {
    public var pageID: String {
        self.tabID
    }
    
    public var pageType: LarkQuickLaunchInterface.PageKeeperType {
        .ccm
    }

}
