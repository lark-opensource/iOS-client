//
//  WikiContainerViewController.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/9/23.
//
// swiftlint:disable file_length type_body_length

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import SKResource
import LarkSuspendable
import LarkTab
import UniverseDesignLoading
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignToast
import SpaceInterface
import SKWorkspace
import LarkContainer
import LarkQuickLaunchInterface
import EENavigator


class WikiContainerViewController: BaseViewController {
    private(set) weak var lastChildVC: UIViewController?
    weak var spaceFollowAPIDelegate: SpaceFollowAPIDelegate?
    let viewModel: WikiContainerViewModel
    private var lastDisplayToken: String = ""
    private var lastDisplaySpaceId: String = ""
    private var lastDisplayisVersion: Bool = false
    private var lastDisplayVersion: String?
    private lazy var loadingView = DocsUDLoadingImageView()
    private lazy var failTipsView: WikiFaildView = WikiFaildView(frame: .zero)
    private(set) var wikiTreeViewController: WikiTreeDraggableViewController?
    private(set) var draggableTreeNavVC: UINavigationController?
    private(set) var draggableTreeViewModel: WikiTreeDraggableViewModel?
    var wikiNodeChanged: ((String, WikiTreeContext?) -> Void)?
    private var bag = DisposeBag()
    private var magicRegister: FeelGoodRegister?
    // 标记刚恢复的wiki文档重新reload目录树
    private var shouldReloadTreeWhenRestoreSuccess: Bool = false
    
    weak var docComponentHostDelegate: DocComponentHostDelegate?
    @InjectedSafeLazy private var temporaryTabService: TemporaryTabService

    let userResolver: UserResolver
    required public init(userResolver: UserResolver, viewModel: WikiContainerViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.lastChildVC?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("WikiContainerViewController - deinit")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusBar.alpha = 0
        setupFeelGood()
        setupViewModel()
        viewModel.reportEnterDetail()
    }
    override var prefersStatusBarHidden: Bool {
        guard let vc = lastChildVC else {
            return false
        }
        return vc.prefersStatusBarHidden
    }

    // BrowserViewController 作为子vc必须调用didMove to,不然会你内存泄漏
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        lastChildVC?.didMove(toParent: parent)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.wikiTreeViewController = nil
            self.draggableTreeNavVC = nil
        }
    }

    override var canShowFullscreenItem: Bool { true }
    // magic share 下不显示返回按钮
    override var canShowBackItem: Bool {
        return spaceFollowAPIDelegate == nil
    }
    //主导航PagePreservable缓存协议使用
    var pageScene: LarkQuickLaunchInterface.PageKeeperScene = .normal

    private func setupViewModel() {
        viewModel.output.viewStateEvent.drive(onNext: {[weak self] (state) in
            guard let self = self else { return }
            self.handleViewState(state: state)
        }).disposed(by: bag)
        viewModel.output.showWikiTreeEvent.drive(onNext: {[weak self] (info) in
            guard let self = self else { return }
            DocsLogger.info("[wiki] show wiki tree")
            self.showWikiTree(treeInfo: info)
        }).disposed(by: bag)
        Driver.combineLatest(viewModel.output.enableOpenTreeItem, viewModel.output.hiddenOpenTreeItem)
            .drive(onNext: {[weak self] (enable, hidden) in
                guard let self = self else { return }
                if hidden {
                    self.removeOpenTreeItem()
                } else {
                    self.configOpenTreeItem(enable: enable)
                }
            }).disposed(by: bag)
        viewModel.output.redirectEvent.emit(onNext: { [weak self] (url, params) in
            guard let self = self else { return }
            self.handleRedirectEvent(url: url, params: params)
        }).disposed(by: bag)
        viewModel.output.createWikiMainTreeViewModelEvent.drive(onNext: {[weak self] (info) in
            guard let self = self else { return }
            self.draggableTreeViewModel = self.createDraggableViewModel(info: info)
            self.draggableTreeNavVC = nil
            self.wikiTreeViewController = nil
        }).disposed(by: bag)
        viewModel.input.createWikiMainTreeViewModelAction.onNext(())
    }
    
    private func createDraggableViewModel(info: WikiTreeInfo) -> WikiTreeDraggableViewModel {
        let viewModel = WikiTreeDraggableViewModel(userResolver: userResolver,
                                                   wikiToken: info.wikiToken,
                                                   spaceId: info.spaceId,
                                                   treeContext: info.treeContext,
                                                   synergyUUID: viewModel.synergyUUID)
        setupDraggableViewModel(viewModel)
        return viewModel
    }
    
    private func setupDraggableViewModel(_ viewModel: WikiTreeDraggableViewModel) {
        viewModel.treeViewModel.setup()
        viewModel.clickSearchResult
            .do(onNext: { [weak self] wikiNodeMeta in
                self?.wikiNodeChanged?(wikiNodeMeta.wikiToken, nil)
            })
            .map { meta -> WikiChangeInfo in
                let url = DocsUrlUtil.url(type: .wiki, token: meta.wikiToken)
                let extraInfo = ["from": WikiStatistic.ClientOpenSource.pages.rawValue]
                return (url: url, params:nil, wikiNodeMeta: meta, extraInfo: extraInfo)
            }
            .emit(to: self.viewModel.input.wikiInfoChangeAction)
            .disposed(by: viewModel.bag)

        viewModel.clickTreeNodeContent
            .do(onNext: { [weak self] (wikiNode, treeContext) in
                self?.wikiNodeChanged?(wikiNode.wikiToken, treeContext)
            })
            .map { [weak self] (wikiNode, _) -> WikiChangeInfo in
                let wikiNodeMeta = WikiTreeNodeUtils.getWikiNodeMeta(treeMeta: wikiNode)
                let url = DocsUrlUtil.url(type: .wiki, token: wikiNodeMeta.wikiToken)
                let extraInfo = [
                    "from": WikiStatistic.ClientOpenSource.pages.rawValue,
                    "action": WikiStatistic.ActionType.switchPage.rawValue
                ] as [AnyHashable: Any]
                WikiStatistic.switchPage(wikiToken: self?.viewModel.wikiToken ?? "",
                                         fileType: wikiNodeMeta.docsType.name,
                                         targetWikiToken: wikiNode.wikiToken)
                return (url: url, params:nil, wikiNodeMeta: wikiNodeMeta, extraInfo: extraInfo)
            }
            .emit(to: self.viewModel.input.wikiInfoChangeAction)
            .disposed(by: viewModel.bag)

        viewModel.dismissVC
            .emit(onNext: { [weak self] _ in
                self?.enableKeyboardIfNeed(true) // wikitree面板dismiss后重新eanble
            })
            .disposed(by: viewModel.bag)

        viewModel.currentNodeDeleted.emit(onNext: {[weak self] _ in
            guard let self = self else { return }
            // 当前节点在树上被删除
            guard self.navigationController?.topViewController == self else {
                return
            }
            // 非版本的情况
            guard self.lastDisplayisVersion == false else {
                return
            }
            if self.presentedViewController != nil {
                self.dismiss(animated: true) { [weak self] in
                    self?.back(canEmpty: true)
                }
            } else {
                self.back(canEmpty: true)
            }
        }).disposed(by: viewModel.bag)
    }
    
    // MARK: - utils
    func handleViewState(state: WikiContainerState) {
        switch state {
        case .prepare:
            DocsLogger.info("[wiki] prepare to load")
            self.beginLoading()
        case let .success(info, treeInfo):
            if viewModel.wikiURL.isVersion,
               !URLValidator.isVCFollowUrl(viewModel.wikiURL),
               let verion = URLValidator.getVersionNum(viewModel.wikiURL),
               needRequestVersionToken(token: info.objToken, type: info.docsType, version: verion) {
                self.loadVersionInfo(token: info.objToken, type: info.docsType, version: verion) { [weak self] (result, error) in
                    if result {
                        self?.handleViewState(state: .success(displayInfo: info, treeInfo: treeInfo))
                    } else {
                        self?.handleViewState(state: .failed(error: error!))
                    }
                }
            } else {
                DocsLogger.info("[wiki] display success")
                self.displayIfNeed(displayInfo: info, treeInfo: treeInfo)
                self.endLoading()
            }
        case .unsupport(let url):
            DocsLogger.info("[wiki] display unsupport")
            self.displayUnsupport(url)
            self.endLoading()
        case .failed(let error):
            DocsLogger.info("[wiki] show failed")
            self.showFailed(error: error)
            self.endLoading()
        }
    }
    func displayIfNeed(displayInfo: WikiDisplayInfo, treeInfo: WikiTreeInfo) {
        guard let curToken = DocsUrlUtil.getFileToken(from: displayInfo.url, with: .wiki) else {
            DocsLogger.error("[wiki] display url has no wiki token")
            return
        }
        if !URLValidator.isVCFollowUrl(self.viewModel.wikiURL)
            && lastDisplayToken == curToken
            && lastDisplaySpaceId == viewModel.wikiNode?.spaceID
            && lastDisplayisVersion == self.viewModel.wikiURL.isVersion
            && lastDisplayVersion == URLValidator.getVersionNum(self.viewModel.wikiURL) {
            DocsLogger.warning("[wiki] display the same wiki")
            return
        }
        DocsLogger.info("[wiki-v2] prepare to display wiki v2 content", extraInfo: ["docsType": displayInfo.docsType])
        switch displayInfo.docsType {
        case .doc, .sheet, .mindnote, .bitable, .docX, .slides:
            setupBrowser(displayInfo: displayInfo)
        case .file:
            setupDrive(displayInfo: displayInfo, token: curToken)
        case .wikiCatalog:
            DocsLogger.error("[wiki-v2] catalog FG disabled, showing unsupport")
            displayUnsupport(displayInfo.url)
        default:
            spaceAssertionFailure("unsupport docstype")

            DocsLogger.error("[wiki-v2] unsupport unknown docsType", extraInfo: ["docsType": displayInfo.docsType])
            displayUnsupport(displayInfo.url)
        }
        lastDisplayToken = curToken
        lastDisplaySpaceId = viewModel.wikiNode?.spaceID ?? ""
        lastDisplayisVersion = self.viewModel.wikiURL.isVersion
        lastDisplayVersion = URLValidator.getVersionNum(self.viewModel.wikiURL)
        // 多任务场景需要处理文件当前identifier变化场景
        if let initialToken = viewModel.initialToken, initialToken != viewModel.wikiToken {
            suspendIdentifierDidChange(from: initialToken)
            viewModel.initialToken = viewModel.wikiToken
        }
    }

    func displayUnsupport(_ url: URL) {
        setupChildViewController(initialzer: {
            return SKRouter.shared.defaultRouterView(url)
        })
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

    func setupBrowser(displayInfo: WikiDisplayInfo) {
        let sessionID = viewModel.sessionID
        DispatchQueue.main.async {
            OpenFileRecord.endRecordTimeConsumingFor(sessionID: sessionID, stage: OpenFileRecord.Stage.pullWikiInfo.rawValue, parameters: nil)
        }
        setNavigationBarHidden(true, animated: false)
        setupChildViewController(initialzer: { [weak self] in
            let type = displayInfo.docsType
            var url = displayInfo.url
            if let ccmOpenType = self?.viewModel.extraInfo[CCMOpenTypeKey] as? String {
                url = url.docs.addEncodeQuery(parameters: [CCMOpenTypeKey: ccmOpenType])
            }
            if let infoParams = displayInfo.params {
                var extraParams: [String: String] = [:]
                infoParams.forEach { key, value in
                    if let key = key as? String, let value = value as? String {
                        extraParams[key] = value
                    }
                }
                url = url.docs.addEncodeQuery(parameters: extraParams)
            }
            /// Wiki记录打开文档拉取wiki_info时长，需要和文档加载流程使用同一个session_id
            var params = displayInfo.params
            params?["session_id"] = sessionID
            if let fatory = SKRouter.shared.getFactory(with: type),
               let vc = fatory(url, params, type) {
                let broserVC = vc as? BrowserViewController
                let isVersion = self?.viewModel.wikiURL.isVersion ?? false
                if let broserVC, isVersion {
                    broserVC.parentDelegate = self
                }
                broserVC?.wikiContextProvider = self
                return vc
            } else {
                spaceAssertionFailure("[wiki] failed to initailize browser")
                return SKRouter.shared.defaultRouterView(url)
            }
        }) { [weak self] in
            guard let self else { return }
            self.registWikiJSEventHandlerIfNeed()
            self.setupWikiResotreStatusIfNeed()
            if self.viewModel.isFakeToken {
                self.configOpenTreeItem(enable: false)
            }
        }
    }
    
    func setupDrive(displayInfo: WikiDisplayInfo, token: String) {
        setNavigationBarHidden(true, animated: false)
        setupChildViewController(initialzer: { [weak self] in
            let type = displayInfo.docsType
            var driveURL = DocsUrlUtil.url(type: .file, token: displayInfo.objToken)
            
            if let ccmOpenType = self?.viewModel.extraInfo[CCMOpenTypeKey] as? String {
                driveURL = driveURL.docs.addEncodeQuery(parameters: [CCMOpenTypeKey: ccmOpenType])
            }
            if let infoParams = displayInfo.params {
                var extraParams: [String: String] = [:]
                infoParams.forEach { key, value in
                    if let key = key as? String, let value = value as? String {
                        extraParams[key] = value
                    }
                }
                driveURL = driveURL.docs.addEncodeQuery(parameters: extraParams)
            }
            driveURL = driveURL.docs.addEncodeQuery(parameters: displayInfo.url.queryParameters)

            if let fatory = SKRouter.shared.getFactory(with: type),
               var vc = fatory(driveURL, displayInfo.params, type) {
                if var proxy = vc as? WikiContextProxy {
                    proxy.wikiContextProvider = self
                }
                return vc
            } else {
                spaceAssertionFailure("[wiki] failed to initailize browser")
                return SKRouter.shared.defaultRouterView(displayInfo.url)
            }
        }) { [weak self] in
            self?.bindDriveActionIfNeed()
            self?.setupWikiResotreStatusIfNeed(isDrive: true)
        }
    }
    
    private func bindDriveActionIfNeed() {
        guard let driveVC = lastChildVC as? WikiBizChildViewController else {
            DocsLogger.error("bind DriveVC permission failed: lastchildVC not implement WikiBizChildViewController")
            return
        }
        Observable.combineLatest(driveVC.wikiNodeDeletedObservable, driveVC.permissionObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (deleted, permission) in
                if deleted {
                    self?.viewModel._hiddenTreeItem.accept(true)
                    return
                }
                self?.viewModel._hiddenTreeItem.accept(!permission)
            })
            .disposed(by: bag)
    }

    private func setupFollowDelegate() {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow onSetup: The lastChildVC not implement FollowableViewController")
            return
        }
        guard self.spaceFollowAPIDelegate != nil  else {
            return
        }
        childFollowVC.onSetup(followAPIDelegate: self.spaceFollowAPIDelegate!)
    }
    
    private func updateTemporaryInfos() {
        guard self.isTemporaryChild else { return }
        temporaryTabService.updateTab(self)
    }

    func setupChildViewController<T: UIViewController>(initialzer: @escaping (() -> T), completion: (() -> Void)? = nil) {
        removeChildVC()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
            guard let self = self else { return }
            let childViewController = initialzer()
            self.addChild(childViewController)
            self.view.addSubview(childViewController.view)
            childViewController.didMove(toParent: self)
            self.makeConstraints(for: childViewController.view)
            self.lastChildVC = childViewController
            self.setupFollowDelegate()
            self.updateTemporaryInfos()
            self.addLeftButtonIfNeed()
            self.fixRotationIfNeed()
            self.onDocComponentHostLoaded()
            completion?()
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

    private func showFailed(error: WikiErrorCode) {
        hiddenTreeItemIfDeleted(error: error)
        if error == .nodeHasBeenDeleted {
            browserShowDeletedFailed()
            return
        }
        if failTipsView.superview == nil {
            view.addSubview(failTipsView)
            failTipsView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
            }
            failTipsView.didTap = {[weak self] error in
                self?.failDidTap(error: error)
            }
            if self.viewModel.wikiURL.isVersion {
                failTipsView.didClickPrimaryButton = {[weak self] button in
                    self?.didClickPrimaryButton()
                }
            }
        }
        let err = convertWikiErrorIfNeed(error: error)
        failTipsView.showFail(error: err)
        failTipsView.isHidden = false
        view.bringSubviewToFront(failTipsView)
        setNavigationBarHidden(false, animated: false)
    }
    
    private func browserShowDeletedFailed() {
        guard let browserVC = lastChildVC as? WikiBizChildViewController else {
            return
        }
        browserVC.showFailed()
    }
    
    private func hiddenTreeItemIfDeleted(error: WikiErrorCode) {
        guard error == .sourceNotExist ||
              error == .nodeHasBeenDeleted ||
              error == .nodePhysicalDeleted else {
            return
        }
        removeOpenTreeItem()
    }
    
    private func convertWikiErrorIfNeed(error: WikiErrorCode) -> WikiErrorCode {
        var err = error
        // 如果是版本要展示版本的错误兜底页
        if self.viewModel.wikiURL.isVersion,
           (error == .sourceNotExist || error == .parentSourceNotExist || error == .invalidWiki) {
            err = .versionNotFound
        }
        return err
    }

    private func failDidTap(error: WikiErrorCode?) {
        guard let err = error else {
            DocsLogger.info("No error Info")
            return
        }
        switch err {
        case .networkError:
            self.hideFailed()
            self.viewModel.input.retryAction.onNext(())
        default:
            break
        }
    }
    private func hideFailed() {
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

    private func addLeftButtonIfNeed() {
        guard !viewModel.isHistory && !viewModel.isFromVC && !isDocComponent && componentConfig == nil else {
            DocsLogger.info("wiki vcFollow or history or DocComponent not need treeItem")
            return
        }
        if let vc = lastChildVC as? WikiBizChildViewController {
            vc.configWikiTreeItem(self.openTreeItem())
            viewModel.checkHiddenTreeItemIfNeed()
        }
    }

    private func openTreeItem() -> SKBarButtonItem {
        let item = SKBarButtonItem(image: UDIcon.treelistOutlined,
                                   style: .plain, target: self, action: #selector(openDirectoryTree))
        item.id = .tree
        return item
    }

    func getLeftBarButtonFrame(by id: SKNavigationBar.ButtonIdentifier) -> CGRect? {
        guard let vc = lastChildVC as? BaseViewController else { return nil }
        guard !vc.navigationBar.isHidden else { return nil }
        for button in vc.navigationBar.leadingButtons where button.item?.id == id {
            guard !button.isHidden else { return nil }
            return button.convert(button.bounds, to: view)
        }
        return nil
    }

    private func configOpenTreeItem(enable: Bool) {
        let item = openTreeItem()
        item.isEnabled = enable

        if let vc = lastChildVC as? WikiBizChildViewController {
            vc.configWikiTreeItem(item)
            // 目录树引导
            // docs页面的navigationBar初始化位置比较靠上，时机有点迷
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                if enable,
                    !OnboardingManager.shared.hasFinished(OnboardingID.wikiNewbiePageTree) {
                    OnboardingManager.shared.showFlowOnboarding(id: OnboardingID.wikiNewbiePageTree,
                                                                delegate: self,
                                                                dataSource: self)
                }
            }
        }

        let fakeItem = navigationBar.leadingBarButtonItems.first { (curItem) -> Bool in
            return curItem.id == item.id
        }
        if fakeItem == nil {
            let curItem = navigationBar.leadingBarButtonItems
            navigationBar.leadingBarButtonItems = curItem + [item]
        }
        fakeItem?.isEnabled = enable
    }
    
    private func removeOpenTreeItem() {
        let item = openTreeItem()
        var curItems = self.navigationBar.leadingBarButtonItems
        if let vc = lastChildVC as? WikiBizChildViewController {
            vc.hiddenWikiTreeItem(item)
        }
        curItems.removeAll { (curItem) -> Bool in
            return curItem.id == item.id
        }
        navigationBar.leadingBarButtonItems = curItems
        navigationBar.setNeedsLayout()
    }

    // 如果对应单品bizVC是 BrowserViewController则添加JS事件监听
    private func registWikiJSEventHandlerIfNeed() {
        if let vc = lastChildVC as? BrowserViewController {
            vc.editor.jsServiceManager.registerWikiServiceWithHandler(self.viewModel)
        }
    }
    private func setupWikiResotreStatusIfNeed(isDrive: Bool = false) {
        guard let vc = lastChildVC as? WikiBizChildViewController else {
            return
        }
        vc.restoreSuccessObservable.subscribe(onNext: {[weak self] success in
            guard success else { return }
            self?.shouldReloadTreeWhenRestoreSuccess = true
            if isDrive {
                self?.configOpenTreeItem(enable: true)
            }
        }).disposed(by: bag)
    }
    private func enableKeyboardIfNeed(_ enable: Bool) {
        if let vc = lastChildVC as? BrowserViewController {
            DocsLogger.info("enable key board focus: \(enable)", component: LogComponents.wiki)
            vc.editor.simulateJSMessage(DocsJSService.simulateCanSetFocusable.rawValue, params: ["canFocusable": enable])
        }
    }
    
    private func setupFeelGood() {
        let weakRef = WeakReference(navigationController)
        magicRegister = FeelGoodRegister(type: .wikiContent) { weakRef.ref }
    }

    // MARK: - actions
    @objc
    func openDirectoryTree() {
        DocsLogger.info("openDirectoryTree")
        viewModel.input.showWikiTreeAction.onNext(())
        logNavBarEvent(.navigationBarClick, click: "wiki_tree", target: "ccm_wiki_tree_view")
    }

    func showWikiTree(treeInfo: WikiTreeInfo) {
        enableKeyboardIfNeed(false) // 避免弹出wikitree面板后再弹出keyboard
        if let wikiTree = wikiTreeViewController, let nvc = draggableTreeNavVC {
            setupTreePerformanceRecord(wikiToken: wikiTree.viewModel.wikiToken, type: .cache)
            self.present(nvc, animated: true)
        } else {
            var draggableTreeViewModel: WikiTreeDraggableViewModel
            if let viewModel = self.draggableTreeViewModel {
                draggableTreeViewModel = viewModel
            } else {
                draggableTreeViewModel = createDraggableViewModel(info: treeInfo)
                self.draggableTreeViewModel = draggableTreeViewModel
            }
            if shouldReloadTreeWhenRestoreSuccess {
                // 被恢复的Wiki文档需要重新load一次目录树
                draggableTreeViewModel.treeViewModel.reload()
                shouldReloadTreeWhenRestoreSuccess = false
            }
            draggableTreeViewModel.supportOrientation = self.supportedInterfaceOrientations
            let wikiTree = WikiTreeDraggableViewController(userResolver: userResolver, viewModel: draggableTreeViewModel)
            wikiTree.hostViewController = self
            let navVC = LkNavigationController(rootViewController: wikiTree)
            navVC.transitioningDelegate = wikiTree
            setupTreePerformanceRecord(wikiToken: wikiTree.viewModel.wikiToken, type: .network)
            wikiTree.modalPresentationStyle = .pageSheet
            navVC.modalPresentationStyle = .pageSheet
            self.present(navVC, animated: true)
            wikiTreeViewController = wikiTree
            draggableTreeNavVC = navVC
        }
    }

    private func setupTreePerformanceRecord(wikiToken: String, type: WikiPerformanceRecorder.OpenType) {
        WikiPerformanceRecorder.shared.clearAllData()
        let context = WikiPerformanceRecorder.RecordContext(
            event: .wikiOpenTreePerformance,
            stage: .total,
            wikiToken: wikiToken,
            source: .panel,
            openType: type,
            action: .openTree
        )
        WikiPerformanceRecorder.shared.wikiPerformanceRecordBegin(context: context)
    }

    private func handleRedirectEvent(url: URL, params: [AnyHashable: Any]?) {
        DocsLogger.info("[wiki] container handle redirect event")
        if let spaceFollowAPIDelegate = spaceFollowAPIDelegate {
            DocsLogger.info("redirect to space in video conference")
            spaceFollowAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openMoveToSpaceUrl(spaceUrl: url.absoluteString, originUrl: viewModel.wikiURL.absoluteString)))
            return
        }

        guard let controller = SKRouter.shared.open(with: url, params: params).0 else {
            // TODO: wuwenjian - 跳一个兜底页
            spaceAssertionFailure()
            return
        }
        
        (self as TabContainable).shouldRedirect = true
        if self.isTemporaryChild {
            self.temporaryTabService.removeTab(id: self.tabContainableIdentifier)
            self.userResolver.navigator.showTemporary(controller, from: self)
        } else {
            navigationController?.pushViewController(controller, animated: false)
        }
        if let coordinate = navigationController?.transitionCoordinator {
            coordinate.animate(alongsideTransition: nil) { [weak self] _ in
                guard let self = self else { return }
                if let presentedVC = self.presentedViewController {
                    presentedVC.dismiss(animated: false)
                }
                self.navigationController?.viewControllers.removeAll(where: { $0 == self })
            }
        } else {
            if let presentedVC = presentedViewController {
                presentedVC.dismiss(animated: false)
            }
            navigationController?.viewControllers.removeAll(where: { $0 == self })
        }
    }
}

// 兼容跳转时判断是否是同一个页面
extension WikiContainerViewController: BrowserControllable {

    var browerEditor: BrowserView? {
        guard let vc = lastChildVC as? BrowserViewController else {
            return nil
        }
        return vc.editor
    }

    func updateUrl(_ url: URL) {
        // do nothing
        DocsLogger.info("wiki container call updateURL", component: LogComponents.wiki)
    }

    func setDismissDelegate(_ newDelegate: BrowserViewControllerDelegate?) {
        // do nothing
        DocsLogger.info("wiki container call setDismissDelegate", component: LogComponents.wiki)
    }

    func setToggleSwipeGestureEnable(_ enable: Bool) {
        // do nothing
        DocsLogger.info("wiki container call setToggleSwipeGestureEnable", component: LogComponents.wiki)
    }
    
    func setLandscapeStrategyWhenAppear(_ enable: Bool) {
        // do nothing
        DocsLogger.info("wiki container call setLandscapeStrategyWhenAppear", component: LogComponents.wiki)
    }
}

extension WikiContainerViewController: SceneProvider {
    
    var objToken: String {
        viewModel.wikiToken
    }

    var objType: DocsType {
        .wiki
    }

    var docsTitle: String? {
        let vc = lastChildVC as? WikiBizChildViewController
        return vc?.displayTitle
    }

    var isSupportedShowNewScene: Bool {
        true
    }
    
    var userInfo: [String: String] {
        return [:]
    }

    var currentURL: URL? { nil }
    
    var version: String? {
        return URLValidator.getVersionNum(viewModel.wikiURL)
    }
}

extension WikiContainerViewController: ViewControllerSuspendable {
    /// 页面的唯一 ID，由页面自己实现
    ///
    /// - 同样 ID 的页面只允许收入到浮窗一次，如果该属性被实现为 ID 恒定，则不可重复收入浮窗，
    /// 如果该属性被实现为 ID 变化（如自增），则可以重复收入多个相同页面。
    public var suspendID: String {
        return self.viewModel.wikiToken + (lastDisplayVersion ?? "")
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
        guard let vc = lastChildVC as? ViewControllerSuspendable else {
            return self.viewModel.wikiNode?.docsType.untitledString ?? DocsType.wiki.i18Name
        }
        return vc.suspendTitle
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
        return "wiki"
    }
    
    public var prefersForcePush: Bool? {
        if lastDisplayVersion != nil {
            return true
        }
        return nil
    }
}

extension WikiContainerViewController: PagePreservable {
    var pageID: String {
        self.tabID
    }
    
    var pageType: LarkQuickLaunchInterface.PageKeeperType {
        .ccm
    }

}

/// 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension WikiContainerViewController: TabContainable {

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
        return DocsType.wiki.rawValue
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
        return "wiki"
    }
    
    /// 重新点击临时区域时是否强制刷新（重新从url获取vc）
    ///
    /// - 默认值为false
    public var forceRefresh: Bool {

        //这个方法主导航会回调多次，目前drive是不做缓存的
        if let childTabContainable = self.lastChildVC as? TabContainable {
            return childTabContainable.forceRefresh
        }
        
        //新缓存是否开启，开启则返回true，关闭旧缓存
        if let keepService = userResolver.resolve(PageKeeperService.self), keepService.hasSetting {
            return true
        }
        
        //旧缓存开启
        return false

    }
 }

extension WikiContainerViewController: WikiContextProvider {
    var synergyUUID: String { viewModel.synergyUUID }
}
