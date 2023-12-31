//
//  ReadStatusViewController.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/30.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxCocoa
import RxSwift
import UniverseDesignToast
import LKCommonsLogging
import LarkCore
import SnapKit
import LarkModel
import EENavigator
import LarkMessengerInterface
import RustPB
import LarkContainer

private enum TableViewType: Int {
    case read = 1
    case unread
    case singleRead
    case search
}

final class ReadStatusViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    private var showTipCount = 100
    private static let logger = Logger.log(ReadStatusViewController.self, category: "ReadStatusViewController")
    private let disposeBag = DisposeBag()

    /// 已读列表； read list
    private(set) lazy var readTable: ChatChatterBaseTable = {
        return self.createListTableView(.read)
    }()

    /// 未读列表； unread list
    private(set) lazy var unreadTable: ChatChatterBaseTable = {
        return self.createListTableView(.unread)
    }()

    /// 所有人都已读，未读列表显示内容；
    /// When everyone has read, the unread list shows
    private(set) lazy var allReadView: ReadStatusEmptyView = {
        return ReadStatusEmptyView(message: viewModel.allRead)
    }()

    /// 所有人都未读，已读列表显示内容；
    /// When no one has read, the read list shows
    private(set) lazy var allUnreadView: ReadStatusEmptyView = {
        return ReadStatusEmptyView(message: viewModel.allunread)
    }()

    /// 单页显示时，已读列表显示内容
    /// read table when show mode is single page mode
    private(set) lazy var singeReadTable: ChatChatterBaseTable = {
        let table = self.createListTableView(.singleRead)
        table.register(
            GrayTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GrayTableHeader.self))
        return table
    }()

    /// 单页显示时，所有人都未读，显示的内容
    private(set) lazy var singleAllUnreadView: ReadStatusEmptyView = {
        return ReadStatusEmptyView(message: viewModel.allunread)
    }()

    private(set) lazy var searchWrapper = SearchUITextFieldWrapperView()
    private lazy var searchTextField: SearchUITextField = {
        searchWrapper.searchUITextField.placeholder = BundleI18n.LarkChat.Lark_Legacy_SearchMember
        return searchWrapper.searchUITextField
    }()

    private var isSearchResultTable: Bool = false
    private(set) lazy var searchResultTable: ChatChatterBaseTable = {
        let table = self.createListTableView(.search)
        self.view.addSubview(table)
        table.snp.makeConstraints({ (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.top.equalTo(self.searchWrapper.snp.bottom)
        })
        table.isHidden = true
        isSearchResultTable = true
        return table
    }()

    private(set) var leftView = UIView()
    private(set) var rightView = UIView()

    private(set) lazy var segmentView: SegmentView = {
        let segment = StandardSegment()
        segment.height = 40
        segment.lineStyle = .adjust
        segment.titleFont = UIFont.systemFont(ofSize: 14)
        segment.titleNormalColor = UIColor.ud.N600
        segment.backgroundColor = UIColor.ud.bgBody
        let view = SegmentView(segment: segment)
        return view
    }()

    private lazy var appendedFooterTableViews = [UITableView]()
    private lazy var defaultTableFooterFrame = ChatterListBottomTipView.defaultFrame(self.view.bounds.width)

    let viewModel: ReadStatusViewModel

    init(viewModel: ReadStatusViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody
        self.title = viewModel.title
        self.viewModel.viewTypeDriver.drive(onNext: { [weak self] (showType) in
            self?.setViewType(showType)
        }).disposed(by: self.disposeBag)

        self.viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: self.disposeBag)

        self.viewModel.firstLoadReadStatus()
    }

    // 双页
    private func setupSegementView(_ segmentViewTopTarget: ConstraintRelatableTarget) {
        self.leftView.addSubview(self.allUnreadView)
        self.leftView.addSubview(self.readTable)
        self.rightView.addSubview(self.allReadView)
        self.rightView.addSubview(self.unreadTable)

        [allUnreadView, readTable, allReadView, unreadTable].forEach {
            $0.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        self.segmentView.set(views:
            [(viewModel.readWithoutCount, self.leftView),
             (viewModel.unreadWithoutCount, self.rightView)])
        self.view.addSubview(segmentView)
        self.segmentView.snp.remakeConstraints { (make) in
            make.top.equalTo(segmentViewTopTarget)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func createListTableView(_ type: TableViewType) -> ChatChatterBaseTable {
        let tableView = ChatChatterBaseTable(frame: .zero, style: .plain)
        tableView.estimatedRowHeight = viewModel.isDisplayPad ? 36 : 68
        tableView.rowHeight = viewModel.isDisplayPad ? 36 : 68
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tag = type.rawValue
        tableView.register(ReadListViewCell.self, forCellReuseIdentifier: ReadListViewCell.identifier)
        tableView.register(LKReadListCell.self, forCellReuseIdentifier: LKReadListCell.identifier)
        return tableView
    }

    private func reloadDoublePage() {
        // 已读Table刷新
        let isReadListEmpty = self.viewModel.readDataSource.isEmpty
        self.allUnreadView.isHidden = !isReadListEmpty
        self.readTable.isHidden = isReadListEmpty

        let isReadTableFooterHidden = viewModel.readCount < showTipCount
        self.readTable.tableFooterView?.isHidden = isReadTableFooterHidden
        self.readTable.tableFooterView?.frame = isReadTableFooterHidden ? .zero : defaultTableFooterFrame

        self.readTable.removeBottomLoadMore()
        if self.viewModel.hasMoreRead {
            self.readTable.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadMore(.read)
            }
        }
        self.readTable.reloadData()
        self.segmentView.segment.updateItem(title: viewModel.readTitleWithCount, index: 0)

        // 未读Table刷新
        let isUnreadListEmpty = self.viewModel.unreadDataSource.isEmpty
        self.allReadView.isHidden = !isUnreadListEmpty
        self.unreadTable.isHidden = isUnreadListEmpty

        let isUnreadTableFooterHidden = viewModel.unreadCount < showTipCount
        self.unreadTable.tableFooterView?.isHidden = isUnreadTableFooterHidden
        self.unreadTable.tableFooterView?.frame =
            isUnreadTableFooterHidden ? .zero : defaultTableFooterFrame

        self.unreadTable.removeBottomLoadMore()
        if self.viewModel.hasMoreUnread {
            self.unreadTable.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadMore(.unread)
            }
        }
        self.unreadTable.reloadData()
        self.segmentView.segment.updateItem(title: viewModel.unreadTitleWithCount, index: 1)
    }

    // 单页刷新
    private func reloadSinglePage() {
        let dataCount = viewModel.singlePageDataSource.reduce(into: 0) { $0 += $1.items.count }
        let isReadListEmpty = dataCount == 0
        self.singleAllUnreadView.isHidden = !isReadListEmpty
        self.singeReadTable.isHidden = isReadListEmpty

        let isTableFooterHidden = viewModel.readCount < showTipCount
        self.singeReadTable.tableFooterView?.isHidden = isTableFooterHidden
        self.singeReadTable.tableFooterView?.frame =
            isTableFooterHidden ? .zero : defaultTableFooterFrame

        self.singeReadTable.reloadData()
        self.singeReadTable.removeBottomLoadMore()
        if self.viewModel.hasMoreRead {
            self.singeReadTable.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadMore(.read)
            }
        }
    }

    // 显示搜索框
    private func showSearch() {
        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_Legacy_Search

        self.view.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints({ make in
            make.left.right.top.equalToSuperview()
        })
        searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.filter(text ?? "")
            }).disposed(by: disposeBag)
    }

    private func addFooterTipView(to table: UITableView) {
        let view = ChatterListBottomTipView(frame: defaultTableFooterFrame)
        view.title = BundleI18n.LarkChat.Lark_Group_HugeGroup_MemberList_Bottom
        table.tableFooterView = view
        appendedFooterTableViews.append(table)
    }

    // 单页显示
    private func changeToSingPage() {
        self.view.addSubview(singleAllUnreadView)
        self.view.addSubview(singeReadTable)

        [singleAllUnreadView, singeReadTable].forEach {
            $0.snp.makeConstraints { (make) in
                make.left.bottom.right.equalToSuperview()
                make.top.equalTo(searchWrapper.snp.bottom)
            }
        }
    }

    // 决定单页、双页、有无Search
    private func setViewType(_ showType: ReadStatusViewModel.ShowViewType) {

        let topTagert: ConstraintRelatableTarget
        if showType.showSearch {
            self.showSearch()
            topTagert = searchWrapper.snp.bottom
        } else {
            topTagert = self.view.snp.top
        }

        if showType.isSingleColumn {
            changeToSingPage()
            if showType.showLimited {
                addFooterTipView(to: singeReadTable)
            }
        } else {
            self.setupSegementView(topTagert)
            if showType.showLimited {
                addFooterTipView(to: readTable)
                addFooterTipView(to: unreadTable)
            }
        }
    }

    // searching searchResultEmpty display
    private func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            setViewDisplayStatus(viewModel.isInSearch ? (viewModel.searchDataSource.isEmpty ? .empty : .display) : .display)
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)

            ReadStatusViewController.logger.error(
                "sync message read status failed",
                additionalData: ["messageId": self.viewModel.message.id],
                error: error
            )

        case .viewStatus(let viewStatus):
            setViewDisplayStatus(viewStatus)
        }
    }

    private func setViewDisplayStatus(_ viewStatus: ChatChatterBaseTable.Status) {
        loadingPlaceholderView.isHidden = true

        switch (viewModel.isInSearch, viewModel.showType.isSingleColumn) {
        // 搜索状态
        case (true, _):
            searchResultTable.isHidden = false
            searchResultTable.reloadData()
            searchResultTable.status = viewStatus

        // 双页刷新
        case (false, false):
            if isSearchResultTable { searchResultTable.isHidden = true }
            reloadDoublePage()

        // 单页刷新
        case (false, true):
            if isSearchResultTable { searchResultTable.isHidden = true }
            reloadSinglePage()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.defaultTableFooterFrame = ChatterListBottomTipView.defaultFrame(self.view.bounds.width)
        for table in appendedFooterTableViews {
            if let tableFooter = table.tableFooterView {
                tableFooter.frame = self.defaultTableFooterFrame
                table.tableFooterView = tableFooter
            }
        }
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchTextField.canResignFirstResponder == true {
            self.searchTextField.resignFirstResponder()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TableViewType(rawValue: tableView.tag) == .singleRead ? 30 : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if TableViewType(rawValue: tableView.tag) == .singleRead,
            section < viewModel.singlePageDataSource.count,
            let view = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GrayTableHeader.self)) as? GrayTableHeader {
            if viewModel.isDisplayPad {
                view.title.attributedText = viewModel.singlePageRichDataSource[section].title
            } else {
                view.title.text = viewModel.singlePageDataSource[section].title
            }
            return view
        }
        return nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewType(rawValue: tableView.tag) == .singleRead ? viewModel.singlePageDataSource.count : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let type = TableViewType(rawValue: tableView.tag) else { return 0 }
        switch type {
        case .read: return self.viewModel.readDataSource.count
        case .unread: return self.viewModel.unreadDataSource.count
        case .singleRead: return self.item(for: viewModel.singlePageDataSource, at: section)?.items.count ?? 0
        case .search: return self.viewModel.searchDataSource.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.isDisplayPad ? LKReadListCell.identifier : ReadListViewCell.identifier, for: indexPath)

        if viewModel.isDisplayPad, let cell = cell as? LKReadListCell, let item = self.tableView(tableView, itemAt: indexPath) {
            cell.updateUI(item)
        } else if let cell = cell as? ReadListViewCell, let item = self.tableView(tableView, itemAt: indexPath) {
            cell.updateUI(item)
        }

        return cell
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = self.tableView(tableView, itemAt: indexPath) {
            if viewModel.chat.type == .group {
                let body = PersonCardBody(chatterId: item.chatter.id,
                                          chatId: viewModel.chat.id,
                                          source: .chat)
                navigator.presentOrPush(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            } else {
                let body = PersonCardBody(chatterId: item.chatter.id)
                navigator.presentOrPush(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    // 根据不同场景读取Item
    private func tableView(_ tableView: UITableView, itemAt indexPath: IndexPath) -> ReadListCellViewModel? {
        guard let type = TableViewType(rawValue: tableView.tag) else { return nil }
        switch type {
        case .read: return item(for: viewModel.readDataSource, at: indexPath.row)
        case .unread: return item(for: viewModel.unreadDataSource, at: indexPath.row)
        case .singleRead:
            if let section = item(for: viewModel.singlePageDataSource, at: indexPath.section) {
                return item(for: section.items, at: indexPath.row)
            }
            return nil
        case .search: return item(for: viewModel.searchDataSource, at: indexPath.row)
        }
    }

    private func item<T>(for items: [T], at index: Int) -> T? {
        return index < items.count ? items[index] : nil
    }
}
