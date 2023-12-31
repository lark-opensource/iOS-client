//
//  MeetingRoomFoldViewController.swift
//  Calendar
//
//  Created by 朱衡 on 2021/1/20.
//

import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignTabs
import LarkTimeFormatUtils
import UniverseDesignToast
import UniverseDesignDialog

protocol MeetingRoomFoldViewControllerDelegate: AnyObject {
    func didSelectMeetingRooms(
        _ meetingRooms: [CalendarMeetingRoom],
        from viewController: MeetingRoomFoldViewController
    )

    func didSelectMeetingRoomDetail(
        _ resourceID: String,
        from viewController: MeetingRoomFoldViewController
    )
    
    // 一键调整被点击
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?)
}

extension MeetingRoomFoldViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }
}

final class MeetingRoomFoldViewController: UIViewController {
    let viewModel: MeetingRoomFoldViewModel
    weak var delegate: MeetingRoomFoldViewControllerDelegate?

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
    private let emptyBuildingHolder = UILabel.cd.textLabel()

    private let disposeBag = DisposeBag()
    init(viewModel: MeetingRoomFoldViewModel, emptyHolderText: String) {
        self.viewModel = viewModel
        self.emptyBuildingHolder.text = emptyHolderText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        bindViewAction()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        view.addSubview(emptyBuildingHolder)
        emptyBuildingHolder.snp.makeConstraints {
            $0.centerY.equalTo(view.snp.top).offset(32)
            $0.left.right.equalToSuperview().inset(16)
        }
        emptyBuildingHolder.isHidden = true
    }

    private func bindViewData() {
        viewModel.onAllCellDataUpdate = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }

        viewModel.rxIsBuildingsEmpty
            .bind { [weak self] (isEmpty) in
                guard let self = self else { return }
                if isEmpty {
                    self.view.bringSubviewToFront(self.emptyBuildingHolder)
                } else {
                    self.view.bringSubviewToFront(self.tableView)
                }
                self.emptyBuildingHolder.isHidden = !isEmpty
            }.disposed(by: disposeBag)
    }

    private func bindViewAction() {
        viewModel.rxAlert
            .subscribeForUI(onNext: { [weak self] (title, content) in
                let dialog = UDDialog(config: UDDialogUIConfig())
                dialog.setTitle(text: title)
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                self?.present(dialog, animated: true)
            }).disposed(by: disposeBag)
    }
}

extension MeetingRoomFoldViewController {
    func initTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIStyle.Color.viewControllerBackground
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(EventMeetingRoomCell.self, forCellReuseIdentifier: CellReuseId.meetingRoom.rawValue)
        tableView.register(MeetingRoomLoadingCell.self, forCellReuseIdentifier: CellReuseId.loading.rawValue)
        tableView.register(MeetingRoomRetryCell.self, forCellReuseIdentifier: CellReuseId.retry.rawValue)
        tableView.register(MeetingRoomEmptyCell.self, forCellReuseIdentifier: CellReuseId.empty.rawValue)
        tableView.register(MeetingRoomAutoJustTimeCell.self, forCellReuseIdentifier: CellReuseId.autoJustTime.rawValue)
        // Section内无cell，tableView reload 会闪，加上 height = 0 的fakeCell解决此问题
        tableView.register(MeetingRoomFakeCell.self, forCellReuseIdentifier: CellReuseId.none.rawValue)

        return tableView
    }
}

extension MeetingRoomFoldViewController: UITableViewDataSource, UITableViewDelegate {

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
        case .meetingRoom(_):
            return UIStyle.Layout.meetingRoomCellHeight
        case .empty, .retry, .loading:
            return UIStyle.Layout.buildingPlaceHolderCellHeight
        case .autoJustTime(_):
            return UITableView.automaticDimension
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
            if let cell = cell as? EventMeetingRoomCell {
                cell.viewData = data
                cell.onTapped = { [weak self] in
                    guard let self = self,
                          let meetingRoom = self.viewModel.meetingRoom(at: indexPath) else {
                              assertionFailure()
                              return
                          }
                    if !data.isAvailable,
                       let reason = data.unAvailableReason,
                       !reason.isEmpty {
                        UDToast.showTips(with: reason, on: self.view)
                        return
                    }
                    self.delegate?.didSelectMeetingRooms([meetingRoom], from: self)
                }
                cell.onSelectClick = { [weak self] in
                    guard let self = self,
                          let meetingRoom = self.viewModel.meetingRoom(at: indexPath) else {
                              assertionFailure()
                              return
                          }
                    if !data.isAvailable,
                       let reason = data.unAvailableReason,
                       !reason.isEmpty {
                        UDToast.showTips(with: reason, on: self.view)
                        return
                    }
                    self.viewModel.toggleMeetingRoomSelectTapped(at: indexPath)
                }

                cell.showInfoButton()
                cell.infoBtnOnTapped = { [weak self] in
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
        case .autoJustTime(let info):
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId.autoJustTime.rawValue, for: indexPath)
            if let cell = cell as? MeetingRoomAutoJustTimeCell, let info = info {
                configAutoJustTimeCell(cell, info: info)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIStyle.Layout.buildingCellHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = FoldingBuildingCell()
        if let cellData = viewModel.buildingCellData(at: section) {
            headerView.viewData = cellData
            headerView.onFoldClick = { [weak self] in
                self?.viewModel.reloadMeetingRoom(at: section, from: .eventEdit, needTrack: true)
            }
            headerView.onUnfoldClick = { [weak self] in
                self?.viewModel.dropMeetingRoom(at: section)
            }
            headerView.onSelectClick = { [weak self] in
                self?.viewModel.toggleBuildingSelectTapped(at: section)
            }
        }

        return headerView
    }

}

// MARK: cell config
extension MeetingRoomFoldViewController {
    // 配置自动调整的cell
    fileprivate func configAutoJustTimeCell(_ cell: MeetingRoomAutoJustTimeCell, info: Rust.LevelAdjustTimeInfo) {
        let newDate = info.resourceStrategy.getAdjustEventFurthestDate(timezone: self.viewModel.timezone ?? .current, endDate: self.viewModel.endDate)
        let timezone = viewModel.timezone ?? .current
        let tapHandler = { [weak self] in
            guard let self = self else { return }
            // 点击埋点
            CalendarTracerV2.UtiltimeAdjustRemind.traceClick {
                $0.click("adjust")
                $0.mergeEventCommonParams(commonParam: self.viewModel.eventParam ?? .init())
                $0.location = CalendarTracerV2.AdjustRemindLocation.addResourceView.rawValue
            }
            // 1. 调整日程的截止日期
            self.viewModel.changeRRuleEndDate(newDate)
            // 2. 同步信息到编辑页
            self.delegate?.autoJustTimeTapped(needRenewalReminder: true, rrule: self.viewModel.rrule)
            // 3. 刷新会议室页面（需要先调整日程的截止日期）
            self.viewModel.reloadAllUnfoldBulidingsSuject.onNext(())
            // 展示toast
            let customOptions = Options(
                timeZone: timezone,
                timeFormatType: .long,
                datePrecisionType: .day
            )
            let dateDesc = TimeFormatUtils.formatDate(from: newDate, with: customOptions)
            UDToast.showTips(with: I18n.Calendar_G_AvailabilitySuggestion_TimeChanged_Popup(eventEndTime: dateDesc), on: self.view, delay: 5.0)
        }
        // 展示埋点
        CalendarTracerV2.UtiltimeAdjustRemind.traceView {
            $0.mergeEventCommonParams(commonParam: self.viewModel.eventParam ?? .init())
            $0.location = CalendarTracerV2.AdjustRemindLocation.addResourceView.rawValue
        }
        cell.updateInfo(date: newDate,
                        timezone: timezone,
                        preferredMaxLayoutWidth: self.view.frame.width - MeetingRoomAutoJustTimeCell.horizontalPadding * 2,
                        tapHandler: tapHandler)
    }
}
