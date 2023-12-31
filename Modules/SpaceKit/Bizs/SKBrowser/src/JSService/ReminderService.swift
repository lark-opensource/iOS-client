//
//  ReminderService.swift
//  SpaceKit
//
//  Created by nine on 2019/3/25.
//

import Foundation
import SKCommon
import SKFoundation
import SKUIKit

public final class ReminderService: BaseJSService {}

extension ReminderService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.reminderSetting]
    }

    public func handle(params: [String: Any], serviceName: String) {
        var reminder: ReminderModel
        var config = ReminderVCConfig.default
        var isCreatingNewReminder = false
        // 判断是修改reminder还是创建
        if let data = params["data"] as? [String: Any] {
            let notCheckboxEntry = data["notCheckboxEntry"] as? Bool ?? false
            config.showNoticeItem = !notCheckboxEntry
            reminder = ReminderModel(reminderBlockID: data["reminderBlockId"] as? String,
                                     expireTime: data["expireTime"] as? TimeInterval,
                                     isWholeDay: data["isWholeDay"] as? Bool,
                                     notifyTime: data["notifyTime"] as? String,
                                     mentions: data["mentions"] as? [String])
            DocsTracker.log(enumEvent: .clientReminderOperation, parameters: self.makeParameters(with: "click_reminder"))
        } else {
            isCreatingNewReminder = true
            reminder = ReminderModel()
            DocsTracker.log(enumEvent: .clientReminderOperation, parameters: self.makeParameters(with: "click_insert_reminder"))
        }
        
        if let createTaskSwitch = params["createTaskSwitch"] as? [String: Any] {
            config.isShowCreateTaskSwitch = createTaskSwitch["show"] as? Bool ?? false
            reminder.isCreateTaskSwitchOn = createTaskSwitch["value"] as? Bool ?? false
        } else {
            config.isShowCreateTaskSwitch = false
            reminder.isCreateTaskSwitchOn = false
        }
        
        guard let hostVC = navigator?.currentBrowserVC else {
            return
        }
        let contentSize = (SKDisplay.pad && (ui?.hostView.isMyWindowRegularSize() ?? false)) ? CGSize(width: 540, height: 620) : hostVC.view.bounds.size
        // 构造reminderVC
        // TODO: 权限模型改造 - 需要梳理 Reminder 的使用场景是否存在不同文档上下文的问题
        let reminderVC = ReminderViewController(
            with: reminder,
            contentSize: contentSize,
            showWholeDaySwitch: params["showWholeDaySwitch"] as? Bool,
            isCreatingNewReminder: isCreatingNewReminder,
            config: config,
            docsInfo: model?.browserInfo.docsInfo
        ) { [weak self] reminder in
            let params = [
                "data": ["reminderBlockId": (reminder.id ?? "") as Any,
                         "isWholeDay": !(reminder.shouldSetTime ?? true),
                         "notifyTime": (reminder.notifyStrategy?.desc ?? "noAlert") as Any,
                         "expireTime": reminder.expireTime ?? Date().timeIntervalSince1970,
                         "isCreateTask": reminder.isCreateTaskSwitchOn
                        ]
            ]
            self?.model?.jsEngine.callFunction(DocsJSCallBack.reminderSetDate, params: params, completion: nil)
        }
        reminderVC.statisticsCallBack = { [weak self] action in
            guard let self = self else { return }
            DocsTracker.log(enumEvent: .clientReminderOperation, parameters: self.makeParameters(with: action))
        }
        reminderVC.cancelCallBack = { [weak self] in
            self?.model?.jsEngine.callFunction(DocsJSCallBack.reminderCancel, params: params, completion: nil)
        }
        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            reminderVC.modalPresentationStyle = .formSheet
            reminderVC.preferredContentSize = contentSize
        } else {
            reminderVC.modalPresentationStyle = .overFullScreen
        }
        navigator?.presentViewController(reminderVC, animated: true, completion: nil)
        DocsLogger.info("收到前端请求，开始present reminderVC")
    }
}

extension ReminderService: ServiceStatistics {}

extension ServiceStatistics where Self: ReminderService {
    public func makeParameters(with action: String) -> [AnyHashable: Any]? {
        return ["action": action,
                "file_id": encryptedToken,
                "file_type": fileType,
                "module": module]
    }
}
