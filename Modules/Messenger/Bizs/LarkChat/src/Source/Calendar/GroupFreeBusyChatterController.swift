//
//  GroupFreeBusyChatterController.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/7/30.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LKCommonsLogging
import UniverseDesignToast
import RxSwift
import LarkCore
import LarkContainer

public final class GroupFreeBusyChatterController: BaseUIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    public typealias SelectedChangeHandler = (_ delta: [ChatChatterItem], _ total: [ChatChatterItem]) -> Void
    public typealias TapHandler = (_ item: ChatChatterItem) -> Void

    static let logger = Logger.log(GroupFreeBusyChatterController.self, category: "Module.IM.GroupFreeBusyChatterController")

    private let disposeBag = DisposeBag()

    private var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField
    private var selectedView = SelectedCollectionView()
    private lazy var tableView: ChatChatterBaseTable = ChatChatterBaseTable(frame: .zero, style: .plain)
    fileprivate lazy var bottomCoverView: ChatterListBottomTipView = {
        let view = ChatterListBottomTipView(frame: ChatterListBottomTipView.defaultFrame(self.view.frame.width))
        view.title = BundleI18n.LarkChat.Lark_Group_HugeGroup_MemberList_Bottom
        return view
    }()

    private var isViewDidApper: Bool = false
    public var showSelectedView: Bool = true
    public private(set) var selectedItems: [ChatChatterItem] = []
    public var displayMode = ChatChatterDisplayMode.display {
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

    private(set) var viewModel: GroupFreeBusyChatterControllerVM

    private var datas: [ChatChatterSection] = []

    public init(viewModel: GroupFreeBusyChatterControllerVM) {
        self.viewModel = viewModel
        self.searchTextField = self.searchWrapper.searchUITextField
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_Group_SearchGroupMember
        searchTextField.delegate = self
        self.view.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints({ make in
            make.left.right.top.equalToSuperview()
        })

        self.view.addSubview(selectedView)
        selectedView.setSelectedCollectionView(selectItems: [], didSelectBlock: { [weak self] (item) in
            self?.selectedViewSeleced(item)
            }, animated: false)
        selectedView.snp.makeConstraints { (maker) in
            maker.top.equalTo(searchWrapper.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(44)
        }

        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.ud.bgBody
        tableView.sectionIndexColor = UIColor.ud.bgBody
        tableView.lu.register(cellSelf: GroupFreeBusyChatterCell.self)
        tableView.register(ContactTableHeader.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: ContactTableHeader.self))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.right.equalToSuperview()
        }

        bandingViewModelEvent()
        addSearchObserver()
        DispatchQueue.global().async { self.viewModel.firstLoadData() }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewDidApper = true
    }
    // MARK: - UITableViewDelegate
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchTextField.canResignFirstResponder == true {
            self.searchTextField.resignFirstResponder()
        }
    }

    // swiftlint:disable did_select_row_protection
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // 抹掉背景
        tableView.deselectRow(at: indexPath, animated: true)

        // 取出对应的Cell & Item
        guard var cell = tableView.cellForRow(at: indexPath) as? ChatChatterCellProtocol,
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
                if selectedItems.count >= 30 {
                    UDToast.showTips(with: BundleI18n.Calendar.Calendar_ChatFindTime_Max, on: view)
                    return
                }
                cell.isCheckboxSelected = true
                whenSelected(item)
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= datas.count || datas[section].title?.isEmpty ?? true || datas[section].title == nil {
            return 0
        }

        return 30
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < datas.count {
            let sectionItem = datas[section]
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: sectionItem.sectionHeaderClass))
            (header as? ChatChatterSectionHeaderProtocol)?.set(sectionItem)
            return header
        }
        return nil
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.shouldShowTipView ? nil : datas.map { $0.indexKey }
    }
    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datas.count else { return 0 }
        return datas[section].items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section < datas.count, indexPath.row < datas[indexPath.section].items.count {

            let item = datas[indexPath.section].items[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.itemCellClass),
                                                 for: indexPath)

            if var itemCell = cell as? ChatChatterCellProtocol {
                itemCell.set(item, filterKey: viewModel.filterKey, userResolver: viewModel.userResolver)
                if displayMode == .multiselect {
                    itemCell.isCheckboxHidden = false
                    itemCell.isCheckboxSelected = selectedItems.contains(where: { $0.itemId == item.itemId })
                } else {
                    itemCell.isCheckboxHidden = true
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

extension GroupFreeBusyChatterController {
    fileprivate func refreshFotterView() {
        tableView.tableFooterView = viewModel.shouldShowTipView && !viewModel.isInSearch ? bottomCoverView : nil
    }

    func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            loadingPlaceholderView.isHidden = true

            tableView.status = (viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas).isEmpty ? .empty : .display
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)

            GroupFreeBusyChatterController.logger.error("GroupFreeBusyChatterController load data error", error: error)
        case .viewStatus(let status):
            datas = viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas

            loadingPlaceholderView.isHidden = true
            tableView.status = status

            // 取出上拉加载更多
            tableView.removeBottomLoadMore()
            tableView.reloadData()

            // 非搜索态，且有更多数据则添加上拉加载更多
            if !viewModel.isInSearch, let cursor = viewModel.cursor, !cursor.isEmpty {
                tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            }
            self.refreshFotterView()
        }
    }

    func loadDefaultSelectedItems(_ items: [ChatChatterItem]) {
        selectedItems = items
        selectedView.removeSelectAllItems()
        selectedView.addSelectItems(selectItems: items.compactMap { $0 as? SelectedCollectionItem })
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
    func whenSelected(_ item: ChatChatterItem) {
        selectedItems.append(item)
        onSelected?([item], selectedItems)

        guard let item = item as? SelectedCollectionItem else { return }

        self.selectedView.addSelectItem(selectItem: item)
        if selectedItems.count == 1 {
            refreshUI()
        }
    }

    // 多选模式下，点击Cell取消选择
    func whenDeselected(_ item: ChatChatterItem) {
        selectedItems.removeAll { $0.itemId == item.itemId }
        onDeselected?([item], selectedItems)

        guard let item = item as? SelectedCollectionItem else { return }

        self.selectedView.removeSelectItem(selectItem: item)
        if selectedItems.isEmpty {
            refreshUI()
        }
    }

    // 点击事件
    func onTapItem(_ item: ChatChatterItem) {
        if self.searchTextField.canResignFirstResponder {
            self.searchTextField.resignFirstResponder()
        }
        onTap?(item)
    }

    func selectedViewSeleced(_ item: SelectedCollectionItem) {
        let removeItems = selectedItems.filter { $0.itemId == item.id }
        selectedItems.removeAll { $0.itemId == item.id }
        onDeselected?(removeItems, selectedItems)

        tableView.visibleCells.forEach { (cell) in
            if var _cell = cell as? ChatChatterCellProtocol, _cell.item?.itemId == item.id {
                _cell.isCheckboxSelected = false
            }
        }

        if selectedItems.isEmpty {
            refreshUI()
        }
    }

    func addSearchObserver() {
        searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.loadFilterData(text ?? "")
            }).disposed(by: disposeBag)
    }
}
