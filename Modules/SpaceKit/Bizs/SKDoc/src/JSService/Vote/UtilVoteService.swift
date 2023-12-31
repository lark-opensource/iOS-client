//
//  UtilVoteService.swift
//  SKBrowser
//
//  Created by zhysan on 2022/9/13.
//

import Foundation
import SKCommon
import SKFoundation
import SKBrowser
import SKUIKit
import SKResource
import UniverseDesignDatePicker

public final class UtilVoteService: BaseJSService {
    var reminderCallback: String?
}

extension UtilVoteService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.openVoteMembers, .showVoteSelectExpirationDatePanel]
    }

    public func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("[VOTE] UtilVoteService handle invoke, serviceName: \(serviceName)")
        switch serviceName {
        case DocsJSService.openVoteMembers.rawValue:
            do {
                let data = try JSONSerialization.data(withJSONObject: params, options: [])
                let model = try JSONDecoder().decode(DocVote.OptionContext.self, from: data)
                let vc = VoteMembersViewController(optionContext: model) { [weak self] user in
                    self?.navigator?.showUserProfile(token: user.userId)
                }
                navigator?.pushViewController(vc)
            } catch {
                DocsLogger.error("[VOTE] handle error", error: error)
            }
        case DocsJSService.showVoteSelectExpirationDatePanel.rawValue:
            var expireTime: TimeInterval?
            if let intVal = params["expireTime"] as? Int {
                expireTime = Double(intVal) / 1000
            }
            self.reminderCallback = params["callback"] as? String
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard let self = self else { return }
                self.showVoteSelectExpirationDatePanel(expireTime: expireTime)
            }
        default:
            return
        }
    }
    
    private func showVoteSelectExpirationDatePanel(expireTime: TimeInterval?) {
        var reminder = ReminderModel()
        var config = ReminderVCConfig.default
        reminder.expireTime = expireTime ?? Date.sk.otherDay(2).sk.changed(hour: 18)!.timeIntervalSince1970 //默认两天后18:00
        reminder.shouldSetTime = true
        config.deadlineText = BundleI18n.SKResource.LarkCCM_Docx_Poll_Deadline_Title
        config.showNoticeItem = false
        config.autoCorrectExpireTimeBlock = { date in
            let now = Date()
            if Calendar.current.isDateInToday(date), date < now {
                //如果选择是今天但过期的时间，自动选中下一个有效时间（下一个半点）
                var newDate = date
                if now.minute < 30 {
                    newDate.minute = 30
                    newDate.hour = now.hour
                    newDate.second = 0
                } else if now.hour < 23 {
                    newDate.hour = now.hour + 1
                    newDate.minute = 0
                    newDate.second = 0
                }
                return newDate
            }
            return nil
        }
        config.datePickerConfig = ReminderVCConfig.DatePickerConfig(minuteInterval: 30, datePickerMode: .hourMinuteCenter)
        
        guard let hostVC = navigator?.currentBrowserVC else {
            return
        }
        let contentSize = (SKDisplay.pad && (ui?.hostView.isMyWindowRegularSize() ?? false)) ? CGSize(width: 540, height: 620) : hostVC.view.bounds.size
        // TODO: 权限模型改造 - 需要针对 SyncBlock 场景做适配
        let reminderVC = ReminderViewController(
            with: reminder,
            contentSize: contentSize,
            config: config,
            docsInfo: model?.browserInfo.docsInfo
        ) { [weak self] reminder in
            guard let self = self, let reminderCallback = self.reminderCallback else {
                DocsLogger.error("[VOTE] reminderCallback is empty")
                return
            }
            guard let expireTime = reminder.expireTime else {
                DocsLogger.error("[VOTE] expireTime is empty")
                return
            }
            let timestamp = Int(expireTime * 1000)
            self.model?.jsEngine.callFunction(DocsJSCallBack(reminderCallback), params: ["expireTime": timestamp], completion: nil)
        }
        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            reminderVC.modalPresentationStyle = .formSheet
            reminderVC.preferredContentSize = contentSize
        } else {
            reminderVC.modalPresentationStyle = .overFullScreen
        }
        navigator?.presentViewController(reminderVC, animated: true, completion: nil)
    }
}
