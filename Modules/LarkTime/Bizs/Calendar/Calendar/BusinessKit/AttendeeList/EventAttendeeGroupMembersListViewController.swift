//
//  EventAttendeeGroupMembersListViewController.swift
//  Calendar
//
//  Created by 白言韬 on 2020/11/10.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkContainer

final class EventAttendeeGroupMembersListViewController: CalendarController, UserResolverWrapper {
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    private typealias UIStyle = EventEditUIStyle
    private let cellReuseId = "nonGroup"
    private lazy var tableView = initTableView()
    private let disposeBag = DisposeBag()

    let viewModel: EventAttendeeGroupMembersListViewModel
    let userResolver: UserResolver

    init(viewModel: EventAttendeeGroupMembersListViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.addBackItem()
        self.title = viewModel.title
        viewModel.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTableView() -> UITableView {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            EventNonGroupEditCell.self,
            forCellReuseIdentifier: cellReuseId
        )
        return tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadData()
        }
        viewModel.rxHasMore
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (hasMore) in
                guard let `self` = self else { return }
                self.tableView.endBottomLoadMore(hasMore: hasMore)
            }).disposed(by: self.disposeBag)
        viewModel.rxCellDataList
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension EventAttendeeGroupMembersListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfCells()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellData = viewModel.cellData(at: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        if let nonGroupCell = cell as? EventNonGroupEditCell {
            nonGroupCell.viewData = cellData
            nonGroupCell.showBottomLine = false
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard let cellData = viewModel.cellData(at: indexPath),
              !cellData.avatar.avatarKey.isEmpty else {
            CDProgressHUD.showTextHUD(hint: BundleI18n.Calendar.Calendar_Common_NoCantacFound, on: view)
            return
        }

        guard let calendarId = cellData.calendarId,
              let eventTitle = viewModel.eventTitle,
              let calendarApi = self.calendarApi else {
            return
        }
        calendarDependency?.jumpToAttendeeProfile(calendarApi: calendarApi,
                                                 attendeeCalendarID: calendarId,
                                                 eventTitle: eventTitle,
                                                 from: self,
                                                 bag: disposeBag)
    }

}
