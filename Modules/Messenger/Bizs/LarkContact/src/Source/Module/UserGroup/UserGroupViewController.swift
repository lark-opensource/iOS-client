//
//  UserGroupViewController.swift
//  LarkContact
//
//  Created by ByteDance on 2023/4/17.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkModel
import LarkSearchCore
import EENavigator
import UniverseDesignToast
import UniverseDesignEmpty
import LarkMessengerInterface
import Homeric
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface

final class UserGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, HasSelectChannel, UserResolverWrapper {
    static let logger = Logger.log(UserGroupViewController.self, category: "Module.IM.UserGroupViewController")
    var selectChannel: SelectChannel {
        return .userGroup
    }

    var userResolver: LarkContainer.UserResolver
    private let disposeBag = DisposeBag()
    weak var fromVC: UIViewController?

    let viewModel: UserGroupViewModel
    weak var selectionSource: SelectionDataSource?
    private let loadingPlaceholderView = LoadingPlaceholderView()
    private var userGroups: [SelectVisibleUserGroup] = []

    struct Config {
        let selectedHandler: ((Int) -> Void)?
    }
    private let config: Config

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 68
        tableView.register(SelectUserGroupTableViewCell.self, forCellReuseIdentifier: "SelectUserGroupTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var emptyDataView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_IM_Picker_NoUserGroupsYet_Empty)
        let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noGroup))
        emptyDataView.isHidden = true
        return emptyDataView
    }()

    init(viewModel: UserGroupViewModel,
         config: Config,
         selectionSource: SelectionDataSource,
         resolver: UserResolver) {
        let maxSize = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        viewModel.pageCount = Int(maxSize / 68 * 1.5 + 1)
        self.viewModel = viewModel
        self.selectionSource = selectionSource
        self.config = config
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.LarkContact.Lark_IM_Picker_UserGroups_Breadcrum
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubViews()

        loadData()
        // Picker 埋点
        SearchTrackUtil.trackPickerUserGroupView()
    }

    private func setupSubViews() {
        self.view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds

        self.view.addSubview(emptyDataView)
        emptyDataView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        loadingPlaceholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingPlaceholderView.frame = view.bounds
        view.addSubview(loadingPlaceholderView)

        loadingPlaceholderView.isHidden = false
    }

    private func loadData() {

        self.viewModel
            .firstLoadUserGroupData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.loadingPlaceholderView.isHidden = true
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                self.loadingPlaceholderView.isHidden = true
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                self.loadingPlaceholderView.isHidden = true
                self.addDataEmptyViewIfNeed()
            }).disposed(by: self.disposeBag)

        self.viewModel
            .userGroupsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (userGroups) in
                guard let self = self else { return }
                self.userGroups = userGroups
                self.addDataEmptyViewIfNeed()
                self.bindTableViewLoadMore()
                let isEnd = self.viewModel.userGroupCursor.isEnd
                if isEnd {
                    self.tableView.enableBottomLoadMore(!isEnd)
                }
            }).disposed(by: disposeBag)

        selectionSource?.isMultipleChangeObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        selectionSource?.selectedChangeObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    private func bindTableViewLoadMore() {
        self.tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadMoreUserGroupData()
                .asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] (isEnd) in
                    self?.tableView.enableBottomLoadMore(!isEnd)
                }).disposed(by: self.disposeBag)
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userGroups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SelectUserGroupTableViewCell") as? SelectUserGroupTableViewCell,
                self.userGroups.count > indexPath.row else {
            return UITableViewCell()
        }
        cell.backgroundColor = UIColor.ud.bgBody
        let props = SelectUserGroupsCellProps(item: self.userGroups[indexPath.row],
                                              checkStatus: contactCheckBoxStaus(with: self.userGroups[indexPath.row]))
        cell.setProps(props)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)

        guard let selectionDataSource = selectionSource,
                userGroups.count > indexPath.row else {
            return
        }
        let userGroup = userGroups[indexPath.row]
        if selectionDataSource.toggle(option: userGroup,
                                      from: self,
                                      at: tableView.absolutePosition(at: indexPath),
                                      event: Homeric.PUBLIC_PICKER_SELECT_USER_GROUP_CLICK,
                                      target: Homeric.PUBLIC_PICKER_SELECT_USER_GROUP_VIEW),
           selectionDataSource.state(for: userGroup, from: self).selected {
            self.config.selectedHandler?(indexPath.row + 1)
        }
    }

    private func contactCheckBoxStaus(with chat: SelectVisibleUserGroup) -> ContactCheckBoxStaus {
        let multiStatusBlock: (SelectVisibleUserGroup) -> ContactCheckBoxStaus = { userGroup in
            if let state = self.selectionSource?.state(for: userGroup, from: self) {
                return state.asContactCheckBoxStaus
            }
            return .unselected
        }
        return selectionSource?.isMultiple == true ? multiStatusBlock(chat) : .invalid
    }
}

extension UserGroupViewController {
    private func addDataEmptyViewIfNeed() {
        if self.userGroups.isEmpty {
            emptyDataView.isHidden = false
            self.tableView.isHidden = true
        } else {
            emptyDataView.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
