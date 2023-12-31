//
//  EventEditCoordinator+Color.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit

/// 编辑日程颜色

extension EventEditCoordinator: EventEditColorDelegate,
    EventColorViewControllerDelegate {

    // MARK: EventEditColorDelegate

    func selectColor(from fromVC: EventEditViewController) {
        guard let color = fromVC.viewModel.eventModel?.rxModel?.value.color else {
            assertionFailure()
            return
        }
        let toVC = EventColorViewController(
            selectedColor: color,
            headerTitle: BundleI18n.Calendar.Calendar_Edit_ChooseEventColor,
            isShowBack: true
        )
        enter(from: fromVC, to: toVC)
        toVC.delegate = self
    }

    // MARK: EventColorViewControllerDelegate

    func didCancelEdit(from viewController: EventColorViewController) {
        exit(from: viewController)
        viewController.navigationController?.popViewController(animated: true)
    }

    func didFinishEdit(from viewController: EventColorViewController) {
        eventViewController?.viewModel.updateColor(viewController.selectedColor)
        exit(from: viewController)
    }

}
