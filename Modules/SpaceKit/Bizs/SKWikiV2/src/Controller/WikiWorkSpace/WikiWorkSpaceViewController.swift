//
//  WikiWorkSpaceViewController.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/30.
//

import UIKit
import EENavigator
import SKResource
import SKCommon
import SKSpace
import SKFoundation
import SKUIKit
import RxSwift
import RxRelay
import UniverseDesignColor
import UniverseDesignEmpty
import SKWorkspace
import SpaceInterface
import SKInfra
import LarkContainer

public enum WikiWorkSpaceType {
    case browse
    case picker(config: WorkspacePickerConfig)
}

enum WorkSpaceCategory: String {
    case all
    case team
    case personal

    var desc: String {
        switch self {
        case .all:
            return BundleI18n.SKResource.CreationMobile_Wiki_All
        case .team:
            return BundleI18n.SKResource.CreationMobile_Wiki_Team
        case .personal:
            return BundleI18n.SKResource.CreationMobile_Wiki_Personal
        }
    }

    var typeValue: Int? {
        switch self {
        case .all:
            return nil
        case .team:
            return 0
        case .personal:
            return 1
        }
    }
}

class WikiWorkspaceCategoryView: UIView {
    var isSelected: Bool = false {
        didSet {
            if isSelected {
                bottomView.isHidden = false
                label.textColor = UIColor.ud.primaryContentDefault
            } else {
                bottomView.isHidden = true
                label.textColor = UIColor.ud.textCaption
            }
        }
    }
    var tapCallback: (() -> Void)?

    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        return label
    }()
    lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryContentDefault
        view.layer.cornerRadius = 2
        return view
    }()
    let category: WorkSpaceCategory
    init(category: WorkSpaceCategory) {
        self.category = category
        super.init(frame: .zero)
        clipsToBounds = true
        label.text = category.desc
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(10)
        }
        label.sizeToFit()
        addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.centerY.equalTo(self.snp.bottom)
            make.height.equalTo(4)
        }
        self.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        let ges = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(ges)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tap() {
        tapCallback?()
    }
}

class WikiWorkSpaceFilterView: UIStackView {

    var tapCallback: ((WorkSpaceCategory) -> Void)?
    var currentCategory: WorkSpaceCategory
    var categories: [WorkSpaceCategory]
    var categoryViews: [WikiWorkspaceCategoryView] = []

    init(categories: [WorkSpaceCategory],
         currentCategory: WorkSpaceCategory = .all) {
        self.categories = categories
        self.currentCategory = currentCategory
        super.init(frame: .zero)
        spacing = 0
        axis = .horizontal
        alignment = .leading
        distribution = .fillProportionally
        self.setupDataSource()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupDataSource() {
        categoryViews = categories.map({ (category: WorkSpaceCategory) -> WikiWorkspaceCategoryView in
            let view = WikiWorkspaceCategoryView(category: category)
            view.isSelected = category == .all ? true : false
            return view
        })
        categoryViews.forEach { view in
            view.tapCallback = { [weak self, weak view] in
                guard let self = self, let view = view else { return }
                let category = view.category
                guard self.currentCategory != category else { return }
                self.currentCategory = category
                view.isSelected = true
                self.categoryViews
                    .filter({ $0.category != category })
                    .forEach({ $0.isSelected = false })
                self.tapCallback?(category)
            }
            self.addArrangedSubview(view)
        }
    }
}

class WikiWorkSpaceViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let disposeBag = DisposeBag()
    private var pickerType: WikiWorkSpaceType
    private var spaces: [WorkSpaceCategory: WorkSpaceInfo]
    var currentCategory: WorkSpaceCategory = .all

    private let viewModel: WikiWorkSpaceViewModel
    private lazy var searchBar: DocsSearchBar = {
        let searchBar = DocsSearchBar()
        searchBar.tapBlock = { [weak self] _ in self?.onSelectSearch() }
        return searchBar
    }()
    private var searchController: UIViewController?
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UDColor.bgBody
        tableView.register(WikiWorkSpaceCell.self, forCellReuseIdentifier: tableViewIdentifier)
        tableView.separatorStyle = .none
        return tableView
    }()
    private lazy var splitLine: UIView = {
        let line = UIView()
        line.backgroundColor = UDColor.lineDividerDefault
        return line
    }()
    private lazy var stackView = WikiWorkSpaceFilterView(categories: [.all, .team, .personal])
    private let tableViewIdentifier = "wiki.workspace"
    private let loadingView = DocsUDLoadingImageView()
    private var isReachable = true
    lazy private var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Wiki_Favorited_None),
                                                  imageSize: 100,
                                                  type: .noSearchResult,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        return emptyView
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         spaces: [WorkSpaceCategory: WorkSpaceInfo],
         pickerType: WikiWorkSpaceType) {
        self.userResolver = userResolver
        self.spaces = spaces
        self.pickerType = pickerType
        viewModel = WikiWorkSpaceViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func refreshLeftBarButtons() {
        super.refreshLeftBarButtons()
        let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
        if self.presentingViewController != nil
            && !hasBackPage
            && !itemComponents.contains(closeButtonItem) {
            self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        _setupUI()
        _observeNetwork()
        viewModel.bindAction = { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingView.isHidden = true
                self.loadingView.removeFromSuperview()
                self.handleViewModelAction(action)
            }
        }
        //网络请求同步
        if spaces.isEmpty {
            viewModel.fetchData(with: .all, lastLabel: "")
            loadingView.isHidden = false
            self.view.addSubview(loadingView)
            loadingView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(self.splitLine.snp.bottom)
            }
        }
        reportViewEvent()
    }

    private func _setupUI() {
        title = BundleI18n.SKResource.Doc_Wiki_Home_WorkspaceTitle
        loadingView.backgroundColor = UDColor.bgBody
        setupSearchBarTitle()
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(6)
            make.height.equalTo(32)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        if LKFeatureGating.wikiNewWorkspace {
            view.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(6)
                make.height.equalTo(44)
                make.top.equalTo(searchBar.snp.bottom).offset(12.5)
            }
            stackView.tapCallback = { [weak self] category in
                guard let self = self else { return }
                self.currentCategory = category
                if self.spaces[category] != nil {
                    self.reload()
                } else {
                    self.view.addSubview(self.loadingView)
                    self.loadingView.isHidden = false
                    self.loadingView.snp.makeConstraints { (make) in
                        make.left.right.bottom.equalToSuperview()
                        make.top.equalTo(self.splitLine.snp.bottom)
                    }
                    self.viewModel.fetchData(with: category, lastLabel: "")
                }
            }

            view.addSubview(splitLine)
            splitLine.snp.makeConstraints { (make) in
                make.height.equalTo(0.5)
                make.top.equalTo(stackView.snp.bottom)
                make.left.right.equalToSuperview()
            }

        } else {
            view.addSubview(splitLine)
            splitLine.snp.makeConstraints { (make) in
                make.height.equalTo(0.5)
                make.top.equalTo(searchBar.snp.bottom).offset(12.5)
                make.left.right.equalToSuperview()
            }
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(splitLine.snp.bottom)
        }
        tableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let self = self else { return }
            let lastLabel = self.spaces[self.currentCategory]?.lastLabel ?? ""
            self.viewModel.fetchData(with: self.currentCategory, lastLabel: lastLabel)
        }
        if let hasMore = spaces[currentCategory]?.hasMore {
            self.tableView.footer?.noMoreData = !hasMore
            self.tableView.footer?.isHidden = !hasMore
        }
    }

    private func setupSearchBarTitle() {
        searchBar.textField.placeholder = BundleI18n.SKResource.Doc_Wiki_SearchWorkspace
    }

    private func _observeNetwork() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (networkType, isReachable) in
            DocsLogger.debug("Current networkType is \(networkType)")
            self?.isReachable = isReachable
            self?.tableView.reloadData()
            self?.showBottomLoadMoreView(isReachable)
        }
    }
    
    private func showBottomLoadMoreView(_ show: Bool) {
        if show {
            tableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
                guard let self = self else { return }
                let lastLabel = self.spaces[self.currentCategory]?.lastLabel ?? ""
                self.viewModel.fetchData(with: self.currentCategory, lastLabel: lastLabel)
            }
        } else {
            tableView.es.removeRefreshFooter()
        }
    }

    private func reload() {
        emptyView.removeFromSuperview()
        self.tableView.reloadData()
        if let spaces = self.spaces[currentCategory]?.spaces, spaces.isEmpty {
            view.addSubview(emptyView)
            emptyView.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(self.splitLine.snp.bottom)
            }
        }
    }

    @objc
    func onSelectSearch() {
        self.setNavigationBarHidden(true, animated: true)
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let searchController = factory.createWikiSpaceSearchController(delegate: self)
        addChild(searchController)
        self.view.addSubview(searchController.view)
        searchController.didMove(toParent: self)
        searchController.view.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        self.searchController = searchController
    }

    private func removeSearchView() {
        guard let searchController else { return }
        searchController.willMove(toParent: nil)
        searchController.view.removeFromSuperview()
        searchController.removeFromParent()
        self.searchController = nil
        setNavigationBarHidden(false, animated: true)
    }
    
    //处理spaces请求
    func handleViewModelAction(_ action: WikiWorkSpaceViewModel.Action) {
        self.tableView.es.stopLoadingMore()
        switch action {
        case let .getSpacesError(error: error, isMoreFetch: isMoreFetch):
            DocsLogger.error("wiki.home --- get space error", error: error)
            guard !isMoreFetch else { return }
            let failTipsView: WikiFaildView = WikiFaildView(frame: .zero)
            failTipsView.showFail(error: .networkError)
            failTipsView.isHidden = false
            self.view.addSubview(failTipsView)
            failTipsView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(self.navigationBar.snp.bottom)
            }
        case let .updateSpaces(category, spaces):
            if self.spaces[category] != nil {
                self.spaces[category]?.spaces.append(contentsOf: spaces.spaces)
                self.spaces[category]?.lastLabel = spaces.lastLabel
                self.spaces[category]?.hasMore = spaces.hasMore
            } else {
                self.spaces[category] = spaces
            }
            let hasMore = spaces.hasMore
            self.tableView.footer?.noMoreData = !hasMore
            self.tableView.footer?.isHidden = !hasMore
            self.reload()
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spaces[currentCategory]?.spaces.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: tableViewIdentifier) as? WikiWorkSpaceCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        guard let spaces = spaces[currentCategory] else {
            return UITableViewCell()
        }
        let space = spaces.spaces[indexPath.item]
        space.isTreeContentCached.drive(onNext: {[weak self, weak cell] isCache in
            guard let self = self else { return }
            let enable = self.isReachable ? true : isCache
            cell?.contentEnable = enable
            cell?.isUserInteractionEnabled = enable
        }).disposed(by: cell.reuseBag)
        cell.update(with: space)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        WikiStatistic.clickAllSpaceView()
        guard let space = spaces[currentCategory] else { return }
        let wikiSpace = space.spaces[indexPath.item]
        jumpToTreeVC(with: wikiSpace.spaceID, spaceName: wikiSpace.spaceName)
    }

    private func reportViewEvent() {
        switch pickerType {
        case .browse:
            WikiStatistic.allSpaceView()
        case let .picker(config):
            config.tracker.reportFileLocationSelectView()
        }
    }

    private func jumpToTreeVC(with spaceId: String, spaceName: String) {
        switch pickerType {
        case .browse:
            let viewModel = WikiTreeCoverViewModel(userResolver: userResolver, spaceId: spaceId)
            let treeVC = WikiTreeCoverViewController(userResolver: userResolver, viewModel: viewModel)
            userResolver.navigator.push(treeVC, from: self)
        case let .picker(config):
            guard let provider = try? userResolver.resolve(assert: WikiPickerProvider.self) else {
                DocsLogger.error("can not get provider")
                return
            }
            let controller = provider.createTreePicker(wikiToken: nil,
                                                      spaceID: spaceId,
                                                      spaceName: spaceName,
                                                      config: config)
            userResolver.navigator.push(controller, from: self)
        }
    }
}

extension WikiWorkSpaceViewController: WikiTreeSearchDelegate {
    func searchControllerDidClickCancel(_ controller: UIViewController) {
        removeSearchView()
    }

    func searchController(_ controller: UIViewController, didClick item: WikiSearchResultItem) {
        guard case let .wikiSpace(spaceId, spaceName) = item else { return }
        self.jumpToTreeVC(with: spaceId, spaceName: spaceName)
    }
}
