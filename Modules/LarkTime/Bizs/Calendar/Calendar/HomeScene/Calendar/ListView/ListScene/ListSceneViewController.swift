//
//  ListSceneViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/7/25.
//

import Foundation
import UIKit
import CalendarFoundation
import RxSwift
import RxCocoa
import CTFoundation
import LarkContainer
import LKCommonsLogging
import EventKit

struct ListScene {
    static let logger = Logger.log(CalendarList.self, category: "lark.calendar.list_scene")

    static func logInfo(_ message: String) {
        logger.info(message)
    }

    static func logError(_ message: String) {
        logger.error(message)
    }

    static func logWarn(_ message: String) {
        logger.warn(message)
    }

    static func logDebug(_ message: String) {
        logger.debug(message)
    }
}

public final class ListSceneViewController: UIViewController, EventViewController, InstanceCacheStrategyProvider, UserResolverWrapper {

    private let fromSceneMode: HomeSceneMode?

    weak var delegate: EventViewControllerDelegate?

    var tabBarDirection: ScrollDriction = .vertical

    public var userResolver: UserResolver

    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?

    let viewModel: ListSceneViewModel

    private let width: CGFloat

    let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    var rxInstanceCacheStrategy: BehaviorRelay<InstanceCacheStrategy>?

    private lazy var monthViewProvider: MonthViewProvider = {
        let monthViewProvider = MonthViewProvider(date: self.viewModel.currentDate,
                                                  superView: view,
                                                  firstWeekday: self.viewModel.rxViewSetting.value.firstWeekday,
                                                  tableView: tableView,
                                                  alternateCalendar: self.viewModel.rxViewSetting.value.alternateCalendar ?? self.viewModel.rxViewSetting.value.defaultAlternateCalendar,
                                                  width: self.width)
        monthViewProvider.delegate = self
        return monthViewProvider
    }()

    // leftHeaderView 数据
    var dateViewDic: [Date: UIView] = [:]

    // tableView 数据源
    var cellItems: [BlockListItem] {
        self.viewModel.itemsSorted
    }

    // 时间红线
    let redLine = EventListRedLine()

    let disposeBag = DisposeBag()

    init(userResolver: UserResolver, viewModel: ListSceneViewModel, width: CGFloat, containerWidthChange: Driver<CGFloat>, fromSceneMode: HomeSceneMode?) {
        HomeScene.coldLaunchTracker?.insertPoint(.initListScene)
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.width = width
        self.fromSceneMode = fromSceneMode
        super.init(nibName: nil, bundle: nil)
        if let range = HomeScene.coldLaunchContext?.dayRange {
            let instanceCacheStrategy = InstanceCacheStrategy(
                timeZone: TimeZone.current,
                diskCacheRange: range,
                memoryCacheDays: .init(range)
            )
            self.rxInstanceCacheStrategy = BehaviorRelay(value: instanceCacheStrategy)
        }

        containerWidthChange.drive(onNext: { [weak self] (width) in
            guard let `self` = self else { return }
            self.monthViewProvider.onWidthChange(width: width)
        }).disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        HomeScene.coldLaunchTracker?.insertPoint(.listSceneDidLoad)

        super.viewDidLoad()
        view.addSubview(monthViewProvider.view)
        monthViewProvider.view.frame.origin.y += 6
        layoutTableView(tableView: tableView, under: monthViewProvider.view)
        bindRefreshSubject()
        bindRedLine()
        coldLaunchIfNeeded()
    }

    func reloadData(with date: Date) {
        self.viewModel.didSelectDate(date, animated: false)
        return
    }

    func currentPageDate() -> Date {
        self.viewModel.currentDate
    }

    func getCurrentSelectDate() -> Date {
        self.viewModel.currentDate
    }

    func scrollToRedLine(animated: Bool) {
        self.viewModel.scrollToRedLine(animated: animated)
    }

    func dayViewContentOffset() -> CGPoint? {
        return nil
    }

}

// MARK: View Refresh

extension ListSceneViewController {

    private func bindRefreshSubject() {
        self.viewModel.rxRefreshSubject
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in
                // 开始渲染日程
                TimerMonitorHelper.shared.launchTimeTracer?.renderInstance.start()
                TimerMonitorHelper.shared.launchTimeTracer?.instanceRenderGap.end()
                HomeScene.coldLaunchTracker?.insertPoint(.listSceneViewDataReady)
            }, afterNext: { [weak self] refreshType in
                self?.fixTableView(animated: refreshType.animated)
                self?.refreshView()
                self?.finishTrack()
            })
            .subscribe(onNext: { [weak self] refreshType in
                guard let self else { return }
                switch refreshType {
                case .loadPrevious:
                    ListScene.logInfo("[refreshType] loadPreviousAndKeepOffset")
                    self.loadPreviousAndKeepOffset()
                case .loadFollowing:
                    ListScene.logInfo("[refreshType] loadFollowing")
                    self.tableView.reloadData()
                case .scrollToDate(let date, let animated, let isScroll):
                    ListScene.logInfo("[refreshType] scrollToDate \(date)")
                    if FeatureGating.taskInCalendar(userID: self.userResolver.userID), !isScroll {
                        self.tableView.reloadData()
                        return
                    }
                    self.scrollToDate(date, animated: animated)
                }
            }).disposed(by: disposeBag)
    }

    func finishTrack() {
        // 冷启动结束，https://bytedance.feishu.cn/docx/doxcnFBVyCUTuChMBhVuo8D1Ycb
        HomeScene.coldLaunchTracker?.finish(.succeed)
        self.calendarSelectTracer?.end()
    }

    private func loadPreviousAndKeepOffset() {
        let beforeContentSize = self.tableView.contentSize
        self.tableView.reloadData()
        let afterContentSize = self.tableView.contentSize
        let afterContentOffset = self.tableView.contentOffset

        let newOffset = CGPoint(
            x: afterContentOffset.x + (afterContentSize.width - beforeContentSize.width),
            y: afterContentOffset.y + (afterContentSize.height - beforeContentSize.height))
        self.tableView.setContentOffset(newOffset, animated: false)
    }

    func scrollToDate(_ date: Date, animated: Bool = false) {
        let items = self.cellItems
        tableView.reloadData()
        guard tableView.numberOfRows(inSection: 0) == items.count else {
            assertionFailureLog()
            return
        }
        self.viewModel.currentDate = date
        if date.isInSameDay(Date()),
           let position = self.redlinePosition() {
            // 滚动到今日即滚动到红线位置
            self.tableView.scrollToRow(at: position.indexPathToScrollsTop(), at: .top, animated: animated)
            return
        }
        guard let index = items.firstIndex(where: { $0.dateStart.isInSameDay(date) }) else { return }
        tableView.scrollToRow(at: IndexPath(row: index, section: 0),
                              at: .top, animated: animated)
    }

    private func fixTableView(animated: Bool) {
        // 修复 tableView 在上下边界触发数据预加载后刷新造成的视图偏移影响
        if let firstVisibleIndexPath = tableView.indexPathsForVisibleRows?.first,
           let item = self.cellItems[safeIndex: firstVisibleIndexPath.row],
           item.isEvent(),
           !item.date.isInSameDay(self.viewModel.currentDate) {
            // 列表刷新后日期矫正
            scrollToDate(self.viewModel.currentDate, animated: animated)
        }
    }

    // 刷新列表视图的各个View
    private func refreshView() {
        let currentDate = self.viewModel.currentDate
        // 更新顶部日期
        self.delegate?.dateDidChanged(self, date: currentDate)
        // 更新视图页显示区域

        let currentJulianDay = JulianDayUtil.julianDay(from: currentDate, in: TimeZone.current)

        let firstWeekDay = EKWeekday(rawValue: viewModel.rxViewSetting.value.firstWeekday.rawValue) ?? .sunday
        let dayRange = JulianDayUtil.julianDayRange(inSameWeekAs: currentJulianDay, with: firstWeekDay)

        let startDate = getDate(julianDay: Int32(dayRange.lowerBound))
        let endDate = getDate(julianDay: Int32(dayRange.upperBound))
        self.delegate?.displayRangeDidChanged(self, startDate: startDate, endDate: endDate)
        // 更新左边日期
        self.updateHeadersLocations()
        // 更新月历日期
        self.monthViewLinkageDate(date: currentDate)
        // 更新月历色点
        self.monthViewProvider.reloadData()
        // 更新红线位置
        self.updateRedline()
        // 更新 tabbar 图标
        self.updatePagingProgress(tableView: self.tableView, isJump: false)
    }
}

// MARK: UITableViewDataSource

extension ListSceneViewController: UITableViewDataSource {

    private func layoutTableView(tableView: UITableView, under: UIView) {
        let wrapperView = UIView()
        self.view.insertSubview(wrapperView, at: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.scrollsToTop = false

        tableView.register(ListCell.self, forCellReuseIdentifier: ListCell.identifier)
        tableView.register(WeekCell.self, forCellReuseIdentifier: WeekCell.identifier)
        tableView.register(MonthCell.self, forCellReuseIdentifier: MonthCell.identifier)
        tableView.register(ListSubCell.self, forCellReuseIdentifier: ListSubCell.identifier)

        wrapperView.clipsToBounds = true
        wrapperView.addSubview(tableView)
        wrapperView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(under.snp.bottom)
        }
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = self.cellItems[safeIndex: indexPath.row],
              let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifer) else {
            return UITableViewCell()
        }
        self.updateCell(cell, item: item)
        return cell
    }

    private func updateCell(_ cell: UITableViewCell, item: BlockListItem) {
        if let monthCell = cell as? MonthCell,
           let separator = item.separator {
            monthCell.updateContent(separator)
        } else if let weekCell = cell as? WeekCell,
                  let separator = item.separator {
            weekCell.updateContent(separator)
        } else if let eventCell = cell as? ListCell,
                  let event = item.event {
            eventCell.update(content: event)
            eventCell.delegate = self
            eventCell.newEventCallBack = { [unowned self] in
                self.createNewEvent(date: event.eventDate)
            }
        } else if let subCell = cell as? ListSubCell,
                  let event = item.event {
            subCell.delegate = self
            subCell.update(content: event)
        } else {
            assertionFailureLog()
        }
    }

    private func createNewEvent(date: Date) {
        let diff = Int(getJulianDay(date: date) - getJulianDay(date: Date()))
        let newEventDate = (Date() + diff.days) ?? Date()
        let newEventModel = NewEventModel.defaultNewModel(startTime: newEventDate)
        self.delegate?.onFastNewEvent(
            self,
            startTime: newEventModel.startTime,
            endTime: newEventModel.endTime ?? Date()
        )
    }

}

// MARK: UITableViewDelegate

extension ListSceneViewController: UITableViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = scrollView as? UITableView else { return
        }
        /// 非用户触发的视图滚动（代码触发），tableView 不进行自适应更新 date
        guard scrollView.isDragging || scrollView.isDecelerating || scrollView.isTracking else {
            refreshView()
            return
        }
        updateDateAndRefresh(tableView: tableView)
    }

    private func updatePagingProgress(tableView: UITableView, isJump: Bool) {
        let progress: CGFloat
        if let position = self.redLine.redlinePosition {
            let originY = tableView.rectForRow(at: position.indexPathToScrollsTop()).minY
            progress = (tableView.contentOffset.y - originY) / tableView.frame.height
            self.delegate?.eventViewController(self, pagingProgress: progress, isJump: isJump, shouldGradual: false)
        } else if let firstVisibleIndexPath = tableView.indexPathsForVisibleRows?.first,
                  let item = self.cellItems[safeIndex: firstVisibleIndexPath.row] {
            let days = Double(daysBetween(date1: Date.today(), date2: item.dateStart))
            progress = CGFloat(days / 3)
            self.delegate?.eventViewController(self, pagingProgress: progress, isJump: isJump, shouldGradual: false)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let tableview = scrollView as? UITableView else { return }
        let navigationType: CalendarTracer.CalNavigationParam.NavigationType = velocity.y > 0 ? .next : .prev
        CalendarTracer.shareInstance.calNavigation(actionSource: .defaultView,
                                                   navigationType: navigationType,
                                                   viewType: .list)

        var targetY = targetContentOffset.pointee.y
        if let indexPath = tableview.indexPathForRow(at: targetContentOffset.pointee),
            abs(velocity.y) > 0.1 {
            let frame = tableview.rectForRow(at: indexPath)
            if targetY - frame.minY < (frame.height / 2) {
                targetY = frame.minY
            } else {
                targetY = frame.minY + frame.height
            }
            targetContentOffset.pointee.y = targetY
        }
    }

    // 数据预加载
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            let contentOffset = scrollView.contentOffset
            let contentSize = scrollView.contentSize

            if contentOffset.y < 10,
               let date = self.cellItems.first?.dateStart {
                // 即将到达列表顶部，进行 Previous 数据预加载
                ListScene.logInfo("preload Previous data")
                self.viewModel.updateCellItems(date: date, refreshType: .loadPrevious)

            }

            if contentOffset.y + scrollView.bounds.height > contentSize.height - 10,
               let date = self.cellItems.last?.date {
                // 即将到达列表底部，进行 Following 数据预加载
                ListScene.logInfo("preload Following data")
                self.viewModel.updateCellItems(date: date, refreshType: .loadFollowing)
            }
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellHeight = self.cellItems[safeIndex: indexPath.row]?.cellHeight else {
            return ListCell.cellHeight
        }
        return cellHeight
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let eventContent = self.cellItems[safeIndex: indexPath.row]?.event?.content else {
            return
        }
        var model: BlockDataProtocol?
        if let instance = eventContent.userInfo["instance"] as? CalendarEventInstanceEntity {
            model = instance
        } else if let timeBlock = eventContent.userInfo["timeBlock"] as? TimeBlockModel {
            model = timeBlock
        }
        guard let model else { return }
        self.delegate?.eventViewController(self, didSelected: model)
        operationLog(optType: CalendarOperationType.listDetail.rawValue)
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard self.cellItems.count <= 4 else { return }
        // cell 不足一屏补满一屏
        if let date = self.cellItems.last?.date {
            ListScene.logInfo("fill one scene")
            self.viewModel.updateCellItems(date: date, refreshType: .loadFollowing)
        }
    }

    // 修改当前时间并刷新View
    private func updateDateAndRefresh(tableView: UITableView) {
        guard let visibleRows = tableView.indexPathsForVisibleRows,
              let firstVisibleIndexPath = visibleRows.first,
              let item = self.cellItems[safeIndex: firstVisibleIndexPath.row] else {
            return
        }
        self.viewModel.currentDate = item.date
        self.refreshView()
    }
}

// MARK: MonthViewDelegate

extension ListSceneViewController: MonthViewDelegate {

    private func monthViewLinkageDate(date: Date) {
        self.monthViewProvider.scrollToDateWithSelect(date,
                                                      triggerScrollToDateDelegate: false,
                                                      animateScroll: false)
    }

    func monthViewProvider(_ monthViewProvider: MonthViewProvider,
                                  didSelectedDate date: Date) {
        self.viewModel.didSelectDate(date, animated: false)
    }

    func monthViewProvider(_ monthViewProvider: MonthViewProvider,
                           cellForItemAt date: Date) -> [UIColor] {
        guard !self.cellItems.isEmpty else { return [] }

        let dateTimeString = BlockListItemModel.formatter.string(from: date)
        let alpha: CGFloat = date < Date.today() ? 0.6 : 1
        return self.cellItems.filter { (item) -> Bool in
            item.dateTimeString == dateTimeString
        }.compactMap({ (item) -> UIColor? in
            item.event?.content?.dotColor
        }).map { color in
            color.withAlphaComponent(alpha)
        }
    }
}

// MARK: Cold Launch

extension ListSceneViewController {
    func coldLaunchIfNeeded() {
        let currentDate = self.viewModel.currentDate
        if self.fromSceneMode == nil,
           let context = HomeScene.coldLaunchContext {
            // 冷启动场景
            self.viewModel.updateCellItemsWithColdLaunch()
        } else {
            self.viewModel.registerBlockUpdated()
            self.viewModel.updateCellItems(date: currentDate,
                                           refreshType: .scrollToDate(currentDate, false, true),
                                           showEmptyDate: currentDate)
        }
    }
}

extension ListSceneViewController: EventInstanceViewDelegate {
    func iconTapped(_ info: [String: Any], isSelected: Bool) {
        guard let model = info["timeBlock"] as? TimeBlockModel else {
            return
        }
        viewModel.timeDataService?.tapIconTapped(model: model, isCompleted: isSelected, from: self)
    }
    
    func showVC(_ vc: UIViewController) {
        self.userResolver.navigator.present(vc, from: self)
    }
}
