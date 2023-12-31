//
//  AddBotViewController.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/9.
//

import LKCommonsLogging
import LarkUIKit
import Swinject
import RxSwift
import RxCocoa
import LarkAccountInterface
import LarkFeatureGating
import LarkContainer

class AddBotViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    static let logger = Logger.oplog(AddBotViewController.self, category: GroupBotDefines.groupBotLogCategory)
    @FeatureGating("suite_help_service_message") var showBots: Bool

    let resolver: UserResolver
    let disposeBag = DisposeBag()
    /// 数据model
    var viewModel: AddBotPageViewModel?

    /// 首次初始化
    var firstInit: Bool = true

    /// chat id
    var chatID: String

    /// 是否是外部群
    var isCrossTenant: Bool

    /// 数据提供者
    var dataProvider: AddBotPageDataProvider

    /// 获取配置
    lazy var configProvider = GroupBotConfigProvider(resolver: resolver)
    /// 帮助文档链接
    var helpURL: URL?

    /// 搜索框
    lazy var textFieldWrap: SearchUITextFieldWrapperView = {
        let textFieldWrap = SearchUITextFieldWrapperView()
        textFieldWrap.backgroundColor = UIColor.ud.bgBody
        textFieldWrap.searchUITextField.placeholder = BundleI18n.GroupBot.Lark_Legacy_Search
        textFieldWrap.searchUITextField.returnKeyType = .search
        textFieldWrap.searchUITextField.enablesReturnKeyAutomatically = true
        textFieldWrap.searchUITextField.tapBlock = { _ in
            TeaReporter(eventKey: TeaReporter.key_groupbot_click_addbot_search)
                .withDeviceType()
                .withUserInfo(resolver: self.resolver)
                .report()
        }
        textFieldWrap.searchUITextField.rx.controlEvent(.editingChanged)
            .bind { [weak self] () in
                self?.searchTextFieldEditChanged()
            }
            .disposed(by: disposeBag)

        return textFieldWrap
    }()

    /// 正常展示数据的tableView
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.showsVerticalScrollIndicator = false
        tableView.register(AddBotPageCell.self, forCellReuseIdentifier: AddBotPageCell.CellConfig.cellID)
        tableView.register(AddBotPageRecommendHeaderView.self, forHeaderFooterViewReuseIdentifier: AddBotPageRecommendHeaderView.headerReuseID)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        return tableView
    }()

    /// 加载态视图
    lazy var loadingView: GroupBotLoadingView = {
        let loadingCellNum: Int = Int(floor(UIScreen.main.bounds.height / GroupBotLoadingCellView.height))
        return GroupBotLoadingView(frame: .zero, cellNum: loadingCellNum)
    }()
    /// 加载失败的视图
    lazy var loadFailedView: LoadFailView = LoadFailView(frame: .zero, reload: { [weak self] in
        self?.reloadPage()
    })
    /// 加载为空的视图
    lazy var loadEmptyView = GroupBotEmptyView(frame: .zero, bizScene: .addBot, isCrossTenant: isCrossTenant, resolver: resolver, fromVC: self)
    /// 搜索结果为空的视图
    lazy var searchEmptyView: SearchEmptyView = SearchEmptyView()

    init(resolver: UserResolver, chatID: String, isCrossTenant: Bool) {
        self.resolver = resolver
        self.chatID = chatID
        self.isCrossTenant = isCrossTenant
        self.dataProvider = AddBotPageDataProvider(resolver: resolver, locale: OpenPlatformAPI.curLanguage(), chatID: chatID)
        super.init(nibName: nil, bundle: nil)
        if showBots {
            configProvider.fetchGroupBotHelpURL { [weak self] helpURL in
                self?.helpURL = helpURL
                self?.setNavigationBarRightItem()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        dataProduce(isSearching: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !firstInit {
            updateDataConsideringSearchText()
        }
        firstInit = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissKeyboard()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _scrollViewWillBeginDragging(scrollView)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        _tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        _tableView(tableView, cellForRowAt: indexPath)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        _numberOfSections(in: tableView)
    }

    // MARK: - UITableViewDelegate {
    /// cell点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _tableView(tableView, didSelectRowAt: indexPath)
    }

    /// cell高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        _tableView(tableView, heightForRowAt: indexPath)
    }

    /// headerView
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        _tableView(tableView, viewForHeaderInSection: section)
    }

    /// header高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        _tableView(tableView, heightForHeaderInSection: section)
    }

    /// footerView
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        _tableView(tableView, viewForFooterInSection: section)
    }

    /// footer高度
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        _tableView(tableView, heightForFooterInSection: section)
    }
}
