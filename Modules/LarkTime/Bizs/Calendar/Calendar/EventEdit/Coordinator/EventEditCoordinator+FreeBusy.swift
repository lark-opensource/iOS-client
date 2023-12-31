//
//  EventEditCoordinator+FreeBusy.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit

/// 编辑日程忙闲

extension EventEditCoordinator: EventEditFreeBusyDelegate,
    EventFreeBusyViewControllerDelegate {

    // MARK: EventEditFreeBusyDelegate

    func selectFreeBusy(from fromVC: EventEditViewController) {
        guard let freeBusy = fromVC.viewModel.eventModel?.rxModel?.value.freeBusy else { return }
        let toVC = EventFreeBusyViewController(freeBusy: freeBusy)
        toVC.delegate = self
        enter(from: fromVC, to: toVC)
    }

    // MARK: EventFreeBusyViewControllerDelegate

    func didCancelEdit(from viewController: EventFreeBusyViewController) {
        exit(from: viewController)
        viewController.navigationController?.popViewController(animated: true)
    }

    func didFinishEdit(from viewController: EventFreeBusyViewController) {
        eventViewController?.viewModel.updateFreeBusy(viewController.selectedFreeBusy)
        exit(from: viewController)
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("edit_availability").target("none")
            if let eventModel = eventViewController?.viewModel.eventModel?.rxModel?.value {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel.getPBModel(), startTime: Int64(eventModel.startDate.timeIntervalSince1970 ?? 0) ))
            }
        }
    }

}
