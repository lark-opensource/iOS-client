//
//  EventEditCoordinator+Visibility.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit

/// 编辑日程可见性

extension EventEditCoordinator: EventEditVisibilityDelegate,
    EventVisibilityViewControllerDelegate {
    // MARK: EventEditVisibilityDelegate

    func selectVisibility(from fromVC: EventEditViewController) {
        guard let visibility = fromVC.viewModel.eventModel?.rxModel?.value.visibility else { return }
        let toVC = EventVisibilityViewController(visibility: visibility)
        toVC.delegate = self
        enter(from: fromVC, to: toVC)
    }

    // MARK: EventVisibilityViewControllerDelegate

    func didCancelEdit(from viewController: EventVisibilityViewController) {
        exit(from: viewController)
    }

    func didFinishEdit(from viewController: EventVisibilityViewController) {
        eventViewController?.viewModel.updateVisibility(viewController.selectedVisibility)
        exit(from: viewController)
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("edit_public_scale").target("none")
            if let eventModel = eventViewController?.viewModel.eventModel?.rxModel?.value {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel.getPBModel(), startTime: Int64(eventModel.startDate.timeIntervalSince1970 ?? 0) ))
            }
        }
    }

}
