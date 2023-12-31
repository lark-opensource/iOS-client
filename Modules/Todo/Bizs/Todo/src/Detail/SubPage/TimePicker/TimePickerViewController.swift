//
//  TimePickerViewController.swift
//  Todo
//
//  Created by 白言韬 on 2021/7/8.
//

import Foundation
import LarkUIKit
import LarkContainer
import UniverseDesignDatePicker
import RxSwift
import UniverseDesignDialog
import UniverseDesignIcon
import UniverseDesignColor
import CTFoundation
import EENavigator
import EventKit
import LarkEnv
import UIKit
import UniverseDesignFont

final class TimePickerViewController: BaseViewController, UserResolverWrapper,
    UIPickerViewDataSource,
    UIPickerViewDelegate {
    var userResolver: LarkContainer.UserResolver
    var saveHandler: ((DueRemindTuple) -> Void)?

    @ScopedInjectedLazy private var formatRule: FormatRuleApi?

    private let viewModel: TimePickerViewModel
    private let disposeBag = DisposeBag()

    // container views
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private var startTimeFG: Bool {
        return FeatureGating(resolver: userResolver).boolValue(for: .startTime)
    }

    // specific views
    private lazy var rangeView = TimePickerRangeView()
    private lazy var startHeaderView = TimePickerCalHeaderView(
        date: viewModel.rxStartTime.value ?? Date(),
        calendar: viewModel.timeService?.calendar ?? .current
    )
    private lazy var dueHeaderView = TimePickerCalHeaderView(date: viewModel.rxDueTime.value ?? Date(), calendar: viewModel.timeService?.calendar ?? .current)
    private lazy var dueCalendarView = getCalendarView()
    private lazy var dueCalContainerView = getCalendarContainerView()
    private lazy var startCalendarView = getCalendarView(isStart: true)
    private lazy var startCalContainerView = getCalendarContainerView(isStart: true)
    private lazy var startTimeCell = TimePickerItemView(leftIconKey: .timeOutlined, title: I18N.Todo_TaskStartTime_SetTime_Button)
    private lazy var newDueTimeCell = TimePickerItemView(leftIconKey: .timeOutlined, title: I18N.Todo_TaskStartTime_SetTime_Button)
    private lazy var newReminderCell = TimePickerItemView(leftIconKey: .bellOutlined, title: I18N.Todo_Task_AlertTimeNoAlert)
    private lazy var newRepeatCell = TimePickerItemView(leftIconKey: .repeatOutlined, title: I18N.Calendar_Detail_NoRepeat)
    private lazy var isAllDayCell = getIsAllDayCell()
    private lazy var dueTimeCell = TimePickerSubTitleCell(title: I18N.Todo_Task_DueAt)
    private lazy var dueTimePicker = getDueTimePicker()
    private lazy var reminderCell = TimePickerSubTitleCell(title: I18N.Todo_Task_SetAlertTime)
    private lazy var reminderPicker = getReminderPicker()
    private lazy var repeatCell: TimePickerSubTitleCell = {
        let view = TimePickerSubTitleCell(title: I18N.Todo_Recurring_RecurringTask, hasIndicator: viewModel.isRruleReadable)
        if viewModel.isRruleReadOnly {
            view.indicatorColor = UIColor.ud.iconDisabled
        }
        return view
    }()

    init(resolver: UserResolver, viewModel: TimePickerViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNaviItem()
        bindViewData()
        bindViewAction()
        Detail.Track.viewDateSelect(with: viewModel.guid)
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgFloatBase

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.centerX.equalToSuperview()
        }

        if startTimeFG {
            addTopLine(to: rangeView)
            addBottomLine(to: rangeView)
            stackView.addArrangedSubview(rangeView)
        }
        if startTimeFG {
            stackView.addArrangedSubview(startHeaderView)
            stackView.addArrangedSubview(dueHeaderView)
        } else {
            stackView.addArrangedSubview(dueHeaderView)
        }
        if startTimeFG {
            stackView.addArrangedSubview(startCalContainerView)
        }
        stackView.addArrangedSubview(dueCalContainerView)

        if startTimeFG {
            addBottomLine(to: startCalContainerView)
            addBottomLine(to: dueCalContainerView)
            stackView.addArrangedSubview(startTimeCell)
            stackView.addArrangedSubview(newDueTimeCell)
            addTopLine(to: dueTimePicker)
            stackView.addArrangedSubview(dueTimePicker)
            stackView.addArrangedSubview(TimePickerEmptyView())
        } else {
            addTopLine(to: isAllDayCell)
            stackView.addArrangedSubview(isAllDayCell)
            stackView.addArrangedSubview(dueTimeCell)
            stackView.addArrangedSubview(dueTimePicker)
        }
        if startTimeFG {
            stackView.addArrangedSubview(newReminderCell)
            stackView.addArrangedSubview(reminderPicker)
            stackView.addArrangedSubview(TimePickerEmptyView())
        } else {
            stackView.addArrangedSubview(reminderCell)
            stackView.addArrangedSubview(reminderPicker)
        }
        if startTimeFG {
            stackView.addArrangedSubview(newRepeatCell)
        } else {
            if viewModel.isRruleVisible {
                stackView.addArrangedSubview(repeatCell)
            }
            addBottomLine(to: dueTimePicker)
            addBottomLine(to: reminderPicker)
        }
    }

    private func addTopLine(to view: UIView) {
        let topLineView = UIView()
        topLineView.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(topLineView)
        topLineView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    private func addBottomLine(to view: UIView) {
        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    private func setupNaviItem() {
        let saveItem = LKBarButtonItem(image: nil, title: I18N.Todo_common_Save, fontStyle: .medium)
        saveItem.button.tintColor = UIColor.ud.primaryContentDefault
        saveItem.button.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        self.navigationItem.setRightBarButton(saveItem, animated: false)
    }

    @objc
    private func savePressed() {
        let tuple = viewModel.getDueRemindTuple()
        Detail.Track.clickSaveDate(with: viewModel.guid, tuple: tuple)
        saveHandler?(tuple)
        closeBtnTapped()
    }

    // MARK: UIPickerViewDataSource & UIPickerViewDelegate

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 40 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { viewModel.reminderPickerItemCount()
    }

    func pickerView(
        _ pickerView: UIPickerView, viewForRow row: Int,
        forComponent component: Int, reusing view: UIView?
    ) -> UIView {
        if let label = view as? UILabel {
            label.text = viewModel.reminderPickerItemTitle(at: row)
            return label
        } else {
            let label = UILabel()
            label.font = UDFont.systemFont(ofSize: 17)
            label.textAlignment = .center
            label.text = viewModel.reminderPickerItemTitle(at: row)
            return label
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.didSeletedReminder(at: row)
    }
}

// MARK: - View Data

extension TimePickerViewController {
    private func bindViewData() {
        viewModel.rxRange
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] range in
                self?.rangeView.viewData = range
                self?.updateStackViews(by: range.selected)
            })
            .disposed(by: disposeBag)

        viewModel.rxDueTime
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] dueTime in
                self?.viewModel.updateTimeRangeData()
                self?.viewModel.updateReminderData()
                self?.onDueTimeChanged(dueTime)
            })
            .disposed(by: disposeBag)

        viewModel.rxStartTime
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] startTime in
                self?.viewModel.updateTimeRangeData()
                self?.onStartTimeChanged(startTime)
            })
            .disposed(by: disposeBag)

        viewModel.rxReminder
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] reminder in
                self?.onReminderChanged(reminder)
            })
            .disposed(by: disposeBag)

        // 跳过默认值
        viewModel.rxIsAllDay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] isAllDay in
                guard let self = self, self.viewModel.lastIsAllDay != isAllDay else { return }
                self.viewModel.lastIsAllDay = isAllDay
                self.viewModel.updateReminderData(cause: true)
                self.onIsAllDayChanged(isAllDay)
            })
            .disposed(by: disposeBag)

        viewModel.rxPickerState
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] pickerState in
                self?.onPickerStateChanged(pickerState)
            })
            .disposed(by: disposeBag)
        viewModel.rxRRule.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] rrule in
                self?.onRruleChanged(rrule)
            })
            .disposed(by: disposeBag)
    }

    private func updateStackViews(by type: TimePickRangeData.RangeType) {
        switch type {
        case .start:
            startHeaderView.isHidden = false
            dueHeaderView.isHidden = true
            startCalContainerView.isHidden = false
            dueCalContainerView.isHidden = true
            newDueTimeCell.isHidden = true
            newRepeatCell.isHidden = true
            newReminderCell.isHidden = true
            startTimeCell.isHidden = false
        case .due:
            startHeaderView.isHidden = true
            dueHeaderView.isHidden = false
            startCalContainerView.isHidden = true
            dueCalContainerView.isHidden = false
            newDueTimeCell.isHidden = false
            newRepeatCell.isHidden = false
            newReminderCell.isHidden = false
            startTimeCell.isHidden = true
        }
    }

    private func onStartTimeChanged(_ startTime: Date?) {
        let timeStr = viewModel.timeTile(startTime)
        startTimeCell.title = timeStr ?? I18N.Todo_TaskStartTime_SetTime_Button
        if viewModel.canDisplayCloseIcon(.startTime) {
            startTimeCell.rightIconStatus = .close
        }
    }

    private func onDueTimeChanged(_ dueTime: Date?) {
        if startTimeFG {
            newDueTimeCell.title = viewModel.timeTile(dueTime) ?? I18N.Todo_TaskStartTime_SetTime_Button
            if viewModel.canDisplayCloseIcon(.dueTime) {
                newDueTimeCell.rightIconStatus = .close
            }
            newReminderCell.disabled = dueTime == nil
            newRepeatCell.disabled = dueTime == nil
        } else {
            if let text = viewModel.timeTile(dueTime) {
                dueTimeCell.subTitle = text
            }
        }
    }

    private func onReminderChanged(_ reminder: ReminderType) {
        if startTimeFG {
            if let value = reminder as? NonAllDayReminder, case .noAlert = value {
                newReminderCell.title = I18N.Todo_Task_AlertTimeNoAlert
            } else {
                newReminderCell.title = viewModel.reminderTitle(reminder)
            }
            if viewModel.canDisplayCloseIcon(.reminder) {
                newReminderCell.rightIconStatus = .close
            }
        } else {
            reminderCell.subTitle = viewModel.reminderTitle(reminder)
        }
    }

    private func onIsAllDayChanged(_ isAllDay: Bool) {
        dueTimeCell.isHidden = isAllDay
    }

    private func onPickerStateChanged(_ pickerState: PickerState) {
        let blue = UIColor.ud.primaryContentDefault
        let black = UIColor.ud.textPlaceholder
        switch pickerState {
        case .startTime:
            dueTimePicker.select(date: viewModel.startTimePickerValue)
            dueTimePicker.isHidden = false
            reminderPicker.isHidden = true
            startTimeCell.rightIconStatus = .indicator(transform: true)
        case .dueTime:
            dueTimePicker.select(date: viewModel.dueTimePickerValue)
            dueTimePicker.isHidden = false
            reminderPicker.isHidden = true
            if startTimeFG {
                newReminderCell.rightIconStatus = viewModel.canDisplayCloseIcon(.reminder) ? .close : .indicator(transform: false)
                newDueTimeCell.rightIconStatus = .indicator(transform: true)
            } else {
                dueTimeCell.subTitleColor = blue
                reminderCell.subTitleColor = black
            }
            scrollToBottom()
        case .reminder:
            reminderPicker.reloadAllComponents()
            reminderPicker.selectRow(viewModel.rowOfCurReminder(), inComponent: 0, animated: false)
            reminderPicker.isHidden = false
            dueTimePicker.isHidden = true

            if startTimeFG {
                newReminderCell.rightIconStatus = .indicator(transform: true)
                newDueTimeCell.rightIconStatus = viewModel.canDisplayCloseIcon(.dueTime) ? .close : .indicator(transform: false)
            } else {
                dueTimeCell.subTitleColor = black
                reminderCell.subTitleColor = blue
            }
            scrollToBottom()
        case .none:
            dueTimePicker.isHidden = true
            reminderPicker.isHidden = true

            if startTimeFG {
                newReminderCell.rightIconStatus = viewModel.canDisplayCloseIcon(.reminder) ? .close : .indicator(transform: false)
                newDueTimeCell.rightIconStatus = viewModel.canDisplayCloseIcon(.dueTime) ? .close : .indicator(transform: false)
                startTimeCell.rightIconStatus = viewModel.canDisplayCloseIcon(.startTime) ? .close : .indicator(transform: false)
            } else {
                dueTimeCell.subTitleColor = black
                reminderCell.subTitleColor = black
            }
        }
    }

    private func onRruleChanged(_ rrule: String?) {
        if let rrule = rrule, let formatRule = formatRule {
            if startTimeFG {
                newRepeatCell.title = formatRule.syncGetParsedRruleText(rrule)
                newRepeatCell.rightIconStatus = .close
            } else {
                repeatCell.subTitle = formatRule.syncGetParsedRruleText(rrule)
            }
        } else {
            if startTimeFG {
                newRepeatCell.title = I18N.Calendar_Detail_NoRepeat
                newRepeatCell.rightIconStatus = .indicator(transform: false)
            } else {
                repeatCell.subTitle = I18N.Calendar_Detail_NoRepeat
            }
        }
    }

    private func scrollToBottom() {
        scrollView.layoutIfNeeded()
        let offset = scrollView.contentSize.height - scrollView.bounds.height
        if offset > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
        }
    }
}

// MARK: - View Action

extension TimePickerViewController {
    private func bindViewAction() {
        rangeView.onSwitchRangeHandler = { [weak self] type in
            self?.viewModel.switchRange(with: type)
        }
        rangeView.onCloseHander = { [weak self] type in
            guard let self = self else { return }
            // 清楚标识
            self.viewModel.cleanRange(type: type)
            switch type {
            case .start:
                self.startCalendarView.select(date: nil, withAnimate: true)
            case .due:
                self.dueCalendarView.select(date: nil, withAnimate: true)
            }
        }
        dueHeaderView.previousHandler = { [weak self] in
            self?.updateCalendarPage(isNext: false)
        }
        dueHeaderView.nextHandler = { [weak self] in
            self?.updateCalendarPage(isNext: true)
        }
        startHeaderView.previousHandler = { [weak self] in
            self?.updateCalendarPage(isNext: false)
        }
        startHeaderView.nextHandler = { [weak self] in
            self?.updateCalendarPage(isNext: true)
        }
        isAllDayCell.didSwitch = { [weak self] isOn in
            TimePicker.logger.info("switch isAllDay to \(!isOn)")
            self?.viewModel.rxIsAllDay.accept(!isOn)
        }
        dueTimeCell.clickHandler = { [weak self] in
            self?.viewModel.onDueTimePickerToggle()
        }
        reminderCell.clickHandler = { [weak self] in
            self?.viewModel.onReminderPickerToggle()
        }
        dueTimePicker.dateChanged = { [weak self] (date) in
            guard let self = self else { return }
            let isStart = self.viewModel.isRangeSelectStart
            let current = (isStart ? self.viewModel.rxStartTime.value : self.viewModel.rxDueTime.value) == nil
            let needUpdate = self.viewModel.onTimePickerUpdated(isStart: isStart, date: date)
            if needUpdate {
                // 需要更新互斥的日历
                if isStart {
                    self.dueCalendarView.select(date: self.viewModel.rxDueTime.value, withAnimate: true)
                } else {
                    self.startCalendarView.select(date: self.viewModel.rxStartTime.value, withAnimate: true)
                }
            }
            if current {
                // 当空变成有值的时候需要变成选中当前
                if isStart {
                    self.startCalendarView.select(date: date, withAnimate: true)
                } else {
                    self.dueCalendarView.select(date: date, withAnimate: true)
                }
            }
        }
        repeatCell.clickHandler = { [weak self] in
            guard let self = self, !self.viewModel.isRruleReadOnly else {
                return
            }
            self.showRepeatVC()
        }
        if startTimeFG {
            newDueTimeCell.clickHandler = { [weak self] in
                self?.viewModel.onDueTimePickerToggle()
            }
            startTimeCell.clickHandler = { [weak self] in
                self?.viewModel.onStartTimePickerToggle()
            }
            newReminderCell.clickHandler = { [weak self] in
                self?.viewModel.onReminderPickerToggle()
            }
            newRepeatCell.clickHandler = { [weak self] in
                guard let self = self, !self.viewModel.isRruleReadOnly else {
                    return
                }
                self.showRepeatVC()
            }
            newDueTimeCell.closeHandler = { [weak self] in
                self?.viewModel.cleanTime(isStart: false)
            }
            startTimeCell.closeHandler = { [weak self] in
                self?.viewModel.cleanTime(isStart: true)
            }
            newReminderCell.closeHandler = { [weak self] in
                self?.viewModel.cleanReminder()
            }
            newRepeatCell.closeHandler = { [weak self] in
                self?.viewModel.updateRRule(nil)
            }
        }
    }

    private func updateCalendarPage(isNext: Bool) {
        if startTimeFG {
            switch viewModel.rxRange.value.selected {
            case .start:
                if isNext {
                    startCalendarView.scrollToNext(withAnimate: true)
                } else {
                    startCalendarView.scrollToPrev(withAnimate: true)
                }
            case .due:
                if isNext {
                    dueCalendarView.scrollToNext(withAnimate: true)
                } else {
                    dueCalendarView.scrollToPrev(withAnimate: true)
                }
            }
        } else {
            if isNext {
                dueCalendarView.scrollToNext(withAnimate: true)
            } else {
                dueCalendarView.scrollToPrev(withAnimate: true)
            }
        }
    }

}

// MARK: - UD Calendar

extension TimePickerViewController {
    private func getCalendarContainerView(isStart: Bool = false) -> CalendarContainerView {
        let container = CalendarContainerView()
        container.addSubview(isStart ? startCalendarView : dueCalendarView)
        if isStart {
            startCalendarView.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            dueCalendarView.snp.makeConstraints { $0.edges.equalToSuperview() }
        }
        return container
    }
    private func getCalendarView(isStart: Bool = false) -> UDDateCalendarPickerView {
        let config = UDCalendarStyleConfig(
            rowNumFixed: true,
            autoSelectedDate: false,
            firstWeekday: .sunday
        )
        let calendarView = UDDateCalendarPickerView(
            date: isStart ? viewModel.rxStartTime.value : viewModel.rxDueTime.value,
            timeZone: viewModel.timeZone,
            calendarConfig: config
        )
        calendarView.delegate = self
        return calendarView
    }
}

private class CalendarContainerView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: 272)
    }
}

// UD Calendar Delegate
extension TimePickerViewController: UDDatePickerViewDelegate {
    func dateChanged(_ date: Date, _ sender: UDDateCalendarPickerView) {
        let changed = viewModel.onCalendarUpdated(isStart: sender == startCalendarView, date: date)
        if changed {
            if sender == startCalendarView {
                dueCalendarView.select(date: viewModel.rxDueTime.value, withAnimate: true)
            } else {
                startCalendarView.select(date: viewModel.rxStartTime.value, withAnimate: true)
            }
        }
    }
    func deselectDate(_ sender: UDDateCalendarPickerView) {
        viewModel.onCalendarUpdated(isStart: sender == startCalendarView, date: nil)
    }
    func calendarScrolledTo(_ date: Date, _ sender: UDDateCalendarPickerView) {
        if sender == startCalendarView {
            startHeaderView.date = date
        } else {
            dueHeaderView.date = date
        }
    }
}

// MARK: - Pickers

extension TimePickerViewController {
    private func getIsAllDayCell() -> TimePickerSwitchBtnCell {
        let cell = TimePickerSwitchBtnCell(title: I18N.Todo_Task_SetDueTime)
        cell.isOn = !viewModel.rxIsAllDay.value
        return cell
    }

    private func getDueTimePicker() -> UDDateWheelPickerView {
        let config = UDWheelsStyleConfig(
            mode: .hourMinuteCenter,
            is12Hour: viewModel.is12HourStyle,
            showSepeLine: false,
            minInterval: 15,
            textColor: UIColor.ud.textTitle,
            textFont: UDFont.systemFont(ofSize: 17)
        )
        let picker = UDDateWheelPickerView(
            timeZone: viewModel.timeZone,
            wheelConfig: config
        )
        return picker
    }

    private func getReminderPicker() -> UIPickerView {
        let picker = PickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }

    private class PickerView: UIPickerView {
        override var intrinsicContentSize: CGSize {
            return CGSize(width: Self.noIntrinsicMetric, height: 156)
        }
    }
}

// MARK: - Repeat

extension TimePickerViewController: EventBuiltinRruleViewControllerDelegate, EventCustomRruleViewControllerDelegate {

    private func showRepeatVC() {
        let vc = EventBuiltinRruleViewController(rrule: EKRecurrenceRule.parseToRRule(with: viewModel.rxRRule.value ?? ""))
        vc.delegate = self
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    // EventBuiltinRruleViewController delegate
    func didCancelEdit(from viewController: EventBuiltinRruleViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didFinishEdit(from viewController: EventBuiltinRruleViewController) {
        viewModel.updateRRule(viewController.selectedRrule?.parseToString())
        viewController.dismiss(animated: true, completion: nil)
    }

    func selectCustomRrule(from viewController: EventBuiltinRruleViewController) {
        let customVC = EventCustomRruleViewController(
            startDate: Date(timeIntervalSince1970: TimeInterval(viewModel.getCurrentTime(isStart: false))),
            rrule: EKRecurrenceRule.parseToRRule(with: viewModel.rxRRule.value ?? ""),
            firstWeekday: EnvManager.env.isChinaMainlandGeo ? .monday : .sunday
        )
        customVC.delegate = self
        viewController.navigationController?.pushViewController(customVC, animated: true)

    }

    func parseRruleToTitle(rrule: EKRecurrenceRule) -> String? {
        return formatRule?.syncGetParsedRruleText(rrule.parseToString())
    }

    // EventCustomRruleViewController delegate
    func didCancelEdit(from viewController: EventCustomRruleViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }

    func didFinishEdit(from viewController: EventCustomRruleViewController) {
        viewModel.updateRRule(viewController.selectedRrule?.parseToString(firstWeekday: viewController.firstWeekday))
        viewController.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func parseRruleToHeaderTitle(rrule: EKRecurrenceRule) -> String? {
        return formatRule?.syncGetParsedRruleText(rrule.parseToString())
    }

}
