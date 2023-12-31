//
//  EventAttendeeListViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/3/23.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignIcon
/// 日程 - 参与人列表页

protocol EventAttendeeListViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventAttendeeListViewController)
    func didFinishEdit(from viewController: EventAttendeeListViewController, attendeeType: AttendeeType)
}

final class EventAttendeeListViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    override var navigationBarStyle: NavigationBarStyle {
        return .default
    }

    let userResolver: UserResolver
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    weak var delegate: EventAttendeeListViewControllerDelegate?
    let viewModel: EventAttendeeListViewModel
    // 是否要展示「仅可删除你添加的参与人」tip
    var showNonFullEditPermissonTip: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            updateHeader()
        }
    }

    private typealias UIStyle = EventEditUIStyle
    private let cellReuseIds: (nonGroup: String, group: String, loadMore: String) = ("nonGroup", "group", "loadMore")
    private let disposeBag = DisposeBag()
    private lazy var headerView = initHeaderView()
    private lazy var tableView = initTableView()
    private let sectionFooterTipViewHeight = CGFloat(56)
    private var doneButton: LKBarButtonItem?

    // 仅用于详情页：跳转个人资料页
    var isFromDetail = false

    init(viewModel: EventAttendeeListViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        viewModel.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if isFromDetail {
            self.addBackItem()
        } else {
            setupNaviItem()
        }
        viewModel.onAllCellDataUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateHeader()
            }
        }
        viewModel.onSectionDataUpdate = { [weak self] (section: Int) -> Void in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        tableView.reloadData()
        updateHeader()

        if isFromDetail {
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(CalendarTracer.EventClickType.showAttendeeList.value).target(CalendarTracer.EventClickType.showAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.on.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: viewModel.eventID, eventStartTime: viewModel.startTime.description, isOrganizer: viewModel.currentUserCalendarId == viewModel.organizerCalendarId, isRecurrence: !self.viewModel.rrule.isEmpty, originalTime: viewModel.getEventTuple().originalTime?.description, uid: viewModel.getEventTuple().key))
            }
        } else {
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click(CalendarTracer.EventClickType.showAttendeeList.value).target(CalendarTracer.EventClickType.showAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.on.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: viewModel.eventID, eventStartTime: viewModel.startTime.description, isOrganizer: viewModel.currentUserCalendarId == viewModel.organizerCalendarId, isRecurrence: !self.viewModel.rrule.isEmpty, originalTime: viewModel.getEventTuple().originalTime?.description, uid: viewModel.getEventTuple().key))
            }
        }
    }

    @objc
    override func backItemTapped() {
        super.backItemTapped()
        logOnExit()
    }

    private func logOnExit() {
        if isFromDetail {
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(CalendarTracer.EventClickType.showAttendeeList.value).target(CalendarTracer.EventClickType.showAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.off.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: viewModel.eventID, eventStartTime: viewModel.startTime.description, isOrganizer: viewModel.currentUserCalendarId == viewModel.organizerCalendarId, isRecurrence: !self.viewModel.rrule.isEmpty, originalTime: viewModel.getEventTuple().originalTime?.description, uid: viewModel.getEventTuple().key))
            }
        } else {
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click(CalendarTracer.EventClickType.showAttendeeList.value).target(CalendarTracer.EventClickType.showAttendeeList.target)
                $0.status = CalendarTracer.EventDetailClickStatus.off.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: viewModel.eventID, eventStartTime: viewModel.startTime.description, isOrganizer: viewModel.currentUserCalendarId == viewModel.organizerCalendarId, isRecurrence: !self.viewModel.rrule.isEmpty, originalTime: viewModel.getEventTuple().originalTime?.description, uid: viewModel.getEventTuple().key))
            }
        }
    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func setupNaviItem() {
        let backItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).renderColor(with: .n1).scaleNaviSize().withRenderingMode(.alwaysOriginal)
        )
        backItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
                self.logOnExit()
                EventEdit.logger.info("cancel edit attendee")
            }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = backItem

        let doneItem = LKBarButtonItem(image: nil, title: BundleI18n.Calendar.Calendar_Common_Done)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        self.doneButton = doneItem
        self.bindDoneButtonStatus()
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                if self.viewModel.changed {
                    self.delegate?.didFinishEdit(from: self, attendeeType: self.viewModel.attendeeType)
                } else {
                    self.delegate?.didCancelEdit(from: self)
                }
                self.logOnExit()
                EventEdit.logger.info("finish edit attendee")
            }
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = doneItem
    }

    private func bindDoneButtonStatus() {
        viewModel.rxEnableDoneBtn.bind { [weak self] enable in
            self?.doneButton?.button.isUserInteractionEnabled = enable
            self?.doneButton?.button.tintColor = enable ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled.withAlphaComponent(0.5)
        }.disposed(by: disposeBag)
    }

    private func updateHeader() {
        headerView.title = viewModel.headerTitle()
        if showNonFullEditPermissonTip {
            headerView.subtitle = BundleI18n.Calendar.Calendar_Edit_CanNotDeleteGuest
        } else {
            headerView.subtitle = nil
        }
    }

    // MARK: UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(inSection: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard viewModel.footerTypeForSection(section) != nil else {
            return .leastNormalMagnitude
        }
        return sectionFooterTipViewHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let type = viewModel.footerTypeForSection(section) else {
            return UIView()
        }
        return makeSectionFooterView(withType: type, section: section)
    }

    // 列表里每一个未展开的 item 都是一个 section，群会展开在对应的 section 里
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellData = viewModel.cellData(at: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        let cell: UITableViewCell
        switch cellData {
        case .nonGroup(let nonGroupCellData), .groupMember(let nonGroupCellData):
            cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIds.nonGroup, for: indexPath)
            if let nonGroupCell = cell as? EventNonGroupEditCell {
                nonGroupCell.canShowDelete = viewModel.aiGenerateAttendeeList.isEmpty
                nonGroupCell.viewData = nonGroupCellData
                nonGroupCell.showBottomLine = indexPath.row == 0
                nonGroupCell.deleteHandler = { [weak self] in
                    self?.viewModel.deleteAttendee(in: indexPath.section)
                }
            }
        case .groupHeader(let groupCellData):
            cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIds.group, for: indexPath)
            if let groupCell = cell as? EventGroupEditCell {
                groupCell.viewData = groupCellData
                groupCell.showBottomLine = indexPath.row == 0
                groupCell.deleteHandler = { [weak self] in
                    self?.viewModel.deleteAttendee(in: indexPath.section)
                }
                groupCell.expandHandler = { [weak self] in
                    self?.viewModel.expandGroup(in: indexPath.section)
                }
                groupCell.collapseHandler = { [weak self] in
                    self?.viewModel.collapseGroup(in: indexPath.section)
                }
                groupCell.breakUpHandler = { [weak self] in
                    self?.viewModel.breakUpGroup(in: indexPath.section)
                    Tracer.shared.calEditGroupExpand()
                }
                groupCell.enterChatHandler = { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.enterToChat(in: indexPath.section, from: self)
                }
                groupCell.seeInvisibleHandler = { [weak self] in
                    let confirmVC = AttendeeNoAuthConfrimViewController.getViewController()
                    self?.present(confirmVC, animated: true)
                    self?.viewModel.seeInvisible(in: indexPath.section)
                }
            }
        case .loadMore(let loadMoreCellData):
            cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIds.loadMore, for: indexPath)
            if let loadMoreCell = cell as? EventAttendeeListLoadMoreCell {
                loadMoreCell.viewData = loadMoreCellData
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let cellData = viewModel.cellData(at: indexPath) else { return }
        switch cellData {
        case .nonGroup(let data), .groupMember(let data):
            if data.avatar.avatarKey.isEmpty {
                CDProgressHUD.showTextHUD(hint: BundleI18n.Calendar.Calendar_Common_NoCantacFound, on: view)
            } else {
                if let calendarId = viewModel.calendarId(at: indexPath) {
                    if isFromDetail {
                        CalendarTracerV2.EventDetail.traceClick {
                            $0.click(CalendarTracer.EventClickType.showUserProfile.value).target(CalendarTracer.EventClickType.showUserProfile.target)
                            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: viewModel.eventID, eventStartTime: viewModel.startTime.description, isOrganizer: viewModel.currentUserCalendarId == viewModel.organizerCalendarId, isRecurrence: !self.viewModel.rrule.isEmpty, originalTime: viewModel.getEventTuple().originalTime?.description, uid: viewModel.getEventTuple().key))
                        }
                    } else {
                        CalendarTracerV2.EventFullCreate.traceClick {
                            $0.click(CalendarTracer.EventClickType.showUserProfile.value).target(CalendarTracer.EventClickType.showUserProfile.target)
                            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: viewModel.eventID, eventStartTime: viewModel.startTime.description, isOrganizer: viewModel.currentUserCalendarId == viewModel.organizerCalendarId, isRecurrence: !self.viewModel.rrule.isEmpty, originalTime: viewModel.getEventTuple().originalTime?.description, uid: viewModel.getEventTuple().key))
                        }
                    }
// @王娟：profile 由于组件不支持设计稿的样式，先改为 ModalView+右侧推进
//                    if isFromDetail {
//                        calendarDependency.presentToAttendeeProfile(
//                            calendarApi: calendarApi,
//                            attendeeCalendarID: calendarId,
//                            eventTitle: viewModel.eventTitle ?? "",
//                            style: .fullScreen,
//                            from: self,
//                            bag: disposeBag)
//                    }
                    guard let calendarApi = self.calendarApi,
                          let calendarDependency = self.calendarDependency else {
                        EventEdit.logger.info("jumpToAttendeeProfile failed, can not get service from larkcontainer")
                        return
                    }
                    calendarDependency.jumpToAttendeeProfile(
                        calendarApi: calendarApi,
                        attendeeCalendarID: calendarId,
                        eventTitle: viewModel.eventTitle ?? "",
                        from: self,
                        bag: disposeBag)
                }
            }
        case .groupHeader, .loadMore:
            break
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let _ = cell as? EventAttendeeListLoadMoreCell {
            self.viewModel.triggerLoadMoreCell()
        }
    }

}

// MARK: Setup View

extension EventAttendeeListViewController {

    private func initHeaderView() -> EventBasicHeaderView {
        let headerView = EventBasicHeaderView()
        headerView.frame = CGRect(
            origin: .zero,
            size: CGSize(width: view.frame.width, height: EventBasicHeaderView.desiredHeight)
        )
        return headerView
    }

    private func makeSectionFooterView(withType type: GroupAttendeeCellFooterType, section: Int) -> UIView {
        switch type {
        case .more:
            return makeMoreFooterView(section: section)
        case .security:
            return makeSecurityFooterView()
        }
    }

    private func makeMoreFooterView(section: Int) -> UIView {
        let footerView = GroupAttendeeCellMoreFooterView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: self.sectionFooterTipViewHeight)), section: section)
        var footerText = BundleI18n.Calendar.Calendar_Edit_SeeMoreGuest
        if case let .webinar(webAttendeeType) = self.viewModel.attendeeType {
            switch webAttendeeType {
            case .speaker:
                footerText = BundleI18n.Calendar.Calendar_G_ViewMorePanelists
            case .audience:
                footerText = BundleI18n.Calendar.Calendar_G_ViewMoreAttendees
            @unknown default:
                print()  // do nothing
            }
        }
        footerView.tipText = footerText

        footerView.tapedHandler = { [weak self] section in
            guard let self = self,
                  let group = self.viewModel.groupAttendee(at: section) else {
                return
            }

            // delegate
            let vm = EventAttendeeGroupMembersListViewModel(
                title: self.viewModel.groupCellHeaderTitle(at: section),
                chatId: group.chatId,
                attendees: group.members,
                simpleAttendeeList: group.memberSeeds,
                userResolver: self.userResolver
            )
            vm.eventTitle = self.viewModel.eventTitle
            let vc = EventAttendeeGroupMembersListViewController(viewModel: vm, userResolver: self.userResolver)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        return footerView
    }

    private func makeSecurityFooterView() -> UIView {
        let tipLabel = UILabel.cd.subTitleLabel(fontSize: 12)
        tipLabel.textColor = UIColor.ud.textPlaceholder
        tipLabel.textAlignment = .center
        tipLabel.text = BundleI18n.Calendar.Calendar_Detail_HideForSafe

        let footerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: self.sectionFooterTipViewHeight)))
        footerView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        return footerView
    }

    private func initTableView() -> UITableView {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            EventNonGroupEditCell.self,
            forCellReuseIdentifier: cellReuseIds.nonGroup
        )

        if isFromDetail {
            tableView.register(
                EventDetailGroupEditCell.self,
                forCellReuseIdentifier: cellReuseIds.group
            )
        } else {
            tableView.register(
                EventEditGroupEditCell.self,
                forCellReuseIdentifier: cellReuseIds.group
            )
        }

        tableView.register(
            EventAttendeeListLoadMoreCell.self,
            forCellReuseIdentifier: cellReuseIds.loadMore
        )
        return tableView
    }

}
