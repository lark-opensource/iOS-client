//
//  EventCustomRruleViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/30.
//

import UIKit
import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkUIKit
import LarkTimeFormatUtils
import EventKit
import CalendarFoundation

/// 日程 - 自定义重复性规则编辑页

public protocol EventCustomRruleViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventCustomRruleViewController)
    func didFinishEdit(from viewController: EventCustomRruleViewController)
    func parseRruleToHeaderTitle(rrule: EKRecurrenceRule) -> String?
    func parseRruleToHeaderTitle(rrule: EKRecurrenceRule, timezone: String) -> String?
}

public extension EventCustomRruleViewControllerDelegate {
    func parseRruleToHeaderTitle(rrule: EKRecurrenceRule, timezone: String) -> String? {
        nil
    }
}

public final class EventCustomRruleViewController: BaseUIViewController, UIGestureRecognizerDelegate {
    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBody)
    }

    public struct Config {
        public typealias Callback = (_ selectItem: String, _ from: UIViewController) -> Void

        // 「每月」选项下的月视图
        public var isMonthDayMultiSelectEnable = true
        public var monthDayMultiSelectDisableCallback: Callback?

        public var isMonthDayUnselectStartDateEnable = true
        public var monthDayUnselectStartDateDisableCallback: Callback?

        // 「每月」选项下的周视图
        public var isMonthWeekScrollEnable = true
        public var monthWeekScrollDisableCallback: Callback?

        // 「每周」选项下的视图
        public var isWeekDayUnselectStartDateEnable = true
        public var weekDayUnselectStartDateDisableCallback: Callback?

        // 开启时，在月、周选择面板下如果一个选项都没有选，会 disable 掉完成按钮
        public var isEmptySelectionDisableDoneBtn = false
        public var eventTimeZoneId: String?

        public init() { }
    }

    public weak var delegate: EventCustomRruleViewControllerDelegate?
    public private(set) var selectedRrule: EKRecurrenceRule? {
        didSet {
            var title: String?
            if let rrule = selectedRrule {
                title = delegate?.parseRruleToHeaderTitle(rrule: rrule, timezone: self.config.eventTimeZoneId ?? "")
                if config.isEmptySelectionDisableDoneBtn {
                    navigationItem.rightBarButtonItem?.isEnabled = isRruleUsability(rrule: rrule)
                }
            }
            assert(title != nil)
            headerView.title = title
        }
    }

    private let disposeBag = DisposeBag()
    private let startDate: Date
    private let originalRrule: EKRecurrenceRule?
    public private(set) var firstWeekday: RRule.FirstWeekday
    private let config: Config
    // 每月重复时间切换，true 表示「月-日」，false 表示「月-星期」
    private var isMonthDayOn = true {
        didSet {
            if isMonthDayOn {
                monthSwitchViews.dayButton.isSelected = true
                monthSwitchViews.weekdayButton.isSelected = false
            } else {
                monthSwitchViews.dayButton.isSelected = false
                monthSwitchViews.weekdayButton.isSelected = true
            }
        }
    }

    private lazy var headerView = initHeaderView()

    // main picker
    private lazy var intervalPicker = initIntervalPicker()

    // secondary pickers
    private lazy var weekdayPicker = initWeekdayPicker()
    private lazy var monthDayPicker = initMonthDayPicker()
    private lazy var monthWeekdayPicker = initMonthWeekdayPicker()

    // 切换 「月-天」「月-星期」
    private lazy var monthSwitchViews = initMonthSwitchViews()

    private lazy var whiteSafeBottomView = UIView()

    public init(
        startDate: Date,
        rrule: EKRecurrenceRule? = nil,
        firstWeekday: RRule.FirstWeekday = .monday,
        config: Config = Config()
    ) {
        self.startDate = startDate
        self.originalRrule = rrule
        self.firstWeekday = firstWeekday
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNaviItem()
        bindViewAction()

        isMonthDayOn = true

        updateSecondaryPickerHidden()
        updateRruleForIntervalPickerValueChanged()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
        }

        view.addSubview(intervalPicker)
        intervalPicker.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(headerView.snp.bottom)
            $0.height.equalTo(156)
        }

        // 周重复 - picker
        view.addSubview(weekdayPicker)
        weekdayPicker.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(228)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        whiteSafeBottomView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(whiteSafeBottomView)
        whiteSafeBottomView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(weekdayPicker.snp.bottom)
        }

        // 月重复 - 日期/星期切换 view
        view.addSubview(monthSwitchViews.wrapperView)
        monthSwitchViews.wrapperView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(49)
            $0.bottom.equalTo(weekdayPicker)
        }

        // 月重复 - 日期 picker
        view.addSubview(monthDayPicker)
        monthDayPicker.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(251)
            $0.bottom.equalTo(monthSwitchViews.wrapperView.snp.top)
        }

        // 月重复 - 星期 picker
        view.addSubview(monthWeekdayPicker)
        monthWeekdayPicker.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(156)
            $0.bottom.equalTo(monthSwitchViews.wrapperView.snp.top)
        }
    }

    private func bindViewAction() {
        monthSwitchViews.dayButton.rx.controlEvent(.touchUpInside)
            .bind { [unowned self] in
                self.isMonthDayOn = true
                self.updateSecondaryPickerHidden()
                let monthDays = Array(self.monthDayPicker.monthDays)
                self.updateRrule(monthDays: monthDays)
            }
            .disposed(by: disposeBag)
        monthSwitchViews.weekdayButton.rx.controlEvent(.touchUpInside)
            .bind { [unowned self] in
                self.isMonthDayOn = false
                self.updateSecondaryPickerHidden()
                let weekday = self.monthWeekdayPicker.weekday
                self.updateRrule(weekdays: [weekday])
            }
            .disposed(by: disposeBag)

        weekdayPicker.rx.controlEvent(.valueChanged)
            .bind { [unowned self] _ in
                let weekdays = self.weekdayPicker.weekdays.map {
                    EKRecurrenceDayOfWeek($0)
                }
                self.updateRrule(weekdays: weekdays)
            }
            .disposed(by: disposeBag)
        weekdayPicker.onRequiredWeekdayClick = { [weak self] (_, dayStr) in
            guard let self = self else { return }
            self.config.weekDayUnselectStartDateDisableCallback?(dayStr, self)
        }

        monthDayPicker.rx.controlEvent(.valueChanged)
            .bind { [unowned self] _ in
                let monthDays = Array(self.monthDayPicker.monthDays)
                self.updateRrule(monthDays: monthDays)
            }
            .disposed(by: disposeBag)
        monthDayPicker.onRequiredDayClick = { [weak self] day in
            guard let self = self else { return }
            self.config.monthDayUnselectStartDateDisableCallback?(TimeFormatUtils.ordinalDayString(number: day), self)
        }
        monthDayPicker.onUnavailableDayClick = { [weak self] _ in
            guard let self = self else { return }
            guard let day = self.monthDayPicker.monthDays.first else { return }
            self.config.monthDayMultiSelectDisableCallback?(TimeFormatUtils.ordinalDayString(number: day), self)
        }

        monthWeekdayPicker.rx.controlEvent(.valueChanged)
            .bind { [unowned self] _ in
                let weekday = self.monthWeekdayPicker.weekday
                self.updateRrule(weekdays: [weekday])
            }
            .disposed(by: disposeBag)

        if !monthWeekdayPicker.isPickingEnabled {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(hanldePanOnMonthWeekdayPicker(_:)))
            panGesture.delegate = self
            monthWeekdayPicker.addGestureRecognizer(panGesture)
        }
    }

    private func setupNaviItem() {
        let closeItem = LKBarButtonItem(
            image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1).withRenderingMode(.alwaysOriginal)
        )
        closeItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }
            .disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = closeItem

        let doneItem = LKBarButtonItem(title: BundleI18n.RRule.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = RRule.UIStyle.Color.blueText
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didFinishEdit(from: self)
            }
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = doneItem
    }

    private func updateSecondaryPickerHidden() {
        switch intervalPicker.selectedFrequency() {
        case .daily, .yearly:
            weekdayPicker.isHidden = true
            monthSwitchViews.wrapperView.isHidden = true
            monthDayPicker.isHidden = true
            monthWeekdayPicker.isHidden = true
            whiteSafeBottomView.isHidden = true
        case .weekly:
            weekdayPicker.isHidden = false
            monthSwitchViews.wrapperView.isHidden = true
            monthDayPicker.isHidden = true
            monthWeekdayPicker.isHidden = true
            whiteSafeBottomView.isHidden = false
        case .monthly:
            weekdayPicker.isHidden = true
            monthSwitchViews.wrapperView.isHidden = false
            if isMonthDayOn {
                monthDayPicker.isHidden = false
                monthWeekdayPicker.isHidden = true
            } else {
                monthDayPicker.isHidden = true
                monthWeekdayPicker.isHidden = false
            }
            whiteSafeBottomView.isHidden = false
        }
    }

    private func updateRruleForIntervalPickerValueChanged() {
        let frequency = intervalPicker.selectedFrequency().toEventKitFrequency()
        let interval = intervalPicker.selectedInterval()
        if let rrule = selectedRrule, rrule.frequency == frequency {
            // update 频次
            selectedRrule = EKRecurrenceRule(
                recurrenceWith: rrule.frequency,
                interval: interval,
                daysOfTheWeek: rrule.daysOfTheWeek,
                daysOfTheMonth: rrule.daysOfTheMonth,
                monthsOfTheYear: rrule.monthsOfTheYear,
                weeksOfTheYear: rrule.weeksOfTheYear,
                daysOfTheYear: rrule.daysOfTheYear,
                setPositions: rrule.setPositions,
                end: rrule.recurrenceEnd
            )
        } else {
            var daysOfTheWeek: [EKRecurrenceDayOfWeek]?
            var daysOfTheMonth: [NSNumber]?
            switch frequency {
            case .weekly:
                daysOfTheWeek = weekdayPicker.weekdays.map { EKRecurrenceDayOfWeek($0) }
            case .monthly:
                if self.isMonthDayOn {
                    daysOfTheMonth = monthDayPicker.monthDays.map { $0 as NSNumber }
                } else {
                    daysOfTheWeek = [monthWeekdayPicker.weekday]
                }
            default:
                break
            }
            selectedRrule = EKRecurrenceRule(
                recurrenceWith: frequency,
                interval: interval,
                daysOfTheWeek: daysOfTheWeek,
                daysOfTheMonth: daysOfTheMonth,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: nil
            )
        }
    }

    private func updateRrule(
        weekdays: [EKRecurrenceDayOfWeek]? = nil,
        monthDays: [Int]? = nil
    ) {
        assert(selectedRrule != nil)
        selectedRrule = EKRecurrenceRule(
            recurrenceWith: intervalPicker.selectedFrequency().toEventKitFrequency(),
            interval: intervalPicker.selectedInterval(),
            daysOfTheWeek: weekdays,
            daysOfTheMonth: monthDays as [NSNumber]?,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: nil
        )
    }

    private func isRruleUsability(rrule: EKRecurrenceRule) -> Bool {
        let isDaysOfTheWeekEmpty = rrule.daysOfTheWeek?.isEmpty ?? true
        if rrule.frequency == .weekly {
            return !isDaysOfTheWeekEmpty
        } else if rrule.frequency == .monthly {
            return !isDaysOfTheWeekEmpty || !(rrule.daysOfTheMonth?.isEmpty ?? true)
        }
        return true
    }

    @objc
    func hanldePanOnMonthWeekdayPicker(_ panGesture: UIPanGestureRecognizer) {
        // do nothing
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        config.monthWeekScrollDisableCallback?(TimeFormatUtils.weekdayFullString(weekday: startDate.weekday), self)
        return false
    }

}

// MARK: IntervalPickerDelegate

extension EventCustomRruleViewController: IntervalPickerDelegate {

    func intervaPicker(
        _ picker: IntervalPicker,
        didSelectAt interval: Int,
        type: IntervalPicker.Frequency
    ) {
        updateSecondaryPickerHidden()
        updateRruleForIntervalPickerValueChanged()
    }

}

extension EventCustomRruleViewController {

    private func initHeaderView() -> EventBasicHeaderView {
        let headerView = EventBasicHeaderView()
        headerView.backgroundColor = UIColor.ud.bgBody
        return headerView
    }

    private func initIntervalPicker() -> IntervalPicker {
        let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 156)
        let intervalPicker = IntervalPicker(frame: frame)
        intervalPicker.delegate = self
        intervalPicker.addBottomBorder()
        return intervalPicker
    }

    private func initWeekdayPicker() -> EventCustomRruleWeekdayPicker {
        let picker = EventCustomRruleWeekdayPicker()
        picker.firstWeekDay = firstWeekday

        // 当前天是必选的
        guard let weekday = EKWeekday(rawValue: startDate.weekday) else {
            assertionFailure("generate EKWeekday failed: \(startDate.weekday)")
            return picker
        }
        if !config.isWeekDayUnselectStartDateEnable {
            picker.requiredWeekdays = [weekday]
        }

        var selectedWeekdays: Set<EKWeekday> = []
        // 之前天也必须给勾选上
        if let daysOfTheWeek = originalRrule?.daysOfTheWeek {
            daysOfTheWeek.forEach { selectedWeekdays.insert($0.dayOfTheWeek) }
        } else {
            selectedWeekdays = [weekday]
        }
        picker.weekdays = selectedWeekdays

        return picker
    }

    private func initMonthDayPicker() -> EventCustomRruleMonthDayPicker {
        let picker = EventCustomRruleMonthDayPicker()
        if !config.isMonthDayUnselectStartDateEnable {
            picker.requiredDays = [startDate.day]
        }

        var selectedMonthdays: Set<Int> = []
        if let daysOfTheMonth = originalRrule?.daysOfTheMonth {
            daysOfTheMonth.forEach { selectedMonthdays.insert(Int($0)) }
        } else {
            selectedMonthdays = [startDate.day]
        }
        picker.monthDays = selectedMonthdays

        picker.allowsMultiSelection = config.isMonthDayMultiSelectEnable
        return picker
    }

    private func initMonthWeekdayPicker() -> EventCustomRruleMonthWeekdayPicker {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: EventCustomRruleMonthWeekdayPicker.desiredHeight)
        let monthWeekdayPicker = EventCustomRruleMonthWeekdayPicker(
            frame: frame,
            weekOfMonth: startDate.weekOfMonth,
            weekday: startDate.weekday
        )
        // 「月-星期」不可滑动
        monthWeekdayPicker.isPickingEnabled = config.isMonthWeekScrollEnable
        return monthWeekdayPicker
    }

    typealias MonthSwitchViews = (
        wrapperView: UIView,
        dayButton: UIButton,
        weekdayButton: UIButton
    )

    private func initMonthSwitchViews() -> MonthSwitchViews {
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgBody
        wrapperView.addTopBorder()

        let dayButton = UIButton()
        dayButton.setTitle(BundleI18n.RRule.Calendar_Common_Ondate, for: .normal)
        dayButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        dayButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        dayButton.setTitleColor(UIColor.ud.textTitle, for: .normal)

        let weekdayButton = UIButton()
        weekdayButton.setTitle(BundleI18n.RRule.Calendar_RRule_WeeklyMobile, for: .normal)
        weekdayButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        weekdayButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        weekdayButton.setTitleColor(UIColor.ud.textTitle, for: .normal)

        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.ud.lineDividerDefault

        wrapperView.addSubview(dayButton)
        dayButton.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.5)
        }

        wrapperView.addSubview(weekdayButton)
        weekdayButton.snp.makeConstraints {
            $0.right.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.5)
        }

        wrapperView.addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.centerX.top.bottom.equalToSuperview()
            $0.width.equalTo(1)
        }

        return (wrapperView, dayButton, weekdayButton)
    }

}
