//
//  MyLibraryViewController.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/1/31.
//

import Foundation
import SKUIKit
import SKCommon
import SKFoundation
import SKResource
import RxSwift
import RxRelay
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import SKSpace
import LarkUIKit
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

class MyLibraryViewController: BaseViewController {
    
    private var treeView: TreeView?
    private let emptyView = MyLibraryEmptyView()
    private lazy var createButton = SKCreateButton()
    private lazy var disabledCreateMaskView = UIControl()
    private var uploadView: MyLibraryUploadView?
    // 文件选择
    private lazy var selectFileHelper = WikiSelectFileHelper(hostViewController: self, triggerLocation: .wikiTree)
    
    private var viewModel: MyLibraryViewModel
    private let bag = DisposeBag()
    private var showUploadView = false
    private var showNoContentView = false
    private let uploadViewVisableRelay = BehaviorRelay(value: false)
    private let uploadViewItemRelay = BehaviorRelay<DriveStatusItem?>(value: nil)
    
    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: MyLibraryViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
        setupStorage()
        setupUI()
        setupCreateButton()
        bindUploadViewAction()
        setupBarItem()
        bindViewModelAction()
        viewModel.prepare()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let bottomInset = view.safeAreaInsets.bottom + 48 /*创建按钮高度*/ + 16 /*创建按钮底部偏移量*/
        treeView?.tableView.contentInset = UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: bottomInset,
                                                       right: 0)
    }
    
    private func setupUI() {
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        emptyView.isHidden = true
    }
    
    private func setupTreeView() {
        guard let treeView else {
            spaceAssertionFailure("set up treeview should get spaceId compeleted")
            return
        }
        view.addSubview(treeView)
        // 防止创建按钮与treeview的最后一行侧滑按钮布局遮挡
        let bottomInset = view.safeAreaInsets.bottom + 48 /*创建按钮高度*/ + 16 /*创建按钮底部偏移量*/
        treeView.tableView.contentInset = UIEdgeInsets(top: 0,
                                                       left: 0,
                                                       bottom: bottomInset,
                                                       right: 0)
        treeView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        viewModel.initailTreeData()
    }
    
    private func bindUploadViewAction() {
        viewModel.uploadState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] item in
                guard let self else { return }
                if let item {
                    if !self.showUploadView {
                        self.showUploadView = true
                        self.uploadViewVisableRelay.accept(true)
                    }
                    self.uploadViewItemRelay.accept(item)
                } else {
                    self.showUploadView = false
                    self.uploadViewVisableRelay.accept(false)
                }
            })
            .disposed(by: bag)
    }
    
    private func setUploadView() {
        uploadView = MyLibraryUploadView(clickHandler: { [weak self] in
            guard let self, let spaceId = self.viewModel.spaceId else { return }
            let encrySpaceID = DocsTracker.encrypt(id: spaceId)
            let params: [String: Any] = ["container_id": encrySpaceID, "container_type": "wiki"]
            DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                .showUploadListViewController(sourceViewController: self,
                                              folderToken: self.viewModel.mountToken,
                                              scene: .workspace,
                                              params: params)
        })
        
        uploadViewVisableRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] show in
            self?.updateUploadView(show: show)
        }).disposed(by: bag)
        
        uploadViewItemRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] item in
            guard let self, let item else { return }
            self.uploadView?.updateUploadView(item: item)
        }).disposed(by: bag)
    }
    
    private func updateUploadView(show: Bool) {
        if show {
            uploadView?.frame.size = CGSize(width: self.view.frame.width, height: 68)
            treeView?.tableView.tableHeaderView = uploadView
        } else {
            treeView?.tableView.tableHeaderView = nil
        }
        uploadView?.setNeedsLayout()
    }
    
    private func setupCreateButton() {
        view.addSubview(createButton)
        view.addSubview(disabledCreateMaskView)
        createButton.isHidden = false
        disabledCreateMaskView.isHidden = true
        disabledCreateMaskView.backgroundColor = .clear
        createButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.height.equalTo(48)
        }
        disabledCreateMaskView.snp.makeConstraints { make in
            make.edges.equalTo(createButton)
        }
        createButton.layer.cornerRadius = 24
        
        createButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.viewModel.treeViewModel?.createRootNodeInput.accept(self.createButton)
            }).disposed(by: bag)
        
        disabledCreateMaskView.rx.controlEvent(.touchUpInside).subscribe { [weak self] _ in
            guard let self else { return }
            UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_CM_MyLib_NewDoc_NA_Tooltip,
                                operationText: nil,
                                on: self.view.window ?? self.view)
        }.disposed(by: bag)
    }
    
    private func setupBarItem() {
        let searchItem = SKBarButtonItem(image: UDIcon.searchOutlined,
                                         style: .plain,
                                         target: self,
                                         action: #selector(searchWiki))
        searchItem.id = .search
        navigationBar.trailingBarButtonItems = [searchItem]
        // 等待目录树加载成功后再置为可点
        updateBarItemStatus(enable: false)
    }
    
    private func updateBarItemStatus(enable: Bool) {
        navigationBar.trailingBarButtonItems.forEach { item in
            item.isEnabled = enable
        }
    }
    
    // 数据库缓存设置
    private func setupStorage() {
        viewModel.userResolver.docs.wikiStorage?.loadStorageIfNeed()
    }
    
    // 跳转搜索页
    @objc
    private func searchWiki() {
        showSearchView()
        WikiStatistic.clickSearch(subModule: .wikiPages, source: .wikiPagesView, action: .searchButton)
    }
    
    private func showSearchView() {
        guard let spaceID = viewModel.spaceId else {
            spaceAssertionFailureWithoutLog("search button should get space id succeed change status enable")
            return
        }

        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let searchController = factory.createWikiTreeSearchController(spaceID: spaceID, delegate: self)
        navigationController?.pushViewController(searchController, animated: false)
    }
    
    private func bindViewModelAction() {
        viewModel.actionOutput.drive(onNext: { [weak self] action in
            guard let self else { return }
            self.handleViewModelAction(action: action)
        }).disposed(by: bag)
    }
    
    private func handleViewModelAction(action: MyLibraryAction) {
        switch action {
        case .getSpaceIdCompelete:
            guard let treeViewModel = self.viewModel.treeViewModel else {
                return
            }
            treeView = TreeView(dataBuilder: treeViewModel)
            treeView?.treeViewRouter = self
            bindWikiTreeAction()
            bindTreeViewLoadAction()
            setupTreeView()
            if !showNoContentView {
                // 非空文档库在数据加载成功后隐藏兜底页
                emptyView.isHidden = true
            }
            //setupCreateButton()
            setUploadView()
        case .showEmpty(let type):
            showEmptyViewIfNeed(type: type)
        case .createLibraryError:
            DocsLogger.error("wiki.my.library.vc --- create my library error")
        }
    }
    
    private func showEmptyViewIfNeed(type: MyLibraryAction.EmptyType) {
        switch type {
        case .loading:
            emptyView.showLoading()
        case .empty:
            emptyView.showEmpty()
            emptyView.configButton(type: .empty) { [weak self] button in
                guard let self else { return }
                self.viewModel.treeViewModel?.createRootNodeInput.accept(button)
            }
        case .error:
            emptyView.showError()
            emptyView.configButton(type: .error) { [weak self] _ in
                guard let self else { return }
                self.emptyView.showLoading()
                self.viewModel.prepare()
            }
        }
        emptyView.isHidden = false
        view.bringSubviewToFront(emptyView)
    }
    
    private func bindWikiTreeAction() {
        // 目录树UI展示出来，搜索按钮可用
        viewModel.treeViewModel?
            .dataModel
            .initialStateUpdated
            .drive(onNext: { [weak self] state in
                if case .success = state.cacheState {
                    self?.updateBarItemStatus(enable: true)
                }
            })
            .disposed(by: bag)
        
        viewModel.treeViewModel?
            .reloadFailedDriver
            .drive(onNext: { [weak self] error in
                guard let self else { return }
                if let wikiError = WikiErrorCode(rawValue: (error as NSError).code),
                   wikiError == .nodePermFailCode {
                    self.updateBarItemStatus(enable: false)
                }
                WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                        stage: .total,
                                                                        wikiToken: "",
                                                                        resultKey: .fail,
                                                                        resultCode: String((error as NSError).code))
            })
            .disposed(by: bag)
        
        viewModel.treeViewModel?
            .onClickNodeSignal
            .emit(onNext: { [weak self] meta, treeContext in
                guard let self = self else { return }
                let nodeMeta = WikiTreeNodeUtils.getWikiNodeMeta(treeMeta: meta)
                self.gotoWikiContainer(wikiNodeMeta: nodeMeta,
                                       treeContext: treeContext,
                                       extraInfo: [
                                        "from": WikiStatistic.ClientOpenSource.myLibrary.rawValue,
                                        CCMOpenTypeKey: CCMOpenType.wikiAll.trackValue,
                                        "action": WikiStatistic.ActionType.switchPage.rawValue
                                       ] as [AnyHashable: Any],
                                       from: self)
            })
            .disposed(by: bag)
        
        // 上传文件
        viewModel.treeViewModel?.onUploadSignal
            .emit(onNext: { [weak self] (token, isImage, action) in
                guard let self else { return }
                if isImage {
                    self.selectFileHelper.selectImages(wikiToken: token, completion: action)
                } else {
                    self.selectFileHelper.selectFile(wikiToken: token, completion: action)
                }
            })
            .disposed(by: bag)
        
        // 创建按钮无网置灰
        viewModel.treeViewModel?.reachabilityRelay
            .skip(1)
            .subscribe(onNext: {[weak self] isReachable in
                guard let self = self else { return }
                let offlineCanCreate = !isReachable
                if offlineCanCreate {
                    self.createButton.isEnabled = true
                    self.disabledCreateMaskView.isHidden = true
                } else {
                    self.createButton.isEnabled = isReachable
                    self.disabledCreateMaskView.isHidden = isReachable
                }
                
            })
            .disposed(by: bag)
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
                self.viewModel.treeViewModel?.syncWithContextInput.accept(treeContext)
            } else {
                // 从搜索结果跳转到某篇 wiki，走通过 token 定位场景
                self.viewModel.treeViewModel?.focusByWikiTokenInput.accept(wikiToken)
            }
        }
    }
    
    private func bindTreeViewLoadAction() {
        guard let treeViewModel = viewModel.treeViewModel else {
            spaceAssertionFailure("wiki.my.library --- use tree view model should get library id compeleted")
            return
        }
        let initialState = treeViewModel.dataModel.initialStateUpdated.asObservable()
        Observable.combineLatest(initialState,
                                 treeViewModel.treeStateRelay)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] reloadState, treeState in
                guard let self else { return }
                var reloadSucceed = false
                if case .success = reloadState.cacheState {
                    reloadSucceed = true
                }
                if case .success = reloadState.serverState {
                    reloadSucceed = true
                    // 创建按钮上屏
                    self.createButton.isHidden = false
                    self.updateBarItemStatus(enable: true)
                    WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                            stage: .total,
                                                                            wikiToken: "",
                                                                            resultKey: .success,
                                                                            resultCode: "0")
                }
                
                // 缓存或网络数据加载成功后判断是否展示空兜底页
                guard reloadSucceed else { return }
                // 空树展示创建兜底页
                if treeState.isEmptyTree {
                    if self.showNoContentView { return }
                    self.showEmptyViewIfNeed(type: .empty)
                    self.view.bringSubviewToFront(self.createButton)
                    self.view.bringSubviewToFront(self.disabledCreateMaskView)
                    self.showNoContentView = true
                } else {
                    self.emptyView.isHidden = true
                    self.showNoContentView = false
                }
            })
            .disposed(by: bag)
    }
}

class MyLibraryUploadView: UIView {
    let uploadView = DriveUploadContentView()
    var didClickUploadView: (() -> Void)
    
    init(clickHandler: @escaping (() -> Void)) {
        self.didClickUploadView = clickHandler
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(uploadView)
        uploadView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
            make.height.equalTo(48)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapUpload))
        uploadView.addGestureRecognizer(tap)
    }
    
    @objc
    private func didTapUpload() {
        didClickUploadView()
    }
    
    func updateUploadView(item: DriveStatusItem) {
        self.uploadView.update(item)
    }
}

extension MyLibraryViewController: TreeViewRouter {
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

extension MyLibraryViewController: WikiTreeSearchDelegate {
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
        viewModel.treeViewModel?.focusByWikiTokenInput.accept(node.wikiToken)
    }
}
