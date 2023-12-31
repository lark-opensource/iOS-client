//
//  EventEditCoordinator+Reminder.swift
//  Calendar
//
//  Created by 张威 on 2020/4/14.
//

import Foundation
import LarkUIKit

/// 编辑日程提醒

extension EventEditCoordinator: EventReminderViewControllerDelegate {

    func selectReminder(from fromVC: EventEditViewController) {
        guard let eventModel = fromVC.viewModel.eventModel?.rxModel?.value else { return }
        let toVC = EventReminderViewController(
            reminders: eventModel.reminders,
            isAllDay: eventModel.isAllDay,
            is12HourStyle: dependency.is12HourStyle?.value ?? true,
            allowsMultipleSelection: fromVC.viewModel.allowsMultipleSelectionForReminder
        )
        toVC.delegate = self
        enter(from: fromVC, to: toVC, present: true)
    }

    // MARK: EventReminderViewControllerDelegate

    func didCancelEdit(from viewController: EventReminderViewController) {
        exit(from: viewController, fromPresent: true)
    }

    func didFinishEdit(from viewController: EventReminderViewController) {
        let reminders = viewController.selectedReminders
        eventViewController?.viewModel.updateReminders(reminders)
        exit(from: viewController, fromPresent: true)
    }

}
