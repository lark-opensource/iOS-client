//
//  PeopleCalendarViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/14.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import RxSwift
import LarkUIKit
import RoundedHUD
import LarkContainer

final class PeopleCalendarViewController: SubscribeCalendarBase, SubscribeAble, UserResolverWrapper {
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    let userResolver: UserResolver

    private lazy var loadFaildView = LoadingView(displayedView: self.view)
    static let countForPage: Int32 = 20
    var cellContents: [MultiCalendarSearchModel] = [MultiCalendarSearchModel]()
    lazy var tableView = { () -> UITableView in
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.register(SubscribePeopleCell.self, forCellReuseIdentifier: SubscribePeopleCell.identifie)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .ud.bgBody
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    let emptyStatus: EmptyStatusView.Status = .noContacts

    var searchType: CalendarTracer.SearchType = .recom
    var allCalendars: [CalendarModel] = []
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.allCalendars = calendarManager?.allCalendars ?? []
    }
    override var searchText: String? {
        didSet {
            guard let searchText = searchText,
                  searchText != oldValue else { return }
            changeSearchText()
        }
    }

    private func changeSearchText() {
        loadFaildView.hideSelf()
        loadingView.show()
        emptyView.hide()
        tableView.isHidden = true
        loadData(loadMore: false)
        searchType = (searchText?.isEmpty ?? true) ? .recom : .search
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.layout(equalTo: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    private func resetMoreView(_ hasMore: Bool, hasSearchText: Bool) {
        if !hasSearchText {
            tableView.tableFooterView = nil
        } else if !hasMore {
            tableView.removeBottomLoadMore()
            tableView.tableFooterView = SubscribeNoMoreView()
        } else {
            tableView.tableFooterView = nil
            tableView.addBottomLoadMoreView { [weak self] in
                guard let `self` = self else { return }
                self.loadData(loadMore: true)
            }
        }
    }

    private func updateSubview(hasData: Bool) {
        loadingView.hide()
        loadFaildView.hideSelf()
        if !hasData && (searchText?.isEmpty ?? true) {
            emptyView.showStatus(with: emptyStatus)
            tableView.isHidden = true
        } else if !hasData && !(searchText?.isEmpty ?? true) {
            emptyView.showStatus(with: .noMatchedContacts)
            tableView.isHidden = true
        } else if hasData {
            emptyView.hide()
            tableView.isHidden = false
        }
    }

    private func loadFaild() {
        loadingView.hide()
        tableView.isHidden = true
        emptyView.hide()
        loadFaildView.showFailed {
            self.changeSearchText()
        }
    }

    private var searchDisposeBag = DisposeBag()

    private func loadData(loadMore: Bool) {
        guard let searchText = searchText,
        let calendarApi = self.calendarApi,
        let calendarManager = self.calendarManager else { return }
        let searchOffset = loadMore ? cellContents.count : 0
        if !loadMore { self.searchDisposeBag = DisposeBag() }
        calendarApi.multiSearchCalendars(query: searchText, offset: Int32(searchOffset), count: PeopleCalendarViewController.countForPage, searchSharedCalendar: false, searchPrimaryCalendar: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (newContents) in
                guard let `self` = self else { return }
                let calendars = calendarManager.allCalendars
                var contents = newContents
                contents = contents.updateSubscribeStatus(calendars)
                contents = contents.updateOwnerCalendar(calendars)
                if !loadMore {
                    self.cellContents.removeAll()
                }
                self.cellContents.append(contentsOf: contents)
                self.resetMoreView(newContents.count >= PeopleCalendarViewController.countForPage, hasSearchText: !searchText.isEmpty)
                self.tableView.reloadData()
                self.updateSubview(hasData: !self.cellContents.isEmpty)
        }, onError: { [weak self] (_) in
            guard let `self` = self else { return }
            self.loadFaild()
        }).disposed(by: searchDisposeBag)
    }
}

extension PeopleCalendarViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellContents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubscribePeopleCell.identifie) as? SubscribePeopleCell, indexPath.row < cellContents.count else {
            assertionFailureLog()
            return UITableViewCell()
        }

        let content = cellContents[indexPath.row]
        cell.updateWith(content)
        cell.tapAction = { [unowned self] () in
            guard let calendarApi = self.calendarApi else { return }
            self.changeSubscribeStatus(content: content,
                                       calendarApi: calendarApi,
                                       disposeBag: self.disposeBag,
                                       searchType: .recom,
                                       pageType: .contacts,
                                       controller: self,
                                       refresh: { [weak self] (content) in
                                        self?.update(content: content)
            })
            /// 点击订阅/退订埋点
            if content.subscribeStatus == .subscribed || content.subscribeStatus == .noSubscribe {
                CalendarTracerV2.CalendarSubscribe.traceClick {
                    let subscribed = (content.subscribeStatus == .subscribed)
                    $0
                        .click(subscribed ? "unsubscribe_contact_cal" : "subscribe_contact_cal")
                        .target("none")
                    $0.calendar_id = content.calendarID
                }
            }
        }
        return cell
    }

    private func update(content: SubscribeAbleModel) {
        let indexPath = getReloadRow(content: content, contents: cellContents)
        guard indexPath.row < cellContents.count else { return }
        cellContents[indexPath.row].subscribeStatus = content.subscribeStatus
        cellContents[indexPath.row].isOwner = content.isOwner
        tableView.reloadData()
    }
}

extension PeopleCalendarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SubscribeBaseCell.cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < cellContents.count, let chatter = cellContents[indexPath.row].chatter else {
            return
        }
        CalendarTracer.shareInstance.calShowUserCard(actionSource: .calendarSubscription)
        calendarDependency?.jumpToProfile(chatter: chatter, eventTitle: "", from: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row != cellContents.count - 1 ||
                !(searchText?.isEmpty ?? true) else {
            return
        }

        if tableView.contentSize.height >= tableView.frame.size.height {
            tableView.tableFooterView = SubscribeNoMoreView(title: BundleI18n.Calendar.Calendar_SubscribeCalendar_NoMoreRecom)
        } else if tableView.contentSize.height < tableView.frame.size.height,
            self.tableView.tableFooterView == nil {
            tableView.addBottomLoadMoreView { [weak self] in
                guard let `self` = self else { return }
                self.tableView.tableFooterView = SubscribeNoMoreView(title: BundleI18n.Calendar.Calendar_SubscribeCalendar_NoMoreRecom)
                self.tableView.removeBottomLoadMore()
            }
        }
    }
}
