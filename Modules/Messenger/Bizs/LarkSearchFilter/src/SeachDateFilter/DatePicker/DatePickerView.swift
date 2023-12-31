//
//  DatePickerView.swift
//  LarkSearch
//
//  Created by SuPeng on 4/23/19.
//

import UIKit
import Foundation
import DateToolsSwift
import JTAppleCalendar
import LarkUIKit
import UniverseDesignCheckBox
import UniverseDesignFont

public protocol DatePickerViewDelegate: AnyObject {
    // date = nil代表不限制
    func pickerView(_ pickerView: DatePickerView, didSelectStart date: Date?)
    func pickerView(_ pickerView: DatePickerView, didSelectEnd date: Date?)
}

@objc(SearchDatePickerView)
public final class DatePickerView: UIView {

    public weak var delegate: DatePickerViewDelegate?

    private let topLayoutGuide = UILayoutGuide()
    private let controlPlaceView = UIView()
    private let dateLabelContainer = UIView()
    private let dateLabel = UILabel()
    private let checkBoxAndTextStackView = UIStackView()
    private let noLimitCheckbox = UDCheckBox(boxType: .multiple)
    private let noLimitLabel = UILabel()
    private let monthDayBackButton = UIButton()
    private let monthDayForwardButton = UIButton()
    private let yearMonthBackButton = UIButton()
    private let calendarContainer = UIView()
    private let monthDayCalendarView = JTAppleCalendarView()
    private lazy var yearMonthPickerView: SearchDateYearMonthPickerView = {
        let config = SearchDateYearMonthPickerConfig(minDate: self.minLimitDate,
                                                     maxDate: self.maxLimitDate,
                                                     defaultSelectedYear: startDate?.year ?? Date().year,
                                                     defaultSelectedMonth: startDate?.month ?? Date().month)
        let yearMonthPickerView = SearchDateYearMonthPickerView(config: config)
        yearMonthPickerView.selectedChanged = { [weak self] year, month in
            guard let self = self else { return }
            self.updateSelectYearMonth(year: year, month: month)
        }
        return yearMonthPickerView
    }()

    private var style: DateFilerItemViewStyle
    private var isMonthDayViewShow: Bool = true
    public private(set) var startDate: Date?
    public private(set) var endDate: Date?
    public let enableSelectFuture: Bool
    private let minLimitDate: Date
    private let maxLimitDate: Date

    public init(startDate: Date?,
                endDate: Date?,
                enableSelectFuture: Bool = false,
                style: DateFilerItemViewStyle,
                minLimitDate: Date? = nil,
                maxLimitDate: Date? = nil) {
        self.style = style
        self.startDate = startDate
        self.enableSelectFuture = enableSelectFuture
        if !enableSelectFuture, endDate == nil {
            self.endDate = Date()
        } else {
            self.endDate = endDate
        }
        self.minLimitDate = minLimitDate ?? SearchDateYearMonthPickerView.defaultMinDate
        self.maxLimitDate = maxLimitDate ?? (enableSelectFuture ? SearchDateYearMonthPickerView.defaultMaxDate : Date())

        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgFloat

        addLayoutGuide(topLayoutGuide)
        topLayoutGuide.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(60)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(yearMonthControlDidClick))
        controlPlaceView.addGestureRecognizer(tapGesture)
        addSubview(controlPlaceView)
        controlPlaceView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(5)
            make.height.equalTo(40)
            make.centerY.equalTo(topLayoutGuide)
        }

        yearMonthBackButton.setImage(Resources.search_date_picker_back, for: .normal)
        yearMonthBackButton.isUserInteractionEnabled = false
        controlPlaceView.addSubview(yearMonthBackButton)
        yearMonthBackButton.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(7)
            make.centerY.equalToSuperview()
        }

        dateLabelContainer.backgroundColor = UIColor.ud.bgFiller
        dateLabelContainer.layer.cornerRadius = 6
        controlPlaceView.addSubview(dateLabelContainer)
        dateLabelContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(7)
            make.right.equalToSuperview().offset(-7)
            make.centerY.equalToSuperview()
        }

        dateLabel.font = UDFont.systemFont(ofSize: 16)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        dateLabel.setContentHuggingPriority(.required, for: .vertical)
        dateLabel.textColor = UIColor.ud.textTitle
        dateLabelContainer.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }

        monthDayBackButton.setImage(Resources.search_date_picker_back, for: .normal)
        monthDayBackButton.addTarget(self, action: #selector(backButtonDidClick), for: .touchUpInside)
        addSubview(monthDayBackButton)
        monthDayBackButton.snp.makeConstraints { (make) in
            make.left.equalTo(dateLabelContainer.snp.right).offset(12)
            make.centerY.equalTo(topLayoutGuide)
        }

        monthDayForwardButton.setImage(Resources.search_date_picker_forward, for: .normal)
        monthDayForwardButton.addTarget(self, action: #selector(forwardButtonDidClick), for: .touchUpInside)
        addSubview(monthDayForwardButton)
        monthDayForwardButton.snp.makeConstraints { (make) in
            make.left.equalTo(monthDayBackButton.snp.right).offset(16)
            make.centerY.equalTo(topLayoutGuide)
        }

        // CheckBox + Text
        checkBoxAndTextStackView.spacing = 7.5
        checkBoxAndTextStackView.alignment = .leading
        checkBoxAndTextStackView.lu.addTapGestureRecognizer(action: #selector(noLimitButtonDidClick), target: self)
        addSubview(checkBoxAndTextStackView)
        checkBoxAndTextStackView.snp.makeConstraints { (make) in
            make.right.equalTo(topLayoutGuide.snp.right).offset(-19)
            make.centerY.equalTo(topLayoutGuide)
        }

        noLimitCheckbox.tapCallBack = { [weak self] (_) in
            self?.noLimitButtonDidClick()
        }
        checkBoxAndTextStackView.addArrangedSubview(noLimitCheckbox)
        noLimitCheckbox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }

        noLimitLabel.text = BundleI18n.LarkSearchFilter.Lark_Search_AnyTime
        noLimitLabel.font = UIFont.systemFont(ofSize: 16)
        checkBoxAndTextStackView.addArrangedSubview(noLimitLabel)
        noLimitLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
        }

        addSubview(calendarContainer)
        calendarContainer.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.height.equalTo(286)
            make.bottom.equalToSuperview()
        }

        monthDayCalendarView.backgroundColor = UIColor.ud.bgFloat
        monthDayCalendarView.calendarDelegate = self
        monthDayCalendarView.calendarDataSource = self
        monthDayCalendarView.scrollDirection = .horizontal
        monthDayCalendarView.isPagingEnabled = true
        monthDayCalendarView.scrollingMode = .stopAtEachCalendarFrame
        monthDayCalendarView.showsHorizontalScrollIndicator = false
        monthDayCalendarView.showsVerticalScrollIndicator = false
        monthDayCalendarView.minimumLineSpacing = 0
        monthDayCalendarView.minimumInteritemSpacing = 0
        monthDayCalendarView.register(DatePickerCell.self, forCellWithReuseIdentifier: "DatePickerCell")
        monthDayCalendarView.register(DatePickerHeaderView.self,
                              forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                              withReuseIdentifier: "DatePickerHeaderView")
        monthDayCalendarView.calendarDelegate = self
        monthDayCalendarView.calendarDataSource = self
        monthDayCalendarView.scrollToDate(Date(), animateScroll: false)
        calendarContainer.addSubview(monthDayCalendarView)
        monthDayCalendarView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(272)
        }

        calendarContainer.addSubview(yearMonthPickerView)
        yearMonthPickerView.isHidden = true
        yearMonthPickerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
            make.top.equalToSuperview()
            make.height.equalTo(256)
        }

        set(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func layoutSubviews() {
        let oldWidth = monthDayCalendarView.frame.width
        super.layoutSubviews()
        if oldWidth != monthDayCalendarView.frame.width {
            monthDayCalendarView.reloadData()
        }
    }

    private func updateSelectYearMonth(year: Int, month: Int) {
        func maxDayCountOf(year: Int, month: Int) -> Int? {
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = 1

            if let date = calendar.date(from: dateComponents) {
                if let range = calendar.range(of: .day, in: .month, for: date) {
                    return range.count
                }
            }
            return nil
        }
        guard let maxDayCount = maxDayCountOf(year: year, month: month) else { return }
        dateLabel.text = Date(year: year, month: month, day: 1).lf.formatedOnlyDateWithoutDay()
        switch style {
        case .left:
            if let _startDate = startDate {
                let targetDay = _startDate.day > maxDayCount ? maxDayCount : _startDate.day
                var targetDate = Date(year: year, month: month, day: targetDay)
                if targetDate.ls.lessOrEqualTo(date: minLimitDate) {
                    targetDate = minLimitDate
                }
                if targetDate.ls.greatOrEqualTo(date: endDate ?? maxLimitDate) {
                    targetDate = endDate ?? maxLimitDate
                }
                updateSelectedDate(targetDate: targetDate, targetStyle: .left)
            }
        case .right:
            if let _endDate = endDate {
                let targetDay = _endDate.day > maxDayCount ? maxDayCount : _endDate.day
                var targetDate = Date(year: year, month: month, day: targetDay)
                if targetDate.ls.greatOrEqualTo(date: maxLimitDate) {
                    targetDate = maxLimitDate
                }
                if targetDate.ls.lessOrEqualTo(date: startDate ?? minLimitDate) {
                    targetDate = startDate ?? minLimitDate
                }
                updateSelectedDate(targetDate: targetDate, targetStyle: .right)
            }
        }
        if isMonthDayViewShow {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                let date = Date(year: self.yearMonthPickerView.selectedYear, month: self.yearMonthPickerView.selectedMonth, day: 1)
                self.monthDayCalendarView.scrollToDate(date, animateScroll: true)
            }
        }
    }

    private func updateSelectedDate(targetDate: Date, targetStyle: DateFilerItemViewStyle) {
        switch targetStyle {
        case .left:
            if targetDate.ls.lessOrEqualTo(date: endDate ?? maxLimitDate) {
                noLimitCheckbox.isSelected = false
                startDate = targetDate
                delegate?.pickerView(self, didSelectStart: startDate)
            }
        case .right:
            if targetDate.ls.greatOrEqualTo(date: startDate ?? minLimitDate) {
                if enableSelectFuture {
                    noLimitCheckbox.isSelected = false
                    endDate = targetDate
                    delegate?.pickerView(self, didSelectEnd: endDate)
                } else {
                    if targetDate.ls.lessOrEqualTo(date: maxLimitDate) {
                        noLimitCheckbox.isSelected = false
                        endDate = targetDate
                        delegate?.pickerView(self, didSelectEnd: endDate)
                    }
                }
            }
        }
    }

    @objc
    private func backButtonDidClick() {
        monthDayCalendarView.scrollToSegment(.previous)
    }

    @objc
    private func forwardButtonDidClick() {
        monthDayCalendarView.scrollToSegment(.next)
    }

    @objc
    private func yearMonthControlDidClick() {
        let _isMonthDayViewShow = self.isMonthDayViewShow
        updateCalendarViewState(showMonthDayView: !_isMonthDayViewShow, animated: true)
        if _isMonthDayViewShow {
            if let date = monthDayCalendarView.visibleDates().monthDates.first?.date {
                switch style {
                case .left:
                    yearMonthPickerView.updateDefaultSelected(minLimitDate: minLimitDate, maxLimitDate: endDate, year: date.year, month: date.month)
                case .right:
                    yearMonthPickerView.updateDefaultSelected(minLimitDate: startDate, maxLimitDate: maxLimitDate, year: date.year, month: date.month)
                }
            }
        } else {
            yearMonthPickerView.stopScrollImmediately()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                let date = Date(year: self.yearMonthPickerView.selectedYear, month: self.yearMonthPickerView.selectedMonth, day: 1)
                self.monthDayCalendarView.scrollToDate(date, animateScroll: true)
            }
        }
    }

    @objc
    private func noLimitButtonDidClick() {
        if noLimitCheckbox.isSelected {
            noLimitCheckbox.isSelected = false
        } else {
            noLimitCheckbox.isSelected = true
            switch style {
            case .left:
                delegate?.pickerView(self, didSelectStart: nil)
                startDate = nil
            case .right:
                delegate?.pickerView(self, didSelectEnd: nil)
                endDate = nil
            }
        }
        monthDayCalendarView.reloadData()
    }

    private func updateCalendarViewState(showMonthDayView: Bool, animated: Bool) {
        updateCheckBoxState()
        if showMonthDayView {
            yearMonthPickerView.isHidden = true
            monthDayBackButton.isHidden = false
            monthDayForwardButton.isHidden = false
            checkBoxAndTextStackView.isHidden = !(style == .left || enableSelectFuture)
            monthDayCalendarView.isHidden = false
            yearMonthPickerView.isHidden = true
            dateLabel.textColor = UIColor.ud.textTitle
            dateLabelContainer.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(7)
                make.right.equalToSuperview().offset(-7)
                make.centerY.equalToSuperview()
            }
            dateLabelContainer.layoutIfNeeded()
            if animated, showMonthDayView != self.isMonthDayViewShow {
                let offset: CGFloat = monthDayBackButton.btd_width
                dateLabelContainer.transform = CGAffineTransformMakeTranslation(offset + 8, 0)
                UIView.animate(withDuration: 0.15) {
                    self.dateLabelContainer.transform = .identity
                } completion: { _ in
                    self.dateLabelContainer.transform = .identity
                    self.yearMonthBackButton.isHidden = true
                }

            } else {
                yearMonthBackButton.isHidden = true
            }
        } else {
            yearMonthBackButton.isHidden = false
            monthDayBackButton.isHidden = true
            monthDayForwardButton.isHidden = true
            checkBoxAndTextStackView.isHidden = true
            yearMonthPickerView.isHidden = false
            monthDayCalendarView.isHidden = true
            dateLabel.textColor = UIColor.ud.primaryPri500
            dateLabelContainer.snp.remakeConstraints { make in
                make.left.equalTo(yearMonthBackButton.snp.right).offset(8)
                make.right.equalToSuperview().offset(-7)
                make.centerY.equalToSuperview()
            }
            dateLabelContainer.layoutIfNeeded()
            if animated, showMonthDayView != self.isMonthDayViewShow {
                let offset: CGFloat = monthDayBackButton.btd_width
                dateLabelContainer.transform = CGAffineTransformMakeTranslation(-(offset + 8), 0)
                UIView.animate(withDuration: 0.15) {
                    self.dateLabelContainer.transform = .identity
                } completion: { _ in
                    self.dateLabelContainer.transform = .identity
                }
            }
        }
        isMonthDayViewShow = showMonthDayView
    }

    private func updateCheckBoxState() {
        switch style {
        case .left:
            noLimitCheckbox.isSelected = startDate == nil
        case .right:
            noLimitCheckbox.isSelected = endDate == nil
        }
    }

    public func configureCell(view: JTAppleCell?, cellState: CellState) {
        guard let cell = view as? DatePickerCell else { return }

        let date = cellState.date
        let startDate = self.startDate ?? Date.distantPast
        let endDate = self.endDate ?? Date.distantFuture

        let canBeSelected: Bool
        let isSelected: Bool
        switch style {
        case .left:
            canBeSelected = date.ls.lessOrEqualTo(date: endDate) && date.ls.lessOrEqualTo(date: maxLimitDate)
            isSelected = (date.ls.compare(date: startDate) == .orderedSame)
        case .right:
            canBeSelected = date.ls.greatOrEqualTo(date: startDate) && date.ls.lessOrEqualTo(date: maxLimitDate)
            isSelected = (date.ls.compare(date: endDate) == .orderedSame)
        }
        let isToday = (date.ls.compare(date: Date()) == .orderedSame)
        var state: DatePickerCellState
        if cellState.dateBelongsTo == .thisMonth {
            if canBeSelected {
                var enableState: DatePickerCellEnableState
                enableState = .currentMonth
                if isSelected {
                    if isToday {
                        enableState = .todaySelected
                    } else {
                        enableState = .selected
                    }
                }
                state = .enable(state: enableState)
            } else {
                state = .disable
            }
        } else {
            if canBeSelected {
                state = .enable(state: .notCurrentMonth)
            } else {
                state = .disable
            }
        }

        cell.set(text: cellState.text, state: state, isToday: isToday)
    }

    public func set(style: DateFilerItemViewStyle) {
        self.style = style
        switch style {
        case .left:
            monthDayCalendarView.scrollToDate(startDate ?? Date()) { [weak self] in
                self?.monthDayCalendarView.reloadData()
            }
        case .right:
            monthDayCalendarView.scrollToDate(endDate ?? Date()) { [weak self] in
                self?.monthDayCalendarView.reloadData()
            }
        }
        updateCalendarViewState(showMonthDayView: true, animated: true)
    }
}

extension DatePickerView: JTAppleCalendarViewDelegate {
    public func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        guard let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "DatePickerCell",
                                                             for: indexPath) as? DatePickerCell else {
            return JTAppleCell(frame: .zero)
        }
        self.calendar(calendar, willDisplay: cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        return cell
    }

    public func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
    }

    public func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let cell = cell as? DatePickerCell, let state = cell.state, case .enable = state else {
            return
        }
        updateSelectedDate(targetDate: date, targetStyle: style)
        if cellState.dateBelongsTo != .thisMonth {
            calendar.scrollToDate(date)
        } else {
            calendar.reloadData()
        }
    }

    public func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        if let date = visibleDates.monthDates.first?.date {
            dateLabel.text = date.lf.formatedOnlyDateWithoutDay()
        }
    }

    public func calendar(_ calendar: JTAppleCalendarView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTAppleCollectionReusableView {
        guard let header = calendar.dequeueReusableJTAppleSupplementaryView(
            withReuseIdentifier: "DatePickerHeaderView",
            for: indexPath) as? DatePickerHeaderView else {
                return JTAppleCollectionReusableView()
        }
        header.setRange(start: range.start, end: range.end)
        return header
    }

    public func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize? {
        return MonthSize(defaultSize: 25)
    }
}

extension DatePickerView: JTAppleCalendarViewDataSource {
    public func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        return ConfigurationParameters(startDate: self.minLimitDate,
                                       endDate: self.maxLimitDate,
                                       generateInDates: .forAllMonths,
                                       generateOutDates: .tillEndOfGrid)
    }
}
