//
//  SubscribeMeetingRoomFoldViewController.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/16.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import RoundedHUD

protocol SubscribeMeetingRoomFoldViewControllerDelegate: AnyObject {

    func didSelectMeetingRoomDetail(
        _ resourceID: String,
        from viewController: SubscribeMeetingRoomFoldViewController
    )
}

final class SubscribeMeetingRoomFoldViewController: UIViewController {
    let viewModel: MeetingRoomFoldViewModel

    enum CellReuseId: String {
        case meetingRoom
        case empty
        case retry
        case loading
        case autoJustTime
        case none
    }

    private typealias UIStyle = EventEditUIStyle
    private lazy var tableView = initTableView()
    private let disposeBag = DisposeBag()
    weak var delegate: SubscribeMeetingRoomFoldViewControllerDelegate?

    init(viewModel: MeetingRoomFoldViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindViewData() {
        viewModel.onAllCellDataUpdate = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }

        viewModel.onSubscribeSuccess = { [weak self] (info) in
            guard let self = self else { return }
            RoundedHUD().showSuccess(with: info, on: self.view)
        }

        viewModel.onSubscribeError = { [weak self] (info) in
            guard let self = self else { return }
            RoundedHUD().showTips(with: info, on: self.view)
        }
    }
}

extension SubscribeMeetingRoomFoldViewController {
    func initTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIStyle.Color.viewControllerBackground
        tableView.separatorInset = .init(top: 0, left: UIStyle.Layout.contentLeftMargin, bottom: 0, right: 0)
        tableView.separatorColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(SubscribeMeetingRoomCell.self, forCellReuseIdentifier: CellReuseId.meetingRoom.rawValue)
        tableView.register(MeetingRoomLoadingCell.self, forCellReuseIdentifier: CellReuseId.loading.rawValue)
        tableView.register(MeetingRoomRetryCell.self, forCellReuseIdentifier: CellReuseId.retry.rawValue)
        tableView.register(MeetingRoomEmptyCell.self, forCellReuseIdentifier: CellReuseId.empty.rawValue)
        tableView.register(MeetingRoomFakeCell.self, forCellReuseIdentifier: CellReuseId.none.rawValue)
        return tableView
    }
}

extension SubscribeMeetingRoomFoldViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfBuildings()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellData = viewModel.meetingRoomCellData(in: indexPath) else {
            return 0
        }

        switch cellData {
        case .meetingRoom(let data):
            return UIStyle.Layout.meetingRoomCellHeight
        case .empty, .retry, .loading, .autoJustTime(_):
            return UIStyle.Layout.buildingPlaceHolderCellHeight
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellData = viewModel.meetingRoomCellData(in: indexPath) else {
            return UITableViewCell()
        }

        let cell: UITableViewCell
        switch cellData {
        case .meetingRoom(let data):
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.meetingRoom.rawValue, for: indexPath)
            if let cell = cell as? SubscribeMeetingRoomCell {
                cell.viewData = data
                cell.subscribeButtonTapped = { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.changeSubscribeState(at: indexPath)
                }

                cell.onTapped = { [weak self] in
                    guard let self = self else { return }
                    guard let meetingRoom = self.viewModel.meetingRoom(at: indexPath) else {
                        assertionFailure()
                        return
                    }
                    self.delegate?.didSelectMeetingRoomDetail(meetingRoom.getPBModel().attendeeCalendarID, from: self)
                }
            }
        case .empty:
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.empty.rawValue, for: indexPath)
        case .autoJustTime(_):
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.autoJustTime.rawValue, for: indexPath)
        case .retry:
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.retry.rawValue, for: indexPath)
            if let cell = cell as? MeetingRoomRetryCell {
                cell.clickHandler = { [weak self] in
                    self?.viewModel.reloadMeetingRoom(at: indexPath.section, from: .default, needTrack: false)
                }
            }
        case .loading:
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.loading.rawValue, for: indexPath)
        case .none:
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.none.rawValue, for: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = FoldingBuildingCell()
        if let cellData = viewModel.buildingCellData(at: section) {
            headerView.viewData = cellData
            headerView.onFoldClick = { [weak self] in
                self?.viewModel.reloadMeetingRoom(at: section, from: .subscribeCalendar, needTrack: true)
            }
            headerView.onUnfoldClick = { [weak self] in
                self?.viewModel.dropMeetingRoom(at: section)
            }
        }

        return headerView
    }

}
