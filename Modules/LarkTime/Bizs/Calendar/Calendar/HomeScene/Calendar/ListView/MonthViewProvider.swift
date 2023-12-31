//
//  File.swift
//  MyDemo
//
//  Created by zhouyuan on 2018/8/5.
//  Copyright © 2018年 zhouyuan. All rights reserved.
//

import UIKit
import SnapKit
import JTAppleCalendar
import CalendarFoundation
import LarkTimeFormatUtils
import LarkUIKit

enum MonthViewMode: Int {
    case singleRow = 1 // 单行
    case multipleRows = 6 // 多行

    func numberOfRows() -> Int {
        return self.rawValue
    }
}

protocol MonthViewDelegate: AnyObject {
    func monthViewProvider(_ monthViewProvider: MonthViewProvider, didSelectedDate date: Date)

    func monthViewProvider(_ monthViewProvider: MonthViewProvider,
                            cellForItemAt date: Date) -> [UIColor]
}

final class MonthViewProvider: NSObject {

    private enum GestureDirection {
        case up, down
    }

    private let cellHeight: CGFloat
    private struct Style {
        static let headerHeight: CGFloat = 18
        static let footerHeight: CGFloat = 26
        static let expiredTextColor = UIColor.ud.textPlaceholder
        static let unexpiredTextColor = UIColor.ud.N800
        static let todayTextColor = UIColor.ud.primaryContentDefault
        static let todaySelectedTextColor = UIColor.white
        static let SelectViewNormalColor = UIColor.ud.N300
        static let SelectViewhighlightColor = UIColor.ud.primaryContentDefault
    }

    weak var delegate: MonthViewDelegate?
    let view = UIView()

    private let weekHeaderView: WeekHeaderView
    private let footerView = MonthViewFooterView()
    private var calendarView = JTAppleCalendarView()

    // 下面的uitableView联动 需要 superView layoutIfNeed
    private let superView: UIView
    private let calendarViewPanGeture = UIPanGestureRecognizer()
    private let tableViewPanGesture = UIPanGestureRecognizer()
    private let debouncer = Debouncer(delay: 0.3) // 暂时缓解小月历左右滑动闪烁问题，完全解决依赖重构
    // 决定calendarView的 模式 周/月
    // calendarView 的配置，calendarView初始化之前设置好
    var monthViewMode: MonthViewMode! {
        didSet {
            if monthViewMode == .singleRow {
                generateOutDates = .off
                generateInDates = .forFirstMonthOnly
                hasStrictBoundaries = false
                footerView.setIndicatorImageView(isExpend: false)
            } else {
                generateOutDates = .tillEndOfGrid
                generateInDates = .forAllMonths
                hasStrictBoundaries = true
                footerView.setIndicatorImageView(isExpend: true)
            }
        }
    }

    private func setMonthViewMode(mode: MonthViewMode) {
        self.monthViewMode = mode
    }

    private var generateInDates: InDateCellGeneration = .forFirstMonthOnly
    private var generateOutDates: OutDateCellGeneration = .off
    private var hasStrictBoundaries: Bool = false
    private var selectedDate: Date
    private var selectedDateRow: Int = 0
    private let firstWeekday: DaysOfWeek

    private var currentCalendar: Calendar {
        return Calendar.gregorianCalendar
    }

    // calendarView的真实高度
    private var numberOfRows: Int {
        return self.monthViewMode.numberOfRows()
    }

    // 当前显示的月份的日期行数
    private func numOfRowsInMonth(visibleDates: DateSegmentInfo) -> Int {
        return visibleDates.outdates.count < 7 ? 6 : 5
    }

    // calendarView的高度 1 * cellHeight 或 6 * cellHeight
    // 月份中的 5/6 行高度由view的高度控制 clipsToBounds
    private var calendarViewheight: CGFloat {
        return CGFloat(numberOfRows) * cellHeight
    }

    private let alternateCalendar: AlternateCalendarEnum
    private let isAlternateCalOpen: Bool

    init(date: Date,
         monthViewMode: MonthViewMode = .singleRow,
         superView: UIView,
         firstWeekday: DaysOfWeek,
         tableView: UITableView,
         alternateCalendar: AlternateCalendarEnum,
         width: CGFloat) {
        self.alternateCalendar = alternateCalendar
        self.isAlternateCalOpen = alternateCalendar != .noneCalendar
        self.cellHeight = isAlternateCalOpen ? MonthViewCell.alternateCalendarCellHeight : MonthViewCell.normalCellHeight
        self.superView = superView
        self.selectedDate = date
        self.firstWeekday = firstWeekday
        self.weekHeaderView = WeekHeaderView(firstWeekday: firstWeekday)
        super.init()
        self.setMonthViewMode(mode: monthViewMode)
        self.view.frame = CGRect(x: 0,
                                 y: 0,
                                 width: width,
                                 height: Style.headerHeight + calendarViewheight + Style.footerHeight)

        self.setupCaledarView(date: date, width: width)

        // 为了view有shadow
        let wrapper = UIView()
        self.setupWrapper(wrapper: wrapper)

        wrapper.addSubview(calendarView)
        wrapper.addSubview(weekHeaderView)
        wrapper.addSubview(footerView)
        if Display.pad {
            footerView.onClick = { [weak self] in
                self?.footerClickAction()
            }
        }
        self.setupViewShadows(self.view)
        self.setupConstraints()
        self.setupViewPanGesture(calendarViewPanGeture)
        self.setupLinkageTableView(tableView: tableView, panGesture: tableViewPanGesture)
    }

    func onWidthChange(width: CGFloat) {
        view.frame.size.width = width
        calendarView.frame.size.width = width
        calendarView.cellSize = width / 7
        calendarView.reloadData()
        calendarView.selectDates([selectedDate], triggerSelectionDelegate: false)
        calendarView.scrollToDate(selectedDate, animateScroll: false)
    }

    private func setupWrapper(wrapper: UIView) {
        wrapper.clipsToBounds = true
        self.view.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func setupViewShadows(_ view: UIView) {
        view.layer.ud.setShadowColor(UIColor.black)
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0.0, height: 2.5)
    }

    private func setupLinkageTableView(tableView: UITableView, panGesture: UIPanGestureRecognizer) {
        panGesture.delegate = self
        panGesture.addTarget(self, action: #selector(move(panGesture:)))
        tableView.addGestureRecognizer(panGesture)
        tableView.panGestureRecognizer.shouldBeRequiredToFail(by: panGesture)
    }

    private func setupViewPanGesture(_ panGesture: UIPanGestureRecognizer) {
        panGesture.addTarget(self, action: #selector(move(panGesture:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }

    private func footerClickAction() {
        if self.monthViewMode != .multipleRows {
            updateCanlendarViewFrame(yOffset: Style.headerHeight - CGFloat(selectedDateRow) * self.cellHeight,
                                     height: self.cellHeight * 6)

            reloadDataWithMode(.multipleRows)

            UIView.animate(withDuration: 0.2, animations: {
                self.updateSelfViewHeight(self.viewMaxHeight())
                self.updateCanlendarViewFrame(yOffset: Style.headerHeight)
                self.superView.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.updateSelfViewHeight(self.viewMinHeight())
                self.updateCanlendarViewFrame(yOffset: Style.headerHeight - CGFloat(self.selectedDateRow) * self.cellHeight)

                self.superView.layoutIfNeeded()
            }) { (_) in
                self.updateCanlendarViewFrame(yOffset: Style.headerHeight, height: self.cellHeight)
                self.reloadDataWithMode(.singleRow) {
                }
            }
        }
    }

    @objc
    func move(panGesture: UIPanGestureRecognizer) {
        self.superView.layoutIfNeeded()
        self.superView.setNeedsLayout()

        let velocity = panGesture.velocity(in: self.view)
        let point = panGesture.translation(in: self.view)
        panGesture.setTranslation(CGPoint.zero, in: self.view)

        if panGesture.state == .began {
            if self.monthViewMode != .multipleRows {
                updateCanlendarViewFrame(yOffset: Style.headerHeight - CGFloat(selectedDateRow) * self.cellHeight,
                                         height: self.cellHeight * 6)

                reloadDataWithMode(.multipleRows)
            }
        }

        if panGesture.state == .changed {
            monthViewAnimate(offset: point.y)
        }

        if panGesture.state == .ended {
            if velocity.y < 0 {
                CalendarTracer.shareInstance.calCalWidgetOperation(actionSource: .defaultView,
                                                                   actionTargetStatus: .close)
                UIView.animate(withDuration: 0.2, animations: {
                    self.updateSelfViewHeight(self.viewMinHeight())
                    self.updateCanlendarViewFrame(yOffset: Style.headerHeight - CGFloat(self.selectedDateRow) * self.cellHeight)
                    panGesture.isEnabled = false
                    self.superView.layoutIfNeeded()
                }) { (_) in
                    self.updateCanlendarViewFrame(yOffset: Style.headerHeight, height: self.cellHeight)
                    self.reloadDataWithMode(.singleRow) {
                        panGesture.isEnabled = true
                    }
                }
            } else {
                CalendarTracer.shareInstance.calCalWidgetOperation(actionSource: .defaultView,
                                                                   actionTargetStatus: .open)
                UIView.animate(withDuration: 0.2, animations: {
                    self.updateSelfViewHeight(self.viewMaxHeight())
                    self.updateCanlendarViewFrame(yOffset: Style.headerHeight)
                    self.superView.layoutIfNeeded()
                })
            }
        }
    }

    private func monthViewAnimate(offset: CGFloat) {
        // 按百分比 同时滑动
        let rowsCount = numOfRowsInMonth(visibleDates: calendarView.visibleDates())
        let percent = (offset / (CGFloat(rowsCount - 1) * self.cellHeight))
        let calendarOffset = (percent * CGFloat(self.selectedDateRow) * self.cellHeight)
        let viewOffset = (percent * CGFloat(rowsCount - self.selectedDateRow - 1) * self.cellHeight)

        let calendarY = self.calendarView.frame.origin.y + calendarOffset
        let viewHeight = self.view.frame.size.height + viewOffset + calendarOffset

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {

            if calendarY > Style.headerHeight {
                self.updateCanlendarViewFrame(yOffset: Style.headerHeight)
            } else if calendarY < Style.headerHeight - CGFloat(self.selectedDateRow) * self.cellHeight {
                self.updateCanlendarViewFrame(yOffset: Style.headerHeight - CGFloat(self.selectedDateRow) * self.cellHeight)
            } else {
                self.updateCanlendarViewFrame(yOffset: calendarY)
            }

            if viewHeight > self.viewMaxHeight() {
                self.updateSelfViewHeight(self.viewMaxHeight())
            } else if viewHeight < self.viewMinHeight() {
                self.updateSelfViewHeight(self.viewMinHeight())
            } else {
                self.updateSelfViewHeight(viewHeight)
            }
            self.superView.layoutIfNeeded()
        })
    }

    private func setupCaledarView(date: Date, width: CGFloat) {
        calendarView.frame = CGRect(x: 0,
                                    y: Style.headerHeight,
                                    width: width,
                                    height: self.cellHeight)
        calendarView.backgroundColor = UIColor.ud.bgBody
        calendarView.calendarDelegate = self
        calendarView.calendarDataSource = self
        calendarView.scrollDirection = .horizontal
        calendarView.isPagingEnabled = true
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.showsHorizontalScrollIndicator = false
        calendarView.showsVerticalScrollIndicator = false
        calendarView.register(MonthViewCell.self, forCellWithReuseIdentifier: "MonthViewCell")
        calendarView.cellSize = width / 7
        calendarView.selectDates([date], triggerSelectionDelegate: false)
        calendarView.scrollToDate(date, animateScroll: false)
    }

    private func setupConstraints() {
        weekHeaderView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Style.headerHeight + 2)
        }

        footerView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(Style.footerHeight)
        }
    }

    private func updateSelfViewHeight(_ height: CGFloat) {
        self.view.frame.size.height = height
    }

    private func updateCanlendarViewFrame(yOffset: CGFloat? = nil, height: CGFloat? = nil) {
        if let yOffset = yOffset {
            calendarView.frame.origin.y = yOffset
        }
        if let height = height {
            calendarView.frame.size.height = height
        }
    }

    private func viewMaxHeight() -> CGFloat {
        return viewMaxHeight(visibleDates: calendarView.visibleDates())
    }

    private func viewMaxHeight(visibleDates: DateSegmentInfo) -> CGFloat {
        return Style.headerHeight
            + visibleDatesMaxHeight(visibleDates: visibleDates)
            + Style.footerHeight
    }

    private func viewMinHeight() -> CGFloat {
        return Style.headerHeight + self.cellHeight + Style.footerHeight
    }

    private func visibleDatesMaxHeight(visibleDates: DateSegmentInfo) -> CGFloat {
        return CGFloat(numOfRowsInMonth(visibleDates: visibleDates)) * self.cellHeight
    }

    private func adjustCalendarViewHeight(from visibleDates: DateSegmentInfo) {
        var viewHeight: CGFloat
        if monthViewMode == .singleRow {
            viewHeight = viewMinHeight()
        } else {
            viewHeight = viewMaxHeight(visibleDates: visibleDates)
        }
        UIView.animate(withDuration: 0.2) {
            self.updateSelfViewHeight(viewHeight)
            self.superView.layoutIfNeeded()
        }
    }

    private func setupViewsOfMonthView(from visibleDates: DateSegmentInfo) {

        let monthDates = visibleDates.monthDates
        guard let startDate = monthDates.first?.date else {
            assertionFailureLog()
            return
        }
        self.handleHeaderWeekTextColor(mode: monthViewMode, startDate: startDate)

        if monthViewMode == .multipleRows {
            // 如果本月第一天和当前选中的在同一个月，则证明视图没有真正翻页 不需要切换选择日期
            guard !startDate.isInSameMonth(selectedDate) else { return }

            // 否则选中当月1号
            selectDate(date: startDate)
        } else {
            // 如果本周第一天和当前选中的在同一个周，则证明视图没有真正翻页 不需要切换选择日期
            guard !startDate.isInSameWeek(selectedDate, firstWeekday: firstWeekday.rawValue) else { return }

            let weekday = selectedDate.weekday
            guard let shouldSelectDate = monthDates.first(where: {
                $0.date.weekday == weekday
            })?.date else {
                assertionFailureLog()
                return
            }
            selectDate(date: shouldSelectDate)
        }
    }

    private func handleHeaderWeekTextColor(mode: MonthViewMode, startDate: Date) {
        if mode == .multipleRows {
            weekHeaderView.setTodaysWeekLabel(isHighlight: startDate.isInSameMonth(Date.today()))
        } else {
            let isHighlight = startDate.isInSameWeek(Date.today(),
                                                     firstWeekday: firstWeekday.rawValue)
            weekHeaderView.setTodaysWeekLabel(isHighlight: isHighlight)
        }
    }

    private func handleCellConfiguration(cell: JTAppleCell?, cellState: CellState) {
        handleCellSelection(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
    }

    // Function to handle the text color of the calendar
    private func handleCellTextColor(view: JTAppleCell?, cellState: CellState) {
        guard let myCustomCell = view as? MonthViewCell  else {
            return
        }

        // 被选中 且 是当天
        if cellState.isSelected && cellState.date.isInSameDay(Date.today()) {
            myCustomCell.setDayLabelColor(color: Style.todaySelectedTextColor)
            myCustomCell.setAlternateCalLabelColor(color: Style.todayTextColor)
            myCustomCell.setSelectViewColor(color: Style.SelectViewhighlightColor)
            return
        }

        // 被选中 不是当天
        if cellState.isSelected {
            myCustomCell.setSelectViewColor(color: Style.SelectViewNormalColor)
        }

        // 当天 没有选中
        if cellState.date.isInSameDay(Date.today()) {
            myCustomCell.setDayLabelColor(color: Style.todayTextColor)
            myCustomCell.setAlternateCalLabelColor(color: Style.todayTextColor)
            return
        }

        // 展开中且属于当月 或 收起中 大于 今日
        if (cellState.dateBelongsTo == .thisMonth && monthViewMode == .multipleRows)
        || (monthViewMode == .singleRow && cellState.date > Date.today()) {
            myCustomCell.setDayLabelColor(color: Style.unexpiredTextColor)
            myCustomCell.setAlternateCalLabelColor(color: Style.expiredTextColor)
            return
        }
        myCustomCell.setDayLabelColor(color: Style.expiredTextColor)
        myCustomCell.setAlternateCalLabelColor(color: Style.expiredTextColor)
    }

    // Function to handle the calendar selection
    private func handleCellSelection(view: JTAppleCell?, cellState: CellState) {
        if cellState.isSelected {
            self.selectedDateRow = cellState.date.weekOfMonth - 1
        }

        guard let myCustomCell = view as? MonthViewCell else { return }
        myCustomCell.setSelected(isSelected: cellState.isSelected)
    }

    private func shouldCalendarViewMove(direction: GestureDirection) -> Bool {
        return !((monthViewMode == .singleRow && direction == .up)
            || (monthViewMode == .multipleRows && direction == .down))
    }

    private func reloadDataWithMode(_ mode: MonthViewMode, completionHandler: (() -> Void)? = nil) {
        setMonthViewMode(mode: mode)
        calendarView.reloadData(withanchor: selectedDate, completionHandler: completionHandler)
    }
}

extension MonthViewProvider: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGesture.velocity(in: self.view)
        if panGesture == calendarViewPanGeture {
            return shouldCalendarViewMove(direction: velocity.y > 0 ? .down : .up)
        }
        if panGesture == tableViewPanGesture {
            return monthViewMode == .multipleRows
        }
        return false
    }
}

// MARK: func
extension MonthViewProvider {

    func selectDate(date: Date, triggerSelectionDelegate: Bool = true) {
        selectedDate = date
        calendarView.selectDates([date],
                                 triggerSelectionDelegate: triggerSelectionDelegate,
                                 keepSelectionIfMultiSelectionAllowed: false)
    }

    func scrollToDateWithSelect(_ date: Date,
                             triggerScrollToDateDelegate: Bool = true,
                             animateScroll: Bool = true) {
        selectDate(date: date, triggerSelectionDelegate: false)
        calendarView.scrollToDate(date,
                                  triggerScrollToDateDelegate: triggerScrollToDateDelegate,
                                  animateScroll: animateScroll) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.handleHeaderWeekTextColor(mode: self.monthViewMode, startDate: date)
        }
    }

    func reloadData() {
        debouncer.call {
            TimerMonitorHelper.shared.launchTimeTracer?.showGrid.end()
            self.calendarView.reloadData(withanchor: self.selectedDate)
        }
    }

    func monthViewDisplayDate(benchmark: Date) -> (Date, Date) {
        guard let first = benchmark.startOfMonth() - (7).days,
            let last = benchmark.endOfMonth() + (7).days else {
                assertionFailureLog()
                return (Date(), Date())
        }
        return (first, last)
    }

}

// MARK: JTAppleCalendarDelegate

extension MonthViewProvider: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {

    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {

        let startDate = currentCalendar.date(byAdding: .year, value: -20, to: Date.today())!
        let endDate = currentCalendar.date(byAdding: .year, value: 20, to: Date.today())!

        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: numberOfRows,
                                                 calendar: currentCalendar,
                                                 generateInDates: generateInDates,
                                                 generateOutDates: generateOutDates,
                                                 firstDayOfWeek: firstWeekday,
                                                 hasStrictBoundaries: hasStrictBoundaries)
        return parameters
    }

    func configureVisibleCell(myCustomCell: MonthViewCell, cellState: CellState, date: Date) {
        guard let day = Int(cellState.text) else {
            myCustomCell.isHidden = true
            return
        }
        if cellState.row() == 5
            && cellState.column() < day
            && cellState.dateBelongsTo != .thisMonth {
            myCustomCell.isHidden = true
            return
        }

        myCustomCell.isHidden = false
        let colors = self.delegate?.monthViewProvider(self, cellForItemAt: date)
        handleCellConfiguration(cell: myCustomCell, cellState: cellState)
        if isAlternateCalOpen {
            let alternateCalendarText = AlternateCalendarUtil.getDisplayElement(date: date, type: self.alternateCalendar)
            myCustomCell.setContent(text: cellState.text, colors: colors, alternateCalendarText: alternateCalendarText)
        } else {
            myCustomCell.setContent(text: cellState.text, colors: colors, alternateCalendarText: nil)
        }
    }

    func calendar(_ calendar: JTAppleCalendarView,
                  willDisplay cell: JTAppleCell,
                  forItemAt date: Date,
                  cellState: CellState,
                  indexPath: IndexPath) {
        // swiftlint:disable force_cast
        let myCustomCell = cell as! MonthViewCell
        configureVisibleCell(myCustomCell: myCustomCell, cellState: cellState, date: date)
    }

    func calendar(_ calendar: JTAppleCalendarView,
                  cellForItemAt date: Date,
                  cellState: CellState,
                  indexPath: IndexPath) -> JTAppleCell {
        // swiftlint:disable force_cast
        let myCustomCell = calendar.dequeueReusableCell(withReuseIdentifier: "MonthViewCell",
                                                           for: indexPath) as! MonthViewCell
        configureVisibleCell(myCustomCell: myCustomCell, cellState: cellState, date: date)
        return myCustomCell
    }

    // 取消选中
    func calendar(_ calendar: JTAppleCalendarView,
                  didDeselectDate date: Date,
                  cell: JTAppleCell?,
                  cellState: CellState) {
        handleCellConfiguration(cell: cell, cellState: cellState)
    }

    // 选中回调
    func calendar(_ calendar: JTAppleCalendarView,
                  didSelectDate date: Date,
                  cell: JTAppleCell?,
                  cellState: CellState) {
        operationLog(message: "dateString: \(date.dateString(in: .short))")
        selectedDate = date
        if cellState.dateBelongsTo != .thisMonth {
            calendar.scrollToDate(date)
        }
        self.delegate?.monthViewProvider(self, didSelectedDate: date)
        handleCellConfiguration(cell: cell, cellState: cellState)
        CalendarTracer.shareInstance.calNavigation(actionSource: .calWidget,
                                                   navigationType: .byDate,
                                                   viewType: .list)
    }

    // 滚动回调
    func calendar(_ calendar: JTAppleCalendarView,
                  didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        self.setupViewsOfMonthView(from: visibleDates)
        if self.monthViewMode == .multipleRows {
            self.adjustCalendarViewHeight(from: visibleDates)
        }
    }

    func calendar(_ calendar: JTAppleCalendarView,
                  headerViewForDateRange range: (start: Date, end: Date),
                  at indexPath: IndexPath) -> JTAppleCollectionReusableView {
        let header: JTAppleCollectionReusableView
        header = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: "WhiteSectionHeaderView",
                                                                  for: indexPath)
        return header
    }

    func sizeOfDecorationView(indexPath: IndexPath) -> CGRect {
        let stride = calendarView.frame.width * CGFloat(indexPath.section)
        return CGRect(x: stride + 5, y: 5,
                      width: calendarView.frame.width - 10,
                      height: calendarView.frame.height - 10)
    }

    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? {
        return nil
    }

}

final class WeekHeaderView: UIView {

    private let textFont = UIFont.cd.regularFont(ofSize: 12)
    private let normalColor = UIColor.ud.N800
    private let highlightColor = UIColor.ud.primaryContentDefault
    private let stackView = UIStackView()
    private var firstWeekday: DaysOfWeek

    init(firstWeekday: DaysOfWeek) {
        self.firstWeekday = firstWeekday
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        layoutStackView(stackView)
        layoutLabels(stackView: stackView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func weekInfo(index: Int) -> (String, Int) {
        let weekday = (index + firstWeekday.rawValue - 1) % 7 + 1
        let string = TimeFormatUtils.weekdayAbbrString(weekday: weekday)
        return (string, weekday)
    }

    private func layoutStackView(_ stackView: UIStackView) {
        self.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually

        stackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(3)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    private func layoutLabels(stackView: UIStackView) {
        for i in 0..<7 {
            let (weekString, weekday) = self.weekInfo(index: i)
            let label = weeklabel(weekString)
            label.tag = weekday
            stackView.addArrangedSubview(label)
        }
    }

    private func weeklabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = textFont
        label.textAlignment = .center
        label.text = text
        label.textColor = normalColor
        return label
    }

    private func labels() -> [UILabel] {
        return stackView.subviews.compactMap({ $0 as? UILabel })
    }

    func setTodaysWeekLabel(isHighlight: Bool, uiCurrentDate: Date = Date.today()) {
        let daysOfWeek = uiCurrentDate.weekday
        self.labels().forEach { (label) in
            label.textColor = normalColor
        }
        guard let label = self.labels().first(where: { $0.tag == daysOfWeek }) else {
            assertionFailureLog()
            return
        }
        label.textColor = isHighlight ? highlightColor : normalColor
    }
}

final class MonthViewFooterView: UIView {

    private let indicatorImageView = UIImageView()

    var onClick: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.setupIndicatorImageView(imageView: indicatorImageView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(footerClick))
              addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupIndicatorImageView(imageView: UIImageView) {
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(2)
        }
    }

    func setIndicatorImageView(isExpend: Bool) {
        if isExpend {
            indicatorImageView.image = UIImage.cd.image(named: "monthViewExpand").withRenderingMode(.alwaysOriginal)
        } else {
            indicatorImageView.image = UIImage.cd.image(named: "monthViewCollapse").withRenderingMode(.alwaysOriginal)
        }
    }

    @objc
       private func footerClick() {
           onClick?()
       }

}
