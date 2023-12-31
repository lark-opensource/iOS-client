//
//  ChatChatterController.swift
//  LarkCore
//
//  Created by kongkaikai on 2019/5/28.
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
import UniverseDesignTabs
import UniverseDesignToast
import RxRelay
import RxSwift
import Homeric
import LarkContainer

@frozen
public enum ChatChatterDisplayMode {
    case display
    case multiselect
}

public protocol ChatChatterControllerLifeCircle: AnyObject {
    func onDataLoad(_ error: Error?)
    func onSearchBegin(key: String)
    func onSearchResult(key: String?, _ error: Error?)
    func onRemoveBegin()
    func onRemoveEnd(_ error: Error?)
}

public final class ChatChatterController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource,
                                          UITextFieldDelegate, TableViewKeyboardHandlerDelegate {
    public typealias SelectedChangeHandler = (_ delta: [ChatChatterItem], _ total: [ChatChatterItem]) -> Void
    public typealias TapHandler = (_ item: ChatChatterItem) -> Void

    static let logger = Logger.log(ChatChatterController.self, category: "Module.IM.ChatChatterController")

    private let disposeBag = DisposeBag()

    private var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField
    private var selectedView = SelectedCollectionView()
    private lazy var tableView: ChatChatterBaseTable = ChatChatterBaseTable(frame: .zero, style: .plain)

    enum SectionIndexViewStyle {
        case none
        case scrolling(Int)
        case end(Int)
        case cancel(Int)
    }

    private var sectionIndexViewStyle: SectionIndexViewStyle = .none
    private lazy var sectionIndexView: UDSectionIndexView = {
        let indexView = UDSectionIndexView(frame: .zero)
        indexView.delegate = self
        indexView.dataSource = self
        indexView.itemPreviewMargin = 20
        return indexView
    }()

    private var lastContentOffset: CGFloat = 0
    private var updateUUID = UUID()

    fileprivate lazy var bottomCoverView: ChatterListBottomTipView = {
        let view = ChatterListBottomTipView(frame: ChatterListBottomTipView.defaultFrame(self.view.frame.width))
        view.title = BundleI18n.LarkCore.Lark_Group_HugeGroup_MemberList_Bottom
        return view
    }()
    fileprivate lazy var securityBottomCoverView: ChatterListBottomTipView = {
        let view = ChatterListBottomTipView(frame: ChatterListBottomTipView.defaultFrame(self.view.frame.width))
        view.title = BundleI18n.LarkCore.Lark_IM_ListEndsDueToSecurityConcerns_Text
        return view
    }()

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

    private let impactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var isViewDidApper: Bool = false
    public private(set) var selectedItems: [ChatChatterItem] = []
    public var displayMode = ChatChatterDisplayMode.display {
        didSet {
            guard isViewDidApper else { return }
            self.tableView.reloadData()
            self.lastContentOffset = 0
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
    public weak var lifeCircle: ChatChatterControllerLifeCircle?

    private(set) var viewModel: ChatterControllerVM

    private var datas: [ChatChatterSection] = []
    private var searchDatas: [ChatChatterSection] = []
    var canSildeRelay: BehaviorRelay<Bool>?

    public init(viewModel: ChatterControllerVM,
                canSildeRelay: BehaviorRelay<Bool>?) {
        self.viewModel = viewModel
        self.canSildeRelay = canSildeRelay
        self.searchTextField = self.searchWrapper.searchUITextField
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody

        viewModel.targetVC = self
        viewModel.delegate = self
        searchTextField.canEdit = true
        searchTextField.placeholder = self.viewModel.searchPlaceHolder
        searchTextField.delegate = self
        self.view.addSubview(selectedView)
        selectedView.setSelectedCollectionView(selectItems: [], didSelectBlock: { [weak self] (item) in
            self?.selectedViewSeleced(item)
        }, animated: false)

        if let viewModel = viewModel as? ChatChatterControllerVM, !viewModel.isAbleToSearch {
            selectedView.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.left.right.equalToSuperview()
                maker.height.equalTo(44)
            }
        } else {
            self.view.addSubview(searchWrapper)
            searchWrapper.snp.makeConstraints({ make in
                make.left.right.top.equalToSuperview()
            })
            selectedView.snp.makeConstraints { (maker) in
                maker.top.equalTo(searchWrapper.snp.bottom)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(44)
            }
        }

        tableView.estimatedRowHeight = 68
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.lu.register(cellSelf: ChatChatterCell.self)
        tableView.lu.register(cellSelf: ChatChatterLeanCell.self)
        tableView.lu.register(cellSelf: UITableViewCell.self)
        tableView.register(
            ContactTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: ContactTableHeader.self))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.right.equalToSuperview()
        }

        // 指示条
        self.view.addSubview(self.sectionIndexView)
        self.sectionIndexView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-6)
            make.width.equalTo(20)
            make.height.equalTo(0)
        }

        keyboardHandler = TableViewKeyboardHandler()
        keyboardHandler?.delegate = self

        bindViewModelEvent()
        addSearchObserver()
        DispatchQueue.global().async { self.viewModel.loadFirstScreenData() }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewDidApper = true
        // 在有外接键盘的 iPad 上，自动聚焦 searchTextField
        if Display.pad && KeyboardKit.shared.keyboardType == .hardware {
            searchTextField.becomeFirstResponder()
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let tableFooter = self.tableView.tableFooterView {
            tableFooter.frame = ChatterListBottomTipView.defaultFrame(self.view.bounds.width)
            self.tableView.tableFooterView = tableFooter
        }
    }

    public func reset() {
        if self.searchTextField.canResignFirstResponder == true {
            self.searchTextField.resignFirstResponder()
        }
        self.searchTextField.text = ""
        let zero = IndexPath(row: 0, section: 0)
        guard self.tableView.cellForRow(at: zero) != nil else { return }
        self.tableView.scrollToRow(at: zero, at: .top, animated: false)
    }

    // MARK: - ChatChatterController
    fileprivate func refreshFotterView() {
        let vm = viewModel as? ChatChatterControllerVM
        let bottomCoverTipView = (vm?.isAbleToSearch == false) ? securityBottomCoverView : bottomCoverView
        tableView.tableFooterView = viewModel.shouldShowTipView && !viewModel.isInSearch ? bottomCoverTipView : nil
    }

    func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            if viewModel.isInSearch {
                lifeCircle?.onSearchResult(key: nil, error)
            } else {
                lifeCircle?.onDataLoad(error)
            }
            loadingPlaceholderView.isHidden = true

            tableView.status = (viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas).isEmpty ? .empty : .display
            UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)

            ChatChatterController.logger.error("GroupChatterViewController load data error", error: error)
        case .viewStatus(let status):
            if viewModel.isInSearch {
                if status.isSearchNoResult ||
                    !viewModel.searchDatas.isEmpty {
                    lifeCircle?.onSearchResult(key: viewModel.filterKey, nil)
                }
            } else {
                lifeCircle?.onDataLoad(nil)
            }
            let newDatas = viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas
            if newDatas.isEmpty != datas.isEmpty {
                self.updateSectionIndexView(isShow: !newDatas.isEmpty)
            }
            self.datas = newDatas
            loadingPlaceholderView.isHidden = true
            tableView.status = status
            tableView.showsVerticalScrollIndicator = viewModel.sortType != .alphabetical

            // 取出上拉加载更多
            tableView.removeBottomLoadMore()
            switch self.sectionIndexViewStyle {
            case .none:
                self.tableView.reloadData()
                self.lastContentOffset = 0
                self.refreshSectionIndexView()
                if let section = self.tableView.indexPathsForVisibleRows?.first?.section,
                   self.sectionIndexView.currentItem != self.sectionIndexView.item(at: section) {
                    self.sectionIndexView.selectItem(at: section)
                }
            case .scrolling(_), .end(_), .cancel(_):
                break
            }
            // 非搜索态，且有更多数据则添加上拉加载更多
            if !viewModel.isInSearch, viewModel.hasMoreData(), viewModel.sortType != .alphabetical {
                tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            }
            if status != .update {
                self.refreshFotterView()
                self.sectionIndexView.selectItem(at: 0)
            }
        }
    }

    func updateSectionIndexView(isShow: Bool) {
        tableView.snp.remakeConstraints { (maker) in
            maker.top.equalTo(selectedView.snp.top).offset(0)
            maker.bottom.left.equalToSuperview()
            maker.right.equalToSuperview().offset(isShow ? -8 : 0)
        }
        self.sectionIndexView.isHidden = !isShow
    }

    func loadDefaultSelectedItems(_ items: [ChatChatterItem]) {
        selectedItems = items
        selectedView.selectItems = items.compactMap { $0 as? SelectedCollectionItem }
        selectedView.selectedCollectionView.reloadData()
        onSelected?(items, items)
        refreshUI(0)
    }

    func bindViewModelEvent() {
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
        let shouldSelectedViewShow = viewModel.showSelectedView && !selectedItems.isEmpty
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

    public func cancelEditting() {
        self.tableView.setEditing(false, animated: true)
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
                self?.lifeCircle?.onSearchBegin(key: text ?? "")
                self?.viewModel.loadFilterData(text ?? "")
                self?.keyboardHandler?.resetFocus()
            }).disposed(by: disposeBag)
    }

    private func refreshSectionIndexView() {
        self.sectionIndexView.snp.updateConstraints({ (make) in
            make.height.equalTo(16 * CGFloat(self.datas.count))
        })

        self.sectionIndexView.superview?.layoutIfNeeded()
        self.sectionIndexView.reloadData()
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
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
        if section >= datas.count || datas[section].title?.isEmpty ?? true || !datas[section].showHeader {
            return 0
        }

        return 28
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

    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datas.count else { return 0 }
        let count = datas[section].items.count
        return count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section < datas.count, indexPath.row < datas[indexPath.section].items.count {

            let item = datas[indexPath.section].items[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.itemCellClass),
                                                 for: indexPath)

            if let itemCell = cell as? ChatChatterCellProtocol {
                itemCell.set(item, filterKey: viewModel.filterKey, userResolver: viewModel.userResolver)
                // 重置cell状态
                itemCell.setCellSelect(canSelect: true, isSelected: false, isCheckboxHidden: false)
                if displayMode == .multiselect {
                    // 处理默认选中无法点击的cell
                    if let id = itemCell.item?.itemId, let isContain = viewModel.defaultUnableCancelSelectedIds?.contains(id), isContain {
                        itemCell.setCellSelect(canSelect: false, isSelected: true, isCheckboxHidden: false)
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

    // MARK: - UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.viewModel.sortType == .alphabetical else { return }
        self.tableView.indexPathsForRows(in: self.tableView.bounds)

        let uuid = UUID()
        self.updateUUID = uuid
        switch self.sectionIndexViewStyle {
        case .none:
            break
        case .scrolling(let section):
            self.viewModel.loadMoreData(.upAndDown(indexPath: IndexPath(row: 0, section: section)))
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                if uuid == self.updateUUID {
                    self.tableView.reloadData()
                    self.sectionIndexViewStyle = .none
                    self.lastContentOffset = 0
                    self.refreshSectionIndexView()
                    if let section = self.tableView.indexPathsForVisibleRows?.first?.section,
                       self.sectionIndexView.currentItem != self.sectionIndexView.item(at: section) {
                        self.sectionIndexView.selectItem(at: section)
                    }
                }
            }
            return
        case .end(let section):
            self.sectionIndexViewStyle = .none
            self.lastContentOffset = scrollView.contentOffset.y
            self.viewModel.loadMoreData(.upAndDown(indexPath: IndexPath(row: 0, section: section)))
            return
        case .cancel(let section):
            self.sectionIndexViewStyle = .none
            self.lastContentOffset = scrollView.contentOffset.y
            self.viewModel.loadMoreData(.upAndDown(indexPath: IndexPath(row: 0, section: section)))
            return
        }

        if let section = self.tableView.indexPathsForVisibleRows?.first?.section,
           self.sectionIndexView.currentItem != self.sectionIndexView.item(at: section) {
            self.sectionIndexView.selectItem(at: section)
        }

        var loader: ChatterControllerVM.DataLoader = .none

        if self.lastContentOffset > scrollView.contentOffset.y, let indexPath = self.tableView.indexPathsForVisibleRows?.first {
            loader = .up(indexPath: indexPath)
        } else if self.lastContentOffset < scrollView.contentOffset.y, let indexPath = self.tableView.indexPathsForVisibleRows?.last {
            loader = .down(indexPath: indexPath)
        }
        self.lastContentOffset = scrollView.contentOffset.y

        self.viewModel.loadMoreData(loader)
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        onClickSearch?()
    }
}

public extension ChatChatterController {
    /// 仅限移除群成员使用
    func removeSelectedItems() {
        let lifeCircle = self.lifeCircle
        lifeCircle?.onRemoveBegin()
        self.viewModel.removeChatterBySelectedItems(selectedItems)
    }

    /// 直接更新选中的items
    func setDefaultSelectedItems(_ items: [ChatChatterItem]) {
        loadDefaultSelectedItems(items)
        tableView.reloadData()
        self.lastContentOffset = 0
    }

    /// 对外开放刷新UI的接口
    func reloadData() {
        tableView.reloadData()
        self.lastContentOffset = 0
    }
}

extension ChatChatterController: ChatterControllerVMDelegate {
    public func getCellByIndexPath(_ indexPath: IndexPath) -> ChatChatterCellProtocol? {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatChatterCellProtocol else { return nil }
        return cell
    }

    public func canLeftSlide() -> Bool {
        return canSildeRelay?.value ?? false
    }

    public func onRemoveEnd(_ error: Error?) {
        self.lifeCircle?.onRemoveEnd(error)
    }
}

// MARK: - SectionIndexViewDataSource
extension ChatChatterController: UDSectionIndexViewDataSource, UDSectionIndexViewDelegate {

    public func numberOfItemViews(in sectionIndexView: UDSectionIndexView) -> Int {
        return self.datas.count
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemViewAt section: Int) -> UDSectionIndexViewItem {
        let itemView = UDSectionIndexViewItem()
        guard section < self.datas.count else { return itemView }

        itemView.titleFont = UIFont.systemFont(ofSize: 14)
        itemView.selectedColor = UIColor.clear
        itemView.titleSelectedColor = UIColor.ud.textLinkNormal
        itemView.titleColor = UIColor.ud.textPlaceholder
        itemView.title = self.datas[section].title
        return itemView
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView,
                                 itemPreviewFor section: Int) -> UDSectionIndexViewItemPreview {
        let preview = UDSectionIndexViewItemPreview(title: self.datas[section].title, type: .drip)
        preview.color = UIColor.ud.colorfulBlue
        return preview
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, didSelect section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section, hideAfter: 0.2)
        // 过滤空section的情况
        if section < tableView.numberOfSections,
           tableView.numberOfRows(inSection: section) > 0 {
            let indexPath = IndexPath(row: 0, section: section)
            self.sectionIndexViewStyle = .end(section)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheMoved section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section)
        // 过滤空section的情况
        if section < tableView.numberOfSections,
           tableView.numberOfRows(inSection: section) > 0 {
            let indexPath = IndexPath(row: 0, section: section)
            self.sectionIndexViewStyle = .scrolling(section)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheCancelled section: Int) {
        if let section = self.tableView.indexPathsForVisibleRows?.first?.section {
            self.sectionIndexView.selectItem(at: section)
            self.sectionIndexViewStyle = .cancel(section)
        }
    }
}
