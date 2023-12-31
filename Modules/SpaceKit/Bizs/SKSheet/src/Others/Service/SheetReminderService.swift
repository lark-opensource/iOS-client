//
// Created by duanxiaochen.7 on 2020/10/20.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKUIKit
import SKCommon
import SKBrowser
import EENavigator

class SheetReminderService: BaseJSService {
    weak var showingReminderVC: SKNavigationController?
}

extension SheetReminderService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetShowReminder]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard !params.isEmpty,
              let data = params["data"] as? [String: Any],
              let callback = params["callback"] as? String else {
            DocsLogger.debug("前端传空收起 sheet reminder", component: LogComponents.reminder)
            showingReminderVC?.dismiss(animated: true)
            return
        }

        guard let sheetID = data["sheetId"] as? String,
              let expireTime = data["expireTime"] as? TimeInterval,
              let notifyUsers = data["notifyUsers"] as? [[String: String]],
              let isSetTime = data["isSetTime"] as? Bool else {
            DocsLogger.error("前端没有传完整的 sheet reminder 参数过来", extraInfo: params)
            return
        }

        let reminder = ReminderModel(sheetID: sheetID,
                                     expireTime: expireTime / 1000.0,
                                     isSetTime: isSetTime,
                                     notifyStrategy: data["notifyStrategy"] as? Int,
                                     notifyUsers: notifyUsers,
                                     notifyText: data["notifyText"] as? String)
        guard let hostVC = navigator?.currentBrowserVC else {
            return
        }
        // 判断是否横屏，如果是转回竖屏再计算contentSize，防止calendarView cell 宽度计算错误
        if UIApplication.shared.statusBarOrientation.isLandscape && SKDisplay.phone {
            LKDeviceOrientation.setOritation(.portrait)
        }
        let contentSize = (SKDisplay.pad && (ui?.hostView.isMyWindowRegularSize() ?? false)) ? CGSize(width: 540, height: 620) : hostVC.view.bounds.size
        // 构造reminderVC
        let reminderVC = ReminderViewController(
            with: reminder,
            contentSize: contentSize,
            showWholeDaySwitch: true,
            isCreatingNewReminder: false,
            config: ReminderVCConfig.sheet,
            docsInfo: model?.browserInfo.docsInfo
        ) { [weak self] reminder in
            var users = [[String: String]]()
            reminder.notifyUsers?.forEach { (user) in
                users.append([
                    "id": user.id,
                    "name": user.name,
                    "enName": user.enName,
                    "avatarUrl": user.avatarURL
                ])
            }
            var reminderArgs: [String: Any] = [
                "sheetId": reminder.id as Any,
                "expireTime": reminder.expireTime! * 1000.0 as Any,
                "notifyUsers": users as Any,
                "isSetTime": reminder.shouldSetTime as Any,
                "notifyStrategy": reminder.notifyStrategy?.rawValue as Any,
                "notifyText": reminder.notifyText as Any
            ]
            if reminder.notifyStrategy == .noAlert {
                reminderArgs["notifyUsers"] = [[String: Any]]() as Any
                reminderArgs["notifyText"] = ""
            }
            let params: [String: Any] = ["isCanceled": false, "reminderUpdateArgs": reminderArgs]
            self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
        }

        reminderVC.statisticsCallBack = nil
        reminderVC.sheetStatisticsCallback = { [weak self] (action, subAction) in
            DocsTracker.log(enumEvent: .sheetOperation,
                            parameters: self?.makeFullParameters(action: action, subAction: subAction, sheetID: sheetID))
        }
        reminderVC.cancelCallBack = { [weak self] in
            let params = ["isCanceled": true, "reminderUpdateArgs": ["sheetId": sheetID]] as [String: Any]
            self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
        }
        let navVC = SKNavigationController(rootViewController: reminderVC)
        showingReminderVC = navVC
        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            navVC.modalPresentationStyle = .formSheet
            reminderVC.modalPresentationStyle = .formSheet
            reminderVC.preferredContentSize = contentSize
        } else {
            navVC.modalPresentationStyle = .overFullScreen
        }
        navigator?.presentViewController(navVC, animated: true, completion: nil)
        DocsLogger.info("收到前端请求，开始present sheet reminderVC")
    }
}

extension SheetReminderService: ServiceStatistics {}

extension ServiceStatistics where Self: SheetReminderService {
    func makeParameters(with action: String) -> [AnyHashable: Any]? {
        return ["action": action,
                "file_id": encryptedToken,
                "file_type": fileType,
                "module": module]
    }

    func makeFullParameters(action: String, subAction: String?, sheetID: String) -> [AnyHashable: Any]? {
        var params = makeParameters(with: action)
        params?["table_id"] = sheetID
        if let subAction = subAction {
            params?["op_item"] = subAction
        }
        return params
    }
}
