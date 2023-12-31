//
//  EventEditCoordinator+Location.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit

/// 编辑日程地址

extension EventEditCoordinator: EventEditLocationDelegate,
    EventLocationViewControllerDelegate {

    // MARK: EventEditLocationDelegate

    func selectLocation(from fromVC: EventEditViewController) {
        guard let event = fromVC.viewModel.eventModel?.rxModel?.value else { return }
        let toVC = EventLocationViewController(location: event.location)
        toVC.delegate = self
        enter(from: fromVC, to: toVC, present: true)
    }

    // MARK: EventLocationViewControllerDelegate

    func didCancelEdit(from viewController: EventLocationViewController) {
        exit(from: viewController, fromPresent: true)
    }

    func didFinishEdit(from viewController: EventLocationViewController) {
        eventViewController?.viewModel.updateLocation(viewController.selectedLocation)
        exit(from: viewController, fromPresent: true)
    }

}
