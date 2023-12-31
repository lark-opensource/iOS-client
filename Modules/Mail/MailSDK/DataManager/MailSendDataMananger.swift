//
//  MailSendDataMananger.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/26.
//

import Foundation
import RxSwift
import LKCommonsLogging
import RustPB
import LarkUIKit
import EENavigator

class MailSendDataMananger {
    static let shared = MailSendDataMananger()

    static let logger = Logger.log(MailModelManager.self, category: "Module.MailManager")

    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }

    init() {
        
    }
}

// MARK: interface
extension MailSendDataMananger {
    func sendMail(_ mail: MailDraft, replyMailId: String, scheduleSendTime: Int64, sendVC: LkNavigationController, fromVC: UIViewController, navigator: Navigatable, feedCardId: String?) -> Observable<(mailItem: MailItem, uuid: String)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let draftId = mail.id
        return fetcher.sendMail(mail, replyMailId: replyMailId, scheduleSendTime: scheduleSendTime, feedCardId: feedCardId)
            .map { (message: MailMessage, threadId: String, uuid: String) in
                // if other toast is shown, don't show success toast
                // ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_Toast_EmailSent)
                if scheduleSendTime > 0 {
                    MailUndoToastFactory.showScheduleSendToast(by: draftId, scheduleSendTime: scheduleSendTime, sendVC: sendVC, fromVC: fromVC, navigator: navigator, feedCardID: feedCardId)
                } else {
                    MailUndoToastFactory.showSendMailToast(by: uuid, draftId: draftId, sendVC: sendVC, fromVC: fromVC, navigator: navigator, feedCardID: feedCardId)
                }
                let event = NewCoreEvent(event: .email_send_status_toast_view)
                event.params = ["status": "success",
                ]
                event.post()
                var messageitem = MailMessageItem()
                messageitem.message = message.toPBModel() // 保存草稿时 editor的数据json转draft pb
                let item = MailItem(threadId: "",
                                    messageItems: [messageitem],
                                    composeDrafts: [],
                                    labels: [],
                                    code: .none,
                                    isExternal: false,
                                    isFlagged: false,
                                    isRead: false,
                                    isLastPage: true)
                return (mailItem: item, uuid: uuid)
            }
            .do(onError: { (error) in
                // ActionToast.showFailureToast(with: BundleI18n.MailSDK.Mail_Toast_CouldNotBeSent)
                let event = NewCoreEvent(event: .email_send_status_toast_view)
                event.params = ["status": "failed"]
                event.post()
                MailSendDataMananger.logger.error("sendMail failed", error: error)

                if FeatureManager.open(.newOutbox) {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_FailedtoSendSavedtoOutbox_toast, on: fromVC.view)
                } else if Store.settingData.mailClient {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_UnableToSend, on: fromVC.view)
                } else {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_CouldNotBeSent, on: fromVC.view)
                }
            })
    }

    func getScheduleSendMessageCount() -> Observable<(Email_Client_V1_MailGetScheduleMessageCountResponse)> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.getScheduleSendMessageCount()
    }

    func createDraft(with messageID: String?, threadID: String?, msgTimestamp: Int64?, action: DraftAction, languageId: String?) -> Observable<Email_Client_V1_MailCreateDraftResponse> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        
        return fetcher.createDraft(with: messageID,
                                        threadID: threadID,
                                        msgTimestamp: msgTimestamp,
                                        action: action,
                                        languageId: languageId)
            .do(onError: { (error) in
                MailSendDataMananger.logger.error("createNewDraft failed messageID:\(messageID ?? "")", error: error)
            })
    }

    func updateDraftAndGetThreadID(draft: MailDraft, isdelay: Bool, feedCardId: String?) -> Observable<String> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.updateDraft(draft: draft, isdelay: isdelay, feedCardId: feedCardId)
            .do(onNext: { _ in
                MailSendDataMananger.logger.info("updateDraft succ")
            }, onError: { (error) in
                MailSendDataMananger.logger.error("updateDraft failed", error: error)
            })
            .map { $0.threadID }
    }

    func downloadImg(urlStr: String, localPath: String) -> Observable<String> {
        guard let fetcher = fetcher else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return fetcher.downloadNormal(remoteUrl: urlStr, localPath: localPath)
            .do(onError: { (error) in
                mailAssertionFailure("error in download drive img \(error)")
            })
            .map { $0.key }
    }
}
