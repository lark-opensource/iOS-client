//
//  MailGroupMemberTableViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkAlertController
import LKCommonsLogging
import LarkSDKInterface
import LarkKeyCommandKit
import LarkKeyboardKit
import UniverseDesignDialog
import LKCommonsTracker
import UniverseDesignToast
import RxRelay
import RxSwift

protocol MailGroupMemberTableViewLifeCircle: AnyObject {
    func onDataLoad(_ error: Error?)
    func onSearchBegin(key: String)
    func onSearchResult(key: String?, _ error: Error?)
    func onRemoveBegin()
    func onRemoveEnd(_ error: Error?)
}

final class MailGroupMemberTableViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource,
                                          UITextFieldDelegate, TableViewKeyboardHandlerDelegate {
    @frozen
    enum DisplayMode {
        case display
        case multiselect
    }

    public typealias SelectedChangeHandler = (_ delta: [GroupInfoMemberItem], _ total: [GroupInfoMemberItem]) -> Void
    public typealias TapHandler = (_ item: GroupInfoMemberItem) -> Void

    static let logger = Logger.log(MailGroupMemberTableViewController.self, category: "NameCardList")

    private let disposeBag = DisposeBag()

    private var selectedView = MailSelectedCollectionView()
    private lazy var tableView: MailGroupMemberBaseTable = MailGroupMemberBaseTable(frame: .zero, style: .plain)

    // TableView Keyboard
    private var keyboardHandler: TableViewKeyboardHandler?
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }

    private var eduInactiveView: UIView?

    private lazy var headerView: UIView = {
        let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 8)
        let headerView = UIView(frame: frame)
        headerView.backgroundColor = UIColor.ud.N100
        return headerView
    }()

    private var isViewDidApper: Bool = false
    public var showSelectedView: Bool {
        viewModel.showSelectedView
    }
    public private(set) var selectedItems: [GroupInfoMemberItem] = []
    public var displayMode: MailGroupMemberTableViewController.DisplayMode {
        didSet {
            guard isViewDidApper else { return }
            self.tableView.reloadData()
            if displayMode == .display {
                selectedView.removeSelectAllItems()
                selectedItems = []
                refreshUI(0)
            }
        }
    }

    public var onSelected: SelectedChangeHandler?
    public var onDeselected: SelectedChangeHandler?
    public var onTap: TapHandler?
    public var onClickSearch: (() -> Void)?
    public weak var lifeCircle: MailGroupMemberTableViewLifeCircle?

    private(set) var viewModel: MailGroupMemberTableVM

    private var datas: [GroupInfoMemberItem] = []

    public init(viewModel: MailGroupMemberTableVM) {
        self.viewModel = viewModel
        self.displayMode = .display
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        viewModel.targetVC = self

        self.view.addSubview(selectedView)
        selectedView.setSelectedCollectionView(selectItems: [], didSelectBlock: { [weak self] (item) in
            self?.selectedViewSeleced(item)
        }, animated: false)
        selectedView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(44)
        }

        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: MailGroupMemberManagedCell.self)
        tableView.lu.register(cellSelf: UITableViewCell.self)
        tableView.register(MailGroupMemberTableHeader.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: MailGroupMemberTableHeader.self))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.right.equalToSuperview()
        }

        keyboardHandler = TableViewKeyboardHandler()
        keyboardHandler?.delegate = self

        bandingViewModelEvent()
        DispatchQueue.global().async { self.viewModel.loadFirstScreenData() }
        viewModel.observeData()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewDidApper = true
    }

    func changeViewStatus(_ status: MailGroupMemberTableViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            lifeCircle?.onDataLoad(error)
            loadingPlaceholderView.isHidden = true

            tableView.status = viewModel.datas.isEmpty ? .empty : .display
            UDToast.showFailure(with: error.localizedDescription, on: self.view, error: error)

            MailGroupMemberTableViewController.logger.error("GroupChatterViewController load data error", error: error)
        case .viewStatus(let status):
            lifeCircle?.onDataLoad(nil)
            datas = viewModel.datas
            loadingPlaceholderView.isHidden = true
            tableView.status = status

            if viewModel.datasHasMore {
                tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            } else {
                tableView.removeBottomLoadMore()
            }

            // 取出上拉加载更多
            tableView.reloadData()
        }
    }

    func loadDefaultSelectedItems(_ items: [GroupInfoMemberItem]) {
        selectedItems = items
        selectedView.removeSelectAllItems()
        selectedView.addSelectItems(selectItems: items.compactMap { $0 as? MailSelectedCollectionItem })
        onSelected?(items, items)
        refreshUI(0)
    }

    func bandingViewModelEvent() {
        viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: disposeBag)

        viewModel.onLoadDefaultSelectedItems = { [weak self] (items) in
            DispatchQueue.main.async {
                self?.loadDefaultSelectedItems(items)
            }
        }

        tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
            self?.viewModel.loadMoreData()
        }
    }

    // 选人后刷新UI
    func refreshUI(_ duration: TimeInterval = 0.25) {
        let shouldSelectedViewShow = showSelectedView && !selectedItems.isEmpty
        self.tableView.snp.updateConstraints {
            $0.top.equalTo(self.selectedView.snp.top).offset(shouldSelectedViewShow ? 44 : 0)
        }

        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        })
    }

    // 多选模式下，点击Cell选择
    func whenSelected(_ item: GroupInfoMemberItem) {
        selectedItems.append(item)
        onSelected?([item], selectedItems)

        guard let item = item as? MailSelectedCollectionItem else { return }

        self.selectedView.addSelectItem(selectItem: item)
        if selectedItems.count == 1 {
            refreshUI()
        }
    }

    // 多选模式下，点击Cell取消选择
    func whenDeselected(_ item: GroupInfoMemberItem) {
        selectedItems.removeAll { $0.itemId == item.itemId }
        onDeselected?([item], selectedItems)

        guard let item = item as? MailSelectedCollectionItem else { return }

        self.selectedView.removeSelectItem(selectItem: item)
        if selectedItems.isEmpty {
            refreshUI()
        }
    }

    // 点击事件
    func onTapItem(_ item: GroupInfoMemberItem) {
        onTap?(item)
    }

    public func cancelEditting() {
        self.tableView.setEditing(false, animated: true)
    }

    func selectedViewSeleced(_ item: MailSelectedCollectionItem) {
        let removeItems = selectedItems.filter { $0.itemId == item.id }
        selectedItems.removeAll { $0.itemId == item.id }
        onDeselected?(removeItems, selectedItems)

        tableView.visibleCells.forEach { (cell) in
            if var _cell = cell as? MailGroupMemberManagedCellProtocol, _cell.item?.itemId == item.id {
                _cell.isCheckboxSelected = false
            }
        }

        if selectedItems.isEmpty {
            refreshUI()
        }
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

    // swiftlint:disable did_select_row_protection
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // 抹掉背景
        tableView.deselectRow(at: indexPath, animated: true)

        // 取出对应的Cell & Item
        guard var cell = tableView.cellForRow(at: indexPath) as? MailGroupMemberManagedCellProtocol,
            let item = cell.item else { return }

        switch displayMode {
        case .display:
            onTapItem(item)
        case .multiselect:
            if selectedItems.contains(where: { $0.itemId == item.itemId }) {
                cell.isCheckboxSelected = false
                whenDeselected(item)
            } else {
                if let maxSelectModel = viewModel.maxSelectModel {
                    let maxNumber = maxSelectModel.0
                    let toast = maxSelectModel.1
                    guard selectedItems.count < maxNumber else {
                        UDToast.showTips(with: toast, on: self.view)
                        return
                    }
                }
               cell.isCheckboxSelected = true
                whenSelected(item)
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let tapTask: () -> Void = {
            tableView.setEditing(false, animated: false)
        }
        guard let actions = viewModel.structureActionItems(tapTask: tapTask,
                                                           indexPath: indexPath)
        else { return nil }
        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }

    // MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.row < datas.count {
            let item = datas[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MailGroupMemberManagedCell.lu.reuseIdentifier),
                                                 for: indexPath)

            if var itemCell = cell as? MailGroupMemberManagedCellProtocol {
                itemCell.set(item)
                // 重置cell状态
                itemCell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: false)
                if displayMode == .multiselect {
                    // 处理默认选中无法点击的cell
                    if let id = itemCell.item?.itemId, let isContain = viewModel.defaultUnableCancelSelectedIds?.contains(id), isContain {
                        itemCell.setCellSelect(canSelect: false, isSelected: false, isCheckboxHidden: false)
                    } else {
                        itemCell.setCellSelect(canSelect: true, isSelected: selectedItems.contains(where: { $0.itemId == item.itemId }), isCheckboxHidden: false)
                    }
                } else {
                    itemCell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: true)
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.lu.reuseIdentifier, for: indexPath)
        }

        return cell
    }
    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        onClickSearch?()
    }
}

extension MailGroupMemberTableViewController {
    /// 仅限移除群成员使用
    func removeSelectedItems() -> Bool {
        if viewModel.needDeleteCheck {
            var allCount = viewModel.datas.count
            if !viewModel.enableDeleteMe {
                let isNoMe = selectedItems.filter { [weak self] item in
                    return item.itemId == self?.viewModel.passportUserService?.user.userID ?? ""
                }.isEmpty
                allCount = viewModel.datas.count - (isNoMe ? 0 : 1)
            }
            if self.selectedItems.count == allCount {
                let dialog = UDDialog()
                dialog.setContent(text: BundleI18n.LarkContact.Mail_MailingList_AMembersRemain)
                dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
                self.present(dialog, animated: true, completion: nil)
                return false
            }
        }
        self.viewModel.removeMemberItems(items: selectedItems)
        return true
    }

    /// 直接更新选中的items
    func setDefaultSelectedItems(_ items: [GroupInfoMemberItem]) {
        loadDefaultSelectedItems(items)
        tableView.reloadData()
    }
}
