//
//  TeamMemberViewController.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/20.
//

import UIKit
import Foundation
import RxSwift
import LarkTag
import RxRelay
import LarkModel
import EENavigator
import LarkNavigator
import LarkContainer
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import UniverseDesignActionPanel
import UniverseDesignColor
import LarkUIKit
import SnapKit
import LarkAlertController
import LKCommonsLogging
import LarkSDKInterface
import LarkKeyCommandKit
import LarkKeyboardKit
import LKCommonsTracker
import Homeric
import LarkCore
import LarkGuideUI
import UniverseDesignShadow
import LarkGuide

// 团队成员列表
final class TeamMemberViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    typealias SelectedChangeHandler = (_ delta: [TeamMemberItem], _ total: [TeamMemberItem]) -> Void
    typealias TapHandler = (_ item: TeamMemberItem) -> Void

    let disposeBag = DisposeBag()

    lazy var tableView = TeamMemberBaseTableView(frame: .zero, style: .plain)
    fileprivate lazy var bottomCoverView: ChatterListBottomTipView = {
        let view = ChatterListBottomTipView(frame: ChatterListBottomTipView.defaultFrame(self.view.frame.width))
        view.title = BundleI18n.LarkTeam.Lark_Group_HugeGroup_MemberList_Bottom
        return view
    }()

    private(set) var selectedItems: [TeamMemberItem] = []
    var displayMode = TeamMemberDisplayMode.display {
        didSet {
            self.tableView.reloadData()
            if displayMode == .display {
                selectedItems = []
            }
        }
    }

    let pickerToolBar = DefaultPickerToolBar()

    private var uiDatas: [TeamMemberItem] = []

    let viewModel: TeamMemberViewModel
    let rightBarItem: LKBarButtonItem
    let leftBarItem: LKBarButtonItem
    let searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField

    init(viewModel: TeamMemberViewModel) {
        self.viewModel = viewModel
        self.rightBarItem = LKBarButtonItem(image: Resources.icon_more_outlined, title: nil)
        self.leftBarItem = LKBarButtonItem(image: nil, title: BundleI18n.LarkTeam.Project_MV_SkipButton)
        self.searchTextField = self.searchWrapper.searchUITextField
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 在有外接键盘的 iPad 上，自动聚焦 searchTextField
        if Display.pad && KeyboardKit.shared.keyboardType == .hardware {
            searchTextField.becomeFirstResponder()
        }
    }

    private func setup() {
        viewModel.targetVC = self
        viewModel.delegate = self
        searchTextField.delegate = self
        searchTextField.canEdit = true
        searchTextField.placeholder = self.viewModel.searchPlaceHolder
        if Feature.teamSearchEnable(userID: self.viewModel.currentUserId) {
            self.view.addSubview(searchWrapper)
            searchWrapper.snp.makeConstraints { make in
                make.top.right.left.equalToSuperview()
                make.height.equalTo(66)
            }
        }

        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: TeamMemberListCell.self)
        tableView.register(
            ContactTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: ContactTableHeader.self))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            if Feature.teamSearchEnable(userID: self.viewModel.currentUserId) {
                maker.top.equalTo(searchWrapper.snp.bottom)
            } else {
                maker.top.equalToSuperview()
            }
            maker.right.left.bottom.equalToSuperview()
        }

        bindViewModelEvent()
        DispatchQueue.global().async { self.viewModel.loadFirstScreenData() }
        setupSubviews()
        bind()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let tableFooter = self.tableView.tableFooterView {
            tableFooter.frame = ChatterListBottomTipView.defaultFrame(self.view.bounds.width)
            self.tableView.tableFooterView = tableFooter
        }
    }

    @objc
    func rightBarItemTapped() {
        _rightBarItemTapped(type: viewModel.navItemType)
    }

    @objc
    func leftBarItemTapped() {
        disappear()
    }

    fileprivate func refreshFotterView() {
        tableView.tableFooterView = viewModel.shouldShowTipView && !viewModel.isInSearch ? bottomCoverView : nil
    }

    func changeViewStatus(_ status: TeamMemberViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            loadingPlaceholderView.isHidden = true
            tableView.status = (viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas).isEmpty ? .empty : .display
            UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
            TeamMemberViewModel.logger.error("GroupChatterViewController load data error", error: error)
        case .viewStatus(let status):
            uiDatas = viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas
            loadingPlaceholderView.isHidden = true
            tableView.status = status

            // 取出上拉加载更多
            tableView.removeBottomLoadMore()
            tableView.reloadData()
            self.changeRightBarItemStyleForNormal()
            DispatchQueue.main.async {
                self.tryShowGuide()
            }
            if viewModel.hasMoreData() {
                tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            }
            self.refreshFotterView()
        }
    }

    func bindViewModelEvent() {
        viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: disposeBag)

        searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.filterKey = text
                self?.viewModel.loadSearchData()
            }).disposed(by: disposeBag)
    }

    // 多选模式下，点击Cell选择
    func whenSelected(_ item: TeamMemberItem) {
        selectedItems.append(item)
        selectedItem(delta: [item], items: selectedItems)
    }

    // 多选模式下，点击Cell取消选择
    func whenDeselected(_ item: TeamMemberItem) {
        selectedItems.removeAll { $0.itemId == item.itemId }
        deselectedItem(delta: [item], items: selectedItems)
    }

    // 点击事件
    func onTapItem(_ item: TeamMemberItem) {
        if self.searchTextField.canResignFirstResponder {
            self.searchTextField.resignFirstResponder()
        }
        tapItem(item: item)
    }

    //滚动时收起键盘
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchTextField.canResignFirstResponder == true {
            self.searchTextField.resignFirstResponder()
        }
    }

    func cancelEditting() {
        self.tableView.setEditing(false, animated: true)
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

    // MARK: - UITableViewDelegatef

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 抹掉背景
        tableView.deselectRow(at: indexPath, animated: true)

        // 取出对应的Cell & Item
        guard let cell = tableView.cellForRow(at: indexPath) as? TeamMemberCellInterface,
            let item = cell.item else { return }

        switch displayMode {
        case .display:
            onTapItem(item)
        case .multiselect:
            guard item.isSelectedable else { return }
            if selectedItems.contains(where: { $0.itemId == item.itemId }) {
                cell.isCheckboxSelected = false
                whenDeselected(item)
            } else {
                cell.isCheckboxSelected = true
                whenSelected(item)
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uiDatas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < uiDatas.count else {
            return UITableViewCell(frame: .zero)
        }

        let item = uiDatas[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.itemCellClass), for: indexPath) as? TeamMemberCellInterface else {
            return UITableViewCell(frame: .zero)
        }
        cell.set(item, filterKey: viewModel.filterKey, from: self, teamId: String(self.viewModel.teamId))
        // 重置cell状态
        cell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: false)
        if displayMode == .multiselect {
            // 处理默认选中无法点击的cell
            cell.setCellSelect(canSelect: true, isSelected: selectedItems.contains(where: { $0.itemId == item.itemId }), isCheckboxHidden: false)
        } else {
            cell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: true)
        }
        return cell
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            tryShowGuide()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        tryShowGuide()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        tryShowGuide()
    }
}

extension TeamMemberViewController {
    /// 仅限移除群成员使用
    func removeSelectedItems() {
        self.viewModel.removeChatterBySelectedItems(selectedItems)
    }

    /// 对外开放刷新UI的接口
    func reloadData() {
        tableView.reloadData()
    }
}

extension TeamMemberViewController: TeamMemberVMDelegate {
    func getCellByIndexPath(_ indexPath: IndexPath) -> TeamMemberCellInterface? {
        guard let cell = tableView.cellForRow(at: indexPath) as? TeamMemberCellInterface else { return nil }
        return cell
    }
}
