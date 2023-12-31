//
//  NewEventNormalAlarmTypePickerView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/19.
//  Copyright © 2017年 EE. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkUIKit
import FigmaKit

final class NewEventReminderPicker: UIView, UITableViewDelegate, UITableViewDataSource {

    var doneCallBack: (([Reminder]) -> Void)?
    let tableView = InsetTableView()
    private let is12HourStyle: BehaviorRelay<Bool>

    init(reminders: [Reminder],
         isAllDay: Bool,
         allowsMultipleSelection: Bool = true,
         is12HourStyle: BehaviorRelay<Bool>) {
//        assertLog(!reminders.isEmpty)
        self.is12HourStyle = is12HourStyle
        self.isAllDay = isAllDay
        super.init(frame: .zero)
        backgroundColor = .clear
        commonInit()
        self.combineReminders(reminders, isAllDay: isAllDay)
        self.tableView.allowsMultipleSelection = allowsMultipleSelection
        reminders.forEach { (reminder) in
            assertLog(reminder.isAllDay == isAllDay)
            if let index = self.reminders().firstIndex(where: { $0 == reminder }) {
                tableView.selectRow(at: IndexPath(row: index + 1, section: 0), animated: false, scrollPosition: .none)
            }
        }
        if reminders.isEmpty {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        }
    }

    func commonInit() {
        self.backgroundColor = .clear
        tableView.rowHeight = 48
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.register(NormalAlarmTypeCell.self, forCellReuseIdentifier: "Cell")
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tableView.contentInset = UIEdgeInsets(top: -18, left: 0, bottom: 0, right: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func combineReminders(_ reminders: [Reminder], isAllDay: Bool) {
        let originalReminders = isAllDay ? self.allDayReminders : self.normalReminders
        var currentReminders = originalReminders
        reminders.forEach({ (reminder) in
            assertLog(reminder.isAllDay == isAllDay)
            if !originalReminders.contains(where: { $0 == reminder }) {
                currentReminders.append(reminder)
            }
        })
        if isAllDay {
            self.allDayReminders = currentReminders
        } else {
            self.normalReminders = currentReminders
        }
    }

    private lazy var normalReminders: [Reminder] = {
        var reminders: [Reminder] = []
        reminders.append(Reminder(minutes: 0, isAllDay: false))
        reminders.append(Reminder(minutes: 5, isAllDay: false))
        reminders.append(Reminder(minutes: 15, isAllDay: false))
        reminders.append(Reminder(minutes: 30, isAllDay: false))
        reminders.append(Reminder(minutes: 60, isAllDay: false))
        reminders.append(Reminder(minutes: 120, isAllDay: false))
        reminders.append(Reminder(minutes: 1440, isAllDay: false))
        reminders.append(Reminder(minutes: 2880, isAllDay: false))
        reminders.append(Reminder(minutes: 10_080, isAllDay: false))
        return reminders
    }()

    private lazy var allDayReminders: [Reminder] = {
        var allDayReminders: [Reminder] = []
        allDayReminders.append(Reminder(minutes: -480, isAllDay: true))
        allDayReminders.append(Reminder(minutes: -540, isAllDay: true))
        allDayReminders.append(Reminder(minutes: -600, isAllDay: true))
        allDayReminders.append(Reminder(minutes: 960, isAllDay: true))
        allDayReminders.append(Reminder(minutes: 900, isAllDay: true))
        allDayReminders.append(Reminder(minutes: 840, isAllDay: true))
        return allDayReminders
    }()

    var isAllDay: Bool = false

    private func reminders() -> [Reminder] {
        return self.isAllDay ? self.allDayReminders : self.normalReminders
    }

    // MARK: tableView delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders().count + 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedIndexs = self.tableView.indexPathsForSelectedRows else {
            self.doneCallBack?([])
            return
        }
        if selectedIndexs.first?.row == 0 {
            self.doneCallBack?([])
            return
        }
        let alarms = selectedIndexs.sorted(by: { $0.row < $1.row }).map({ self.reminders()[$0.row - 1] })
        self.doneCallBack?(alarms)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? NormalAlarmTypeCell else {
            assertionFailureLog()
            return UITableViewCell()
        }
        if indexPath.row == 0 {
            cell.setText(BundleI18n.Calendar.Calendar_Common_NoAlerts)
        } else {
            let reminder = self.reminders()[indexPath.row - 1]
            cell.setText(reminder.reminderString(is12HourStyle: is12HourStyle.value))
        }
        if indexPath.row == reminders().count {
            cell.showBorder(false)
        } else {
            cell.showBorder(true)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedIndex = tableView.indexPathsForSelectedRows else {
            return indexPath
        }
        if selectedIndex.contains(indexPath) && selectedIndex.count > 1 {
            tableView.deselectRow(at: indexPath, animated: false)
            return nil
        }
        return indexPath
    }
}

final class ReminderCellContentView: UIView {
    let label = UILabel.cd.textLabel()
    let checkbox = LKCheckbox(boxType: .list)
    lazy var bottomBorder: UIView = {
        let bottomBorder = addCellBottomBorder()
        return bottomBorder
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(NewEventViewUIStyle.Margin.leftMargin)
        }

        checkbox.isUserInteractionEnabled = false
        self.addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(NewEventViewUIStyle.Margin.rightMargin)
        }
        backgroundColor = UIColor.ud.bgFloat
    }

    func setSelected(_ selected: Bool) {
        checkbox.isSelected = selected
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NormalAlarmTypeCell: UITableViewCell {

    private let content = ReminderCellContentView(frame: .zero)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addCustomHighlightedView()
        self.contentView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func showBorder(_ isShow: Bool) {
        content.bottomBorder.isHidden = !isShow
    }

    func setText(_ text: String) {
        self.content.label.text = text
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        self.content.setSelected(selected)
        self.content.label.textColor = selected ? UIColor.ud.functionInfoContentDefault: UIColor.ud.textTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
