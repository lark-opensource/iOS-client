//
//  ReminderViewController+Action.swift
//  SpaceKit
//
//  Created by nine on 2019/10/15.
//

import SKFoundation
import SKCommon
import SKResource
import UniverseDesignDialog
import UniverseDesignToast


extension ReminderViewController {

    /// 退出时事件
    func tryCancel() {
        if !isCreatingNewReminder, reminder == oldReminder {
            cancelCallBack?()
            dismiss(animated: true)
            SheetTracker.report(event: .editReminder(old: oldReminder, new: reminder), docsInfo: self.context.docsInfo)
        } else {
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.SKResource.Doc_Reminder_CloseConfirm)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Reminder_Confirm, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.statisticsCallBack?("click_confirm_quit")
                self.cancelCallBack?()
                self.dismiss(animated: true, completion: nil)
                SheetTracker.report(event: .editReminder(old: self.oldReminder, new: self.reminder), docsInfo: self.context.docsInfo)
            })
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Reminder_Cancel, dismissCompletion: { [weak self] in
                self?.statisticsCallBack?("click_continue_edit")
            })
            present(dialog, animated: true)
        }
        callBackActionOrNot = true
    }

    func trySave() {
        if let users = reminder.notifyUsers, users.isEmpty, reminder.notifyStrategy != .noAlert {
            showNoUserToNoticeAlert()
            return
        }
        if let text = textItemView.textView.text, text.count > 1000 {
            showIllegalInputAlert(title: BundleI18n.SKResource.Doc_Reminder_Note_Fail_Title,
                                  message: BundleI18n.SKResource.Doc_Reminder_Note_Max_BodyText,
                                  cancelAction: { [weak self] in
                                    self?.textItemView.textView.text = self?.reminder.notifyText
                                    self?.textItemView.textView.endEditing(true)
                                  },
                                  reEditAction: { [weak self] in
                                    let endIndex = text.index(text.startIndex, offsetBy: 1000)
                                    let truncatedText = String(text[text.startIndex ..< endIndex])
                                    self?.textItemView.textView.text = truncatedText
                                    self?.reminder.notifyText = truncatedText
                                    self?.textItemView.textView.becomeFirstResponder()
                                  })
            return
        }
        statisticsCallBack?("click_save")
        
        if context.config.showDeadlineTips, let expireTime = reminder.expireTime, !checkExpireTime(expireTime) {
            DocsLogger.error("expireTime is invalid:\(expireTime)")
            setupInvalidTimeTipsItemView(isShow: true)
            return
        }
        
        saveReminderCallback(reminder)
        dismiss(animated: true, completion: nil)
        callBackActionOrNot = true
        SheetTracker.report(event: .editReminder(old: oldReminder, new: reminder), docsInfo: self.context.docsInfo)
    }

    func directCancel() {
        if !callBackActionOrNot {
            cancelCallBack?()
        }
    }

    func showIllegalInputAlert(title: String, message: String, cancelAction: @escaping () -> Void, reEditAction: @escaping () -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: message)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Reminder_Button_Cancel, dismissCompletion: { [weak dialog] in
            dialog?.dismiss(animated: true, completion: {
                cancelAction()
            })
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Reminder_Button_Reedit, dismissCompletion: { [weak dialog] in
            dialog?.dismiss(animated: true, completion: {
                reEditAction()
            })
        })
        present(dialog, animated: true)
    }

    func showNoUserToNoticeAlert() {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Reminder_FillNotifyPerson)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Reminder_Button_Reedit, dismissCompletion: { [weak dialog] in
            dialog?.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.setNoticePicker(isHidden: true, scrollsToBottom: false)
                self.setTimePicker(isHidden: true, scrollsToBottom: false)
                self.showUserPicker()
            }
        })
        present(dialog, animated: true)
    }
}
