//
//  ReadReceiptDataManager.swift
//  MailSDK
//
//  Created by Ender on 2023/9/13.
//
// 注：PM 要求
// 1. 回执发送中退出读信，继续发送回执
// 2. 退出读信再回去依然能显示 Loading
// 3. 发送结果返回后，无论是否在读信页，都显示 Toast
// 因此采用用户态单例模式，维护正在发送中的请求 & 状态
// 跟随 UserContext

import Foundation
import RxSwift
import LKCommonsLogging
import UniverseDesignToast

protocol ReadReceiptDelegate: AnyObject {
    func hideReadReceiptBanner(threadID: String, messageID: String)
    func hideReadReceiptBannerLoading(threadID: String, messageID: String)
}

class ReadReceiptDataManager {

    let disposeBag = DisposeBag()

    var fetcher: DataService?

    var sendingMessages: Set<String> = []
    weak var delegate: ReadReceiptDelegate?

    init(dataService: DataService) {
        self.fetcher = dataService
    }
}

extension ReadReceiptDataManager {
    func dontSendReadReceipt(threadID: String, messageID: String, fromLabelID: String, on view: UIView) {
        self.fetcher?.dontSendReadReceipt(threadID: threadID,
                                          messageID: messageID,
                                          fromLabelID: fromLabelID).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.hideReadReceiptBanner(threadID: threadID, messageID: messageID)
        }, onError: { error in
            MailLogger.error("[Read Receipt] handle dont send receipt error:\(error)")
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: view)
        }).disposed(by: disposeBag)
    }

    func sendReadReceipt(threadID: String, messageID: String, msgTimestamp: Int64, languageId: String, on view: UIView) {
        guard let fetcher = fetcher else { return }
        sendingMessages.insert(messageID) // 标记这封邮件正在回复
        // 处理引用区的邮件时间 - 发送时间
        var messageTimestamp = msgTimestamp / 1000
        if messageTimestamp == 0 {
            messageTimestamp = Int64(Date().timeIntervalSince1970)
        }
        let sendTime = fetcher.getReadReceiptTimeText(timestamp: messageTimestamp, languageId: languageId)

        // 处理回执邮件的时间 - 阅读时间
        let readTime = fetcher.getReadReceiptTimeText(timestamp: Int64(Date().timeIntervalSince1970), languageId: languageId)
        fetcher.sendReadReceipt(messageID: messageID,
                                sendTime: sendTime,
                                readTime: readTime).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            MailLogger.error("[Read Receipt] handle send receipt success.")
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ReadReceipt_SentSuccessfully_Toast, on: view)
            self.sendingMessages.remove(messageID)
            self.delegate?.hideReadReceiptBanner(threadID: threadID, messageID: messageID)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            MailLogger.error("[Read Receipt] handle send receipt error:\(error)")
            if error.mailErrorCode == MailErrorCode.cantSendExternal {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ReadReceipt_UnableToSendReachOutAgain_Toast, on: view)
            } else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ReadReceipt_SentFailure_Toast, on: view)
            }
            self.sendingMessages.remove(messageID)
            self.delegate?.hideReadReceiptBannerLoading(threadID: threadID, messageID: messageID)
        }).disposed(by: disposeBag)
    }
}
