//
//  PublicCalendarViewController.swift
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
import RustPB
import LarkUIKit
import RoundedHUD
import UniverseDesignIcon
import LarkContainer

final class PublicCalendarViewController: SubscribeCalendarBase, SubscribeAble, UserResolverWrapper {
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    let userResolver: UserResolver
    private lazy var loadFaildView = LoadingView(displayedView: self.view)
    static let cellCountMax: Int32 = 100
    var cellContents: [MultiCalendarSearchModel] = [MultiCalendarSearchModel]()
    var searchOffset: Int = 0
    lazy var tableView = { () -> UITableView in
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.register(SubscribeCalendarCell.self, forCellReuseIdentifier: SubscribeCalendarCell.identifie)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .ud.bgBody
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    let emptyStatus: EmptyStatusView.Status = .noCalendar
    let emptyMatchStatus: EmptyStatusView.Status = .noMatchedCalendar
    let calendarApi: CalendarRustAPI?
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
        searchOffset = 0
        loadData()
    }

    init(calendarApi: CalendarRustAPI?, userResolver: UserResolver) {
        self.calendarApi = calendarApi
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.layout(equalTo: view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadData() {
        guard let searchText = searchText else { return }
        calendarApi?.multiSearchCalendars(query: searchText, offset: Int32(searchOffset), count: PublicCalendarViewController.cellCountMax, searchSharedCalendar: true, searchPrimaryCalendar: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (newContents) in
                guard let `self` = self else { return }
                let calendars = self.calendarManager?.allCalendars ?? []
                var contents = newContents
                contents = contents.updateOwnerCalendar(calendars)
                contents = contents.updateSubscribeStatus(calendars)
                self.cellContents = contents
                self.tableView.tableFooterView = SubscribeNoMoreView()
                self.tableView.reloadData()
                self.updateSubview(hasData: !self.cellContents.isEmpty)
                }, onError: { [weak self] (_) in
                    guard let `self` = self else { return }
                    self.loadFaild()
            }).disposed(by: disposeBag)
    }

    func updateSubview(hasData: Bool) {
        loadingView.hide()
        loadFaildView.hideSelf()
        if !hasData && (searchText?.isEmpty ?? true) {
            emptyView.showStatus(with: emptyStatus)
            tableView.isHidden = true
        } else if !hasData && !(searchText?.isEmpty ?? true) {
            emptyView.showStatus(with: emptyMatchStatus)
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
}

extension PublicCalendarViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellContents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubscribeCalendarCell.identifie) as? SubscribeCalendarCell, indexPath.row < cellContents.count else {
            assertionFailureLog()
            return UITableViewCell()
        }

        let content = cellContents[indexPath.row]
        cell.updateWith(content)
        cell.tapAction = { [unowned self] () in
            self.changeSubscribeStatus(content: content,
                                       calendarApi: self.calendarApi,
                                       disposeBag: self.disposeBag,
                                       searchType: .search,
                                       pageType: .public_cal,
                                       controller: self,
                                       refresh: { [weak self] (content) in
                                        self?.update(content: content)
            })
            /// 点击订阅/退订埋点
            if content.subscribeStatus == .subscribed || content.subscribeStatus == .noSubscribe {
                CalendarTracerV2.CalendarSubscribe.traceClick {
                    let subscribed = (content.subscribeStatus == .subscribed)
                    $0
                        .click(subscribed ? "unsubscribe_public_cal" : "subscribe_public_cal")
                        .target("none")
                    $0.calendar_id = content.calendarID
                }
            }
        }

        if !FG.optimizeCalendar {
            cell.avatarView.image = UDIcon.getIconByKeyNoLimitSize(.calendarOutlined).renderColor(with: .n3)
            return cell
        }

        cell.avatarView.image = CalendarDetailCardViewModel.defaultAvatar.avatar
        if !content.avatarKey.isEmpty {
            calendarApi?.downLoadImage(with: content.avatarKey)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe { imagePath in
                    guard let path = imagePath?.asAbsPath(), let avatar = try? UIImage.read(from: path) else {
                        CalendarBiz.editLogger.error("Haven't found any image from the path.")
                        return
                    }
                    cell.avatarView.image = avatar
                }.disposed(by: disposeBag)
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

extension PublicCalendarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SubscribeBaseCell.cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
