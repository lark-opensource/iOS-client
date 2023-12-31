//
//  GroupBotListViewController.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LKCommonsLogging
import LarkUIKit
import Swinject
import RxSwift
import LarkAccountInterface
import LarkContainer

class GroupBotListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    static let logger = Logger.oplog(GroupBotListViewController.self, category: GroupBotDefines.groupBotLogCategory)

    let resolver: UserResolver
    let disposeBag = DisposeBag()
    /// 数据model
    var viewModel: GroupBotListPageViewModel?

    /// 首次初始化
    var firstInit: Bool = true

    /// chat id
    var chatID: String

    /// 是否是外部群
    var isCrossTenant: Bool

    /// 数据提供者
    var dataProvider: GroupBotListPageDataProvider

    /// 正常展示数据的tableView
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.showsVerticalScrollIndicator = false
        tableView.register(GroupBotListPageCell.self, forCellReuseIdentifier: GroupBotListPageCell.CellConfig.cellID)
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
    lazy var loadEmptyView = GroupBotEmptyView(frame: .zero, bizScene: .groupBotList, isCrossTenant: isCrossTenant, resolver: resolver, fromVC: self)

    init(resolver: UserResolver, chatID: String, isCrossTenant: Bool) {
        self.resolver = resolver
        self.chatID = chatID
        self.isCrossTenant = isCrossTenant
        self.dataProvider = GroupBotListPageDataProvider(resolver: resolver, locale: OpenPlatformAPI.curLanguage(), chatID: chatID)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        dataProduce()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !firstInit {
            dataProduce()
        }
        firstInit = false
    }

    // MARK: - UITableViewDelegate
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

    // MARK: -UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        _tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        _tableView(tableView, cellForRowAt: indexPath)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        _numberOfSections(in: tableView)
    }
}
