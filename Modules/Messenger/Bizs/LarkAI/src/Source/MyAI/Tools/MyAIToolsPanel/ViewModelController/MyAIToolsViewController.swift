//
//  MyAIToolsViewController.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/22.
//  MyAITools 选择列表

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignEmpty
import LarkMessengerInterface
import LKCommonsLogging
import LarkModel
import LarkContainer
import LarkAIInfra
import UniverseDesignDialog
import LarkCore
import LarkListItem

final class MyAIToolsViewController: BaseUIViewController, MyAIToolsPanelInterface, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {

    static let logger = Logger.log(MyAIToolsViewController.self, category: "Module.LarkAI.MyAITool")

    var userResolver: LarkContainer.UserResolver
    private let chat: Chat
    public var completionHandle: MyAIToolsPanelConfig.SelectToolsSureCallBack?
    public var closeHandler: (() -> Void)?
    weak var fromVc: UIViewController?

    private var context: MyAIToolsContext
    private var selectViewHeightConstraint: Constraint?
    private var searchViewHeightConstraint: Constraint?
    /// 推荐tools
    var tools: [MyAIToolInfo] = []
    /// 搜索tools
    var searchTools: [MyAIToolInfo] = []

    private(set) lazy var confimItem: LKBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkAI.Lark_Profile_UseDefaultProfilePhotoConfirmButton)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: Cons.barItemTextFont), alignment: .right)
        btnItem.button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        btnItem.button.setTitleColor(UIColor.ud.textLinkDisabled, for: .disabled)
        btnItem.button.addTarget(self, action: #selector(didTapConfim), for: .touchUpInside)
        return btnItem
    }()

    private lazy var searchTextView: SearchUITextFieldWrapperView = {
        let searchTextView = SearchUITextFieldWrapperView()
        searchTextView.searchUITextField.clearButtonMode = .always
        searchTextView.searchUITextField.isUserInteractionEnabled = true
        searchTextView.searchUITextField.placeholder = BundleI18n.LarkAI.MyAI_IM_SelectUpToNumPlugins_Placeholder(self.viewModel.maxSelectCount)
        searchTextView.searchUITextField.returnKeyType = .search
        return searchTextView
    }()

    private lazy var selectView: MyAIToolsSelectedView = {
        let selectView = MyAIToolsSelectedView()
        selectView.isHidden = true
        return selectView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MyAIToolsSelectTableViewCell.self, forCellReuseIdentifier: "MyAIToolsSelectTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var emptyDataView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkAI.Lark_Legacy_PullEmptyResult)
        let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noApplication))
        emptyDataView.useCenterConstraints = true
        emptyDataView.isHidden = true
        return emptyDataView
    }()

    lazy var dividerView: UIView = {
        let view = UIView()
        // 分割线颜色先用clear替换，避免善变的UX又变更了回来还得重新加上(灬ꈍ ꈍ灬)
        view.backgroundColor = UIColor.clear
        return view
    }()

    var myAIToolRustService: RustMyAIToolServiceAPI?
    private var aiService: MyAIService?

    private lazy var viewModel: MyAIToolsViewModel = {
        let viewModel = MyAIToolsViewModel(context: self.context,
                                           userResolver: userResolver,
                                           myAIToolRustService: self.myAIToolRustService)
        viewModel.toolsVc = self
        return viewModel
    }()
    private let disposeBag = DisposeBag()

    /// 是否在执行搜索操作
    var isPerformSearch: Bool {
        return !searchTextView.searchUITextField.text.isEmpty
    }
    /// 搜索关键字
    var searchKeyWord: String {
        return searchTextView.searchUITextField.text ?? ""
    }

    var tableViewData: [MyAIToolInfo] {
        return isPerformSearch ? searchTools : tools
    }

    init(context: MyAIToolsContext,
         userResolver: UserResolver,
         chat: Chat) {
        self.context = context
        self.userResolver = userResolver
        self.chat = chat
        self.aiService = try? userResolver.resolve(assert: MyAIService.self)
        self.myAIToolRustService = try? userResolver.resolve(assert: RustMyAIToolServiceAPI.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkAI.MyAI_IM_SelectPlugins_Button
        self.view.backgroundColor = UIColor.ud.bgBase

        setupViews()
        bindVMAction()
        loadData()
        addExposureIMTracker()
    }

    private func addExposureIMTracker() {
        guard let myAIPageService = self.context.myAIPageService else {
            Self.logger.info("my ai add IMTracker, service is none")
            return
        }
        IMTracker.Chat.Main.Click.clickExtension(
            self.chat,
            params: viewModel.teaEventParams(isClick: false),
            myAIPageService.chatFromWhere)
        IMTracker.Chat.Main.viewExtension(
            self.chat,
            params: viewModel.teaEventParams(isClick: false),
            myAIPageService.chatFromWhere)
    }

    private func addClickIMTracker() {
        guard let myAIPageService = self.context.myAIPageService else {
            Self.logger.info("my ai add IMTracker, service is none")
            return
        }
        IMTracker.Chat.Main.Click.selectExtension(
            self.chat,
            params: viewModel.teaEventParams(isClick: true),
            myAIPageService.chatFromWhere)
    }

    private func setupViews() {
        self.view.addSubview(searchTextView)
        self.view.addSubview(dividerView)
        self.view.addSubview(selectView)
        self.view.addSubview(tableView)
        self.view.addSubview(emptyDataView)

        searchTextView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            self.searchViewHeightConstraint = make.height.equalTo(0).constraint
        }
        selectView.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            make.left.right.equalToSuperview()
            make.top.equalTo(searchTextView.snp.bottom)
            self.selectViewHeightConstraint = make.height.equalTo(0).constraint
        }
        dividerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(selectView.snp.bottom)
            make.height.equalTo(Cons.dividerViewHeight)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        emptyDataView.snp.makeConstraints { (make) in
            make.edges.equalTo(tableView)
        }
        loadingPlaceholderView.snp.remakeConstraints { (make) in
            make.edges.equalTo(tableView)
        }
    }

    private func bindVMAction() {
        viewModel.selectToolsSubject.observeOn(MainScheduler.instance).subscribe { [weak self] (items) in
            guard let self = self else { return }
            let comfimTitle = !items.isEmpty ? "\(BundleI18n.LarkAI.Lark_Profile_UseDefaultProfilePhotoConfirmButton) (\(items.count))" :
            BundleI18n.LarkAI.Lark_Profile_UseDefaultProfilePhotoConfirmButton
            self.confimItem.resetTitle(title: comfimTitle)
            if !items.isEmpty, !self.viewModel.isSingleSelect {
                self.displaySelectTool(true)
            } else {
                self.displaySelectTool(false)
            }
        }.disposed(by: disposeBag)

        self.selectView.didDeleteItemHandler = { [weak self] (item) in
            guard let self = self else { return }
            self.viewModel.toggleItemSelected(item: item)
        }
        viewModel.selectToolsSubject.map { [weak self] (tools) -> Bool in
            guard let self = self else { return !tools.isEmpty }
            return self.viewModel.checkIsChangeSelect(tools)
        }.bind(to: confimItem.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.status.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (status) in
            guard let self = self else { return }
            switch status {
            case .loading, .searching:
                self.loadingPlaceholderView.isHidden = false
            case .reload, .loadComplete, .searchComplete:
                self.loadingPlaceholderView.isHidden = true
                self.tableView.reloadData()
                self.addDataEmptyViewIfNeed()
            case .loadMore:
                self.loadingPlaceholderView.isHidden = true
                self.tableView.reloadData()
                self.bindTableViewLoadMore()
                self.addDataEmptyViewIfNeed()
            case .searchMore:
                self.loadingPlaceholderView.isHidden = true
                self.tableView.reloadData()
                self.bindTableViewSearchMore()
            case .empty:
                self.loadingPlaceholderView.isHidden = true
                let emptyConfig = self.getUDEmptyConfig(.empty)
                self.emptyDataView.update(config: emptyConfig)
                self.addDataEmptyViewIfNeed()
            case .noSearchResult:
                self.loadingPlaceholderView.isHidden = true
                let emptyConfig = self.getUDEmptyConfig(.noSearchResult)
                self.emptyDataView.update(config: emptyConfig)
                self.addDataEmptyViewIfNeed()
            case .retry:
                self.loadingPlaceholderView.isHidden = true
                let erroyConfig = self.getUDEmptyConfig(.retry)
                self.emptyDataView.update(config: erroyConfig)
                self.addDataEmptyViewIfNeed()
            case .fail(let error):
                self.loadingPlaceholderView.isHidden = true
                if case .searchError(let err) = error {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: err)
                } else if case .requestError(let err) = error {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: self.view, error: err)
                }
            }
        }).disposed(by: disposeBag)

        self.viewModel
            .toolsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tools) in
                guard let self = self else { return }
                self.tools = tools
                self.configSearchTextPlaceholder()
                self.viewModel.processToolsData()
            }).disposed(by: disposeBag)
        self.viewModel
            .toolsSearchObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tools) in
                guard let self = self else { return }
                self.searchTools = tools
                self.viewModel.processSearchToolsData()
            }).disposed(by: disposeBag)
        self.searchTextView.searchUITextField.rx.controlEvent(.editingChanged).asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.searchAction()
        }).disposed(by: self.disposeBag)

        viewModel.singleSelectSubject.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (isSingleSelect) in
            guard let self = self else { return }
            if !isSingleSelect {
                self.navigationItem.rightBarButtonItem = self.confimItem
            }
        }).disposed(by: disposeBag)

        UIView.animate(withDuration: Cons.searchViewDisplayAnimateTime) {
            self.searchViewHeightConstraint?.update(offset: Cons.searchViewHeight)
            self.view.layoutIfNeeded()
        }
        if !self.viewModel.selectedToolsInfo.isEmpty {
            self.displaySelectTool(true)
        }
    }

    private func loadData() {
        self.viewModel.firstLoadToolsData()
    }

    private func searchData(_ keyWord: String) {
        self.viewModel
            .firstSearchToolsData(by: keyWord)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
            }).disposed(by: self.disposeBag)
    }

    private func bindTableViewLoadMore() {
        self.tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadMoreToolsData()
                .asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] (isEnd) in
                    self?.tableView.enableBottomLoadMore(!isEnd)
                }).disposed(by: self.disposeBag)
        }
    }

    private func bindTableViewSearchMore() {
        self.tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.viewModel.searchMoreToolsData(by: self.searchKeyWord)
                .asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] (isEnd) in
                    self?.tableView.enableBottomLoadMore(!isEnd)
                }).disposed(by: self.disposeBag)
        }
    }

    private func displaySelectTool(_ isShow: Bool) {
        if isShow {
            selectView.reloadCollect(items: self.viewModel.selectedToolsInfo)
            guard selectView.isHidden  else { return }
            selectView.isHidden = false
            UIView.animate(withDuration: Cons.selectViewDisplayAnimateTime) {
                self.selectViewHeightConstraint?.update(offset: Cons.selectViewHeight)
                self.view.layoutIfNeeded()
            }
        } else {
            selectView.isHidden = true
            UIView.animate(withDuration: Cons.selectViewDisplayAnimateTime) {
                self.selectViewHeightConstraint?.update(offset: 0)
                self.view.layoutIfNeeded()
            }
        }
    }

    private func configSearchTextPlaceholder() {
        self.searchTextView.searchUITextField.placeholder = BundleI18n.LarkAI.MyAI_IM_SelectUpToNumPlugins_Placeholder(self.viewModel.maxSelectCount)
    }

    public func show(from vc: UIViewController?) {
        self.fromVc = vc
    }

    @objc
    public override func closeBtnTapped() {
        self.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else {
                return
            }
            self.closeHandler?()
        })
    }

    func getUDEmptyConfig(_ status: MyAIToolsStatus) -> UDEmptyConfig {
        if case .retry = status {
            let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError)
            let errorConfig = UDEmptyConfig(description: desc, type: .error)
            emptyDataView.clickHandler = { [weak self] in
                guard let self = self else { return }
                self.emptyRetryClickHandler()
            }
            return errorConfig
        } else if case .noSearchResult = status {
            let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkAI.Lark_Legacy_PullEmptyResult)
            let emptyConfig = UDEmptyConfig(description: desc, type: .searchFailed)
            emptyDataView.clickHandler = nil
            return emptyConfig
        } else {
            let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkAI.Lark_Legacy_PullEmptyResult)
            let emptyConfig = UDEmptyConfig(description: desc, type: .noApplication)
            emptyDataView.clickHandler = nil
            return emptyConfig
        }
    }

    /// 失败重试
    func emptyRetryClickHandler() {
        if isPerformSearch {
            searchData(searchKeyWord)
        } else {
            loadData()
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        self.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else {
                return
            }
            self.closeHandler?()
            completion?()
        })
    }

    private func showToolAlertPrompt() {
        DispatchQueue.main.async {
            let aiBrandName = MyAIResourceManager.getMyAIBrandNameFromSetting(userResolver: self.userResolver)
            let alert = UDDialog()
            alert.setTitle(text: BundleI18n.LarkAI.MyAI_IM_ExtensionLimitationNotice_Title)
            alert.setContent(text: BundleI18n.LarkAI.MyAI_IM_ExtensionLimitationNotice_aiName_Desc(aiBrandName), numberOfLines: 0)
            alert.addPrimaryButton(text: BundleI18n.LarkAI.MyAI_IM_ExtensionLimitationNotice_GotIt_Button, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                Self.logger.info("toolAlert selected toolIds: \(self.viewModel.selectedToolIds)")
            })
            self.fromVc?.present(alert, animated: true)
        }
    }

    func selectedToolCallBack() {
        guard let aiService = self.aiService else { return }
        let extensionInfoList = self.viewModel.selectedToolsInfo.map { MyAIExtensionInfo(id: $0.toolId, name: $0.toolName, avatarKey: $0.toolAvatar) }
        let extensionCallBackInfo = MyAIExtensionCallBackInfo(extensionList: extensionInfoList, fromVc: self.fromVc)
        aiService.selectedExtension.accept(extensionCallBackInfo)
    }

    @objc
    private func didTapConfim() {
        addClickIMTracker()
        Self.logger.info("did tap set my ai tools isSingleSelect:\(viewModel.isSingleSelect)")
        hideKeyboard()
        let loadingHUD = UDToast.showDefaultLoading(with: BundleI18n.LarkAI.Lark_LocalDataEncryptionKey_LoadingTitle, on: self.view, disableUserInteraction: true)
        self.myAIToolRustService?.sendMyAITools(toolIds: self.viewModel.selectedToolIds,
                                                messageId: viewModel.getMessageId(),
                                                aiChatModeID: self.context.aiChatModeId,
                                                toolInfoList: viewModel.selectedToolsInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                loadingHUD.remove()
                guard let self = self else { return }
                Self.logger.info("set my ai tools success")
                self.selectedToolCallBack()
                // NOTE: 将函数传作闭包会隐式持有 self，这里考虑换一种方式
                self.dismiss(completion: self.viewModel.isShowToolAlertPrompt ? self.showToolAlertPrompt : nil)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.info("set my ai tools failure error: \(error)")
                UDToast.showFailure(
                    with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError,
                    on: self.view,
                    error: error.transformToAPIError()
                )
            }).disposed(by: self.disposeBag)
    }

    private func searchAction() {
        guard searchTextView.searchUITextField.markedTextRange == nil else { return }
        if let text = searchTextView.searchUITextField.text, !text.isEmpty {
            self.viewModel.resetSearchCursor()
            searchData(text)
        } else {
            self.viewModel.clearSearchToolsData()
        }
    }

    private func didClickDetailInfo(_ item: MyAIToolInfo?) {
        guard let item = item else { return }
        var toolItem = item
        if isPerformSearch {
            let originToolName = SearchAttributeString(searchHighlightedString: item.toolName).attributeText.string
            toolItem.toolName = originToolName
        }
        let toolDetailBody = MyAIToolsDetailBody(toolItem: toolItem,
                                                 isSingleSelect: viewModel.isSingleSelect,
                                                 chat: self.chat,
                                                 myAIPageService: self.context.myAIPageService,
                                                 extra: viewModel.teaEventParams(isClick: true)) { [weak self] (toolItem) in
            guard let self = self else { return }
            self.toggleItemSelected(toolItem)
        }
        userResolver.navigator.push(body: toolDetailBody, from: self)
    }

    private func hideKeyboard() {
        self.view.endEditing(true)
    }

    func toggleItemSelected(_ toolItem: MyAIToolInfo) {
        guard self.viewModel.checkIsSelected(toolItem) else {
            UDToast.showTips(with: BundleI18n.LarkAI.MyAI_IM_SelectUpToNumPlugins_Placeholder(self.viewModel.maxSelectCount), on: self.view)
            return
        }
        viewModel.toggleItemSelected(item: toolItem)
    }

    func multipleItemSelected(_ toolItem: MyAIToolInfo) {
        viewModel.multipleItemSelected(item: toolItem)
        didTapConfim()
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyAIToolsSelectTableViewCell") as? MyAIToolsSelectTableViewCell,
              self.tableViewData.count > indexPath.row else {
            return UITableViewCell()
        }
        cell.backgroundColor = UIColor.ud.bgBody
        let toolItem = self.tableViewData[indexPath.row]
        cell.isSingleSelect = self.viewModel.isSingleSelect
        cell.isSourceSearch = self.isPerformSearch
        cell.toolItem = toolItem
        cell.didClickInfoHandler = { [weak self] (item) in
            self?.didClickDetailInfo(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
        self.tableViewData.count > indexPath.row else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        let toolItem = self.tableViewData[indexPath.row]
        if self.viewModel.isSingleSelect {
            // 单选
            multipleItemSelected(toolItem)
        } else {
            // 多选
            toggleItemSelected(toolItem)
        }
    }

    deinit {
        print("MyAIToolsViewController - deinit")
    }
}

extension MyAIToolsViewController {
    enum Cons {
        static var barItemTextFont: CGFloat { 16 }
        static var searchViewHeight: CGFloat { 54 }
        static var selectViewHeight: CGFloat { 56 }
        static var selectViewDisplayAnimateTime: TimeInterval { 0.3 }
        static var searchViewDisplayAnimateTime: TimeInterval { 0.2 }
        static var dividerViewHeight: CGFloat { 0 }
    }
}

extension MyAIToolsViewController {
    private func addDataEmptyViewIfNeed() {
        if self.tableViewData.isEmpty {
            emptyDataView.isHidden = false
            self.tableView.isHidden = true
        } else {
            emptyDataView.isHidden = true
            self.tableView.isHidden = false
        }
    }
}
