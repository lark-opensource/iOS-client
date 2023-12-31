#if !LARK_NO_DEBUG
//
//  ConvenientDebug.swift
//  Calendar
//
//  Created by huoyunjie on 2022/2/11.
//

import Foundation
import UIKit
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkUIKit
import RxSwift
import LarkEMM
import LKCommonsLogging
import CalendarFoundation
import LarkSensitivityControl

// debug 调试数据
protocol ConvenientDebugInfo {
    var eventDebugInfo: Rust.Event? { get }
    var calendarDebugInfo: Rust.Calendar? { get }
    var meetingRoomInstanceDebugInfo: RoomViewInstance? { get }
    var meetingRoomDebugInfo: Rust.MeetingRoom? { get }
    var otherDebugInfo: [String: String]? { get }
}

// debug UI展示部分
protocol ConvenientDebug {
    func addDebugGesture()
}

extension ConvenientDebug {

    func addDebugGesture() {}

    func showActionSheet(debugInfo: ConvenientDebugInfo, in controller: UIViewController) {
        guard FG.canDebug else { return }
        let actionSheetVC = UDActionSheet(config: UDActionSheetUIConfig())
        if let event = debugInfo.eventDebugInfo {
            actionSheetVC.addItem(UDActionSheetItem(title: "event info", action: {
                showInfo(info: event.debugDescription, in: controller)
            }))
        }
        if let calendar = debugInfo.calendarDebugInfo {
            actionSheetVC.addItem(UDActionSheetItem(title: "calendar info", action: {
                showInfo(info: calendar.debugDescription, in: controller)
            }))
        }
        if let meetingRoomInstance = debugInfo.meetingRoomInstanceDebugInfo {
            actionSheetVC.addItem(UDActionSheetItem(title: "meetingRoomInstance info", action: {
                showInfo(info: meetingRoomInstance.debugDescription, in: controller)
            }))
        }
        if let meetingRoom = debugInfo.meetingRoomDebugInfo {
            actionSheetVC.addItem(UDActionSheetItem(title: "meetingRoom info", action: {
                showInfo(info: meetingRoom.debugDescription, in: controller)
            }))
        }
        if let other_info = debugInfo.otherDebugInfo {
            other_info.forEach { info in
                actionSheetVC.addItem(UDActionSheetItem(title: info.key, action: {
                    showInfo(info: info.value, in: controller)
                }))
            }
        }
        actionSheetVC.setCancelItem(text: I18n.Calendar_Common_Cancel)
        controller.present(actionSheetVC, animated: true)
    }

    func showInfo(info: String, in controller: UIViewController) {
        guard FG.canDebug else { return }
        let config = UDDialogUIConfig()
        let alert = UDDialog(config: config)
        let scrollView = UIScrollView()
        let label = UILabel()
        label.numberOfLines = 0
        label.text = info
        scrollView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalTo(scrollView.frameLayoutGuide)
            make.bottom.top.equalTo(scrollView.contentLayoutGuide)
        }
        alert.setContent(view: scrollView)
        scrollView.frameLayoutGuide.snp.makeConstraints { make in
            make.height.equalTo(600)
        }
        alert.addCancelButton()
        alert.addPrimaryButton(text: I18n.Calendar_Common_Copy, dismissCompletion: {
            do {
                var config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.debugModeInfoCopy)))
                config.shouldImmunity = true
                try SCPasteboard.generalUnsafe(config).string = info
                UDToast.showSuccess(with: I18n.Calendar_Share_Copied, on: controller.view)
            } catch {
                SCPasteboardUtils.logCopyFailed()
                UDToast.showFailure(with: I18n.Calendar_Share_UnableToCopy, on: controller.view)
            }
        })
        controller.present(alert, animated: true)
    }
}
#endif
