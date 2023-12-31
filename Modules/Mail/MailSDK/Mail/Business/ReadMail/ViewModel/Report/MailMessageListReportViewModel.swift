//
//  MailMessageListControllerViewModel+Report.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/6/4.
//

import Foundation
import RxSwift

class MailMessageListReportViewModel {
    private weak var delegate: MailMessageListControllerViewModeling?
    private let disposeBag = DisposeBag()
    private var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }
    init(delegate: MailMessageListControllerViewModeling) {
        self.delegate = delegate
    }
    private func logBannerClick(action: String, labelItem: String, riskReason: String, riskLevel: String) {
        MailTracker.log(event: "email_risk_banner_click", params: ["click": action, "label_item": labelItem, "risk_reason": riskReason, "risk_level": riskLevel])
    }
    /// 举报邮件
    func reportMessage(threadID: String, messageID: String, fromLabelID: String, messageCount: Int, logLabelID: String, ignoreUnauthorized: Bool, riskReason: String, riskLevel: String, feedCardId: String? = nil) {
        let addLabelIDs: [String]
        var toastText: String = ""
        if fromLabelID == Mail_LabelId_Trash || fromLabelID == Mail_LabelId_Spam {
            // 不需要改变label
            addLabelIDs = []
            toastText = BundleI18n.MailSDK.Mail_ReportTrash_ReportedMobile
        } else {
            // 从其他地方操作
            addLabelIDs = [Mail_LabelId_Spam]
            // 移到Spam，需要删除message
            if messageCount > 1 {
                delegate?.callJSFunction("removeMessage", params: [messageID, "\(true)"], withThreadId: threadID, completionHandler: nil)
            }
            toastText = BundleI18n.MailSDK.Mail_ReportTrash_ReportedMovedToTrashMobile
        }
        if FeatureManager.open(.newSpamPolicy) {
            toastText = BundleI18n.MailSDK.Mail_MarkedAsSpam_Toast
        }
        fetcher?.report(threadID: threadID, messageID: messageID, fromLabelID: fromLabelID, addLabelIDs: addLabelIDs, ignoreUnauthorized: ignoreUnauthorized, feedCardId: feedCardId)
            .subscribe(onNext: { (_) in
                MailLogger.info("Mail report message success \(threadID) \(messageID)")
            }, onError: { (error) in
                MailLogger.info("Mail report message error \(error)")
            }).disposed(by: self.disposeBag)
        delegate?.showSuccessToast(toastText)
        logBannerClick(action: "report_spam", labelItem: logLabelID, riskReason: riskReason, riskLevel: riskLevel)
    }
    /// 标为正常
    func trustMessage(threadID: String, messageID: String, fromLabelID: String, messageCount: Int, logLabelID: String, ignoreUnauthorized: Bool, riskReason: String, riskLevel: String, feedCardId: String? = nil) {
        fetcher?.trust(threadID: threadID, messageID: messageID, fromLabelID: fromLabelID, ignoreUnauthorized: ignoreUnauthorized, feedCardId: feedCardId)
            .subscribe(onNext: { (_) in
                MailLogger.info("Mail trustMessage success \(threadID) \(messageID)")
            }, onError: { (error) in
                MailLogger.info("Mail trustMessage error \(error)")
            }).disposed(by: self.disposeBag)
        if messageCount > 1 {
            delegate?.callJSFunction("removeMessage", params: [messageID, "\(true)"], withThreadId: threadID, completionHandler: nil)
        }
        let toastText = FeatureManager.open(.newSpamPolicy)
        ? BundleI18n.MailSDK.Mail_UnmarkedSpamMovetoInbox_Toast
        : BundleI18n.MailSDK.Mail_ReportTrash_LabelNormalMovedToInboxMobile
        delegate?.showSuccessToast(toastText)
        logBannerClick(action: "not_spam", labelItem: logLabelID, riskReason: riskReason, riskLevel: riskLevel)
    }
    /// 关闭banner
    func closeSafetyBanner(threadID: String, messageID: String, fromLabelID: String, logLabelID: String, riskReason: String, riskLevel: String, feedCardId: String? = nil) {
        fetcher?.closeSafetyBanner(threadID: threadID, messageID: messageID, fromLabelID: fromLabelID, feedCardId: feedCardId)
            .subscribe(onNext: { (_) in
                MailLogger.info("Mail closeSafetyBanner success \(threadID) \(messageID)")
            }, onError: { (error) in
                MailLogger.info("Mail closeSafetyBannerv error \(error)")
            }).disposed(by: self.disposeBag)
        logBannerClick(action: "close", labelItem: logLabelID, riskReason: riskReason, riskLevel: riskLevel)
    }
    /// ChangeLog更新时，对比新旧MailItem
    func onMailItemUpdate(newMailItem: MailItem, oldMailItem: MailItem) {
        for oldMessage in oldMailItem.messageItems {
            if let newMessage = newMailItem.messageItems.first(where: { $0.message.id == oldMessage.message.id }) {
                // message 还存在，更新状态
                // 更新状态
                let newSecurityInfo = newMessage.message.security
                let oldSecurityInfo = oldMessage.message.security
                if newSecurityInfo != oldSecurityInfo {
                    let isRisky = newSecurityInfo.isSuspect || newSecurityInfo.isPhishing || newSecurityInfo.isSpoof
                    delegate?.callJSFunction("updateSafetyBanner",
                                             params: [newMessage.message.id,
                                                      "\(isRisky)",
                                                      "\(newSecurityInfo.reportType.rawValue)"],
                                             withThreadId: newMailItem.threadId,
                                             completionHandler: nil)
                }
            } else {
                // message 被删除
                // call remove message
                delegate?.callJSFunction("removeMessage", params: [oldMessage.message.id, "\(false)"], withThreadId: newMailItem.threadId, completionHandler: nil)
            }
        }
    }
}
