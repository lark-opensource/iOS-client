//
//  EventDetailNavigationBarViewModel+Transfer.swift
//  Calendar
//
//  Created by Rico on 2021/4/13.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignActionPanel
import UniverseDesignToast
import LarkAlertController
import UniverseDesignDialog
import EENavigator
import UniverseDesignFont

/// 转让逻辑链条比较长，可以优化
/// 重复性日程确认 -> 选人 -> 弹窗提醒是否退出 -> 结束

extension EventDetailNavigationBarViewModel {
    func transfer() {

        EventDetail.logInfo("transfer action start")
        CalendarTracerV2.EventMore.traceClick {
            $0.click("transfer").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }
        if let schemaLink = event.dt.schemaLink(key: .transfer) {
            rxRoute.accept(.url(url: schemaLink))
            return
        }
        if event.dt.isRecurrence || event.dt.isException {
            rxRoute.accept(.actionSheet(title: BundleI18n.Calendar.Calendar_Transfer_RepeatConfirm, confirm: { [weak self] in
                guard let `self` = self else { return }
                self.getChattersIfNeeded()
            }))
        } else {
            self.getChattersIfNeeded()
        }
    }

    func getChattersIfNeeded() {
        // 共享日历不需要选人组件过滤 organizer 的逻辑
        guard let event = model.event else {
            return
        }

        if model.getCalendar(calendarManager: self.calendarManager)?.type == .other {
            transferWithChatId()
        } else {
            self.calendarApi?.getChatters(calendarIDs: [event.organizerCalendarID])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatters) in
                    guard let `self` = self else { return }
                    let organlizerChatId = chatters.keys.first
                    self.transferWithChatId(organlizerChatId: organlizerChatId)
                }).disposed(by: disposeBag)
        }
    }

    func transferWithChatId(organlizerChatId: String? = nil) {
        rxRoute.accept(.transferChat(organizer: organlizerChatId ?? "", confirm: { [weak self] (transferUserName, transferUserId, currentController) in
            guard let self = self else { return }
            let isShareCalendar = (self.calendar?.type == .other)
            self.tansferWithACK(transferUserName: transferUserName,
                                transferUserId: transferUserId,
                                currentController: currentController,
                                isShareCalendar: isShareCalendar)
        }))
    }

    func tansferWithACK(transferUserName: String, transferUserId: String, currentController: UIViewController, isShareCalendar: Bool) {

        EventDetail.logInfo("tranfer with ack: name: \(transferUserName), id: \(transferUserId), isshareCalendar: \(isShareCalendar)")
        let isCrossTenant = event.isCrossTenant ? "yes" : "no"
        let doTransfer: (Bool) -> Void = { [weak self] (removeOriginalOrganizer) in
            let calendarType = isShareCalendar ? "subscribe_calendar" : "user_calendar"
            self?.tansferEvent(with: transferUserId, pickerController: currentController, calendarType: calendarType, isCrossTenant: isCrossTenant, removeOriginalOrganizer: removeOriginalOrganizer)
        }
        self.calendarApi?.checkCollaborationPermissionIgnoreError(uids: [transferUserId])
            .observeOn(MainScheduler.instance)
            .subscribeForUI { [weak self] forbiddenIDs in
                guard let self = self else { return }
                guard !forbiddenIDs.contains(transferUserId) else {
                    UDToast.showTips(with: I18n.Calendar_G_CreateEvent_UserList_CantInvite_Hover, on: currentController.view)
                    return
                }
                if isShareCalendar {
                    let transferExplanationInfo = BundleI18n.Calendar.Calendar_Transfer_TransferEventFromSharedCalendar
                    self.showTransferAlert(transferUserName: transferUserName,
                                           transferExplanationInfo: transferExplanationInfo,
                                           confirmInfo: BundleI18n.Calendar.Calendar_Common_Transfer,
                                           currentController: currentController,
                                           confirmAction: {
                        doTransfer(true)
                    })
                } else {
                    let pop = UDActionSheet(config: UDActionSheetUIConfig(style: .normal, isShowTitle: true))
                    pop.setTitle(BundleI18n.Calendar.Calendar_MV_OriginalOrganizerKeepsEventOrNot_Desc)
                    pop.addDefaultItem(text: BundleI18n.Calendar.Calendar_MV_TheyKeepEvent_Button) {
                        doTransfer(false)
                        CalendarTracerV2.EventTransfer.traceClick {
                            $0.click("stay")
                            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                        }
                    }
                    pop.addDefaultItem(text: BundleI18n.Calendar.Calendar_MV_TheyDontKeepEvent_Button) {
                        doTransfer(true)
                        CalendarTracerV2.EventTransfer.traceClick {
                            $0.click("exit")
                            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
                        }
                    }
                    pop.setCancelItem(text: BundleI18n.Calendar.Calendar_Common_Cancel)
                    currentController.present(pop, animated: true, completion: nil)
                }
            }
            .disposed(by: disposeBag)
    }

    private func showTransferAlert(transferUserName: String,
                                   transferExplanationInfo: String,
                                   confirmInfo: String,
                                   currentController: UIViewController,
                                   confirmAction: @escaping () -> Void) {
        let transferConfirmInfo = BundleI18n.Calendar.Calendar_Transfer_ConfirmTransfer(name: transferUserName)
        let message = transferExplanationInfo + transferConfirmInfo

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Calendar.Calendar_Transfer_Transfer)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.Calendar.Calendar_Common_Cancel)
        alertController.addPrimaryButton(text: confirmInfo, dismissCompletion: {
            confirmAction()
        })

        currentController.present(alertController, animated: true)
    }

    func tansferEvent(with userId: String, pickerController: UIViewController, calendarType: String, isCrossTenant: String, removeOriginalOrganizer: Bool) {
        guard let event = model.event else {
            return
        }

        CalendarTracer.shareInstance.calTransferEvent(eventType: event.type == .meeting ? .meeting : .event,
                                                      eventId: event.serverID,
                                                      transferUserId: userId,
                                                      calendarType: calendarType,
                                                      isCrossTenant: isCrossTenant,
                                                      removeOriginalOrganizer: removeOriginalOrganizer)

        monitor.track(.start(.transfer))
        self.calendarApi?
            .transferEvent(with: event.calendarID, key: event.key, originalTime: event.originalTime, userId: userId, removeOriginalOrganizer: removeOriginalOrganizer)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                EventDetail.logInfo("tranfer success")
                let navigator = self.userResolver.navigator
                self.monitor.track(.success(.transfer, self.model, [:]))
                let transferCompleted = {
                    if res.hasTransferBitableURL,
                       var url = URL(string: res.transferBitableURL),
                       let topVC = navigator.mainSceneTopMost {
                        let dialog = UDDialog()
                        dialog.setTitle(text: I18n.Calendar_Event_TransferredEventAlsoData)
                        dialog.addSecondaryButton(text: I18n.Calendar_Event_LaterButton)
                        dialog.addPrimaryButton(text: I18n.Calendar_Event_GoToTransferClick, dismissCompletion: {
                            let type = "from_vc_bot_transfer_checkin"
                            url = url.append(parameters: ["ccm_open_type": type, "from": type])
                            navigator.present(url, from: topVC)
                        })
                        navigator.present(dialog, from: topVC)
                    }
                }
                self.rxRoute.accept(.transferDone(.success(pickerController), transferCompleted: transferCompleted))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                EventDetail.logError("transfer error: \(error)")
                self.monitor.track(.failure(.transfer, self.model, error, [:]))
                self.rxRoute.accept(.transferDone(.failure(error), transferCompleted: {}))
            }).disposed(by: self.disposeBag)
    }
}
