//
//  EventEditCoordinator+Notes.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit
/// 编辑日程描述

extension EventEditCoordinator: EventEditNotesDelegate,
    EventNotesViewControllerDelegate {
    // MARK: EventEditNotesDelegate

    func editNotes(from fromVC: EventEditViewController) {
        guard let notes = fromVC.viewModel.eventModel?.rxModel?.value.notes else {
            assertionFailure()
            return
        }
        let toVC = EventNotesViewController(notes: notes, userResolver: self.userResolver)
        toVC.delegate = self

        enter(from: fromVC, to: toVC, present: true)
    }

    // MARK: EventNotesViewControllerDelegate

    func didCancelEdit(from viewController: EventNotesViewController) {
        exit(from: viewController, fromPresent: true)
    }

    func didFinishEdit(from viewController: EventNotesViewController) {
        eventViewController?.viewModel.updateNotes(viewController.notes)
        exit(from: viewController, fromPresent: true)
    }
}
