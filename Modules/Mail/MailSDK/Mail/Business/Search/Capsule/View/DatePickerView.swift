//
//  DatePickerView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/12/1.
//

import UIKit
import Foundation
import DateToolsSwift
import JTAppleCalendar
import LarkUIKit
import UniverseDesignCheckBox
import UniverseDesignFont
import UniverseDesignIcon

public protocol DatePickerViewDelegate: AnyObject {
    // date = nil代表不限制
    func pickerView(_ pickerView: DatePickerView, didSelectStart date: Date?)
    func pickerView(_ pickerView: DatePickerView, didSelectEnd date: Date)
}

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
            self.dateLabel.text = Date(year: year, month: month, day: 1).lf.formatedOnlyDateWithoutDay()
        }
        return yearMonthPickerView
    }()

    private var style: DateFilerItemViewSyle
    private var isMonthDayViewShow: Bool = true
    public private(set) var startDate: Date?
    public private(set) var endDate: Date = Date()
    private let minLimitDate: Date
    private let maxLimitDate: Date
    private let canSelectedFuture: Bool

    public init(startDate: Date?,
                endDate: Date,
                style: DateFilerItemViewSyle,
                minLimitDate: Date? = nil,
                maxLimitDate: Date? = nil,
                canSelectedFuture: Bool = false) {
        self.style = style
        self.startDate = startDate
        self.endDate = endDate
        self.minLimitDate = minLimitDate ?? Date(year: 1900, month: 1, day: 1)
        self.maxLimitDate = maxLimitDate ?? (canSelectedFuture ? Date(year: 2099, month: 12, day: 31) : Date())
        self.canSelectedFuture = canSelectedFuture

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

        yearMonthBackButton.setImage(UDIcon.getIconByKey(.leftOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
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

        monthDayBackButton.setImage(UDIcon.getIconByKey(.leftOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        monthDayBackButton.addTarget(self, action: #selector(backButtonDidClick), for: .touchUpInside)
        addSubview(monthDayBackButton)
        monthDayBackButton.snp.makeConstraints { (make) in
            make.left.equalTo(dateLabelContainer.snp.right).offset(12)
            make.centerY.equalTo(topLayoutGuide)
        }

        monthDayForwardButton.setImage(UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
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
        noLimitCheckbox.isSelected = (startDate == nil)
        checkBoxAndTextStackView.addArrangedSubview(noLimitCheckbox)
        noLimitCheckbox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }

        noLimitLabel.text = BundleI18n.MailSDK.Mail_shared_FilterSearch_AnyTime_Mobile_Text
        noLimitLabel.font = UIFont.systemFont(ofSize: 16)
        checkBoxAndTextStackView.addArrangedSubview(noLimitLabel)
        noLimitLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
        }

        addSubview(calendarContainer)
        calendarContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
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
            make.left.right.top.equalToSuperview()
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
                yearMonthPickerView.updateDefaultSelected(year: date.year, month: date.month)
            }
        } else {
            let date = Date(year: yearMonthPickerView.selectedYear, month: yearMonthPickerView.selectedMonth, day: 1)
            monthDayCalendarView.scrollToDate(date, animateScroll: true)
        }
    }

    @objc
    private func noLimitButtonDidClick() {
        if noLimitCheckbox.isSelected {
            noLimitCheckbox.isSelected = false
        } else {
            noLimitCheckbox.isSelected = true
            delegate?.pickerView(self, didSelectStart: nil)
            startDate = nil
        }
        monthDayCalendarView.reloadData()
    }

    private func updateCalendarViewState(showMonthDayView: Bool, animated: Bool) {
        if showMonthDayView {
            yearMonthPickerView.isHidden = true
            monthDayBackButton.isHidden = false
            monthDayForwardButton.isHidden = false
            checkBoxAndTextStackView.isHidden = style != .left
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

    public func configureCell(view: JTAppleCell?, cellState: CellState) {
        guard let cell = view as? DatePickerCell else { return }

        let date = cellState.date
        let startDate = self.startDate ?? Date.distantPast

        let canBeSelected: Bool
        let isSelected: Bool
        switch style {
        case .left:
            canBeSelected = date.mail.lessOrEqualTo(date: endDate) && date.mail.lessOrEqualTo(date: Date())
            isSelected = (date.mail.compare(date: startDate) == .orderedSame)
        case .right:
            canBeSelected = date.mail.greatOrEqualTo(date: startDate) && date.mail.lessOrEqualTo(date: Date())
            isSelected = (date.mail.compare(date: endDate) == .orderedSame)
        }
        let isToday = (date.mail.compare(date: Date()) == .orderedSame)
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

    public func set(style: DateFilerItemViewSyle) {
        self.style = style
        switch style {
        case .left:
            if let startDate = self.startDate {
                monthDayCalendarView.scrollToDate(startDate) { [weak self] in
                    self?.monthDayCalendarView.reloadData()
                }
            }
        case .right:
            monthDayCalendarView.scrollToDate(endDate) { [weak self] in
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
        if style == .left {
            if date.mail.lessOrEqualTo(date: endDate) {
                noLimitCheckbox.isSelected = false
                startDate = date
                delegate?.pickerView(self, didSelectStart: startDate)
            }
        } else if style == .right {
            if date.mail.greatOrEqualTo(date: startDate ?? Date.distantPast),
                date.mail.lessOrEqualTo(date: Date()) {
                endDate = date
                delegate?.pickerView(self, didSelectEnd: endDate)
            }
        }
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
