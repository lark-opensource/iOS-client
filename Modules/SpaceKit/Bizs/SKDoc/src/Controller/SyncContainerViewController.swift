//
//  SyncContainerViewController.swift
//  SKDoc
//
//  Created by liujinwei on 2023/10/10.
//  


import Foundation
import SKCommon
import SKInfra
import SKFoundation
import SwiftyJSON
import SKBrowser
import RxSwift
import SpaceInterface
import SKUIKit
import LarkSuspendable
import LarkTab
import UniverseDesignIcon
import SKResource
import LarkContainer
import LarkQuickLaunchInterface
import UniverseDesignToast
import EENavigator

class SyncContainerViewController: BaseViewController {
    
    private let userResolver: UserResolver
    
    private var viewModel: SyncContainerViewModel
    
    private var contentVC: SyncedBlockSeparatePage?
    
    @InjectedSafeLazy var temporaryTabService: TemporaryTabService
    
    private var bag = DisposeBag()

    var failTipsView: EmptyListPlaceholderView?
    
    private var currentUrl: URL {
        viewModel.currentUrl
    }
    
    override var canShowFullscreenItem: Bool { true }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.contentVC?.supportedInterfaceOrientations ?? .allButUpsideDown
    }
    
    init(userResolver: UserResolver, url: URL) {
        self.userResolver = userResolver
        self.viewModel = SyncContainerViewModel(userResolver: userResolver, url: url)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        contentVC?.didMove(toParent: parent)
    }
    
    override func back(canEmpty: Bool = false) {
        if #available(iOS 16.0, *) {
            setToPortraitIfNeeded()
        }
        super.back(canEmpty: canEmpty)
        if let vc = self.parent as? TabContainable {
            temporaryTabService.removeTab(id: vc.tabContainableIdentifier)
        } else {
            temporaryTabService.removeTab(id: tabContainableIdentifier)
        }
    }
    
    private func setupViewModel() {
        viewModel.bindState = { [weak self] state in
            guard let `self` = self else { return }
            switch state {
            case .prepare:
                DocsLogger.info("loading parent token", component: LogComponents.syncBlock)
                self.showLoading()
            case let .success(token):
                DocsLogger.info("request token success, ready to display", component: LogComponents.syncBlock)
                self.displayIfNeed(parentToken: token) {
                    self.hideLoading()
                }
            case .noPermission:
                self.displayIfNeed(parentToken: nil) {
                    self.hideLoading()
                }
            case .failed(let error):
                self.hideLoading()
                self.showFailed(with: error)
                DocsLogger.error("syncedBlock show failed", component: LogComponents.syncBlock)
            }
        }
        DocsLogger.info("start request parent token", component: LogComponents.syncBlock)
        viewModel.loadSyncInfoIfNeed()
    }
    
    private func showFailed(with error: NSError) {
        setNavigationBarHidden(false, animated: false)
        if failTipsView?.superview == nil {
            let failedView = EmptyListPlaceholderView()
            view.addSubview(failedView)
            failedView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
            }
            failTipsView = failedView
        }
        let errorInfo: ErrorInfoStruct
        switch error.code {
        case DocsNetworkError.Code.entityDeleted.rawValue:
            //同步块被删除直接展示删除页
            errorInfo = ErrorInfoStruct(type: .trash, title: BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Deleted_Toast, domainAndCode: nil)
            navigationBar.removeAllItemsExceptBack()
        case DocsNetworkError.Code.forbidden.rawValue, DocsNetworkError.Code.syncedBlockError.rawValue:
            //无权限或特殊错误码拿不到源文档token，跳到H5打开，H5会重定向到源文档请求权限
            redirectToH5IfNeed()
            return
        default:
            errorInfo = ErrorInfoStruct(type: .empty, title: BundleI18n.SKResource.CreationMobile_Stats_FailedToLoad_title, domainAndCode: nil)
        }
        failTipsView?.config(error: errorInfo)
    }
    
    private func displayIfNeed(parentToken: String?, completion: @escaping () -> Void) {
        if let lastVC = self.contentVC {
            self.removeContentVC(lastVC)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
            guard let self else { return }
            let context = DocContext.syncedBlock(parentToken: parentToken)
            let param = ["doc_context": context]
            if let fatory = SKRouter.shared.getFactory(with: .docX),
               let vc = fatory(self.viewModel.currentUrl, param, .docX) {
                guard let contentVC = vc as? SyncedBlockSeparatePage else {
                    completion()
                    return
                }
                contentVC.setup(delegate: self)
                self.addContentVC(contentVC)
                self.setNavigationBarHidden(true, animated: false)
                self.contentVC = contentVC
                completion()
            } else {
                self.showFailed(with: NSError(domain: "failed to initailize browser", code: -1))
                spaceAssertionFailure("synced block failed to initailize browser")
            }
        }
    }
}

extension SyncContainerViewController: SyncedBlockContainerDelegate {
    
    func backToOriginDocIfNeed(token: String, type: DocsType) {
        if viewModel.type == .sync, let parentToken = viewModel.parentToken {
            let viewModel = SyncContainerViewModel(userResolver: userResolver, url: DocsUrlUtil.url(type: .docX, token: parentToken))
            self.viewModel = viewModel
            setupViewModel()
        }
    }
    
    //同步块刷新时重新加载一遍viewmodel
    func refresh() {
        let viewModel = SyncContainerViewModel(userResolver: userResolver, url: currentUrl)
        self.viewModel = viewModel
        setupViewModel()
    }
    
    private func redirectToH5IfNeed() {

        DocsLogger.info("has no permission, prepare redirect to h5",
                        component: LogComponents.syncBlock)
        var url = self.currentUrl.docs.addEncodeQuery(parameters: ["routeFromSync": "true"])
        //syncedblock独立页还不支持在vc和feed中打开

        self.shouldRedirect = true
        let redirectAction = {
            if self.isTemporaryChild {
                self.temporaryTabService.removeTab(id: self.tabContainableIdentifier)
                self.userResolver.navigator.showTemporary(url, from: self)
            } else {
                self.userResolver.navigator.push(url, from: self)
            }
            if let coordinate = self.navigationController?.transitionCoordinator {
                coordinate.animate(alongsideTransition: nil) { _ in
                    self.navigationController?.viewControllers.removeAll(where: { $0 == self })
                }
            } else {
                self.navigationController?.viewControllers.removeAll(where: { $0 == self })
            }
        }

        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: false, completion: redirectAction)
        } else {
            redirectAction()
        }

    }
}
//MARK: 浮窗delegate
extension SyncContainerViewController: ViewControllerSuspendable {
    /// 页面的唯一 ID，由页面自己实现
    ///
    /// - 同样 ID 的页面只允许收入到浮窗一次，如果该属性被实现为 ID 恒定，则不可重复收入浮窗，
    /// 如果该属性被实现为 ID 变化（如自增），则可以重复收入多个相同页面。
    public var suspendID: String {
        return self.viewModel.token ?? ""
    }
    /// 悬浮窗展开显示的图标
    public var suspendIcon: UIImage? {
        guard let vc = contentVC as? ViewControllerSuspendable else {
            return UDIcon.fileRoundUnknowColorful
        }
        return vc.suspendIcon
    }
    /// 悬浮窗展开显示的标题
    public var suspendTitle: String {
        guard let vc = contentVC as? BrowserViewController, !vc.displayTitle.isEmpty else {
            return self.viewModel.type?.untitledString ?? BundleI18n.SKResource.Doc_Facade_UntitledDocument
        }
        return vc.displayTitle
    }
    /// EENavigator 路由系统中的 URL
    ///
    /// 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面。
    public var suspendURL: String {
        return viewModel.currentUrl.absoluteString
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
        viewModel.type?.fileTypeForSta ?? ""
    }
    
    public var prefersForcePush: Bool? {
        return nil
    }
}

//MARK: 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension SyncContainerViewController: TabContainable {

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
        if shouldRedirect {
            return ""
        }
        return suspendID
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
        return viewModel.type?.rawValue ?? -1
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    public var tabIcon: CustomTabIcon {
        guard let vc = contentVC as? TabContainable else {
            return .iconName(viewModel.type?.squareColorfulIconKey ?? .fileUnknowColorful)
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

//MARK: iPad分屏协议
extension SyncContainerViewController: SceneProvider {
    public var objToken: String {
        viewModel.token ?? ""
    }

    public var objType: DocsType {
        viewModel.type ?? .unknownDefaultType
    }

    public var docsTitle: String? {
        let vc = contentVC as? BrowserViewController
        return vc?.displayTitle
    }

    public var isSupportedShowNewScene: Bool {
        true
    }
    
    public var userInfo: [String: String] {
        return [:]
    }

    public var currentURL: URL? {
        currentUrl
    }
    
    public var version: String? {
        return nil
    }
}
