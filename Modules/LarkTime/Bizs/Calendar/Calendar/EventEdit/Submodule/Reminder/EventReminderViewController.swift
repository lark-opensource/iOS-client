//
//  EventReminderViewController.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/24.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import CTFoundation
import UniverseDesignCheckBox

protocol EventReminderViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventReminderViewController)
    func didFinishEdit(from viewController: EventReminderViewController)
}

final class EventReminderViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UIAdaptivePresentationControllerDelegate {
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }
    weak var delegate: EventReminderViewControllerDelegate?
    internal private(set) var selectedReminders: [EventEditReminder]
    // 用户开始编辑前的 selectedReminders，退出取消编辑时，用于判断是否应该弹窗提醒
    internal private(set) var selectedRemindersBeforeEditing: [EventEditReminder]

    private let disposeBag = DisposeBag()
    private let availableReminders: [EventEditReminder]
    private var defaultReminder: EventEditReminder {
        isAllDay ? Self.allDayAvailableReminders[2] : Self.nonAllDayAvailableReminders[1]
    }
    private var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    private let cellReuseId = "Cell"
    private let allowsMultipleSelection: Bool
    private let reminderFormatter: (EventEditReminder) -> String
    private let isAllDay: Bool

    init(
        reminders: [EventEditReminder],
        isAllDay: Bool,
        is12HourStyle: Bool,
        allowsMultipleSelection: Bool = true
    ) {
        assert(allowsMultipleSelection || reminders.count <= 1)
        self.isAllDay = isAllDay
        self.selectedReminders = reminders
        self.selectedRemindersBeforeEditing = reminders
        self.availableReminders = isAllDay ? Self.allDayAvailableReminders : Self.nonAllDayAvailableReminders
        self.allowsMultipleSelection = allowsMultipleSelection
        self.reminderFormatter = { (reminder: EventEditReminder) -> String in
            reminder.toReminderString(isAllDay: isAllDay, is12HourStyle: is12HourStyle)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Edit_ChooseAlerts
        setupView()
        bindViewAction()
        tableView.reloadData()
        navigationController?.presentationController?.delegate = self
    }

    private func setupView() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        tableView.tableHeaderView = headerView()
        tableView.register(ReminderCell.self, forCellReuseIdentifier: cellReuseId)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        navigationItem.leftBarButtonItem = cancelItem

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = doneItem
    }

    private func headerView() -> UIView {
        let wrapper = UIView(frame: .init(origin: .zero, size: CGSize(width: view.bounds.width, height: 76)))
        let switchCell = EventEditSwitch(isOn: !selectedReminders.isEmpty,
                                         descText: BundleI18n.Calendar.Calendar_Legacy_EventReminder_Switch)
        let bottomSeparator = EventBasicDivideView()
        bottomSeparator.isHidden = self.selectedReminders.isEmpty
        switchCell.rxIsOn.skip(1).bind { [weak self] (isOn) in
            guard let self = self else { return }
            if !isOn {
                self.selectedReminders.removeAll()
            } else {
                self.selectedReminders.append(self.defaultReminder)
            }
            bottomSeparator.isHidden = !isOn
            self.tableView.reloadData()
            self.selectedRemindersChanged()
        }.disposed(by: disposeBag)

        wrapper.addSubview(switchCell)
        wrapper.addSubview(bottomSeparator)
        switchCell.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(12)
            $0.bottom.equalTo(bottomSeparator.snp.top).offset(-12)
        }
        bottomSeparator.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        return wrapper
    }

    private func bindViewAction() {
        let closeItem = navigationItem.leftBarButtonItem as? LKBarButtonItem
        closeItem?.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.willCancelEdit()
            }
            .disposed(by: disposeBag)

        let doneItem = navigationItem.rightBarButtonItem as? LKBarButtonItem
        doneItem?.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didFinishEdit(from: self)
            }
            .disposed(by: disposeBag)
    }

    private func willCancelEdit() {
        if selectedReminders != selectedRemindersBeforeEditing {
            let alertTexts = EventEditConfirmAlertTexts(
                message: BundleI18n.Calendar.Calendar_Edit_UnSaveTip
            )
            self.showConfirmAlertController(
                texts: alertTexts,
                confirmHandler: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didCancelEdit(from: self)
                }
            )
        } else {
            self.delegate?.didCancelEdit(from: self)
        }
    }

    private func selectedRemindersChanged() {
        if #available(iOS 13.0, *) {
            isModalInPresentation = selectedReminders != selectedRemindersBeforeEditing
        }
    }
    
    // MARK: UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return selectedReminders.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableReminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        guard let reminderCell = cell as? ReminderCell else {
            return cell
        }
        let reminder = availableReminders[indexPath.row]
        reminderCell.title = reminderFormatter(reminder)
        reminderCell.isChecked = selectedReminders.contains(where: { $0 == reminder })
        // 设置顶部或者底部的左右两边圆角
        // (reminderCell as CalendarCornerCell).setHorizontalConrner(row: indexPath.row, dataCount: availableReminders.count)
        return reminderCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EventEditUIStyle.Layout.secondaryPageCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let reminder = availableReminders[indexPath.row]
        if !selectedReminders.contains(reminder) {
            if !allowsMultipleSelection {
                // 单选
                selectedReminders = [reminder]
            } else {
                selectedReminders.append(reminder)
            }
        } else if selectedReminders.count > 1 {
            selectedReminders = selectedReminders.filter { $0 != reminder }
        } else {
            // do nothing
        }
        tableView.reloadData()
        selectedRemindersChanged()
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        willCancelEdit()
    }
}

extension EventReminderViewController {

    final class ReminderCell: UITableViewCell {
        var innerView = EventEditCellLikeView()
        var title: String = "" {
            didSet {
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title)
                innerView.content = .title(titleContent)
            }
        }
        
        var isChecked: Bool = false {
            didSet {
                innerView.accessory = isChecked ? .type(.checkmark) : .none
                let titleContent = EventBasicCellLikeView.ContentTitle(text: title, color: isChecked ? UIColor.ud.functionInfoContentDefault: UIColor.ud.textTitle)
                innerView.content = .title(titleContent)
            }
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            isChecked = false
            innerView.icon = .none
            contentView.addSubview(innerView)
            innerView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
            innerView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension EventReminderViewController {

    // 非全天日程的可选提醒
    private static let nonAllDayAvailableReminders: [EventEditReminder] = [
        EventEditReminder(minutes: 0),
        EventEditReminder(minutes: 5),
        EventEditReminder(minutes: 15),
        EventEditReminder(minutes: 30),
        EventEditReminder(minutes: 60),
        EventEditReminder(minutes: 120),
        EventEditReminder(minutes: 1440),
        EventEditReminder(minutes: 2880),
        EventEditReminder(minutes: 10_080)
    ]

    // 全天日程的可选提醒
    private static let allDayAvailableReminders: [EventEditReminder] = [
        EventEditReminder(minutes: -480),
        EventEditReminder(minutes: -540),
        EventEditReminder(minutes: -600),
        EventEditReminder(minutes: 960),
        EventEditReminder(minutes: 900),
        EventEditReminder(minutes: 840)
    ]

}

extension EventReminderViewController: EventEditConfirmAlertSupport {}
