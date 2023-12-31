//
//  WikiTreeViewController.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/29.

import UIKit
import RxSwift
import EENavigator
import SKCommon
import SKSpace
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignIcon
import UniverseDesignToast
import SpaceInterface
import SKWorkspace
import SKInfra
import LarkContainer

class WikiTreeViewController: BaseViewController {

    private let viewModel: WikiTreeViewModel
    private let bag = DisposeBag()

    private lazy var searchBar: DocsSearchBar = {
        let searchBar = DocsSearchBar()
        searchBar.textField.placeholder = BundleI18n.SKResource.Doc_Wiki_Tree_Search
        searchBar.tapBlock = { [weak self] _ in self?.onSelectSearch() }
        return searchBar
    }()

    //添加到，移动到按钮
    private lazy var actionButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle(viewModel.config.actionName, for: .normal)
        button.addTarget(self, action: #selector(didClickActionButton), for: .touchUpInside)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.docs.addStandardLift()
        return button
    }()

    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var btnBackView: UIView = {
        let v = UIView()
        return v
    }()

    private var searchController: UIViewController?

    private let treeView: TreeView

    var toastDisplayView: UIView {
        guard let window = self.view.window else {
            spaceAssertionFailure("cannot get current window")
            return self.view
        }
        return window
    }

    init(viewModel: WikiTreeViewModel) {
        self.viewModel = viewModel
        self.treeView = TreeView(dataBuilder: viewModel.treeViewModel)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.displayTittle
        _setupUI()
        setupViewModel()
    }

    private func setupViewModel() {
        viewModel.treeViewModel.sectionsDriver
            .drive(onNext: { [weak self] _ in
                spaceAssert(Thread.isMainThread)
                guard let self = self else { return }
                self.updateActionButton(isEnabled: self.viewModel.isSelectedValidNode)
            })
            .disposed(by: bag)
    }

    private func _setupUI() {
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(6)
            make.height.equalTo(32)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        let splitLine = UIView()
        splitLine.backgroundColor = UDColor.lineDividerDefault
        view.addSubview(splitLine)
        splitLine.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.top.equalTo(searchBar.snp.bottom).offset(12.5)
            make.left.right.equalToSuperview()
        }

        view.addSubview(btnBackView)
        btnBackView.addSubview(actionButton)
        btnBackView.addSubview(separator)
        btnBackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(80.0)
        }
        actionButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.height.equalTo(44.0)
        }
        separator.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        view.addSubview(treeView)
        self.viewModel.initailTreeData()
        treeView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(splitLine.snp.bottom)
            make.bottom.equalTo(btnBackView.snp.top)
        }

        updateActionButton(isEnabled: false)
    }

    @objc
    func onSelectSearch() {
        self.setNavigationBarHidden(true, animated: true)
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let searchController = factory.createWikiTreeSearchController(spaceID: viewModel.spaceID, delegate: self)
        addChild(searchController)
        self.view.addSubview(searchController.view)
        searchController.didMove(toParent: self)
        searchController.view.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        self.searchController = searchController
        reportDidClickSearchBar()
    }

    private func reportDidClickSearchBar() {
        let source: WikiStatistic.ClickSearchSource = .wikiPagesOperation
        WikiStatistic.clickSearch(subModule: .wikiPages, source: source, action: .searchButton)
    }

    private func removeSearchView() {
        guard let searchController else { return }
        searchController.willMove(toParent: nil)
        searchController.view.removeFromSuperview()
        searchController.removeFromParent()
        self.searchController = nil
        setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Done Button

    @objc
    private func didClickActionButton() {
        guard let node = viewModel.selectedNode else {
            spaceAssertionFailure("cannot get node")
            return
        }
        let isRootNode = node.nodeType == .mainRoot
        let location = WikiPickerLocation(wikiToken: node.wikiToken,
                                          nodeName: node.displayTitle,
                                          spaceID: node.spaceID,
                                          spaceName: viewModel.spaceName,
                                          isMainRoot: isRootNode,
                                          isMylibrary: MyLibrarySpaceIdCache.isMyLibrary(node.spaceID))
        viewModel.config.completion(location, self)
    }

    private func updateActionButton(isEnabled: Bool) {
        actionButton.isEnabled = isEnabled
        actionButton.backgroundColor = isEnabled ? UDColor.primaryContentDefault : UDColor.fillDisabled
    }
}

extension WikiTreeViewController: WikiTreeSearchDelegate {
    func searchControllerDidClickCancel(_ controller: UIViewController) {
        removeSearchView()
    }

    func searchController(_ controller: UIViewController, didClick item: WikiSearchResultItem) {
        guard case let .wikiNode(node) = item else { return }
        // 更新目录树
        self.viewModel.updateTreeData(node.wikiToken)
        removeSearchView()
    }
}
