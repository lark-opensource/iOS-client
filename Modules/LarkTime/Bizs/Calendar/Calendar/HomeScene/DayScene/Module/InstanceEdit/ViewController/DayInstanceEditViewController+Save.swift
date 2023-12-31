//
//  DayInstanceEditViewController+Save.swift
//  Calendar
//
//  Created by 张威 on 2020/9/8.
//

import LarkUIKit
import LarkActionSheet
import LarkAlertController
import UniverseDesignToast

/// DayScene - InstanceEdit - ViewController: SaveContext

extension DayInstanceEditViewController {

    func handleSaveViewMessage(_ viewMessage: DayInstanceEditViewModel.SaveViewMessage) {
        switch viewMessage {
        case .alert(let alert):
            let alertVC = LarkAlertController()
            if let title = alert.title {
                alertVC.setTitle(text: title)
            }
            if let message = alert.message {
                alertVC.setContent(text: message)
            }
            alert.actions.forEach { item in
                alertVC.addButton(text: item.title, color: item.titleColor) {
                    item.handler()
                }
            }
            present(alertVC, animated: true)
        case .meetingRoomReservationAlert(let alert):
            let alertVC = LarkAlertController()
            alertVC.setTitle(text: alert.title)
            alert.actions.forEach { item in
                alertVC.addButton(text: item.title, color: item.titleColor) {
                    item.handler()
                }
            }
            CalendarTracerV2.RoomNoReserveConfirm.traceView()
            present(alertVC, animated: true)
        case .generalMeetingRoomInfoAlert(let alert):
            let alertVC = LarkAlertController.generalMeetingRoomAlert(title: alert.title,
                                                                      itemInfos: alert.itemInfos)
            alert.actions.forEach { item in
                alertVC.addButton(text: item.title, color: item.titleColor) {
                    item.handler()
                }
            }
            present(alertVC, animated: true)
        case .meetingRoomApprovalAlert(let alert):
            LarkAlertController.showAddApproveInfoAlert(
                from: self,
                title: alert.title,
                itemTitles: alert.itemInfos,
                disposeBag: disposeBag,
                cancelText: BundleI18n.Calendar.Calendar_Detail_CancelEdit,
                cancelAction: alert.cancelHandler,
                confirmAction: alert.confirmHandler
            )
        case .notiOptionAlert(let alert):
            let confirmVC = NotificationOptionViewController()
            confirmVC.setTitles(
                titleText: alert.title,
                subTitleText: alert.checkBoxTitle ?? alert.subtitle,
                showSubtitleCheckButton: false,
                subTitleMailText: nil
            )
            let actionButtons = alert.actions.map { item in
                ActionButton(title: item.title, titleColor: item.titleColor) { (_, disappear) in
                    disappear {
                        item.handler()
                    }
                }
            }
            actionButtons.forEach {
                confirmVC.addAction(actionButton: $0)
            }
            confirmVC.show(controller: self.navigationController ?? self)
        case .present(let vc):
            present(vc, animated: true)
        case .successToast(let text):
            if let window = self.view.window {
                UDToast.showSuccess(with: text, on: window)
            }
        }
    }

}
