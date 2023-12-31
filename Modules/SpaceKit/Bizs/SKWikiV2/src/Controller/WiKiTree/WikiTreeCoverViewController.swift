//
//  WikiTreeCoverViewController.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/12/19.
// swiftlint:disable type_body_length file_length function_body_length

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignToast
import EENavigator
import SKCommon
import SKSpace
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignMenu
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignIcon
import UniverseDesignTheme
import LarkUIKit
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer
import LarkSplitViewController
import LarkQuickLaunchInterface
import LarkTab

class WikiTreeCoverViewController: BaseViewController, UserResolverWrapper {
    // 适配主导航
    @ScopedInjectedLazy var temporaryTabService: TemporaryTabService?
    
    private lazy var myAIViewModel: WikiSpaceMyAIViewModel = {
        return WikiSpaceMyAIViewModel(spaceID: viewModel.space.spaceID, hostVC: self)
    }()
    
    private(set) var viewModel: WikiTreeCoverViewModel
    private(set) var treeView: TreeView!
    private(set) var targetRect: CGRect = .zero

    private var coverNavigationBarIsShow = true
    private var isDefaultStatusBar = false {
        didSet {
            if isDefaultStatusBar != oldValue {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    private let bag = DisposeBag()
    private var treeReady = false

    private lazy var coverView: WikiTreeCoverView = {
        let view = WikiTreeCoverView(space: viewModel.space, frame: .zero)
        view.didClickUploadView = { [weak self] in
            guard let self = self else { return }
            let encrySpaceID = DocsTracker.encrypt(id: self.viewModel.space.spaceID)
            let params: [String: Any] = ["container_id": encrySpaceID, "container_type": "wiki"]
            DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                .showUploadListViewController(sourceViewController: self,
                                              folderToken: self.viewModel.mountToken,
                                              scene: .workspace,
                                              params: params)
        }
        return view
    }()
    private(set) lazy var coverNavigationBar: WikiTreeCoverNavigationBar = {
        let space = viewModel.space
        let navBar = WikiTreeCoverNavigationBar(isDarkStyle: space.displayIsDarkStyle, isStar: space.isStar ?? false)
        return navBar
    }()
    
    private lazy var myAIBarItem: SKBarButtonItem = {
        let myAIItem = SKBarButtonItem(image: UDIcon.chatAiOutlined.ud.withTintColor(UDColor.iconN1),
                                       style: .plain,
                                       target: self,
                                       action: #selector(tapMyAI))
        myAIItem.useOriginRenderedImage = true
        myAIItem.id = .aiChatMode
        return myAIItem
    }()
    
    private lazy var spaceDetailItem: SKBarButtonItem = {
        let spaceDetailItem = SKBarButtonItem(image: UDIcon.infoOutlined.ud.withTintColor(UDColor.iconN1),
                                              style: .plain,
                                              target: self,
                                              action: #selector(tapSpaceDetail))
        spaceDetailItem.id = .wikiSpaceDetail
        
        return spaceDetailItem
    }()
    
    // 悬浮创建按钮
    private lazy var createButton = SKCreateButton()
    private let keyboard = Keyboard()

    static let coverTreeNavHeight: CGFloat = 44
    private var wikiTreeHeaderViewHeight: CGFloat {
        coverView.estimatedContentHeight(for: view.frame.width) + Self.coverTreeNavHeight + self.view.safeAreaInsets.top
    }

    // 文件选择
    private lazy var selectFileHelper = WikiSelectFileHelper(hostViewController: self, triggerLocation: .wikiTree)
    private let updateSecondaryInput = BehaviorRelay<Void>(value: ())
    let showWikiHomeWhenClosed: Bool
    
    // 通过链接路由打开时不为nil, 仅适配主导航使用
    private(set) var wikiSpaceUrl: URL?

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: WikiTreeCoverViewModel, wikiSpaceUrl: URL? = nil, showWikiHomeWhenClosed: Bool = false) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.showWikiHomeWhenClosed = showWikiHomeWhenClosed
        self.wikiSpaceUrl = wikiSpaceUrl
        super.init(nibName: nil, bundle: nil)
        
        treeView = TreeView(dataBuilder: viewModel.treeViewModel)
        treeView.treeViewRouter = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if isDefaultStatusBar {
            return .default
        } else {
            return viewModel.space.displayIsDarkStyle ? .lightContent : .default
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.space.displayTitle
        navigationBar.alpha = 0
        navigationBar.layoutAttributes.titleHorizontalAlignment = .leading
        statusBar.alpha = 0
        let topSafeAreaHeight = view.safeAreaInsets.top
        let naviBarOffset = navigationBar.intrinsicHeight + topSafeAreaHeight
        navigationBar.snp.updateConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset)
        }
        self.customChildrenIdentifier = .init(identifier: [.initial, .primary])
        bindCoverAction()
        bindWikitreeAction()
        setupTreeView()
        setupUI()
        setupBarItem()
        setupUploadView()
        setupKeyboardMonitor()
        WikiStatistic.treeView(spaceId: viewModel.space.spaceId ?? "null")
    }
    
    var showUploadView: Bool = false
    var coverHeight: CGFloat {
        let height = showUploadView ? wikiTreeHeaderViewHeight + 68 : wikiTreeHeaderViewHeight
        return height
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let previousTraitCollection = traitCollection
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.updateTreeHeaderView(size, height: self.coverHeight)
            if UserScopeNoChangeFG.MJ.newIpadSpaceEnable,
               self.traitCollection.horizontalSizeClass == .regular {
                self.updateSecondaryInput.accept(())
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if UserScopeNoChangeFG.MJ.newIpadSpaceEnable {
            updateSecondaryPlaceholder(previousTraitCollection: previousTraitCollection)
        }
    }

    private func updateSecondaryPlaceholder(previousTraitCollection: UITraitCollection?) {
        if let previousTraitCollection {
            if previousTraitCollection.horizontalSizeClass == .compact,
               traitCollection.horizontalSizeClass == .regular {
                // C -> R 检查 secondary
                updateSecondaryInput.accept(())
            } else if previousTraitCollection.horizontalSizeClass == .regular,
                      traitCollection.horizontalSizeClass == .compact {
                // R -> C 暂时无事发生
            }
        }
    }

    private static func getFirstNodes(sections: [NodeSection], nodeUID: WikiTreeNodeUID?) -> TreeNode? {
        var firstNode: TreeNode?
        for section in sections {
            for item in section.items {
                guard item.type == .normal else { continue }
                if firstNode == nil {
                    firstNode = item
                }
                if let nodeUID {
                    if item.diffId == nodeUID {
                        // 找到 nodeUID 匹配的节点，直接返回
                        return item
                    }
                } else {
                    // nodeUID 为 nil 且找到第一个节点，直接返回
                    return item
                }
            }
        }
        // 传了 nodeUID 但没有匹配到 node，则返回第一个节点
        return firstNode
    }

    func updateSecondaryIfNeed(treeReady: Bool, firstNode: TreeNode?) {
        guard checkSecondaryIsDefaultController() else { return }
        if treeReady {
            if let firstNode {
                // secondary 是 defaultVC, 目录树有内容, showDetail 第一篇文档
                firstNode.clickContentAction(IndexPath()) // IndexPath 参数未被使用且将要移除，暂时随便传
            } else {
                // secondary 是 defaultVC, 目录树是空树, showDetail WikiIPadDefaultDetailController+showEmpty
                let controller = WikiIPadDefaultDetailController(initialState: .empty)
                userResolver.navigator.showDetail(controller, from: self)
            }
        } else {
            // secondary 是 defaultVC, 目录树加载中, showDetail WikiIPadDefaultDetailController+showLoading
            let controller = WikiIPadDefaultDetailController(initialState: .loading)
            userResolver.navigator.showDetail(controller, from: self)
        }
    }

    private func checkSecondaryIsDefaultController() -> Bool {
        guard let larkSplitViewController else { return false }
        guard var secondaryController = larkSplitViewController.viewController(for: .secondary) else { return false }
        if let navigationController = secondaryController as? UINavigationController,
           let topController = navigationController.topViewController {
            secondaryController = topController
        }
        if secondaryController.isKind(of: WikiIPadDefaultDetailController.self) { return true }
        if let containerController = secondaryController as? WorkspaceIPadContainerController,
           containerController.regularController.isKind(of: WikiIPadHomePageViewController.self) {
            return true
        }
        if (secondaryController as? DefaultDetailVC) != nil { return true }
        return false
    }

    override func viewWillBackToPreviousPage() {
        super.viewWillBackToPreviousPage()
        showWikiHomeIfNeed()
    }

    private func showWikiHomeIfNeed() {
        guard showWikiHomeWhenClosed,
              traitCollection.horizontalSizeClass == .regular else {
            return
        }
        let wikiVC = WikiVCFactory.makeWikiHomePageVC(userResolver: userResolver,
                                                      params: ["from": "recent"])
        let regularVC = WikiIPadHomePageViewController(userResolver: userResolver)
        let container = WorkspaceIPadContainerController(compactController: wikiVC, regularController: regularVC)
        userResolver.navigator.showDetail(container, from: self)
    }

    private func updateTreeHeaderView(_ size: CGSize, height: CGFloat) {
        if treeView.tableView.contentOffset.y < 0 {
            treeView.tableView.contentOffset.y = 0
        }
        coverView.frame.size = CGSize(width: size.width, height: height)
        coverView.imageBackgroundView.frame = coverView.frame
        coverView.refreshNoticeLayout()
        treeView.tableView.tableHeaderView = coverView
        coverView.setNeedsLayout()
    }

    private func setupTreeView() {
        view.addSubview(treeView)
        // 防止创建按钮与treeview的最后一行侧滑按钮布局遮挡
        let bottomInset = view.safeAreaInsets.bottom + 48 /*创建按钮高度*/ + 16 /*创建按钮底部偏移量*/
        treeView.tableView.contentInset = UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: bottomInset,
                                                       right: 0)
        treeView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        treeView.tableView.rx.didScroll.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            self.treeTableViewDidScroll(self.treeView.tableView)
        }).disposed(by: bag)
        updateTreeHeaderView(view.bounds.size, height: coverHeight)
        viewModel.initailTreeData()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.updateTreeHeaderView(view.bounds.size, height: coverHeight)
        let bottomInset = view.safeAreaInsets.bottom + 48 /*创建按钮高度*/ + 16 /*创建按钮底部偏移量*/
        treeView.tableView.contentInset = UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: bottomInset,
                                                       right: 0)
    }
    
    private func setupUploadView() {
        viewModel.uploadState.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] item in
            guard let self = self else { return }
            if let uploadItem = item {
                if !self.showUploadView {
                    self.showUploadView = true
                    self.coverView.showUploadView(true)
                }
                self.coverView.updateUploadView(item: uploadItem)
            } else {
                self.showUploadView = false
                self.coverView.showUploadView(false)
            }
            self.updateTreeHeaderView(self.view.bounds.size, height: self.coverHeight)
        }).disposed(by: bag)
    }

    private func setupUI() {
        view.addSubview(coverNavigationBar)
        coverNavigationBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(Self.coverTreeNavHeight)
        }

        view.addSubview(createButton)
        createButton.isHidden = true
        createButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.height.equalTo(48)
        }
        createButton.layer.cornerRadius = 24
        createButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.viewModel.treeViewModel.createRootNodeInput.accept((self.createButton))
            }).disposed(by: bag)
    }

    private func bindCoverAction() {
        coverNavigationBar.backBtn.rx.tap.subscribe(onNext: {[weak self] _ in
            spaceAssert(Thread.isMainThread)
            guard let self = self else { return }
            self.showWikiHomeIfNeed()
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: bag)
        
        coverNavigationBar.myAIBtn.rx.tap.subscribe(onNext: {[weak self] _ in
            spaceAssert(Thread.isMainThread)
            guard let self = self else { return }
            self.tapMyAI()
        }).disposed(by: bag)

        coverNavigationBar.searchBtn.rx.tap.subscribe(onNext: {[weak self] _ in
            spaceAssert(Thread.isMainThread)
            guard let self = self else { return }
            self.searchWiki()
        }).disposed(by: bag)
        
        coverNavigationBar.starBtn.rx.tap.subscribe(onNext: {[weak self] _ in
            spaceAssert(Thread.isMainThread)
            guard let self = self else { return }
            self.tapStar()
        }).disposed(by: bag)
        
        coverNavigationBar.detailBtn.rx.tap.subscribe(onNext: {[weak self] _ in
            spaceAssert(Thread.isMainThread)
            guard let self = self else { return }
            self.tapSpaceDetail()
        }).disposed(by: bag)
        
        coverNavigationBar.closeBtn.rx.tap.subscribe(onNext: { [weak self] _ in
            spaceAssert(Thread.isMainThread)
            guard let self else { return }
            self.closeButtonClickHandler()
        }).disposed(by: bag)
        
        coverView.clickMigrateTipEvent.emit(onNext: { [weak self] in
            guard let self = self else { return }
            WikiRouter.goToMigrationTip(userResolver: self.userResolver,from: self)
        }).disposed(by: bag)

        viewModel.handleStar
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (result) in
                spaceAssert(Thread.isMainThread)
                guard let self = self else { return }
                guard let window = self.view.window else {
                    spaceAssertionFailure("cannot get current view window")
                    return
                }
                switch result {
                case .next(let isStar):
                    self.viewModel.space.isStar = isStar
                    self.changeStarButtonStatus(isStar)
                    self.coverNavigationBar.update(isDarkStyle: self.viewModel.space.displayIsDarkStyle, isStar: isStar)
                    if !isStar {
                        // 取消收藏
                        UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Wiki_UnstarSuccess, on: window)
                        DocsLogger.info("🐘取消收藏成功")
                    } else {
                        // 收藏
                        UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Wiki_StarSuccess, on: window)
                        DocsLogger.info("🐘收藏成功")
                    }
                case .error(let error):
                    if self.viewModel.space.isStar ?? false {
                        // 取消收藏
                        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Wiki_UnstarFail, on: window)
                        DocsLogger.info("🐘取消收藏失败\(error)")
                    } else {
                        // 收藏
                        if (error as NSError).code == WikiErrorCode.starSpaceNumLimited.rawValue {
                            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_Wiki_Favorited_Max, on: window)
                        } else {
                            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Wiki_StarFail, on: window)
                        }
                        DocsLogger.info("🐘收藏失败\(error)")
                    }
                default: break
                }
            }).disposed(by: bag)
    }

    // swiftlint:disable cyclomatic_complexity
    private func bindWikitreeAction() {
        setupCreateAction()
        setupNavigtionBarUpdate()
        setupSpaceInfoUpdate()
        setupSpacePermission()
        setupUpdateSecondary()
       
        viewModel.treeViewModel
            .input
            .build
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] in
                guard let self = self else { return }
                self.treeTableViewDidScroll(self.treeView.tableView)
            })
            .disposed(by: bag)
        
        viewModel.treeViewModel
            .reloadFailedDriver
            .drive(onNext: { [weak self] error in
                guard let self = self else { return }
                if let wikiError = WikiErrorCode(rawValue: (error as NSError).code),
                   wikiError == .nodePermFailCode {
                    self.hiddenAllBarItem()
                }
                WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                        stage: .total,
                                                                        wikiToken: "",
                                                                        resultKey: .fail,
                                                                        resultCode: String((error as NSError).code))
            })
            .disposed(by: bag)
        viewModel.treeViewModel.onClickNodeSignal
            .emit(onNext: { [weak self] meta, treeContext in
                guard let self = self else { return }
                let nodeMeta = WikiTreeNodeUtils.getWikiNodeMeta(treeMeta: meta)
                self.gotoWikiContainer(wikiNodeMeta: nodeMeta,
                                       treeContext: treeContext,
                                       extraInfo: [
                                        "from": WikiStatistic.ClientOpenSource.pages.rawValue,
                                        CCMOpenTypeKey: CCMOpenType.wikiAll.trackValue,
                                        "action": WikiStatistic.ActionType.switchPage.rawValue
                                       ] as [AnyHashable: Any],
                                       from: self)
            })
            .disposed(by: bag)
    }
    
    private func setupCreateAction() {
        // 新建按钮上屏
        Observable.combineLatest(viewModel.treeViewModel.reloadSuccessDriver.asObservable(),
                                 viewModel.treeViewModel.moreProvider.spacePermissionInput.asObservable(),
                                 viewModel.treeViewModel.moreProvider.spaceInput.asObservable())
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _, spacePermission, spaceInfo in
            guard let self = self else { return }
            
            let isMyLibrary = (spaceInfo?.spaceType == .library)
            let isMember = spacePermission.isWikiMember || spacePermission.isWikiAdmin
            
            DocsLogger.info("wiki cover viewcontroller -- isMyLibrary: \(isMyLibrary), isMember: \(isMember)")

            // 仅空间成员可见，不支持「个人文档库」
            if aiServiceEnabled() && UserScopeNoChangeFG.ZH.enableWikiSpaceMyAIEntrance && isMember && !isMyLibrary {
                self.coverNavigationBar.showMyAIItem()
                self.showAIBarItem()
            }
            
            guard spacePermission.canEditFirstLevel else {
                DocsLogger.info("wiki cover viewcontroller --- can not show create button without edit first level permission")
                return
            }
            self.createButton.isHidden = false
            WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                    stage: .total,
                                                                    wikiToken: "",
                                                                    resultKey: .success,
                                                                    resultCode: "0")
        })
        .disposed(by: bag)
        
        // 上传文件
        viewModel.treeViewModel.onUploadSignal
            .emit(onNext: { [weak self] (token, isImage, action) in
                if isImage {
                    self?.selectFileHelper.selectImages(wikiToken: token, completion: action)
                } else {
                    self?.selectFileHelper.selectFile(wikiToken: token, completion: action)
                }
            })
            .disposed(by: bag)
        
        // 创建按钮无网置灰
        viewModel.treeViewModel.reachabilityRelay
            .skip(1)
            .subscribe(onNext: {[weak self] isReachable in
                guard let self = self else { return }
                self.createButton.isEnabled = isReachable
            })
            .disposed(by: bag)
    }
    
    private func setupNavigtionBarUpdate() {
        viewModel.treeViewModel
            .actionSignal
            .filter { action in
                switch action {
                case .showErrorPage, .showLoading:
                    // showLoading 隐含了 hideLoadingPage 的含义
                    return true
                default:
                    return false
                }
            }
            .emit(onNext: { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .showErrorPage:
                    self.updateCustomNavigationBar(ratio: 1)
                    self.createButton.isHidden = true
                    self.navigationBar.trailingBarButtonItems = []
                    var isDarkModeTheme: Bool = false
                    if #available(iOS 13.0, *) {
                        isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
                    }
                    self.coverNavigationBar.update(isDarkStyle: isDarkModeTheme,
                                                   isStar: self.viewModel.space.isStar ?? false)
                case .showLoading:
                    let space = self.viewModel.space
                    self.coverNavigationBar.update(isDarkStyle: space.displayIsDarkStyle,
                                                   isStar: space.isStar ?? false)
                default:
                    return
                }
            })
            .disposed(by: bag)
        
        viewModel.treeViewModel
            .sectionRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                spaceAssert(Thread.isMainThread)
                guard let self = self else { return }
                self.treeTableViewDidScroll(self.treeView.tableView)
            })
            .disposed(by: bag)
    }
    
    private func setupSpacePermission() {
        viewModel.treeViewModel.dataModel
            .userSpacePermissionUpdated
            .drive(onNext: { [weak self] permission in
                guard let self = self else { return }
                if permission.canViewGeneralInfo {
                    self.coverNavigationBar.showMoreItems()
                    self.showMoreBarItem()
                }
            })
            .disposed(by: bag)
    }
    
    private func setupSpaceInfoUpdate() {
        viewModel.spaceInfoUpdate
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] space in
                guard let self = self else { return }
                spaceAssert(Thread.isMainThread)
                self.coverView.update(space: space)
                self.coverNavigationBar.update(isDarkStyle: space.displayIsDarkStyle, isStar: space.isStar ?? false)
                self.title = space.displayTitle
                self.updateTreeHeaderView(self.view.bounds.size, height: self.coverHeight)
            })
            .disposed(by: bag)
        
        viewModel.treeViewModel.dataModel
            .spaceInfoUpdated
            .drive(onNext: { [weak self] spaceInfo in
                guard let self = self else { return }
                if let spaceInfo = spaceInfo,
                   spaceInfo.spaceID != self.viewModel.space.spaceID {
                    self.viewModel.updateSpaceInfo(spaceId: spaceInfo.spaceID)
                }
            })
            .disposed(by: bag)
        
        
    }
    
    private func setupUpdateSecondary() {
        guard UserScopeNoChangeFG.MJ.newIpadSpaceEnable, SKDisplay.pad else {
            return
        }
        
        let treeReady = viewModel.treeViewModel.dataModel.initialStateUpdated
            .map { state in
                if let serverState = state.serverState {
                    switch serverState {
                    case .success:
                        return true
                    case .failure:
                        return false
                    }
                } else if let cacheState = state.cacheState {
                    switch cacheState {
                    case .success:
                        return true
                    case .failure:
                        return true
                    }
                } else {
                    return false
                }
            }
        let firstNode = viewModel.treeViewModel.sectionsDriver
            .compactMap { [weak self] sections in
                return Self.getFirstNodes(sections: sections,
                                          nodeUID: self?.viewModel.treeViewModel.selectedNodeUID)
            }
        Driver.combineLatest(treeReady, firstNode, updateSecondaryInput.asDriver())
            .drive(onNext: { [weak self] ready, firstNode, _ in
                guard let self else { return }
                self.updateSecondaryIfNeed(treeReady: ready, firstNode: firstNode)
            })
            .disposed(by: bag)
    }

    private func setupBarItem() {
        let searchBarItem = SKBarButtonItem(image: UDIcon.searchOutlined,
                                         style: .plain,
                                         target: self,
                                         action: #selector(searchWiki))
        searchBarItem.id = .search
        // 完整item: spaceDetailItem - searchBarItem - myAIBarItem
        navigationBar.trailingBarButtonItems = [searchBarItem]
    }
    
    private func showMoreBarItem() {
        DocsLogger.info("showMoreBarItem")
        if !findBarItem(id: .wikiSpaceDetail) {
            var items = navigationBar.trailingBarButtonItems
            items.insert(spaceDetailItem, at: 0)
            navigationBar.trailingBarButtonItems = items
        }
    }
    
    private func showAIBarItem() {
        DocsLogger.info("showAIBarItem")
        if !findBarItem(id: .aiChatMode) {
            var items = navigationBar.trailingBarButtonItems
            items.append(myAIBarItem)
            navigationBar.trailingBarButtonItems = items
        }
    }
    
    private func findBarItem(id: SKNavigationBar.ButtonIdentifier) -> Bool {
        var result = false
        
        navigationBar.trailingBarButtonItems.forEach { barItem in
            if barItem.id == id {
                DocsLogger.info("found BarItem -- id: \(id)")
                result = true
            }
        }
        return result
    }
    
    private func hiddenAllBarItem() {
        let emptyItems: [SKBarButtonItem] = []
        navigationBar.trailingBarButtonItems = emptyItems
        coverNavigationBar.hiddenBarRightItems()
    }
    
    @objc
    private func tapMyAI() {
        guard DocsNetStateMonitor.shared.isReachable else {
            DocsLogger.warning("no network to show my ai")
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_Common_NoInternet,
                             on: self.view)
            return
        }
        
        myAIViewModel.enterMyAIChat()
        WikiStatistic.clickMyAI()
    }

    @objc
    private func searchWiki() {
        showSearchView()
        WikiStatistic.clickSearch(subModule: .wikiPages, source: .wikiPagesView, action: .searchButton)
    }
    
    @objc
    private func tapStar() {
        let isStar = self.viewModel.space.isStar ?? false
        self.viewModel.tapStar.onNext(!isStar)
    }
    
    @objc
    private func tapSpaceDetail() {
        WikiStatistic.clickWorkSpaceDetail()
        WikiRouter.goToSpaceDetail(userResolver: userResolver, space:self.viewModel.space, fromVC: self)
    }
    
    @objc
    func closeButtonClickHandler() {
        if let vc = self.parent as? TabContainable {
            temporaryTabService?.removeTab(id: vc.tabContainableIdentifier)
        } else {
            temporaryTabService?.removeTab(id: tabContainableIdentifier)
        }
    }
    
    private func changeStarButtonStatus(_ isStar: Bool) {
        let icon = isStar ? UDIcon.collectFilled : UDIcon.collectionOutlined
        let items = navigationBar.trailingBarButtonItems
        items.forEach { item in
            if item.id == .wikiSpaceStar {
                item.image = icon
                item.foregroundColorMapping = [.normal: isStar ? UDColor.colorfulYellow : UDColor.iconN1,
                                               .highlighted: isStar ? UDColor.colorfulYellow : UDColor.iconN1,
                                               .selected: isStar ? UDColor.colorfulYellow : UDColor.iconN1,
                                               [.selected, .highlighted]: isStar ? UDColor.colorfulYellow : UDColor.iconN1,
                                               .disabled: isStar ? UDColor.colorfulYellow : UDColor.iconN1]
                return
            }
        }
    }
    
    private func updateCustomNavigationBar(ratio: CGFloat) {
        guard navigationBar.alpha != ratio else { return }
        navigationBar.alpha = ratio
        statusBar.alpha = ratio
        let topSafeAreaHeight = view.safeAreaInsets.top
        let naviBarOffset = navigationBar.intrinsicHeight + topSafeAreaHeight
        navigationBar.snp.updateConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset * (1 - ratio))
        }
        statusBar.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(-naviBarOffset * (1 - ratio))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset * (1 - ratio))
        }
    }

    private func showCoverNavigationBar() {
        if !coverNavigationBarIsShow {
            coverNavigationBarIsShow = true
            self.coverNavigationBar.isHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.coverNavigationBar.alpha = 1
            })
        }
    }

    private func hideCoverNavigationBar() {
        if coverNavigationBarIsShow {
            coverNavigationBarIsShow = false
            UIView.animate(withDuration: 0.25, animations: {
                self.coverNavigationBar.alpha = 0
            }, completion: { _ in
                if !self.coverNavigationBarIsShow {
                    self.coverNavigationBar.isHidden = true
                }
            })
        }
    }

    private func gotoWikiContainer(wikiNodeMeta: WikiNodeMeta,
                                   treeContext: WikiTreeContext?,
                                   extraInfo: [AnyHashable: Any],
                                   from: UIViewController) {
        let wikiContainerVC = WikiRouter.gotoWikiDetail(wikiNodeMeta,
                                                        userResolver: userResolver,
                                                        extraInfo: extraInfo,
                                                        fromVC: from,
                                                        treeContext: treeContext)
        guard let vc = wikiContainerVC else { return }
        vc.wikiNodeChanged = { [weak self] wikiToken, treeContext in
            guard let self = self else { return }
            if let treeContext = treeContext {
                // 从目录树内切换到某篇 wiki 走 treeContext 同步场景
                self.viewModel.treeViewModel.syncWithContextInput.accept(treeContext)
            } else {
                // 从搜索结果跳转到某篇 wiki，走通过 token 定位场景
                self.viewModel.treeViewModel.focusByWikiTokenInput.accept(wikiToken)
            }
        }
    }

    // search
    private func showSearchView() {
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let spaceID = viewModel.treeViewModel.spaceID
        let searchController = factory.createWikiTreeSearchController(spaceID: spaceID, delegate: self)
        navigationController?.pushViewController(searchController, animated: false)
    }

    private func aiServiceEnabled() -> Bool {
        guard let aiService = try? Container.shared.resolve(assert: CCMAIService.self),
              aiService.enable.value else {
            DocsLogger.warning("MyAIService is nil")
            return false
        }
        return true
    }
}

extension WikiTreeCoverViewController: WikiTreeSearchDelegate {
    func searchControllerDidClickCancel(_ controller: UIViewController) {
        controller.navigationController?.popViewController(animated: false)
    }
    func searchController(_ controller: UIViewController, didClick item: WikiSearchResultItem) {
        guard case let .wikiNode(node) = item else { return }
        gotoWikiContainer(wikiNodeMeta: node,
                          treeContext: nil,
                          extraInfo: ["from": WikiStatistic.ClientOpenSource.pages.rawValue],
                          from: controller)
        // 更新目录树
        viewModel.treeViewModel.focusByWikiTokenInput.accept(node.wikiToken)
    }
}

extension WikiTreeCoverViewController {

    func treeTableViewDidScroll(_ scrollView: UIScrollView) {
        // 下拉封面放大
        if scrollView.contentOffset.y <= 0 {
            let increasedY = -scrollView.contentOffset.y
            let newHeight = coverHeight + increasedY
            coverView.imageBackgroundView.frame = CGRect(x: 0, y: scrollView.contentOffset.y, width: self.view.frame.width, height: newHeight)
        }
        // 导航栏显示隐藏逻辑
        let endY = wikiTreeHeaderViewHeight / 2
        let isFullScreen: Bool = scrollView.contentSize.height >= self.view.bounds.height
        if scrollView.contentOffset.y < 20 {
            showCoverNavigationBar()
            updateCustomNavigationBar(ratio: 0)
            let bottomInset = view.safeAreaInsets.bottom + 48 /*创建按钮高度*/ + 16 /*创建按钮底部偏移量*/
            scrollView.contentInset = .init(top: 0,
                                            left: 0,
                                            bottom: bottomInset,
                                            right: 0)
        }
        if scrollView.contentOffset.y >= 20 && scrollView.contentOffset.y <= endY {
            hideCoverNavigationBar()
            let ratio = isFullScreen ? ((scrollView.contentOffset.y - 20) / (endY - 20)) : 0
            updateCustomNavigationBar(ratio: ratio)
            isDefaultStatusBar = false
        }
        if scrollView.contentOffset.y > endY {
            let ratio: CGFloat = isFullScreen ? 1 : 0
            updateCustomNavigationBar(ratio: ratio)
            isDefaultStatusBar = true
            if isFullScreen {
                let bottomInset = view.safeAreaInsets.bottom + 48 /*创建按钮高度*/ + 16 /*创建按钮底部偏移量*/
                scrollView.contentInset = .init(top: self.navigationBar.bounds.height + self.view.safeAreaInsets.top,
                                                left: 0,
                                                bottom: bottomInset,
                                                right: 0)
            }
        }
    }
}

// Keyboard Show/Hide event
extension WikiTreeCoverViewController {
    func setupKeyboardMonitor() {
        guard SKDisplay.pad else { return }
        keyboard.on(event: .willShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .willHide) { [weak self] opt in
            self?.resetCreateButton(animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            self?.resetCreateButton(animationDuration: nil)
        }
        keyboard.start()
    }

    func updateCreateButtonIfNeed(keyboardFrame: CGRect, animationDuration: Double?) {
        let safeAreaViewFrame = view.safeAreaLayoutGuide.layoutFrame
        let buttonX = safeAreaViewFrame.maxX - 16 - 48
        let buttonY = safeAreaViewFrame.maxY - 16 - 48
        let originButtonFrame = CGRect(x: buttonX, y: buttonY, width: 48, height: 48)
        let buttonFrameOnWindow = view.convert(originButtonFrame, to: nil)
        let accessoryViewHeight = UIResponder.sk.currentFirstResponder?.inputAccessoryView?.frame.height ?? 0
        let keyboardMinY = keyboardFrame.minY - accessoryViewHeight
        if buttonFrameOnWindow.intersects(keyboardFrame), keyboardMinY > buttonFrameOnWindow.minY {
            // 仅当键盘与创建按钮有交集，且键盘高度不足以完全遮挡创建按钮时，抬高创建按钮的高度
            let inset = buttonFrameOnWindow.maxY - keyboardFrame.origin.y - accessoryViewHeight + 16
            let realInset = max(inset, 16)
            createButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(realInset)
            }
        } else {
            createButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            }
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    func resetCreateButton(animationDuration: Double?) {
        createButton.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}

extension WikiTreeCoverViewController: TreeViewRouter {
    func treeView(_ treeView: TreeView, openURL url: URL) {
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.userResolver.navigator.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: self, animated: true)
            }
        } else {
            userResolver.navigator.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: self, animated: true)
        }
    }
}
