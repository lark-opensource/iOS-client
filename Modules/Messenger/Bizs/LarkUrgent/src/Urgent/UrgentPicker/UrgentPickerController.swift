//
//  ChatChatterViewController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/2/24.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignTag

/// 加急选人完成后，跳转到哪个界面
typealias UrgentConfirmControllerProvider =
(Message, UrgentConfirmDisplayMode, @escaping (_ type: SendUrgentSelectType, _ cancelAck: Bool) -> Void) -> UIViewController

enum SendUrgentSelectType {
    case selectSomeChatter(urgentResults: [UrgentResult])
    case selectUnreadChatter(disableList: [String], additionalList: [String])
    case selectAllChatter(disableList: [String], additionalList: [String])
}

/// 加急选人界面
final class UrgentPickerController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private static let logger = Logger.log(
        UrgentPickerController.self,
        category: "Module.IM.UrgentPickerController")
    private let disposeBag = DisposeBag()

    /// vm
    private var viewModel: UrgentPickerViewModel
    private var tableViewModel: UrgentTableViewModel {
        return self.viewModel.tableViewModel
    }
    private lazy var bottomCoverView: ChatterListBottomTipView = {
        return ChatterListBottomTipView(frame:
            ChatterListBottomTipView.defaultFrame(self.view.bounds.width))
    }()
    /// 表格视图
    private lazy var tableView: ChatChatterBaseTable = self.createTableView()
    /// 选中全部未读用户
    private var tableHeaderView: UrgentChatterTableHeader?
    private var pickerToolBar = DefaultPickerToolBar()
    /// 搜索文本框
    private var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField
    /// 加急选人界面 -> 跳转到哪个确认界面
    private let confirmControllerProvider: UrgentConfirmControllerProvider

    /// 加急选人界面 -> 加急确认界面 -> 点击确认 -> 调用该方法
    var sendSelected: ((_ type: SendUrgentSelectType, _ cancelAck: Bool) -> Void)?

    init(viewModel: UrgentPickerViewModel, confirmControllerProvider: @escaping UrgentConfirmControllerProvider) {
        self.viewModel = viewModel
        self.searchTextField = self.searchWrapper.searchUITextField
        self.confirmControllerProvider = confirmControllerProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.title = BundleI18n.LarkUrgent.Lark_Legacy_UrgentPickerTitle
        /// 添加导航取消按钮
        self.addCancelItem()
        self.closeCallback = { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
            UrgentTracker.trackImDingReceiverSelectClick(click: "cancel",
                                                         target: "im_chat_main_view",
                                                         chat: self.viewModel.chat,
                                                         message: self.viewModel.message)
        }
        /// 添加搜索文本框
        self.searchTextField.canEdit = true
        self.searchTextField.placeholder = BundleI18n.LarkUrgent.Lark_Legacy_SearchMember
        self.view.addSubview(self.searchWrapper)
        self.searchWrapper.backgroundColor = UIColor.ud.bgBody
        self.searchWrapper.snp.makeConstraints({ make in
            make.left.right.top.equalToSuperview()
        })
        /// 添加tooBar
        self.pickerToolBar.setItems(
            self.pickerToolBar.toolbarItems(),
            animated: false)
        self.pickerToolBar.allowSelectNone = false
        self.pickerToolBar.updateSelectedItem(
            firstSelectedItems: [],
            secondSelectedItems: [],
            updateResultButton: true)
        self.pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            self?.confirmRemove()
        }
        self.view.addSubview(self.pickerToolBar)

        self.pickerToolBar.snp.updateConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.avoidKeyboardBottom)
        }
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.searchWrapper.snp.bottom).offset(-6)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(self.pickerToolBar.snp.top)
        }
        let tableHeaderView = UrgentChatterTableHeader()
        self.tableHeaderView = tableHeaderView
        self.tableHeaderView?.backgroundColor = UIColor.ud.bgBase
        tableHeaderView.delegate = self
        self.tableView.tableHeaderView = tableHeaderView
        tableHeaderView.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.height.equalTo(66)
            make.width.equalToSuperview()
        }
        self.view.bringSubviewToFront(self.pickerToolBar)
        /// 绑定事件
        self.bandingViewModelEvent()
        self.bandingTableViewModelEvent()
        self.bandingSearchTextFieldEvent()
        /// 开始加载数据，会异步拉取
        self.viewModel.firstLoadData()

        // track
        UrgentTracker.trackImDingReceiverSelectView(chat: viewModel.chat, message: viewModel.message)
    }

    private func refreshFotterView() {
        self.bottomCoverView.title = self.tableViewModel.bottomTipMessage
        let showTipView = self.tableViewModel.shouldShowTipView
        let filterKeyIsEmpty = self.viewModel.filterKey?.isEmpty ?? true
        let footerView = (showTipView && filterKeyIsEmpty) ? self.bottomCoverView : nil
        self.tableView.tableFooterView = footerView
    }

    /// 创建表格视图
    private func createTableView() -> ChatChatterBaseTable {
        let tableView = ChatChatterBaseTable()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.ud.bgBody
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: UrgentChatterCell.self)
        tableView.register(UrgentContactTableHeader.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: UrgentContactTableHeader.self))
        return tableView
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let tableFooter = self.tableView.tableFooterView {
            tableFooter.frame = ChatterListBottomTipView.defaultFrame(self.view.bounds.width)
            self.tableView.tableFooterView = tableFooter
        }
    }
    // MARK: - UITableViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchTextField.canResignFirstResponder == true {
            self.searchTextField.resignFirstResponder()
        }
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 取出对应的Cell & Item
        let cell = tableView.cellForRow(at: indexPath)
        guard let item = (cell as? UrgentChatterCellProtocol)?.item else { return }

        if let denyReason = item.hitDenyReason {
            var tip: String = BundleI18n.LarkUrgent.Lark_Legacy_ErrorMessageTip
            switch denyReason {
            case .sameTenantDeny:
                tip = BundleI18n.LarkUrgent.Lark_Server_Put_Urgent_OU_Deny_V1
            case .externalCoordinateCtl:
                tip = BundleI18n.LarkUrgent.Lark_Contacts_NoExternalCommunicationPermissions
            case .targetExternalCoordinateCtl:
                tip = BundleI18n.LarkUrgent.Lark_Contacts_OtherUserHasNoExternalCommunicationPermissions
            case .noFriendship:
                tip = BundleI18n.LarkUrgent.Lark_NewContacts_NeedToAddToContactstBuzzOneDialogContent
            case .beBlocked:
                tip = BundleI18n.LarkUrgent.Lark_IM_CantBuzzBlocked_Hover
            default:
                break
            }
            UDToast.showTips(with: tip, on: view.window ?? view)
            return
        }

        /// 获取所有选中的cell，刷新选中状态
        let cells = tableView.visibleCells.compactMap { (cell) -> UrgentChatterCellProtocol? in
            if let cell_ = cell as? UrgentChatterCellProtocol,
                cell_.item?.chatter.id == item.chatter.id {
                return cell_
            }
            return nil
        }

        if viewModel.isSelecteAllUnreadMode, !viewModel.isFetchAll {
            guard var cell = cell as? UrgentChatterCellProtocol else { return }
            if cell.isCheckboxSelected == true {
                cell.isCheckboxSelected = false
                self.tableViewModel.deselected(item)
            } else {
                cell.isCheckboxSelected = true
                self.tableViewModel.selected(item)
                /// 勿扰模式需要弹toast
                if (item.itemTags ?? []).contains { $0.tagType == .doNotDisturb } {
                    UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_Notification_DndBuzzTips, on: view.window ?? view)
                }
            }
        } else {
            /// 向tableViewModel传递UrgentChatterModel
            if self.tableViewModel.isItemSelected(item) {
                for var cell in cells { cell.isCheckboxSelected = false }
                self.tableViewModel.deselected(item)
            } else {
                for var cell in cells { cell.isCheckboxSelected = true }
                self.tableViewModel.selected(item)
                /// 勿扰模式需要弹toast
                if (item.itemTags ?? []).contains { $0.tagType == .doNotDisturb } {
                    UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_Notification_DndBuzzTips, on: view.window ?? view)
                }
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int) -> CGFloat {
        guard section < self.tableViewModel.datas.count,
            let title = self.tableViewModel.datas[section].title else { return 0 }
        return title.isEmpty ? 0 : 30
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int) -> UIView? {
        guard section < self.tableViewModel.datas.count else { return nil }

        let sectionItem = self.tableViewModel.datas[section]
        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: sectionItem.sectionHeaderClass))
        if let header = header as? UrgentContactTableHeader {
            header.setContent(sectionItem.indexKey)
        }
        return header
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !self.tableViewModel.shouldShowTipView else { return nil }
        return self.tableViewModel.datas.map { $0.indexKey }
    }
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableViewModel.datas.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
        guard section < self.tableViewModel.datas.count else { return 0 }

        return self.tableViewModel.datas[section].items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < self.tableViewModel.datas.count,
            indexPath.row < self.tableViewModel.datas[indexPath.section].items.count else {
                return UITableViewCell()
        }

        let item = self.tableViewModel.datas[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.itemCellClass), for: indexPath)
        if var itemCell = cell as? UrgentChatterCellProtocol {
            itemCell.set(item, filterKey: self.viewModel.filterKey)
            // 全选未读场景 & 未全部拉取
            if viewModel.isSelecteAllUnreadMode, !viewModel.isFetchAll {
                if viewModel.unselectedChatterIdsWhenAllSelectedUnreadSet.contains(item.id) {
                    itemCell.isCheckboxSelected = false
                } else if viewModel.selectedReadChatterIdsWhenAllSelectedUnreadSet.contains(item.id) {
                    itemCell.isCheckboxSelected = true
                } else {
                    itemCell.isCheckboxSelected = !item.isRead
                }
            } else {
                itemCell.isCheckboxSelected =
                    self.tableViewModel.selectedItems.contains(
                        where: { $0.chatter.id == item.chatter.id })
            }
        }

        return cell
    }
}

private extension UrgentPickerController {
    func confirmRemove() {
        let mode: UrgentConfirmDisplayMode
        if viewModel.isSelecteAllUnreadMode {
            mode = .group(self.viewModel.groups, self.viewModel.unselectedChatterIdsWhenAllSelectedUnread, self.viewModel.selectedReadChatterIdsWhenAllSelectedUnread)
            let allCount = self.viewModel.groups.reduce(0) { partialResult, group in
                return partialResult + group.allCount
            }
            if true {
                let disableCount = self.viewModel.unselectedChatterIdsWhenAllSelectedUnread.count
                let addtionalCount = self.viewModel.selectedReadChatterIdsWhenAllSelectedUnread.count
                Self.logger.info("""
                    UrgentPicker select group mode, groupsCount = \(self.viewModel.groups.count), allCount = \(allCount), disableCount = \(disableCount), addtionalCount= \(addtionalCount)
                """)
            }
        } else {
            let chatterWrappers = self.viewModel.tableViewModel.selectedItems.map { item in
                ChatterWrapper(chatter: item.chatter, unSupportChatterType: item.unSupportChatterType)
            }
            Self.logger.info("UrgentPickerController select single mode, selectCount = \(self.viewModel.tableViewModel.selectedItems.count)")
            mode = .single(chatterWrappers)
        }
        let controller = self.confirmControllerProvider(self.viewModel.message, mode) { [weak self] type, cancelAck in
            self?.sendSelected?(type, cancelAck)
        }
        self.navigationController?.pushViewController(controller, animated: true)
        // track
        UrgentTracker.trackImDingReceiverSelectClick(click: "confirm",
                                                     target: "im_ding_confirm_view", isAllUnreadMemberSelected: self.viewModel.isSelecteAllUnreadMode,
                                                     chat: self.viewModel.chat,
                                                     message: self.viewModel.message)
    }

    func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            self.loadingPlaceholderView.isHidden = false
        case .error(let error):
            loadingPlaceholderView.isHidden = true

            tableView.status = (viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas).isEmpty ? .empty : .display
            UDToast.showFailure(with: BundleI18n.LarkUrgent.Lark_Legacy_ErrorMessageTip,
                                on: view.window ?? view,
                                error: error)

            UrgentPickerController.logger.error("UrgentPickerController load data error", error: error)
        case .viewStatus(let status):
            self.loadingPlaceholderView.isHidden = true
            self.tableView.status = status

            self.tableViewModel.datas = self.getTableViewDatas()
            for chatter in self.viewModel.totalDenyChatters {
                self.tableViewModel.deselected(chatter)
            }
            self.loadingPlaceholderView.isHidden = true
            self.tableView.status = status

            self.tableHeaderView?.isEnabled = self.viewModel.canAllSelectedUnread

            // 取出上拉加载更多
            self.tableView.removeBottomLoadMore()
            self.tableView.reloadData()

            // 非搜索态，且有更多数据则添加上拉加载更多
            if !self.viewModel.isInSearch, let cursor = viewModel.cursor, !cursor.isEmpty {
                self.tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            }
        }
    }

    func bandingSearchTextFieldEvent() {
        self.searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.loadFilterData(text ?? "")
            }).disposed(by: self.disposeBag)
    }

    func bandingTableViewModelEvent() {
        self.tableViewModel.reloadData.throttle(.milliseconds(200))
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.refreshFotterView()
            }).disposed(by: self.disposeBag)
    }

    func bandingViewModelEvent() {
        self.viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: disposeBag)
        self.viewModel.tableViewModel.onSelected = { [weak self] (item) in
            self?.onSelected(item)
        }
        self.viewModel.tableViewModel.onDeSelected = { [weak self] (item) in
            self?.onDeselected(item)
        }
        self.viewModel.getDefalutSelectedItems = { [weak self] (items) in
            DispatchQueue.main.async {
                self?.tableViewModel.setDefaultSelectedItems(items)
                self?.pickerToolBar.updateSelectedItem(
                    firstSelectedItems: items,
                    secondSelectedItems: [],
                    updateResultButton: true)
            }
        }
    }

    /// 某个人被选中
    func onSelected(_ item: UrgentChatterModel) {
        Self.logger.info("onSelected: isFetchAll: \(viewModel.isFetchAll), isSelecteAllUnreadMode: \(viewModel.isSelecteAllUnreadMode)")
        // 拉取了全部人
        if viewModel.isFetchAll {
            fetchAllHandler()
        } else if viewModel.isSelecteAllUnreadMode {
            // 非拉取全部人状态 & 选择全部未读
            notFetchAllAndSelectAllUnreadHandler()
        } else {
            defaultHandler()
        }

        func fetchAllHandler() {
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.viewModel.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)
            // 如果没有未读的人不进行处理，否则会导致随便选择一个人都会将“全选未读成员”checkBox选中
            if !self.viewModel.unreadChatterIdsSet.isEmpty {
                // 如果当前所选包含所有未读的人员，就将“全选未读成员”的checkBox选中
                if Set(self.viewModel.tableViewModel.selectedItems.map({ $0.id })).isSuperset(of: self.viewModel.unreadChatterIdsSet) {
                    self.tableHeaderView?.isCheckboxSelected = true
                }
            }
        }

        // 非拉取全部人状态 & 选择了全部未读
        func notFetchAllAndSelectAllUnreadHandler() {
            if item.isRead {
                if !viewModel.selectedReadChatterIdsWhenAllSelectedUnreadSet.contains(item.id) {
                    viewModel.appendSelectedReadChatterIdsWhenAllSelectedUnreadWith(item)
                    self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll += 1
                }
            } else {
                if viewModel.unselectedChatterIdsWhenAllSelectedUnreadSet.contains(item.id) {
                    viewModel.removeUnselectedChatterIdsWhenAllSelectedUnreadWith(item)
                    self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll += 1
                }
            }
            // 取消全选态, 但选中了全部的情况下将全选态置为true
            if viewModel.unselectedChatterIdsWhenAllSelectedUnreadSet.isEmpty, self.tableHeaderView?.isCheckboxSelected == false {
                self.tableHeaderView?.isCheckboxSelected = true
            }
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: [Int?](repeating: nil, count: Int(self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll)),
                secondSelectedItems: [],
                updateResultButton: true)
        }

        func defaultHandler() {
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.viewModel.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)
        }
    }

    /// 某个人取消选中
    func onDeselected(_ item: UrgentChatterModel) {
        Self.logger.info("onDeselected: isFetchAll: \(viewModel.isFetchAll), isSelecteAllUnreadMode: \(viewModel.isSelecteAllUnreadMode)")
        // 拉取全部人状态
        if viewModel.isFetchAll {
            fetchAllHandler()
        } else if viewModel.isSelecteAllUnreadMode {
            // 非拉取全部人状态 & 选择了全部未读
            notFetchAllAndSelectAllUnreadHandler()
        } else {
            defaultHandler()
        }

        func fetchAllHandler() {
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.viewModel.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)
            // 如果当前弃选的人属于未读人员，就将“全选未读成员”的checkBox置为未选中
            if !item.isRead && item.hitDenyReason == nil {
                self.tableHeaderView?.isCheckboxSelected = false
            }
        }

        func notFetchAllAndSelectAllUnreadHandler() {
            if item.isRead {
                if viewModel.selectedReadChatterIdsWhenAllSelectedUnreadSet.contains(item.id) {
                    viewModel.removeSelectedReadChatterIdsWhenAllSelectedUnreadWith(item)
                    if self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll > 0 {
                        self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll -= 1
                    }
                }
            } else {
                // 如果当前弃选的人属于未读人员，就将“全选未读成员”的checkBox置为未选中
                if item.hitDenyReason == nil {
                    self.tableHeaderView?.isCheckboxSelected = false
                }
                if !viewModel.unselectedChatterIdsWhenAllSelectedUnreadSet.contains(item.id) {
                    viewModel.appendUnselectedChatterIdsWhenAllSelectedUnreadWith(item)
                    if self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll > 0 {
                        self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll -= 1
                    }
                }
            }
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: [Int?](repeating: nil, count: Int(self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll)),
                secondSelectedItems: [],
                updateResultButton: true)
        }

        func defaultHandler() {
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.viewModel.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)
        }
    }

    private func getTableViewDatas() -> [UrgentChatterSectionData] {
        return self.viewModel.isInSearch ? self.viewModel.searchDatas.getImmutableCopy() : self.viewModel.datas.getImmutableCopy()
    }
}

extension UrgentPickerController: UrgentChatterTableHeaderDelegate {
    func showLoading() {
        UDToast.showLoading(on: view)
    }

    func hiddenLoading() {
        UDToast.removeToast(on: view)
    }

    // 点击全选未读按钮
    func onAllUnreadChattersSelected() {
        guard self.viewModel.canAllSelectedUnread else {
            UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_buzz_SelectUnreadMembersSecurity, on: view.window ?? view)
            return
        }
        UrgentTracker.trackUnreadCheckboxSelect()
        Self.logger.info("onAllUnreadChattersSelected: isFetchAll: \(viewModel.isFetchAll)")
        // 当拉取了全部人员
        if viewModel.isFetchAll {
            fetchAllHanlder()
        } else {
            // 当未拉取全部人员
            notFetchAllHandler()
        }

        func fetchAllHanlder() {
            self.tableHeaderView?.isCheckboxSelected = true
            let unSelectedUnreadChatterIds = self.viewModel.unreadChatterIdsSet.subtracting(self.tableViewModel.selectedItems.map { $0.id })
            let unSelectedUnreadChatters = self.viewModel.unreadChatters.filter {
                unSelectedUnreadChatterIds.contains($0.chatter.id)
            }

            self.tableViewModel.selectedItems.append(contentsOf: unSelectedUnreadChatters)
            for chatter in self.viewModel.totalDenyChatters {
                self.tableViewModel.deselected(chatter)
            }

            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.viewModel.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)

            self.tableView.reloadData()
        }

        func notFetchAllHandler() {
            self.showLoading()
            // 调用接口查找全选未读的列表
            self.viewModel.pullSelectUrgentChattersRequest()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] res in
                    guard let self = self else { return }
                    self.viewModel.groups = res
                    // 取消加载
                    self.hiddenLoading()

                    // 处理数据
                    if res.allSatisfy { $0.displayChatters.isEmpty } {
                        Self.logger.info("selectUnreadMembersAllReadTipsDidShow")
                        UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_buzz_SelectUnreadMembersAllRead, on: self.view.window ?? self.view)
                        return
                    }

                    // 重置标记
                    self.tableHeaderView?.isCheckboxSelected = true
                    self.viewModel.isSelecteAllUnreadMode = true

                    let allCount = res.reduce(0) { partialResult, group in
                        return partialResult + group.allCount
                    }
                    self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll = Int64(allCount)
                    Self.logger.info("pullSelectUrgentChattersRequest allCount = \(allCount)")

                    for chatter in self.viewModel.totalDenyChatters {
                        self.tableViewModel.deselected(chatter)
                    }

                    // 刷新UI
                    self.pickerToolBar.updateSelectedItem(
                        firstSelectedItems: [Int?](repeating: nil, count: Int(self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll)),
                        secondSelectedItems: [],
                        updateResultButton: true)

                    self.tableView.reloadData()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    UDToast.showFailure(with: "error", on: self.view, error: error)
                }).disposed(by: disposeBag)
        }
    }

    // 取消全选未读按钮
    func onAllUnreadChattersDeselected() {
        Self.logger.info("onAllUnreadChattersDeselected: isFetchAll: \(viewModel.isFetchAll)")
        // 当拉取了全部人员
        if viewModel.isFetchAll {
            self.tableHeaderView?.isCheckboxSelected = false

            let itemIds = Set(self.viewModel.unreadChatters.map { $0.chatter.id })
            self.tableViewModel.selectedItems.removeAll(where: { itemIds.contains($0.chatter.id) })
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.viewModel.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)

            self.tableView.reloadData()
        } else {
            // 当未拉取全部人员
            // 重置标记
            self.tableHeaderView?.isCheckboxSelected = false
            self.viewModel.isSelecteAllUnreadMode = false

            // 处理数据
            self.tableViewModel.selectedItems.removeAll(where: { $0.isRead == false })
            self.viewModel.selectedReadChatterIdsWhenAllSelectedUnread = self.tableViewModel.selectedItems.map({ $0.id })
            self.viewModel.unselectedChatterIdsWhenAllSelectedUnread.removeAll()
            self.viewModel.allCountWhenAllSelectedUnreadAndNotFetchAll = 0
            self.viewModel.groups = []

            // 刷新UI
            self.pickerToolBar.updateSelectedItem(
                firstSelectedItems: self.tableViewModel.selectedItems,
                secondSelectedItems: [],
                updateResultButton: true)
            self.tableView.reloadData()
        }
    }
}
