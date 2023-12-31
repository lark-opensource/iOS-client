//
//  WikiHomePageViewController.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/22.
//
// swiftlint:disable file_length

import UIKit
import LarkUIKit
import SnapKit
import EENavigator
import ESPullToRefresh
import SKCommon
import RxSwift
import RxCocoa
import SKSpace
import SKResource
import SKUIKit
import SKFoundation
import Lottie
import UniverseDesignToast
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

extension WikiHomePageViewController: CustomHomeWrappee {
    public var scrollView: UIScrollView? {
        return self.recentTableView
    }

    public var navigationBarItems: [SKBarButtonItem] {
        let searchItem = SKBarButtonItem(image: UDIcon.searchOutlined,
                                         style: .plain,
                                         target: self,
                                         action: #selector(didClickSearchItem))
        searchItem.id = .search
        if UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
            let createItem = SKBarButtonItem(image: UDIcon.moreAddOutlined,
                                             style: .plain,
                                             target: self,
                                             action: #selector(didClickCreateItem(sourceView:)))
            createItem.id = .add
            return [createItem, searchItem]
        } else {
            return [searchItem]
        }
    }

    public var scrollViewShouldScrollToTop: Observable<Bool>? {
        return viewModel.tableViewShouldScrollToTop
    }

    public var createButton: UIButton? {
        if UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
            return nil
        }
        return self.innerCreateButton
    }
}
// swiftlint:disable type_body_length
open class WikiHomePageViewController: BaseViewController, UITableViewDragDelegate {
    public struct NavigationBarDependency {
        let navigationBarHeight: CGFloat
        let shouldShowCustomNaviBar: Bool
        let shouldShowNetworkBanner: Bool

        public init(navigationBarHeight: CGFloat,
                    shouldShowCustomNaviBar: Bool,
                    shouldShowNetworkBanner: Bool) {
            self.navigationBarHeight = navigationBarHeight
            self.shouldShowCustomNaviBar = shouldShowCustomNaviBar
            self.shouldShowNetworkBanner = shouldShowNetworkBanner
        }

        // 提供默认值，普通导航栏高度
        static public let `default` = NavigationBarDependency(navigationBarHeight: 44,
                                                              shouldShowCustomNaviBar: true,
                                                              shouldShowNetworkBanner: true)
    }

    public static var wikiHomePageTitle: String {
        return BundleI18n.SKResource.Doc_Wiki_Home_Title
    }

    private lazy var networkBannerView: NetInterruptTipView = {
        return NetInterruptTipView.defaultView()
    }()

    private lazy var refreshAnimator: WikiHomePageRefreshAnimator = {
        let refreshView = WikiHomePageRefreshAnimator(frame: .zero)
        return refreshView
    }()

    private lazy var recentTableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.register(WikiHomePageTableViewCell.self, forCellReuseIdentifier: WikiHomePageCellIdentifier.recentCellReuseIdentifier.rawValue)
        view.register(WikiUploadCell.self, forCellReuseIdentifier: WikiHomePageCellIdentifier.uploadCellReuseIdentifier.rawValue)
        view.register(WikiWorkSpaceCell.self, forCellReuseIdentifier: WikiHomePageCellIdentifier.wikiSpaceListIdentifier.rawValue)
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.tableHeaderView = UIView(frame: .zero)
        view.tableFooterView = UIView(frame: .zero)
        view.dataSource = viewModel
        view.delegate = viewModel
        view.dragDelegate = self
        return view
    }()

    public lazy var innerCreateButton: UIButton = {
        let btn = SKCreateButton()
        btn.addTarget(self, action: #selector(didClickCreateItem(sourceView:)), for: .touchUpInside)
        return btn
    }()

    private lazy var spaceHeaderView: WikiHomePageSpaceView = {
        let view = WikiHomePageSpaceView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 110),
                                         cellIdentifier: WikiHomePageCellIdentifier.spaceCellReuseIdentifier.rawValue,
                                         placeHolderCellIdentifier: WikiHomePageCellIdentifier.spacePlaceHolderCellReuseIdentifier.rawValue,
                                         isV2: viewModel.isV2)
        view.spaceCollectionViewDelegate = viewModel
        view.spaceCollectionViewDataSource = viewModel
        view.setupClickHandler { [weak self] in
            self?.viewModel.didClickAllSpaces()
        }
        return view
    }()
    
    private lazy var uploadHelper = WikiSelectFileHelper(hostViewController: self, triggerLocation: .wikiHome)

    private let viewModel: WikiHomePageViewModelProtocol
    private let navigationBarDependency: NavigationBarDependency
    private let params: [AnyHashable: Any]?
    private var isFirstLoad = true
    private var createButtonFrame: CGRect?
    private let bag = DisposeBag()
    var magicRegister: FeelGoodRegister?
    private var isOpenFinish = false

    public override var isLoggingNavigationBarViewDelegated: Bool { true } // 代理给了 CustomHomeWrapper 做埋点
    public override var commonTrackParams: [String: String] {
        [
            "module": "wiki_home",
            "sub_module": "none"
        ]
    }
    
    public let userResolver: UserResolver
    private let openWikiHomeWhenClosedWikiTree: Bool

    public init(userResolver: UserResolver,
                params: [AnyHashable: Any]?,
                navigationBarDependency: NavigationBarDependency = .default,
                openWikiHomeWhenClosedWikiTree: Bool = false) {
        viewModel = WikiHomePageViewModelV2(userResolver: userResolver)
        self.userResolver = userResolver
        self.navigationBarDependency = navigationBarDependency
        self.params = params
        self.openWikiHomeWhenClosedWikiTree = openWikiHomeWhenClosedWikiTree
                
        super.init(nibName: nil, bundle: nil)
        viewModel.ui = self
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("wiki.HomePageViewController deinit")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupFeelGood()
        setupUI()
        viewModel.actionOutput.drive(onNext: { [weak self] action in
            guard let self else { return }
            self.handleViewModelAction(action)
        }).disposed(by: bag)
        reportOpenEvent()
    }

    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateNetworkBanner(isReachable: viewModel.isReachable)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.reloadTableHeaderView()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateEmptyPlaceHolderViewHeight()
        viewModel.didAppear(isFirstTime: isFirstLoad)
        isFirstLoad = false
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .wiki, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markStart(scene: scene)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .wiki, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markEnd(scene: scene)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.reloadTableHeaderView()
        }
    }

    /// 点击创建按钮事件，Lark 中需要绑定到 Lark 的导航栏按钮
    @objc
    public func didClickCreateItem(sourceView: UIView) {
        viewModel.didClickCreate(sourceView: sourceView)
        WikiStatistic.homePageClickCreate()
        WikiStatistic.createNewView()
        WikiStatistic.clickHomeView(click: .create, target: DocsTracker.EventType.wikiCreateNewView.rawValue)
    }

    /// 上报点击搜索按钮事件，Lark 中点击搜索按钮后需要主动调用
    public func reportOpenSearchEvent() {
        WikiStatistic.homePageClickSearch()
    }

    // 子类会 override，所以写在声明函数体内
    open func updateCreateBarItem(isEnabled: Bool) {
        guard let createItem = navigationBar.trailingBarButtonItems.first else {
            DocsLogger.error("wiki.home --- failed to get create bar button item")
            return
        }
        createItem.isEnabled = isEnabled
        navigationBar.trailingBarButtonItems = navigationBar.trailingBarButtonItems
    }

    // MARK: - Privete Functions
    private var topOffset: CGFloat {
        return navigationBarDependency.navigationBarHeight + UIApplication.shared.statusBarFrame.height
    }
    
    // make emptyView center
    private var emptyViewOffset: CGFloat {
        return 60
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        if navigationBarDependency.shouldShowCustomNaviBar {
            navigationBar.title = WikiHomePageViewController.wikiHomePageTitle
            let searchItem = SKBarButtonItem(image: UDIcon.searchOutlined,
                                             style: .plain,
                                             target: self,
                                             action: #selector(didClickSearchItem))
            searchItem.id = .search
            let createItem = SKBarButtonItem(image: UDIcon.moreAddOutlined,
                                             style: .plain,
                                             target: self,
                                             action: #selector(didClickCreateItem(sourceView:)))
            createItem.id = .add
            navigationBar.trailingBarButtonItems = [createItem, searchItem]
        } else {
            navigationBar.isHidden = true
        }

        if self.navigationBarDependency.shouldShowNetworkBanner {
            view.addSubview(networkBannerView)
            let bannerHeight: CGFloat
            if viewModel.isReachable {
                bannerHeight = 0
                networkBannerView.isHidden = true
            } else {
                let containerSize = CGSize(width: view.frame.width, height: .infinity)
                bannerHeight = networkBannerView.sizeThatFits(containerSize).height
            }
            networkBannerView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(topOffset)
                make.height.equalTo(bannerHeight)
            }
            view.addSubview(recentTableView)
            recentTableView.snp.makeConstraints { make in
                make.top.equalTo(networkBannerView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            view.addSubview(recentTableView)
            recentTableView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(topOffset)
                make.left.right.bottom.equalToSuperview()
            }
        }
        recentTableView.tableHeaderView = spaceHeaderView
        setupRecentPullRefresher(isReachable: viewModel.isReachable)
        setupRecentScrollFooter()
    }

    private func reloadTableHeaderView() {
        self.spaceHeaderView.spaceCollectionView.collectionViewLayout.invalidateLayout()
        self.view.layoutIfNeeded()
        self.spaceHeaderView.reloadSpaceData(count: self.viewModel.headerSpacesCount, isLoading: false)
        if viewModel.headerSpacesCount == 0, viewModel.isV2 {
            self.recentTableView.tableHeaderView = nil
        } else {
            self.recentTableView.tableHeaderView = self.spaceHeaderView
        }
    }

    private func setupRecentPullRefresher(isReachable: Bool) {
        if isReachable {
            recentTableView.es.addPullToRefreshOfDoc(animator: refreshAnimator) { [weak self] in
                self?.viewModel.refresh()
            }
        } else {
            recentTableView.es.removeRefreshHeader()
        }
    }

    private func setupRecentScrollFooter() {
        recentTableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadMoreList()
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func handleViewModelAction(_ action: WikiHomeAction) {
        switch action {
        case .getListError(let error):
            DocsLogger.error("wki.home --- get list error", error: error)
        case let .updateHeaderList(count, isLoading):
            spaceHeaderView.reloadSpaceData(count: count, isLoading: isLoading)
            if count == 0, viewModel.isV2 {
                recentTableView.tableHeaderView = nil
            } else {
                recentTableView.tableHeaderView = spaceHeaderView
            }
            updateEmptyPlaceHolderViewHeight()
            if isLoading {
                updateCreateBarItem(isEnabled: false)
            } else {
                updateCreateBarItem(isEnabled: count != 0)
            }
        case .updateList:
            //首次加载完成后上报
            if !isOpenFinish {
                isOpenFinish = true
                WikiPerformanceTracker.shared.reportOpenFinish()
            }
            recentTableView.reloadData()
        case .stopPullToRefresh:
            stopPullToRefresh()
        case .stopLoadMoreList(let hasMore):
            recentTableView.es.stopLoadingMore()
            if let hasMore = hasMore {
                recentTableView.footer?.noMoreData = !hasMore
                recentTableView.footer?.isHidden = !hasMore
            }
        case .updateNetworkState(let isReachable):
            updatenavigationBars(isReachable: isReachable)
            updateNetworkBanner(isReachable: isReachable)
            updateSpaceCells()
            updateRecentCells(isReachable: isReachable)
            setupRecentPullRefresher(isReachable: isReachable)
            updateCreateButtonStatus(enable: isReachable)
        case .jumpToWikiTree(let space):
            let viewModel = WikiTreeCoverViewModel(userResolver: userResolver, space: space)
            let treeVC = WikiTreeCoverViewController(userResolver: userResolver, viewModel: viewModel, showWikiHomeWhenClosed: openWikiHomeWhenClosedWikiTree)
            setupTreePerformanceRecord(wikiToken: "")
            userResolver.navigator.push(treeVC, from: self)
        case .updatePlaceHolderView(let shouldShow):
            updateEmptyPlaceHolderView(shouldShow: shouldShow)
        case let .jumpToCreateWikiPicker(sourceView):
            jumpToCreateWikiPicker(sourceView: sourceView)
        case let .jumpToUploadList(mountToken):
            // 首页没有container_id
            let params: [String: Any] = ["container_id": "none", "container_type": "wiki"]
            DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                .showUploadListViewController(sourceViewController: self,
                                              folderToken: mountToken,
                                              scene: .workspace,
                                              params: params)
        case let .present(vc):
            userResolver.navigator.present(vc, from: self)
        case let .scrollHeaderView(index):
            spaceHeaderView.spaceCollectionView.scrollToItem(at: index, at: .left, animated: true)
        }
    }

    private func stopPullToRefresh() {
        recentTableView.es.stopPullToRefresh()
    }

    private func updatenavigationBars(isReachable: Bool) {
        let items = navigationBar.trailingBarButtonItems.map({ (item) -> SKBarButtonItem in
            item.isEnabled = isReachable
            return item
        })
        navigationBar.trailingBarButtonItems = items
        updateCreateBarItem(isEnabled: isReachable)
    }

    private func updateNetworkBanner(isReachable: Bool) {
        guard navigationBarDependency.shouldShowNetworkBanner else { return }
        var bannerHeight: CGFloat = 0
        if !isReachable {
            let containerSize = CGSize(width: view.frame.width, height: .infinity)
            bannerHeight = networkBannerView.sizeThatFits(containerSize).height
        }
        DocsLogger.info("wiki.home --- network banner height updated", extraInfo: ["isReachable": isReachable, "bannerHeight": bannerHeight, "topOffset": topOffset])
        networkBannerView.isHidden = isReachable
        networkBannerView.snp.updateConstraints { (make) in
            make.height.equalTo(bannerHeight)
        }
    }

    private func updateSpaceCells() {
        spaceHeaderView.spaceCollectionView.reloadData()
    }

    private func updateRecentCells(isReachable: Bool) {
        recentTableView.reloadData()
    }

    private func updateEmptyPlaceHolderViewHeight() {
        guard let placeHolderView = recentTableView.tableFooterView else { return }
        var viewHeight = view.frame.height
        viewHeight -= refreshAnimator.frame.height
        viewHeight -= topOffset
        viewHeight -= spaceHeaderView.frame.height
        viewHeight -= viewModel.heightOfHeaderSection
        viewHeight -= self.view.safeAreaInsets.bottom
        viewHeight -= emptyViewOffset
        placeHolderView.frame.size.height = viewHeight
        recentTableView.tableFooterView = placeHolderView
    }

    private func updateEmptyPlaceHolderView(shouldShow: Bool) {
        recentTableView.footer?.stopRefreshing()
        guard shouldShow else {
            recentTableView.tableFooterView = nil
            return
        }
        recentTableView.footer?.noMoreData = true
        recentTableView.footer?.isHidden = true
        let description = viewModel.emptyListDescription
        let placeHolderView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                          description: .init(descriptionText: description),
                                          imageSize: 100,
                                          type: .noSearchResult,
                                          labelHandler: nil,
                                          primaryButtonConfig: nil,
                                          secondaryButtonConfig: nil))
        placeHolderView.useCenterConstraints = true
        recentTableView.tableFooterView = placeHolderView
        updateEmptyPlaceHolderViewHeight()
    }
    
    private func updateCreateButtonStatus(enable: Bool) {
        innerCreateButton.isEnabled = enable
    }

    @objc
    private func didClickSearchItem() {
        if viewModel.isV2 {
            guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
                DocsLogger.error("can not get WorkspaceSearchFactory")
                return
            }

            let controller = factory.createWikiSearchController()
            userResolver.navigator.push(controller, from: self)
        } else {
            spaceAssertionFailure()
            DocsLogger.error("should not go here")
        }
        reportOpenSearchEvent()
    }

    private func showPickerForCreate(type: DocsType, templateModel: TemplateModel? = nil) {
        let tracker = WorkspacePickerTracker(actionType: .createFile, triggerLocation: .wikiHome)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_CreateIn_Header_Mob,
                                           action: .createWiki,
                                           entrances: .wikiAndSpace,
                                           tracker: tracker) { [weak self] location, picker in
            guard let self = self else { return }
            switch location {
            case let .folder(location):
                self.confirmCreateInSpace(type: type, location: location, templateModel: templateModel, picker: picker)
            case let .wikiNode(location):
                self.confirmCreate(type: type, spaceID: location.spaceID, wikiToken: location.wikiToken, template: templateModel, picker: picker)
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        userResolver.navigator.present(picker, from: self)
    }

    private func jumpToCreateWikiPicker(sourceView: UIView) {
        let isReachable = viewModel.isReachable
        var items = [WikiCreateItem]()
        let wikiCreateDocxEnable = LKFeatureGating.createDocXEnable
        if wikiCreateDocxEnable {
            items.append(
                .docX(enable: isReachable) { [weak self] in
                    guard isReachable else { return }
                    WikiStatistic.clickCreateNewView(fileType: DocsType.docX.name)
                    self?.showPickerForCreate(type: .docX)
                }
            )
        } else {
            items.append(
                .docs(enable: isReachable) { [weak self] in
                    guard isReachable else { return }
                    WikiStatistic.clickCreateNewView(fileType: DocsType.doc.name)
                    self?.showPickerForCreate(type: .doc)
                }
            )
        }

        items.append(
            .sheet(enable: isReachable) { [weak self] in
                guard isReachable else { return }
                WikiStatistic.clickCreateNewView(fileType: DocsType.sheet.name)
                self?.showPickerForCreate(type: .sheet)
            }
        )
        
        if UserScopeNoChangeFG.PXR.baseWikiSpaceHasSurveyEnable, let template = TemplateModel.createBlankSurvey(templateSource: .wikiHomepageLarkSurvey) {
            ///多维表格
            if LKFeatureGating.bitableEnable {
                items.append(
                    .bitable(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.bitable.name)
                        self?.showPickerForCreate(type: .bitable)
                    }
                )
            }
            ///问卷入口
            let wikiSurveyItem = WikiCreateItem.bitableSurvey(enable: isReachable){ [weak self] in
                guard isReachable else { return }
                let track:CreateNewClickParameter = .wikiHomePageNewSurvey
                WikiStatistic.clickCreateNewViewByTemplate(click: track.clickValue, target: track.targetValue)
                self?.showPickerForCreate(type: .bitable, templateModel: template)
            }
            items.append(wikiSurveyItem)
            ///思维笔记
            if LKFeatureGating.mindnoteEnable {
                items.append(
                    .mindnote(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.mindnote.name)
                        self?.showPickerForCreate(type: .mindnote)
                    }
                )
            }
        } else {
            ///思维笔记
            if LKFeatureGating.mindnoteEnable {
                items.append(
                    .mindnote(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.mindnote.name)
                        self?.showPickerForCreate(type: .mindnote)
                    }
                )
            }
            ///多维表格
            if LKFeatureGating.bitableEnable {
                items.append(
                    .bitable(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.bitable.name)
                        self?.showPickerForCreate(type: .bitable)
                    }
                )
            }
        }
        
        if !UserScopeNoChangeFG.LJY.disableCreateDoc, wikiCreateDocxEnable {
            items.append(
                .docs(enable: isReachable) { [weak self] in
                    guard isReachable else { return }
                    WikiStatistic.clickCreateNewView(fileType: DocsType.doc.name)
                    self?.showPickerForCreate(type: .doc)
                }
            )
        }

        let showOffLineIntercept = { [weak self] in
            guard let self = self else { return }
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet,
                                    on: self.view.window ?? self.view)
        }
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let showAdminIntercept: () -> Void
        let adminEnable: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: "", type: .file, operation: .upload, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            adminEnable = response.allow
            showAdminIntercept = { [weak self] in
                guard let self else { return }
                response.didTriggerOperation(controller: self)
            }
        } else {
            let validateResult = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
            showAdminIntercept = { [weak self] in
                guard let self = self else { return }
                switch validateResult.validateSource {
                case .fileStrategy:
                    CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
                case .securityAudit:
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                        on: self.view.window ?? self.view)
                case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                    DocsLogger.info("unknown type or dlp type")
                }
            }
            adminEnable = validateResult.allow
        }
        items.append(
            .uploadImage(enable: adminEnable && isReachable) { [weak self] in
                guard let self = self else { return }
                guard isReachable else {
                    showOffLineIntercept()
                    return
                }
                guard adminEnable else {
                    showAdminIntercept()
                    return
                }
                WikiStatistic.clickCreateNewView(fileType: "upload_picture")
                self.uploadHelper.selectImagesWithPicker(allowInSpace: true)
                let biz = CreateNewClickParameter.bizParameter(for: "", module: .wikiHome)
                DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "picture"), bizParms: biz, mountPoint: "wiki")
                DocsTracker.isSpaceOrWikiUpload = true
            }
        )

        items.append(
            .uploadFile(enable: adminEnable && isReachable) { [weak self] in
                guard let self = self else { return }
                guard isReachable else {
                    showOffLineIntercept()
                    return
                }
                guard adminEnable else {
                    showAdminIntercept()
                    return
                }
                WikiStatistic.clickCreateNewView(fileType: "upload_file")
                self.uploadHelper.selectFileWithPicker(allowInSpace: true)
                let biz = CreateNewClickParameter.bizParameter(for: "", module: .wikiHome)
                DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "file"), bizParms: biz, mountPoint: "wiki")
                DocsTracker.isSpaceOrWikiUpload = true
            }
        )

        let createVC = WikiCreateViewController(items: items)
        createVC.setupPopover(sourceView: sourceView, direction: [.up, .down])
        createVC.dismissalStrategy = [.larkSizeClassChanged]
        userResolver.navigator.present(createVC, from: self)
    }

    private func confirmCreateInSpace(type: DocsType, location: SpaceFolderPickerLocation, templateModel: TemplateModel? = nil, picker: UIViewController) {
        guard location.canCreateSubNode else {
            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantNew_Tooltip, on: picker.view.window ?? picker.view)
            return
        }
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_Wiki_CreateDialog,
                            on: picker.view.window ?? picker.view,
                            disableUserInteraction: true)
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .docCreate, module: .wikiHome, ccmOpenSource: .wiki)
        let director = DocsCreateDirectorV2(type: type,
                                            ownerType: location.folderType.ownerType,
                                            name: nil,
                                            in: location.folderToken,
                                            trackParamters: trackParameters)
        director.makeSelfReferenced()
        director.handleRouter = false
        ///模版创建
        if let template = templateModel {
            var templateSource: TemplateCenterTracker.TemplateSource? = nil
            if let s = template.templateSource {
                templateSource = TemplateCenterTracker.TemplateSource(rawValue: s)
            }
            director.createByTemplate(templateObjToken: template.objToken , templateId: template.id, templateType: template.templateMainType, templateCenterSource: nil, templateSource: templateSource, statisticsExtra: nil) { [weak self] _, controller, _, _, error in
                guard let self = self else { return }

                UDToast.removeToast(on: picker.view.window ?? picker.view)
                if let error = error {
                    UDToast.showFailure(with: error.localizedDescription, on: picker.view.window ?? picker.view)
                    return
                }
                guard let controller = controller else { return }
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.userResolver.navigator.docs.showDetailOrPush(controller, wrap: LkNavigationController.self, from: self)
                }
            }
        } else {
            ///DocsType创建
            director.create { [weak self] _, controller, _, _, error in
                guard let self = self else { return }
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                if let error = error {
                    UDToast.showFailure(with: error.localizedDescription, on: picker.view.window ?? picker.view)
                    return
                }
                guard let controller = controller else { return }
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.userResolver.navigator.docs.showDetailOrPush(controller, wrap: LkNavigationController.self, from: self)
                }
            }
        }
    }

    private func confirmCreate(type: DocsType, spaceID: String, wikiToken: String, template: TemplateModel? = nil, picker: UIViewController) {
        WikiStatistic.createFromHomePage(docsType: type,
                                         targetWikiToken: wikiToken)
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_Wiki_CreateDialog,
                            on: picker.view.window ?? picker.view,
                            disableUserInteraction: true)
        WikiNetworkManager.shared.createNode(spaceID: spaceID,
                                             parentWikiToken: wikiToken,
                                             template: template,
                                             objType: type,
                                             synergyUUID: nil)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] newNode in
                guard let self = self else { return }
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                picker.dismiss(animated: true) {
                    WikiRouter.gotoWikiDetail(WikiNodeMeta(wikiToken: newNode.meta.wikiToken,
                                                           objToken: newNode.meta.objToken,
                                                           docsType: newNode.meta.objType,
                                                           spaceID: spaceID),
                                              userResolver: self.userResolver,
                                              extraInfo: ["from": "tab_create",
                                                            CCMOpenTypeKey: CCMOpenType.wikiCreateNew.trackValue],
                                              fromVC: self)
                    WikiStatistic.clickFileLocationSelect(targetSpaceId: spaceID,
                                                          fileId: newNode.meta.objToken,
                                                          fileType: newNode.meta.objType.name,
                                                          filePageToken: newNode.meta.wikiToken,
                                                          viewTitle: .createFile,
                                                          originSpaceId: "none",
                                                          originWikiToken: "none",
                                                          isShortcut: false,
                                                          triggerLocation: .wikiHome,
                                                          targetModule: .wiki,
                                                          targetFolderType: nil)
                }
            } onError: { error in
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                DocsLogger.error("\(error)")
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                UDToast.showFailure(with: error.addErrorDescription, on: picker.view.window ?? picker.view)
            }
            .disposed(by: bag)
    }

    private func setupFeelGood() {
        magicRegister = FeelGoodRegister(type: .wikiHome) { [weak self] in return self }
    }

    // UITableViewDragDelegate
    public func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard SceneManager.shared.supportsMultipleScenes else { return [] }
        let itemType = viewModel.items[indexPath.item]
        switch itemType {
        case .upload, .wikiSpace:
            return []
        }
    }

    public func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let params = UIDragPreviewParameters()
        params.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 12)
        return params
    }
}

// MARK: - WikiStatistic
extension WikiHomePageViewController {
    private func reportOpenEvent() {
        let from = params?["from"] as? String ?? "other"
        WikiStatistic.homePageEnterEvent(from: from)
    }

    private func setupTreePerformanceRecord(wikiToken: String) {
        WikiPerformanceRecorder.shared.clearAllData()
        let context = WikiPerformanceRecorder.RecordContext(
            event: .wikiOpenTreePerformance,
            stage: .total,
            wikiToken: wikiToken,
            source: .fullScreen,
            openType: .network,
            action: .openTree
        )
        WikiPerformanceRecorder.shared.wikiPerformanceRecordBegin(context: context)
    }
}

// MARK: - SearchBarDelegate
extension WikiHomePageViewController: SearchBarDelegate {
    public func searchBarDidClickCancel() {
        if navigationController != nil {
            if presentingViewController != nil {
                navigationController?.dismiss(animated: true, completion: nil)
            } else {
                navigationController?.popViewController(animated: true)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    public func searchContentDidChange(_ content: String) {
    }
}

extension WikiHomePageViewController: WikiHomePageUIDelegate {
    var isiPadRegularSize: Bool {
        SKDisplay.pad && isMyWindowRegularSize()
    }
}
