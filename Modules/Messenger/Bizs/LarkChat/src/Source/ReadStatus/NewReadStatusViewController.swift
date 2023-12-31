//
//  NewReadStatusViewController.swift
//  LarkChat
//
//  Created by zhenning on 2002/02/05.
//  Copyright © 2020年. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxCocoa
import RxSwift
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

final class NewReadStatusViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    private var showTipCount = 100
    private static let logger = Logger.log(NewReadStatusViewController.self, category: "NewReadStatusViewController")
    private let disposeBag = DisposeBag()

    private(set) lazy var readTable: ChatChatterBaseTable = {
        let table = self.createListTableView(.read)
        table.register(DoubleLineTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: DoubleLineTableHeader.self))
        return table
    }()

    private(set) lazy var unreadTable: ChatChatterBaseTable = {
        let table = self.createListTableView(.unread)
        table.register(DoubleLineTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: DoubleLineTableHeader.self))
        return table
    }()

    private(set) lazy var singeReadTable: ChatChatterBaseTable = {
        let table = self.createListTableView(.singleRead)
        table.register(
            DoubleLineTableHeader.self,
            forHeaderFooterViewReuseIdentifier: String(describing: DoubleLineTableHeader.self))
        return table
    }()

    private(set) lazy var singleAllReadView: ReadStatusEmptyView = {
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

    private(set) var doubleLineReadStatusView = UIView()
    private(set) var leftView = UIView()
    private(set) var rightView = UIView()
    private var hasSubviewSetuped = false

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

        self.view.backgroundColor = UIColor.ud.N00
        self.title = viewModel.title
        self.viewModel.viewTypeDriver.drive(onNext: { [weak self] (showType) in
            self?.setViewType(showType)
        }).disposed(by: self.disposeBag)

        self.viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: self.disposeBag)

        self.viewModel.firstLoadReadStatus()
    }

    // 双栏
    private func setupSubViews(_ doubleRowlineTopTarget: ConstraintRelatableTarget) {
        hasSubviewSetuped = true

        /// top seperator line
        let topSeparatorLine = UIView()
        topSeparatorLine.backgroundColor = UIColor.ud.N100
        self.view.addSubview(topSeparatorLine)

        //add left and right
        doubleLineReadStatusView.addSubview(self.leftView)
        doubleLineReadStatusView.addSubview(self.rightView)
        /// mid seperator line
        let midSepertorLine = UIView()
        midSepertorLine.backgroundColor = UIColor.ud.N100
        doubleLineReadStatusView.addSubview(midSepertorLine)
        self.view.addSubview(doubleLineReadStatusView)

        topSeparatorLine.snp.makeConstraints { (make) in
            make.top.equalTo(doubleRowlineTopTarget)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        doubleLineReadStatusView.snp.makeConstraints { (make) in
            make.top.equalTo(topSeparatorLine.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        self.leftView.snp.makeConstraints { (make) in
            make.width.equalTo(self.view.frame.width / 2 - 0.5)
            make.top.left.bottom.equalToSuperview()
        }

        midSepertorLine.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(self.leftView.snp.right)
            make.width.equalTo(0.5)
        }

        self.rightView.snp.makeConstraints { (make) in
            make.left.equalTo(midSepertorLine.snp.right)
            make.top.right.bottom.equalToSuperview()
        }

        self.leftView.addSubview(self.readTable)
        self.rightView.addSubview(self.unreadTable)

        [readTable, unreadTable].forEach {
            $0.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
    }

    private func createListTableView(_ type: TableViewType) -> ChatChatterBaseTable {
        let tableView = ChatChatterBaseTable(frame: .zero, style: .plain)
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = 50
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

        // 未读Table刷新
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
    }

    // 单页刷新
    private func reloadSinglePage() {
        let dataCount = viewModel.singlePageDataSource.reduce(into: 0) { $0 += $1.items.count }
        let isReadListEmpty = dataCount == 0
        self.singleAllReadView.isHidden = !isReadListEmpty
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
        self.view.addSubview(singleAllReadView)
        self.view.addSubview(singeReadTable)

        [singleAllReadView, singeReadTable].forEach {
            $0.snp.makeConstraints { (make) in
                make.left.bottom.right.equalToSuperview()
                make.top.equalTo(searchWrapper.snp.bottom)
            }
        }
    }

    // 决定单页、双页、有无Search, 是否是pad的双栏
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
            self.setupSubViews(topTagert)
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
            NewReadStatusViewController.logger.error(
                "sync message read status failed",
                additionalData: ["messageId": self.viewModel.message.id],
                error: error
            )
        case .viewStatus(let viewStatus):
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
                reloadSinglePage()

            // 单页刷新
            case (false, true):
                if isSearchResultTable { searchResultTable.isHidden = true }
                reloadSinglePage()
            }
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
        let type = TableViewType(rawValue: tableView.tag)
        return type == .singleRead ? 30 : (type == .search ? 0 : 50)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableType = TableViewType(rawValue: tableView.tag)

        if (tableType == .read) || (tableType == .unread),
            let view = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: DoubleLineTableHeader.self)) as? DoubleLineTableHeader {
            let doubleLineDataSource = processDoubleLineDataSource()
            if tableType == .read {
                view.title.attributedText = doubleLineDataSource.0
            } else if tableType == .unread {
                view.title.attributedText = doubleLineDataSource.1
            } else {
                return nil
            }
            return view
        } else if tableType == .singleRead,
            section < viewModel.singlePageDataSource.count,
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                String(describing: DoubleLineTableHeader.self)) as? DoubleLineTableHeader {
            view.title.attributedText = viewModel.singlePageRichDataSource[section].title
            return view
        }
        return nil
    }

    private func processDoubleLineDataSource() -> (NSAttributedString, NSAttributedString) {
        if !viewModel.chat.isUserCountVisible {
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.N900,
                                                             .font: UIFont.systemFont(ofSize: 17)]
            return (NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_HideMember_Read_Text, attributes: attributes),
                    NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_HideMember_Unread_Text, attributes: attributes))
        }

        let readCountTitle = "\(viewModel.readCount)"
        let unreadCountTitle = "\(viewModel.unreadCount)"
        let iPadRead = BundleI18n.LarkChat.Lark_Legacy_iPadRead
        let iPadUnread = BundleI18n.LarkChat.Lark_Legacy_iPadUnread
        let readTitle = readCountTitle + " " + iPadRead
        let unreadTitle = unreadCountTitle + " " + iPadUnread

        let readAttrText = NSMutableAttributedString(string: readTitle, attributes: [.foregroundColor: UIColor.ud.N900])
        let unreadAttrText = NSMutableAttributedString(string: unreadTitle, attributes: [.foregroundColor: UIColor.ud.N900])
        readAttrText.addAttributes([.font: UIFont.systemFont(ofSize: 20)],
                                   range: NSRange(location: 0, length: (readCountTitle as NSString).length))
        readAttrText.addAttributes([.font: UIFont.systemFont(ofSize: 17)], range: (readTitle as NSString).range(of: iPadRead))
        unreadAttrText.addAttributes([.font: UIFont.systemFont(ofSize: 20)],
                                   range: NSRange(location: 0, length: (unreadCountTitle as NSString).length))
        unreadAttrText.addAttributes([.font: UIFont.systemFont(ofSize: 17)], range: (unreadTitle as NSString).range(of: iPadUnread))
        return (readAttrText, unreadAttrText)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: LKReadListCell.identifier, for: indexPath)

        if let cell = cell as? LKReadListCell, let item = self.tableView(tableView, itemAt: indexPath) {
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
