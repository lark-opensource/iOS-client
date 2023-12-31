//
//  SettingDefaultReminderModule.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/25.
//

import EENavigator
import LarkUIKit
import LarkContainer
import RxSwift
import UniverseDesignFont

final class SettingDefaultReminderModule: SettingBaseModule {

    override var view: UIView { rootView }

    private lazy var rootView = UIView()
    private lazy var subTitleCell = SettingSubTitleCell()

    @ScopedInjectedLazy private var settingService: SettingService?
    @ScopedInjectedLazy private var timeService: TimeService?
    private let disposeBag = DisposeBag()

    private lazy var selectedRow: Int = {
        guard let settingService = settingService else { return 1 }
        let strategy = NonAllDayReminder(rawValue: settingService.value(forKeyPath: \.dueReminderOffset)) ?? .atTimeOfEvent
        let index = selectOptions.firstIndex(where: { p in p.key == strategy }) ?? 1
        return index
    }()

    private lazy var selectOptions: [(key: NonAllDayReminder, value: String)] = {
        var typeList: [NonAllDayReminder] = [
            .noAlert, .atTimeOfEvent, .fiveMinutesBefore, .aQuarterBefore, .halfAnHourBefore,
            .anHourBefore, .twoHoursBefore, .aDayBefore, .twoDaysBefore, .aWeekBefore
        ]
        let isAllDay = false
        let is12HourStyle = self.timeService?.rx12HourStyle.value ?? false
        return typeList.map {
            (key: $0, value: Utils.Reminder.reminderStr(minutes: $0.rawValue, isAllDay: isAllDay, is12HourStyle: is12HourStyle))
        }
    }()

    private lazy var pickerAdapter: PickerAdapter = {
        let adapter = PickerAdapter()
        adapter.items = selectOptions
        return adapter
    }()

    override func setup() {
        subTitleCell.setup(
            title: I18N.Todo_Settings_TaskDefaultAlertTime,
            description: I18N.Todo_Settings_TaskDefaultAlertTimeDesc,
            subTitle: selectOptions[selectedRow].value
        ) { [weak self] in
            guard let self = self else { return }
            self.trackClick()
            let picker = self.getPicker()
            let risingVC = RisingViewController(contentView: picker, customTitle: I18N.Todo_Settings_TaskDefaultAlertTimeMobile)
            risingVC.confirmHandler = { [weak self] in
                let selectedRow = picker.selectedRow(inComponent: 0)
                self?.trackConfirm(selectedRow)
                self?.onSelectedRowChanged(selectedRow)
            }
            risingVC.cancelHandler = { [weak self] in
                self?.trackCancel()
            }
            if Display.pad {
                risingVC.modalPresentationStyle = .popover
                risingVC.preferredContentSize = CGSize(width: 375, height: 250)
                if let popOver = risingVC.popoverPresentationController {
                    popOver.sourceView = self.subTitleCell
                    popOver.sourceRect = CGRect(x: self.subTitleCell.frame.width / 2, y: self.subTitleCell.frame.height / 2, width: 0, height: 0)
                    popOver.backgroundColor = UIColor.ud.bgBodyOverlay
                }
            }
            self.containerContext.viewController?.present(risingVC, animated: true)
        }
        layoutSubviews()

        settingService?.observe(forKeyPath: \.dueReminderOffset)
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] offset in
                guard let self = self else { return }
                if let key = NonAllDayReminder(rawValue: offset),
                   let index = self.selectOptions.firstIndex(where: { $0.key == key }) {
                    self.selectedRow = index
                    self.subTitleCell.subTitleLabel.text = self.selectOptions[index].value
                }
            }.disposed(by: disposeBag)
    }

    private func layoutSubviews() {
        rootView.addSubview(subTitleCell)

        subTitleCell.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
    }

    private func getPicker() -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = pickerAdapter
        picker.dataSource = pickerAdapter
        picker.selectRow(selectedRow, inComponent: 0, animated: false)
        return picker
    }

    private func onSelectedRowChanged(_ selectedRow: Int) {
        let oldValue = selectOptions[self.selectedRow].key.rawValue
        settingService?.update(selectOptions[selectedRow].key.rawValue, forKeyPath: \.dueReminderOffset) { [weak self] in
            guard let self = self else { return }
            self.settingService?.updateCache(oldValue, forKeyPath: \.dueReminderOffset)
            Utils.Toast.showError(with: I18N.Todo_Task_FailedToSet, on: self.containerContext.viewController?.view ?? UIView())
        }
    }

}

// MARK: UIPickerViewDataSource & UIPickerViewDelegate

private class PickerAdapter: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    var items = [(key: NonAllDayReminder, value: String)]()

    func numberOfComponents(in pickerView: UIPickerView)
    -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int)
    -> CGFloat { 40 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int)
    -> Int { items.count }

    func pickerView(
        _ pickerView: UIPickerView, viewForRow row: Int,
        forComponent component: Int, reusing view: UIView?
    ) -> UIView {
        if let reuseView = view, let label = view as? UILabel {
            label.text = items[row].value
            return label
        } else {
            let label = UILabel()
            label.font = UDFont.systemFont(ofSize: 17)
            label.textAlignment = .center
            label.text = items[row].value
            return label
        }
    }
}

// MARK: - Tracker

extension SettingDefaultReminderModule {
    private func trackClick() {
        Setting.Track.clickDefaultReminderSetting()
        Setting.Track.viewDefaultReminder()
    }

    private func trackConfirm(_ selectedRow: Int) {
        var status = ""
        let item = selectOptions[selectedRow]
        switch item.key {
        case .noAlert: status = "no_alert"
        case .atTimeOfEvent: status = "alert_task_due"
        case .fiveMinutesBefore: status = "alert_5min_before"
        case .aQuarterBefore: status = "alert_15min_before"
        case .halfAnHourBefore: status = "alert_30min_before"
        case .anHourBefore: status = "alert_1hour_before"
        case .twoHoursBefore: status = "alert_2hour_before"
        case .aDayBefore: status = "alert_1day_before"
        case .twoDaysBefore: status = "alert_2day_before"
        default: break
        }
        Setting.Track.defaultReminderClickConfirm(status: status)
    }

    private func trackCancel() {
        Setting.Track.defaultReminderClickCancel()
    }
}
