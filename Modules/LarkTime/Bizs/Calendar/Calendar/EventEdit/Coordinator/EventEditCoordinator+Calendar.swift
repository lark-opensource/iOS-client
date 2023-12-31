//
//  EventEditCoordinator+Calendar.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit
import UniverseDesignToast

/// 编辑日程日历

extension EventEditCoordinator: EventEditCalendarDelegate,
    EventCalendarViewControllerDelegate {
    // MARK: EventEditCalendarDelegate

    func selectCalendar(from fromVC: EventEditViewController) {
        guard let calendar = fromVC.viewModel.eventModel?.rxModel?.value.calendar else {
            assertionFailure()
            return
        }
        let availableCalendars: [EventEditCalendar] = fromVC.viewModel.availableCalendars

        let toVC = EventCalendarViewController(
            calendar: calendar,
            calendars: availableCalendars,
            userResolver: self.userResolver
        )
        toVC.delegate = self
        enter(from: fromVC, to: toVC)
    }

    // MARK: EventCalendarViewControllerDelegate

    private var hasMeetingNotes: Bool {
        eventViewController?.viewModel.meetingNotesModel?.currentNotes != nil
    }

    func didCancelEdit(from viewController: EventCalendarViewController) {
        exit(from: viewController)
        viewController.navigationController?.popViewController(animated: true)
    }

    func didFinishEdit(from viewController: EventCalendarViewController) {
        eventViewController?.viewModel.updateCalendar(viewController.selectedCalendar)
        exit(from: viewController)
    }

    /// 日历是否不可用
    func isDisable(_ calendar: EventEditCalendar) -> Bool {
        if hasMeetingNotes && [.exchange, .google].contains(calendar.source) {
            return true
        }
        return false
    }

    /// 点击回调，true 表示被外部拦截，false 表示继续执行内部逻辑
    func didClick(from fromVC: EventCalendarViewController,_ calendar: EventEditCalendar) -> Bool {
        if hasMeetingNotes && [.exchange, .google].contains(calendar.source) {
            UDToast.showTips(with: I18n.Calendar_Event_NotesNoSwicth, on: fromVC.view)
            return true
        }
        return false
    }

    func alertTextsForSelectingCalendar(_ calendar: EventEditCalendar, from fromVC: EventCalendarViewController)
        -> EventEditConfirmAlertTexts? {
        return eventViewController?.viewModel.alertTextsForSelectingCalendar(calendar)
    }

}
