//
//  MailUndoToastFactory.swift
//  MailSDK
//
//  Created by majx on 2020/8/25.
//

import Foundation
import EENavigator
import LarkUIKit
import UniverseDesignToast

struct MailUndoToastFactory {
    static func showSendMailToast(by uuid: String, draftId: String, sendVC: LkNavigationController, fromVC: UIViewController, navigator: Navigatable, feedCardID: String?) {
        if !Store.settingData.mailClient && MailUndoTaskManager.default.sendConfig.enable {
            guard let mailSetting = Store.settingData.getCachedCurrentSetting() else { return }
            let toastContainer = mailToastLayerView()
            fromVC.view.addSubview(toastContainer)
            toastContainer.setupView()
            UDToast.removeToast(on: toastContainer)
            let time = mailSetting.undoTime
            let toast = UDToast()
            let operation = UDToastOperationConfig(text: BundleI18n.MailSDK.Mail_UndoCountdown_Button(time), displayType: .auto)
            toast.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_EmailSent,
                              operation: operation,
                              on: toastContainer,
                              delay: TimeInterval(time * 2), // 有冗余，因为秒数刷新可能丢帧，使得真正显示时间长于设置时间
                              operationCallBack: { _ in
                UDToast.removeToast(on: toastContainer)
                toastContainer.removeFromSuperview()
                MailTracker.toastCancelSendLog()

                MailUndoTaskManager.default.undo(feedCardID: feedCardID) {
                    navigator.present(sendVC, wrap: nil, from: fromVC, prepare: nil, animated: true) { [weak sendVC] in
                        if let sendView = sendVC?.view {
                            UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_SendingUndone, on: sendView)
                        }
                    }
                    if let vc = sendVC.viewControllers.first as? MailSendController {
                        vc.draftSent = false
                        vc.undoReloadDraft()
                        vc.scrollContainer.webView.focus()
                    }
                } onError: {
                    ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_Toast_UndoFailed, on: toastContainer)
                    InteractiveErrorRecorder.recordError(event: .undo_failed, tipsType: .toast)
                }
            })
            MailUndoTaskManager.default.update(type: .send, uuid, draftId, onUpdate: { timeLeave in
                let operation = UDToastOperationConfig(text: BundleI18n.MailSDK.Mail_UndoCountdown_Button(timeLeave), displayType: .auto)
                toast.updateToast(with: BundleI18n.MailSDK.Mail_Toast_EmailSent,
                                  superView: toastContainer,
                                  operation: operation)
            }, onDismiss: {
                UDToast.removeToast(on: toastContainer)
                toastContainer.removeFromSuperview()
            })
        } else {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_EmailSent, on: fromVC.view)
        }
    }

    static func showMailActionToast(by uuid: String, type: MailUndoTask.UndoTaskType, fromLabel: String, toastText: String, on view: UIView, feedCardID: String?) {
        var action: String? = nil
        var autoDismiss: Bool = true
        let fromWindow: UIView? = view.window
        MailUndoTaskManager.default.update(type: .trash, uuid, nil, onUpdate: nil, onDismiss: {
            ActionToast.removeToast(on: fromWindow ?? view)
        })
        action = BundleI18n.MailSDK.Mail_Toast_Undo
        autoDismiss = false
        if Store.settingData.mailClient {
            action = nil
            autoDismiss = true
        }
        ActionToast.showSuccessToast(with: toastText,
                                     on: view,
                                     action: action,
                                     autoDismiss: autoDismiss,
                                     dissmissOnTouch: true,
                                     dissmissDuration: type == .archive ? 0 : timeIntvl.toastDismiss) {
            ActionToast.removeToast(on: fromWindow ?? view)
            /// undo埋点
            MailTracker.log(event: "email_action_toast_click", params: ["click": "action_recall", "action_type": type.rawValue, "label_item": fromLabel])
            MailUndoTaskManager.default.undo(feedCardID:feedCardID) {
                ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_Toast_ActionUndone, on: view)
            } onError: {
//                ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_Toast_ActionUndone)
            }
        }
    }

    static func showScheduleSendToast(by draftId: String, scheduleSendTime: Int64, sendVC: LkNavigationController, fromVC: UIViewController, navigator: Navigatable, feedCardID: String?) {
        var action: String? = nil
        var autoDismiss: Bool = true
        action = BundleI18n.MailSDK.Mail_Toast_Undo
        autoDismiss = true
        if Store.settingData.mailClient {
            action = nil
            autoDismiss = true
        }
        let timeStr = ProviderManager.default.timeFormatProvider?.mailScheduleSendTimeFormat(scheduleSendTime / 1000)
        // iPad上多scene场景，presentingVC.view.window 为空会导致toast在错的window
        let toastView: UIView = (fromVC.view.window ?? sendVC.view.window) ?? fromVC.view
        ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_SendLater_ScheduledForDate(timeStr ?? ""),
                                     on: toastView,
                                     action: action,
                                     autoDismiss: autoDismiss,
                                     dissmissOnTouch: true,
                                     dissmissDuration: 7) {
            MailTracker.log(event: "email_thread_scheduledSend_undo", params: nil)
            if let vc = sendVC.viewControllers.first as? MailSendController {
                vc.clearScheduleSendTime()
                vc.draftSent = false
            }
            ActionToast.removeToast(on: toastView)
            MailDataServiceFactory.commonDataService?.cancelScheduleSend(by: draftId, threadIds: [], feedCardID: feedCardID)
                .subscribe(onNext: { (_) in
                    navigator.present(sendVC, wrap: nil, from: fromVC, prepare: nil, animated: true) { [weak sendVC] in
                        if let sendView = sendVC?.view {
                            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_SendLater_Cancelsucceed, on: sendView)
                        }
                    }
                }, onError: { (error) in
                    ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_SendLater_CancelFailure, on: fromVC.view)
                    InteractiveErrorRecorder.recordError(event: .schedule_send_cancel_fail)
                })
        }
    }
}

class mailToastLayerView: UIView {
    
    func setupView() {
        self.snp.makeConstraints{ (make) in
            make.edges.equalToSuperview()
        }
        self.isUserInteractionEnabled = true
        self.isHidden = false
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        guard !isHidden else { return nil }
        guard self.point(inside: point, with: event) else { return nil }
        for subview in self.subviews {
            let relatePoint = self.convert(point, to: subview)
            if let candidate = subview.hitTest(relatePoint, with: event) {
                return candidate
            } else {
                UDToast.removeToast(on: self)
                self.removeFromSuperview()
                MailUndoTaskManager.default.reset()
                break
            }
        }
        return self.superview
    }
}
