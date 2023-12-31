//
//  TodayEventViewController.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/9.
//

import LarkUIKit
import UniverseDesignColor
import CalendarFoundation
import LarkSwipeCellKit
import UniverseDesignIcon
import RxSwift
import UniverseDesignEmpty
import LarkContainer
import LarkSplitViewController
import LarkTraitCollection

public class TodayEventViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    private enum SectionType {
        case eventCard
        case todayPlan
    }

    private let todayPlanViewModel: TodayPlanViewModel
    private let eventFeedCardViewModel: EventFeedCardViewModel
    private let dataSource: TodayEventDataSourceInterface
    private let userResolver: UserResolver
    private var sections: [SectionType] = []
    private var didUpLoad = false // 是否上报过埋点
    private let feedTap: String
    private let feedIsTop: Int
    private let showCalendarID: String
    public let feedID: String

    private let disposeBag = DisposeBag()
    private lazy var emptyView: UDEmptyView = {
        let config = UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.Calendar.Lark_Feed_EventCenter_AllCaughtUp_EmptyState),
                                   type: .noMessageLog)
        return UDEmptyView(config: config)
    }()
    private var naviBar: TitleNaviBar?
    private lazy var backItem = TitleNaviBarItem(image: UDIcon.leftOutlined) { [weak self] _ in
        guard let self = self else { return }
        self.navigationController?.popViewController(animated: true)
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UDColor.bgBody
        tableView.separatorStyle = .none
        let zeroRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: Double.leastNormalMagnitude)
        tableView.tableHeaderView = UIView(frame: zeroRect)
        tableView.register(TodayPlanTableCell.self, forCellReuseIdentifier: TodayPlanTableCell.identifier)
        tableView.register(EventFeedCardTableCell.self, forCellReuseIdentifier: EventFeedCardTableCell.identifier)
        tableView.register(ScheduleCardTableCell.self, forCellReuseIdentifier: ScheduleCardTableCell.identifier)
        tableView.register(EmptyCardTableCell.self, forCellReuseIdentifier: EmptyCardTableCell.identifier)
        tableView.register(TodayPlanHeaderView.self, forHeaderFooterViewReuseIdentifier: TodayPlanHeaderView.identifier)
        tableView.register(EventFeedCardHeaderView.self, forHeaderFooterViewReuseIdentifier: EventFeedCardHeaderView.identifier)
        return tableView
    }()

    private lazy var settingBtn: LKBarButtonItem = {
        let btn = LKBarButtonItem(image: UDIcon.settingOutlined)
        btn.button.tintColor = UDColor.iconN1
        return btn
    }()

    init(dataSource: TodayEventDataSourceInterface,
         todayPlanViewModel: TodayPlanViewModel,
         eventFeedCardViewModel: EventFeedCardViewModel,
         userResolver: UserResolver,
         feedTab: String,
         feedIsTop: Bool,
         showCalendarID: String,
         feedID: String) {
        self.dataSource = dataSource
        self.todayPlanViewModel = todayPlanViewModel
        self.eventFeedCardViewModel = eventFeedCardViewModel
        self.userResolver = userResolver
        self.feedTap = feedTab
        self.feedIsTop = feedIsTop ? 1 : 0
        self.showCalendarID = showCalendarID
        self.feedID = feedID
        super.init(nibName: nil, bundle: nil)
        self.eventFeedCardViewModel.viewController = self
        self.navigationItem.rightBarButtonItem = settingBtn
        self.title = BundleI18n.Calendar.Lark_Feed_EventCenter_EventTitle
        self.view.backgroundColor = UDColor.bgBody

        dataSource.getData()
        settingBtn.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                CalendarTracerV2.TodayEventCilck.traceClick() {
                    $0.click("setting")
                    $0.is_top = self.feedIsTop
                }
                self.jumpToSettingPage()
            }
            .disposed(by: self.disposeBag)
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if Display.pad {
            addNvaiBar()
        }
        DispatchQueue.main.async {
            RootTraitCollection.observer
                .observeRootTraitCollectionDidChange(for: self.view)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.autoConfigNaviItem()
                }).disposed(by: self.disposeBag)
        }
        self.supportSecondaryPanGesture = true

        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
            if Display.pad, let naviBar = self.naviBar {
                make.top.equalTo(naviBar.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        autoConfigNaviItem()
    }

    private func autoConfigNaviItem() {
        let hasBackItem = hasBackPage && Display.pad
        self.naviBar?.leftItems = hasBackItem ? [backItem] : []
    }

    private func addNvaiBar() {
        self.isNavigationBarHidden = true
        let naviBar = TitleNaviBar(titleString: BundleI18n.Calendar.Lark_Feed_EventCenter_EventTitle)
        let barItem = TitleNaviBarItem(image: UDIcon.settingOutlined) { [weak self] _ in
            guard let self = self else { return }
            CalendarTracerV2.TodayEventCilck.traceClick() {
                $0.click("setting")
                $0.feed_tab = self.feedTap
                $0.is_top = self.feedIsTop
            }
            self.jumpToSettingPage()
        }
        naviBar.backgroundColor = UDColor.bgBody
        self.view.addSubview(naviBar)
        naviBar.snp.makeConstraints { make in
            make.trailing.leading.top.equalToSuperview()
        }
        naviBar.rightItems = [barItem]
        self.naviBar = naviBar
    }

    private func bind() {
        Observable.merge(eventFeedCardViewModel.scheduleCardObservable, todayPlanViewModel.todayPlanObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.showOrHideEmptyView(scheduleCardSate: self.eventFeedCardViewModel.state,
                                         todayPlanState: self.todayPlanViewModel.state)
                self.tableView.reloadData()
                if !self.didUpLoad && self.eventFeedCardViewModel.state == .done && self.todayPlanViewModel.state == .done {
                    self.didUpLoad = true
                    CalendarTracerV2.TodayEventView.traceView() {
                        $0.event_cnt = self.eventFeedCardViewModel.cellModels.count / 2 + self.todayPlanViewModel.todayPlanModels.count
                        $0.vc_cnt = self.eventFeedCardViewModel.eventFeedCards[.vc]?.count ?? 0
                        $0.cal_cnt = self.eventFeedCardViewModel.scheduleCardModels.count
                        $0.live_cnt = self.eventFeedCardViewModel.cellModels.filter({ cell in
                            switch cell {
                            case .schedule(let viewModel):
                                switch viewModel.model.btnModel {
                                case .otherBtn(let btnModel):
                                    return btnModel.isLive
                                default:
                                    return false
                                }
                            default:
                                return false
                            }
                        }).count
                        $0.today_cal_cnt = self.todayPlanViewModel.todayPlanModels.count
                        $0.is_has_today_cal_widget = self.todayPlanViewModel.todayPlanModels.isEmpty ? 0 : 1
                        $0.feed_tab = self.feedTap
                        $0.show_cal_id = self.showCalendarID
                        $0.is_top = self.feedIsTop
                        $0.show_cal_id = self.showCalendarID
                    }
                }
            }).disposed(by: disposeBag)
    }

    private func jumpToSettingPage() {
        let body = CalendarSettingBody(fromWhere: .todayEvent)
        userResolver.navigator.push(body: body, from: self)
    }

    private func showOrHideEmptyView(scheduleCardSate: TodayEventDataState,
                                     todayPlanState: TodayEventDataState) {
        if scheduleCardSate == .done && todayPlanState == .done {
            if eventFeedCardViewModel.cellModels.isEmpty && todayPlanViewModel.todayPlanModels.isEmpty {
                self.view.addSubview(emptyView)
                emptyView.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                }
            } else {
                emptyView.snp.removeConstraints()
                emptyView.removeFromSuperview()
            }
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < sections.count {
            if sections[section] == .eventCard {
                return eventFeedCardViewModel.cellModels.count
            } else if sections[section] == .todayPlan {
                return todayPlanViewModel.todayPlanModels.count
            }
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < sections.count else { return UITableViewCell() }
        if sections[indexPath.section] == .eventCard {
            guard let type = eventFeedCardViewModel.cellData(at: indexPath.row) else { return UITableViewCell() }
            switch type {
            case .external(let model):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: EventFeedCardTableCell.identifier, for: indexPath) as? EventFeedCardTableCell
                else {
                    return UITableViewCell()
                }
                cell.setModel(model: model)
                cell.delegate = self
                return cell
            case .schedule(let viewModel):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleCardTableCell.identifier, for: indexPath) as? ScheduleCardTableCell
                else {
                    return UITableViewCell()
                }
                cell.setModel(viewModel: viewModel, vc: self, width: tableView.frame.size.width - 32)
                cell.delegate = self
                return cell
            case .separation:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: EmptyCardTableCell.identifier, for: indexPath) as? EmptyCardTableCell
                else {
                    return UITableViewCell()
                }
                return cell
            }
        } else if sections[indexPath.section] == .todayPlan {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TodayPlanTableCell.identifier, for: indexPath) as? TodayPlanTableCell,
                  let model = todayPlanViewModel.cellData(at: indexPath.row)
            else {
                return UITableViewCell()
            }
            cell.setModel(model: model)
            return cell
        }
        return UITableViewCell()
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        sections = []
        if !eventFeedCardViewModel.cellModels.isEmpty {
            sections.append(.eventCard)
        }
        if !todayPlanViewModel.todayPlanModels.isEmpty {
            sections.append(.todayPlan)
        }
        return sections.count
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < sections.count else { return nil }
        if sections[section] == .eventCard {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: EventFeedCardHeaderView.identifier) as?
                    EventFeedCardHeaderView else { return nil }
            return headerView
        }
        if sections[section] == .todayPlan {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TodayPlanHeaderView.identifier) as?
                    TodayPlanHeaderView else { return nil }
            return headerView
        }
        return nil
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < sections.count else { return }
        if sections[indexPath.section] == .eventCard {
            CalendarTracerV2.TodayEventCilck.traceClick() {
                $0.click("cal_event")
                $0.feed_tab = self.feedTap
                $0.is_top = self.feedIsTop
            }
            eventFeedCardViewModel.jumpToDetail(at: indexPath.row, from: self)
            tableView.deselectRow(at: indexPath, animated: true)
        } else if sections[indexPath.section] == .todayPlan {
            CalendarTracerV2.TodayEventCilck.traceClick() {
                $0.click("today_cal_event_widget")
                $0.feed_tab = self.feedTap
                $0.is_top = self.feedIsTop
            }
            todayPlanViewModel.jumpToDetail(at: indexPath.row, from: self)
        }
    }

    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if let cell = tableView.cellForRow(at: indexPath) as? ScheduleCardTableCell {
            cell.contentView.backgroundColor = UDColor.bgBody
        }
        return indexPath
    }
}

extension TodayEventViewController: SwipeTableViewCellDelegate {
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: LarkSwipeCellKit.SwipeActionsOrientation) -> [LarkSwipeCellKit.SwipeAction]? {
        if orientation == .left {
            return nil
        }
        let action = SwipeAction(style: .default,
                                 title: "",
                                 handler: { [weak self] _, indexPath, _ in
            guard let self = self else { return }
            CalendarTracerV2.TodayEventCilck.traceClick() {
                $0.click("delete")
                $0.feed_tab = self.feedTap
                $0.is_top = self.feedIsTop
            }
            self.eventFeedCardViewModel.deleteCell(at: indexPath.row)
        })
        action.backgroundColor = UDColor.functionDangerFillDefault
        action.image = UDIcon.deleteTrashOutlined.ud.resized(to: CGSize(width: 24, height: 24)).colorImage(UDColor.primaryOnPrimaryFill)
        return [action]
    }
}
