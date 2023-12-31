//
//  GroupChattersSingleController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/30.
//

import Foundation
import UIKit
import RxSwift
import LarkCore
import LarkUIKit
import LarkModel
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignTabs
import LKCommonsLogging
import LarkSDKInterface
import RustPB
import LarkContainer

final class GroupChattersSingleController: BaseSettingController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    var sortType: ChatterSortType {
        return self.viewModel.sortType
    }

    enum SectionIndexViewStyle {
        case none
        case scrolling(Int)
        case end(Int)
        case cancel(Int)
    }

    private var sectionIndexViewStyle: SectionIndexViewStyle = .none
    private let logger = Logger.log(
        GroupChattersSingleController.self,
        category: "Module.IM.GroupChattersSingleController")
    private let disposeBag = DisposeBag()

    private var datas: [ChatChatterSection] = []

    private lazy var sectionIndexView: UDSectionIndexView = {
        let indexView = UDSectionIndexView(frame: .zero)
        indexView.delegate = self
        indexView.dataSource = self
        indexView.itemPreviewMargin = 20
        return indexView
    }()

    private var lastContentOffset: CGFloat = 0
    private var updateUUID = UUID()

    private let impactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var displayMode: ChatChatterDisplayMode = .display

    private let viewModel: GroupChattersSingleViewModel
    private var tableView: ChatChatterBaseTable = ChatChatterBaseTable(frame: .zero, style: .plain)

    private weak var dependency: GroupChattersSingleUIDependencyProtocol?

    private var hasFirstLoadData = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 68
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.sectionIndexBackgroundColor = UIColor.ud.bgBody
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: ChatChatterCell.self)
        tableView.lu.register(cellSelf: UITableViewCell.self)
        tableView.register(
            ContactTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: ContactTableHeader.self))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 指示条
        self.view.addSubview(self.sectionIndexView)
        self.sectionIndexView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-6)
            make.width.equalTo(20)
            make.height.equalTo(0)
        }

        if viewModel.condition == .nonDepartment {
            tableView.emptyPlaceholder = BundleI18n.LarkChatSetting.Lark_Group_OutsideDepartmentMemberEmpty
            tableView.emptyPlaceholderImage = UDEmptyType.noContent.defaultImage()
        }

        bandingViewModelEvent()
        bandingUIDependencyEvent()
        viewModel.firstLoadData()
        viewModel.observeData()
        dependency?.tracker.viewDidLoadEnd()
    }

    init(viewModel: GroupChattersSingleViewModel,
         dependency: GroupChattersSingleUIDependencyProtocol
    ) {
        self.viewModel = viewModel
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.viewModel.clearOrderedChatChatters()
        super.dismiss(animated: flag, completion: completion)
    }

    func updateSortType(_ sortType: ChatterSortType) {
        self.viewModel.updateSortType(sortType)
    }

    func updateSectionIndexView(isShow: Bool) {
        tableView.snp.remakeConstraints { (maker) in
            maker.top.bottom.left.equalToSuperview()
            maker.right.equalToSuperview().offset(isShow ? -8 : 0)
        }
        self.sectionIndexView.isHidden = !isShow
    }

    // MARK: - UITableViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dependency?.onTableDragging()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 抹掉背景
        tableView.deselectRow(at: indexPath, animated: true)

        // 取出对应的Cell & Item
        if var cell = tableView.cellForRow(at: indexPath) as? ChatChatterCellProtocol, let item = cell.item {
            self.dependency?.onTapItem(item) { (isSelected) in
                cell.isCheckboxSelected = isSelected
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= datas.count || datas[section].title?.isEmpty ?? true || !datas[section].showHeader {
            return 0
        }

        return 28
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < datas.count {
            let sectionItem = datas[section]

            let header = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: sectionItem.sectionHeaderClass))

            (header as? ChatChatterSectionHeaderProtocol)?.set(sectionItem)
            return header
        }
        return nil
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datas.count else { return 0 }
        return datas[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section < datas.count, indexPath.row < datas[indexPath.section].items.count {
            let item = datas[indexPath.section].items[indexPath.row]
            cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: item.itemCellClass),
                for: indexPath)

            if var itemCell = cell as? ChatChatterCellProtocol {
                itemCell.set(item, filterKey: viewModel.filterKey, userResolver: userResolver)

                if displayMode == .multiselect {
                    itemCell.isCheckboxHidden = false
                    itemCell.isCheckboxSelected = self.dependency?.isItemSelected(item) ?? false
                } else {
                    itemCell.isCheckboxHidden = true
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.lu.reuseIdentifier, for: indexPath)
        }

        return cell
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
}

// MARK: - SectionIndexViewDataSource
extension GroupChattersSingleController: UDSectionIndexViewDataSource, UDSectionIndexViewDelegate {

    func numberOfItemViews(in sectionIndexView: UDSectionIndexView) -> Int {
        return self.datas.count
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemViewAt section: Int) -> UDSectionIndexViewItem {
        let itemView = UDSectionIndexViewItem()
        guard section < self.datas.count else { return itemView }

        itemView.titleFont = UIFont.systemFont(ofSize: 14)
        itemView.selectedColor = UIColor.clear
        itemView.titleSelectedColor = UIColor.ud.textLinkNormal
        itemView.titleColor = UIColor.ud.textPlaceholder
        itemView.title = self.datas[section].title
        return itemView
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView,
                          itemPreviewFor section: Int) -> UDSectionIndexViewItemPreview {
        let preview = UDSectionIndexViewItemPreview(title: self.datas[section].title, type: .drip)
        preview.color = UIColor.ud.colorfulBlue
        return preview
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, didSelect section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section, hideAfter: 0.2)
        // 过滤空section的情况
        if tableView(self.tableView, numberOfRowsInSection: section) > 0 {
            let indexPath = IndexPath(row: 0, section: section)
            self.sectionIndexViewStyle = .end(section)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheMoved section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section)
        // 过滤空section的情况
        if tableView(self.tableView, numberOfRowsInSection: section) > 0 {
            let indexPath = IndexPath(row: 0, section: section)
            self.sectionIndexViewStyle = .scrolling(section)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheCancelled section: Int) {
        if let section = self.tableView.indexPathsForVisibleRows?.first?.section {
            self.sectionIndexView.selectItem(at: section)
            self.sectionIndexViewStyle = .cancel(section)
        }
    }
}

private extension GroupChattersSingleController {
    func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            loadingPlaceholderView.isHidden = true
            if !viewModel.isInSearch {
                dependency?.tracker.error(error)
            }

            tableView.status = (viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas).isEmpty ? .empty : .display

            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .noSecretChatPermission(let message):
                    UDToast.showFailure(with: message, on: view, error: error)
                case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                    UDToast.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                        on: view, error: error
                    )
                default:
                    UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                }
            } else {
                UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: view, error: error)
            }

            logger.error("GroupChatterViewController load data error", error: error)
        case .viewStatus(let status):
            if !hasFirstLoadData, !viewModel.isInSearch {
                hasFirstLoadData = true
                dependency?.tracker.sdkCostEnd()
                dependency?.tracker.end()
            }

            // 确定数据源
            let newDatas = viewModel.isInSearch ? viewModel.searchDatas : viewModel.datas
            if newDatas.isEmpty != datas.isEmpty {
                self.updateSectionIndexView(isShow: !newDatas.isEmpty)
            }
            self.datas = newDatas

            // 隐藏Loading
            loadingPlaceholderView.isHidden = true
            tableView.status = status
            tableView.showsVerticalScrollIndicator = viewModel.sortType != .alphabetical

            // 去除上拉加载更多
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
            if !viewModel.isInSearch, let cursor = viewModel.cursor, !cursor.isEmpty, viewModel.sortType != .alphabetical {
                tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            }

            if status != .update {
                self.sectionIndexView.selectItem(at: 0)
            }
        }
    }

    func bandingViewModelEvent() {
        viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: disposeBag)
    }

    private func refreshSectionIndexView() {
        self.sectionIndexView.snp.updateConstraints({ (make) in
            make.height.equalTo(16 * CGFloat(self.datas.count))
        })

        self.sectionIndexView.superview?.layoutIfNeeded()
        self.sectionIndexView.reloadData()
    }

    private func reloadSelectedStatus() {
        guard displayMode == .multiselect else { return }
        self.tableView.visibleCells.compactMap { $0 as? ChatChatterCell }.forEach { (cell) in
            if let item = cell.item {
                cell.isCheckboxSelected = self.dependency?.isItemSelected(item) ?? false
            } else {
                cell.isCheckboxSelected = false
            }
        }
    }

    func bandingUIDependencyEvent() {
        dependency?.displayMode.asDriver().drive(onNext: { [weak self] (mode) in
            guard let self = self else { return }
            self.displayMode = mode
            self.tableView.reloadData()
            self.lastContentOffset = 0
        }).disposed(by: disposeBag)

        dependency?.searchKey.skip(1).subscribe(onNext: { [weak self] (key) in
            self?.viewModel.loadFilterData(key ?? "")
        }).disposed(by: disposeBag)

        dependency?.selectedItemsRelay.asDriver().drive(onNext: { [weak self] _ in
            self?.reloadSelectedStatus()
        }).disposed(by: disposeBag)
    }
}
