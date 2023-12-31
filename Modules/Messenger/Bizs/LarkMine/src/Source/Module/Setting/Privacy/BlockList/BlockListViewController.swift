//
//  BlockListViewController.swift
//  LarkMine
//
//  Created by 姚启灏 on 2020/7/22.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkContainer
import LarkModel
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import RustPB
import UniverseDesignEmpty
import FigmaKit
import LKCommonsLogging
import LarkAlertController

final class BlockListViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let logger = Logger.log(BlockListViewController.self)
    /// 表格视图
    private lazy var tableView = self.createTableView()

    private lazy var emptyView: UIView = {
        /// 暂无用户
        let empty = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkMine.Lark_NewContacts_NoUsers), type: .noContact))
        empty.backgroundColor = UIColor.ud.bgFloatBase
        return empty
    }()

    private lazy var errorView: UIView = {
        let content = NSMutableAttributedString(string: BundleI18n.LarkMine.Lark_NewContacts_FailedToLoadComma)
        let retry = NSMutableAttributedString(string: BundleI18n.LarkMine.Lark_NewContacts_RefreshToTryAagin,
                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault])
        content.append(retry)
        let error = EmptyDataView(content: content,
                                  placeholderImage: UDEmptyType.loadingFailure.defaultImage())
        error.backgroundColor = .clear
        error.lu.addTapGestureRecognizer(action: #selector(reload), target: self, touchNumber: 1)
        return error
    }()

    private lazy var editBar: UIBarButtonItem = {
        let editBar = UIBarButtonItem(title: BundleI18n.LarkMine.Lark_NewSettings_PermissionExceptionsRemove,
                                      style: .plain,
                                      target: self,
                                      action: #selector(remove))
        editBar.tintColor = UIColor.ud.primaryContentDefault
        return editBar
    }()

    private let disposeBag = DisposeBag()

    private let viewModel: BlockListViewModel

    private var dataSource: [RustPB.Contact_V2_BlockUser] = []

    init(viewModel: BlockListViewModel) {
        self.viewModel = viewModel
        self.logger.info("[LarkMine]{block user list}-init")
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.monitor.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkMine.Lark_NewSettings_Blocklist
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        emptyView.isHidden = true

        self.view.addSubview(errorView)
        errorView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        errorView.isHidden = true

        self.bindViewModel()
        self.viewModel.fetchFristPageData()
        self.viewModel.monitor.registerObserver(self, method: #selector(reload), serverType: .blockStatusChangeService)
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0, height: 0)))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 68
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        /// registerCell
        tableView.lu.register(cellSelf: BlockListTableViewCell.self)

        return tableView
    }

    private func bindViewModel() {
        viewModel
            .refreshDriver
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.refreshTableViewData()
            }).disposed(by: self.disposeBag)

        // 这里和安卓统一一下错误逻辑
        viewModel
            .errorDriver
            .drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                // 第一页失败 直接展示错误页
                if self.viewModel.isFirstPage {
                    self.errorView.isHidden = false
                    self.navigationItem.rightBarButtonItem = nil
                } else {
                    UDToast.showFailure(
                        with: BundleI18n.LarkMine.Lark_Legacy_FailedtoLoadTryLater,
                        on: self.view
                    )
                    self.tableView.endBottomLoadMore()
                }
            }).disposed(by: self.disposeBag)
    }

    func refreshTableViewData() {
        self.logger.info("[LarkMine]{block user list}-refreshTableViewData")
        self.dataSource = self.viewModel.dataSource
        self.tableView.reloadData()
        self.emptyView.isHidden = !self.dataSource.isEmpty
        self.errorView.isHidden = true
        if !self.dataSource.isEmpty {
            self.navigationItem.rightBarButtonItem = self.editBar
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        self.addLoadMoreIfNeed()
    }

    /// 下拉加载更多
    func addLoadMoreIfNeed() {
        self.tableView.removeBottomLoadMore()
        if self.viewModel.hasMore {
            // 上拉加载更多
            self.tableView.addBottomLoadMoreView {  [weak self] in
                guard let self = self else { return }
                self.viewModel.fetchData()
            }
        }
    }

    /// 点击右上角删除
    @objc
    private func remove() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            editBar.title = BundleI18n.LarkMine.Lark_NewSettings_PermissionExceptionsRemoveDoneMobile
        } else {
            editBar.title = BundleI18n.LarkMine.Lark_NewSettings_PermissionExceptionsRemove
        }
    }

    private func showAlert(title: String, message: String, rightButtonTitle: String, handler: @escaping (() -> Void)) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addCancelButton(dismissCompletion: nil)
        alertController.addPrimaryButton(text: rightButtonTitle, dismissCompletion: {
            handler()
        })
        self.viewModel.userNavigator.present(alertController, from: self)
    }

    func deleteItem(by item: RustPB.Contact_V2_BlockUser, indexPath: IndexPath) {
        let hud = UDToast.showLoading(on: self.view)
        self.viewModel
            .deleteUserByID(item.userID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                hud.remove()
                guard let `self` = self else { return }
                self.dataSource.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.logger.info("[LarkMine]{block user list}-delete row: \(self.dataSource.count), \(indexPath)")
                if let window = self.view.window {
                    UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_Legacy_RemovedSuccessfully, on: window)
                }
                // 当数据为空的时候 刷新一下UI
                if self.dataSource.isEmpty {
                    self.viewModel.dataSource.removeAll()
                    self.autoReloadDataIfNeed()
                }
            }, onError: { [weak self] (_) in
                guard let window = self?.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_Legacy_RemoveFailed, on: window)
            }).disposed(by: self.disposeBag)
    }

    // MARK: tableView 代理方法
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataSource.count
        return count
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return BundleI18n.LarkMine.Lark_NewSettings_PermissionExceptionsRemove
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if editingStyle == .delete {
            let item = dataSource[indexPath.row]
            self.showAlert(title: BundleI18n.LarkMine.Lark_Profile_UnBlockWindow_Title,
                           message: BundleI18n.LarkMine.Lark_Profile_UnBlockWindow_Desc,
                           rightButtonTitle: BundleI18n.LarkMine.Lark_Profile_UnBlockWindow_Unblock_Button) { [weak self] in
                guard let self = self else { return }
                self.deleteItem(by: item, indexPath: indexPath)
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let id = dataSource[indexPath.row].userID
        tableView.deselectRow(at: indexPath, animated: true)
        self.viewModel.userNavigator.push(body: PersonCardBody(chatterId: id), from: self)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: BlockListTableViewCell.lu.reuseIdentifier) as? BlockListTableViewCell {
            let item = dataSource[indexPath.row]
            cell.setInfo(avatarKey: item.avatarKey,
                         avatarId: item.userID,
                         name: item.userName)
            return cell
        }
        return UITableViewCell()
    }

    /// 重新刷新数据
    @objc
    private func reload() {
        self.viewModel.fetchFristPageData()
    }

    /**
      用户手动把所有的数据都删除了的时候触发
      1 如果这个时候 还可以下拉 直接刷新数据
      2 如果这个时候 不可以下拉 说明没有数据 展示空白页
     */
    func autoReloadDataIfNeed() {
        if self.viewModel.hasMore {
            self.viewModel.fetchFristPageData()
        } else {
            self.refreshTableViewData()
        }
    }

}
