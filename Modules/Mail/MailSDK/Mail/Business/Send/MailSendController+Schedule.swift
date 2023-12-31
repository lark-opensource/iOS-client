//
//  MailSendController+Schedule.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation

extension MailSendController: MailScheduleSendDelegate {
    func didSetScheduleSendTime(_ timestamp: Int64) {
        scheduleSendTime = timestamp
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_SendLater_Scheduling, on: self.view)
        sendButton?.isEnabled = false
        let delayTime: Double = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
            guard let `self` = self else { return }
            self.scheduleSend()
            self.sendButton?.isEnabled = true
            //MailRoundedHUD.remove(on: self.view)
            self.removeScheduleLoading = true
        }
    }

    func scheduleSend() {
        func startSend() {
//            MailTracker.startRecordTimeConsuming(event: "email_apm_send_draft", params: nil)
            apmMarkSendStart()
            prepareMailContent(.scheduleSend)
        }
        /// before send, check if more than 100 schedule
        if !Store.settingData.mailClient {
            _ = dataManager.getScheduleSendMessageCount().subscribe(onNext: { (resp) in
                if resp.scheduleSendMessageCount < 100 {
                    MailLogger.info("mail send get schedule message count then send")
                    startSend()
                } else {
                    MailLogger.info("mail send get schedule message count more than 100")
                }
            }, onError: { _ in
                MailLogger.info("mail send get many schedule error then send")
                startSend()
            })
        } else {
            startSend()
        }
        // core event
        let event = NewCoreEvent(event: .email_email_edit_click)
        let (attNum, largeAttNum) = self.getSuccessUploadedAttachmentsCount()
        event.params = ["target": "none",
                        "click": "time_send",
                        "label_item": baseInfo.statInfo.newCoreEventLabelItem,
                        "large_attachment": largeAttNum,
                        "attachment": attNum]
        if let draft = draft {
            event.params["sender_id"] = ["user_id": draft.content.from.larkID.encriptUtils(),
                                         "mail_id": draft.content.from.address.lowercased().encriptUtils(),
                                         "mail_type": (draft.content.from.type ?? .unknown).rawValue]
            var receIds : [[String: Any]] = []
            for address in viewModel.sendToArray {
                if address.larkID.isEmpty || address.larkID == "0" {
                    let receId = ["user_id": address.address.lowercased().encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                } else {
                    let receId = ["user_id": address.larkID.encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                }
            }
            for address in viewModel.ccToArray {
                if address.larkID.isEmpty || address.larkID == "0" {
                    let receId = ["user_id": address.address.lowercased().encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                } else {
                    let receId = ["user_id": address.larkID.encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                }
            }
            for address in viewModel.bccToArray {
                if address.larkID.isEmpty || address.larkID == "0" {
                    let receId = ["user_id": address.address.lowercased().encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                } else {
                    let receId = ["user_id": address.larkID.encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                }
            }
            if let stringData = try? JSONSerialization.data(withJSONObject: receIds, options: []),
               let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                event.params["rece_id"] = JSONString as String
            }
            event.params["send_timestamp"] = Int(Date().timeIntervalSince1970 * 1000)
        }
        event.post()
    }
}
