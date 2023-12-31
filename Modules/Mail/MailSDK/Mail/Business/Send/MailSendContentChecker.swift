//
//  MailSendContentChecker.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/1/3.
//

import Foundation
import LarkAlertController
import UniverseDesignDialog
import EENavigator
import RustPB

typealias MailUserType = Email_Client_V1_Setting.UserType

protocol MailSendContentCheckerDelegate: AnyObject {
    func refreshInputView(mailContent: MailContent)
    func saveContentAndShowAlert(result: MailSendContentChecker.SendEnableCheckResult,
                                 mailContent: MailContent,
                                 title: String?,
                                 leftTitle: String?,
                                 rightTitle: String,
                                 content: String,
                                 sendHandler: (() -> Void)?)
    func checkDocsUrlBeforeSend(docsLinks: [MailClientDocsPermissionConfig], mailContent: MailContent, nextStepHandler: @escaping (_ content: MailContent) -> Bool)
    func checkDriveAttachmentExternalBeforeSend(mailContent: MailContent, nextStepHandler: @escaping (_ content: MailContent) -> Bool)
    func checkDriveAttachmentPermissionBeforeSend(mailContent: MailContent, nextStepHandler: @escaping (_ content: MailContent) -> Bool)
    func showAlert(alert: LarkAlertController)
    func showCustomAlert(alert: LarkAlertController, content: String)
    func moveBccTocc()
    func disableSendSep()
    func needShowDocLinkAlert(urls: [String],
                              directlySendBlock: @escaping () -> Void,
                              showAlertBlock: @escaping () -> Void)
    func checkDocLinkBeforeSend(mailContent: MailContent,
                                                nextStepHandler: @escaping (_ content: MailContent) -> Bool)
}

enum TipsTypeSendCheck: Int {
    case invalidFile    /// 不给发的附件，目前包括过期、封禁、有害 (二期新增已删除
    case largeFilePermission   /// 大附件分享到外部
    case docsUrlCheck   /// 含有docs的邮件分享到外部，
    case titleMissing   /// 无标题和内容
    case largeFileExternal  /// 大附件是否可分享
    case calendarHasBcc         /// 日历中含有密送
    case calendarExpired        /// 日历时间过期提醒
    case calendarSendSep        /// 分别发送
    case recipientOverLimit   /// 大规模发信弹窗提醒
    case documentShare              /// 云文档未开启链接分享
}

struct MailSendContentChecker {
    enum SendEnableCheckResult {
        case avaliable                  /// 可发送
        case noRecipients               /// 无收件人
        case invailEmailAddress         /// 邮件地址错误
        case restrictOutbound           /// 限制外发
        case overLimitRecipients        /// 收件人超过数量
        case attachmentsSending         /// 附件正在上传
        case imagesIsSending            /// 图片正在上传
        case coverSending               /// 封面上传/加载
        case attachmentsUploadError     /// 附件上传失败
        case imagesUploadError          /// 图片上传失败
        case coverUploadError           /// 封面上传/加载失败
        case overLimitSize              /// 邮件超过限制大小
        case calendarMailGroup          /// 地址中有邮件组的
    }
    var userType: MailUserType = .larkServer
    var mailLimitSize: Int64 {
        let gmailLimit: Int64 = 25 // GC 限制 25MB，超过会发信失败
        let defaultLimit: Int64 = 50
        if userType == .newUser || userType == .oauthClient || userType == .gmailApiClient {
            return gmailLimit
        } else {
            return defaultLimit
        }
    }
    /// 收件人数量限制  LarkMailService - 500 | GmailClient  - 100
    // disable-lint: magic_number
    var recipientsLimit: Int {
        if userType == .larkServer {
            return 500
        } else if userType == .exchangeClient {
            return 200
        } else {
            return 100
        }
    }
    // enable-lint: magic_number

    weak var delegate: MailSendContentCheckerDelegate?
    //上传失败附件、图片计数
    var failedAttachCount: Int = 0
    var failedImgCount: Int = 0
    var imgUploading: Bool = false
    var attachUploading: Bool = false

    private let accountContext: MailAccountContext

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
    }

    mutating func updateErrorUploadCount(imgHandler:MailImageHandler?,_ attachmentViewModel: MailSendAttachmentViewModel){
        failedAttachCount = attachmentViewModel.getFailedAttachCount()
        if let imgHandler = imgHandler {
            failedImgCount = imgHandler.errorImg.count
        }
        if let imgHandler = imgHandler{
            imgUploading = imgHandler.isContainsUploadingImg
        }else {
            imgUploading = false
        }
        attachUploading = !attachmentViewModel.isFinished
    }
    
    func sendEnbleResult(_ mailContent: MailContent,
                         _ attachmentViewModel: MailSendAttachmentViewModel,
                         mailCoverState: MailCoverDisplayState,
                         calendarEvent: DraftCalendarEvent?,
                         isContainsErrorImg: Bool,
                         isContainsUploadingImg: Bool,
                         canSendExternal: Bool) -> SendEnableCheckResult {
        /// 检查项优先级文档可见：https://bytedance.feishu.cn/docs/doccnlyIeCflvILCK1AldxQ9N1g
        /// -----> 以下为必填项
        /// 1.检查是否有收件人
        let allEmailAddress = mailContent.to + mailContent.cc + mailContent.bcc
        guard !allEmailAddress.isEmpty else {
            return .noRecipients
        }
        /// 2.检查所有邮件地址是否有效
        for item in allEmailAddress {
            if !item.address.isLegalForEmail() && (item.larkID.isEmpty || item.larkID == "0") {
                return .invailEmailAddress
            }
        }
        /// 2.5. 检查是否存在外发邮件
        let allAddresses = mailContent.to + mailContent.cc + mailContent.bcc
        var containExternalAddress = false
        if let domains = accountContext.user.emailDomains {
            var domainString = ""
            for domain in domains {
                domainString = domainString + "\(domain)" + ","
            }
            for address in allAddresses.map({ $0 .address }) {
                if domains.first(where: { address.contains($0) }) == nil {
                    if !canSendExternal {
                        NotificationCenter.default.post(name: lkTokenViewNotificationName, object: address)
                    }
                    var addressCnt = address.count
                    if let atRange = address.range(of: "@") {
                        let suffixAddress = address.suffix(from: atRange.upperBound)
                        MailLogger.info("extern address is \(suffixAddress), domainString is \(domainString)，toCnt=\(mailContent.to.count), ccCnt=\(mailContent.cc.count), bccCnt=\(mailContent.bcc.count)")
                    } else {
                        MailLogger.info("address doesn't has @, len=\(addressCnt)")
                    }
                    containExternalAddress = true
                }
            }
        }
        if containExternalAddress, !canSendExternal {
            MailLogger.info("return restrictOutbound")
            return .restrictOutbound
        }

        /// 3. 检查收件人数量
        guard allEmailAddress.count <= recipientsLimit else {
            return .overLimitRecipients
        }
        
        /// 4. 检查是否有封面正在加载/上传
        if accountContext.featureManager.open(.editMailCover) {
            switch mailCoverState {
            case .none, .thumbnail, .cover:
                break
            case .loading:
                return .coverSending
            case .loadFailed:
                return .coverUploadError
            }
        }
        /// 5.检查附件是否全部上传完成
        guard attachmentViewModel.isFinished else {
            return .attachmentsSending
        }
        /// 6.检查是否存在附件上传失败
        guard !attachmentViewModel.isExistError else {
            return .attachmentsUploadError
        }
        /// 6.检查是否有图片上传失败
        guard !isContainsErrorImg else {
            return .imagesUploadError
        }
        /// 7.检查是否有图片正在上传
        guard !isContainsUploadingImg else {
            return .imagesIsSending
        }
        /// 8.检查是否有图片上传失败
        guard !isContainsErrorImg else {
            return .imagesUploadError
        }
        /// 9.自动转关闭，邮件（image+attachment）超过限定大小 25(GC) / 50(Other) MB
        if !accountContext.featureManager.open(.autoTranslateAttachment) &&
            mailContent.calculateMailSize() > Float(mailLimitSize) {
            return .overLimitSize
        }
        /// 9.1 自动转打开，邮件(image)超过限定大小 25(GC) / 50(Other) MB
        if accountContext.featureManager.open(.autoTranslateAttachment) &&
            mailContent.calculateMailSize(ignoreAttachment: true) > Float(mailLimitSize) {
            return .overLimitSize
        }
        
        let fromAddress = mailContent.from
        /// 9.2 含有日历的邮件不能发给邮件组
        if let event = calendarEvent, fromAddress.type == .enterpriseMailGroup {
            return .calendarMailGroup
        }
        return .avaliable
    }

    @discardableResult
    func sendCheckTips(type: TipsTypeSendCheck,
                       attachmentViewModel: MailSendAttachmentViewModel,
                       mailContent: MailContent,
                       calendarEvent: DraftCalendarEvent?,
                       sendSep: Bool,
                       isRecipientOverLimit: Bool,
                       recipientLimit: Int64,
                       sendHandler: @escaping (MailContent) -> Void,
                       cancelCompletion: (() -> Void)? = nil) -> Bool {
        var alert = LarkAlertController()
        let recursiveCheckBlock = { (content: MailContent) -> Bool in
            let rawValue = type.rawValue + 1
            if let nextType = TipsTypeSendCheck(rawValue: rawValue) {
                return self.sendCheckTips(type: nextType,
                                          attachmentViewModel: attachmentViewModel,
                                          mailContent: content,
                                          calendarEvent: calendarEvent,
                                          sendSep: sendSep,
                                          isRecipientOverLimit: isRecipientOverLimit,
                                          recipientLimit: recipientLimit,
                                          sendHandler: sendHandler,
                                          cancelCompletion: cancelCompletion)
            } else {
                sendHandler(content)
                return true
            }
        }
        if type == .invalidFile {
            // 按钮文本过长，UX 要求改为上下布局，取消按钮在下
            alert = LarkAlertController(config: UDDialogUIConfig(style: .vertical))
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_UnableToSendAttachments_RemoveAndSend_Title, dismissCompletion: {
                _ = recursiveCheckBlock(mailContent)
            })
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel, dismissCompletion: {
                cancelCompletion?()
            })
        } else if type == .recipientOverLimit {
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Shared_MassEmail_MassReminderNoticeEdit_Button, dismissCompletion: {
                MailCountdownTaskManager.default.reset()
                MailTracker.log(event: "email_large_mail_alert_click", params: ["click": "cancel",
                                                                                "mail_account_type": Store.settingData.getMailAccountType()])
                cancelCompletion?()
            })
        } else {
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel, dismissCompletion: {
                cancelCompletion?()
            })
        }
        
        var confirmText = BundleI18n.MailSDK.Mail_Recipients_Confirm
        if type == .calendarHasBcc ||
            type == .calendarExpired ||
            type == .calendarSendSep {
            confirmText = BundleI18n.MailSDK.Mail_Event_ContinueSend
        }
        if type == .calendarHasBcc {
            alert.addPrimaryButton(text: confirmText, dismissCompletion: {
                // 将bcc转为cc
                var mutContent = mailContent
                let bccArray = mutContent.bcc
                mutContent.bcc = []
                for bcc in bccArray where !mutContent.cc.contains(bcc) {
                    mutContent.cc.append(bcc)
                }
                // UI调整
                self.delegate?.moveBccTocc()
                _ = recursiveCheckBlock(mutContent)
            })
        } else if type == .calendarSendSep {
            alert.addPrimaryButton(text: confirmText, dismissCompletion: {
                var mutContent = mailContent
                let bccArray = mutContent.bcc
                mutContent.bcc = []
                for bcc in bccArray where !mutContent.to.contains(bcc) {
                    mutContent.to.append(bcc)
                }
                self.delegate?.disableSendSep()
                _ = recursiveCheckBlock(mutContent)
            })
        } else if type == .invalidFile {
            // 已经加过确认按钮了，这里什么也不做
        } else if type == .recipientOverLimit {
            let second: Int64 = 5   // 5s 倒计时防呆
            let btn = alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Shared_MassEmail_MassReminderNoticeSendCountdown_Button(second), dismissCompletion: {
                MailTracker.log(event: "email_large_mail_alert_click", params: ["click": "send",
                                                                                "mail_account_type": Store.settingData.getMailAccountType()])
                _ = recursiveCheckBlock(mailContent)
            })
            let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Shared_MassEmail_MassReminderNoticeSendCountdown_Button(second),
                                          attributes: [.foregroundColor: UIColor.ud.textDisabled])
            btn.setAttributedTitle(text, for: .disabled)
            btn.isEnabled = false
            MailCountdownTaskManager.default.initTask(timeSecond: second, onUpdate: { timeLeave in
                // UD 按钮改了 baseLineOffset，不能简单用 setTitle
                let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Shared_MassEmail_MassReminderNoticeSendCountdown_Button(timeLeave),
                                              attributes: [.foregroundColor: UIColor.ud.textDisabled])
                btn.setAttributedTitle(text, for: .disabled)
            }, onComplete: {
                // UD 按钮改了 baseLineOffset，不能简单用 setTitle
                let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Recipients_Confirm, attributes: [:])
                btn.setAttributedTitle(text, for: .normal)
                btn.isEnabled = true
            })
        } else {
            alert.addPrimaryButton(text: confirmText, dismissCompletion: {
                _ = recursiveCheckBlock(mailContent)
            })
        }
        
        switch type {
        case .invalidFile:
            if attachmentViewModel.isExistInvalid {
                if attachmentViewModel.isAllInvalid {
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_UnableToSendAttachmentsAll_Title(attachmentViewModel.invalidFileCount))
                } else {
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_UnableToSendAttachmentsNum_Title(attachmentViewModel.invalidFileCount))
                }
                delegate?.showAlert(alert: alert)
                InteractiveErrorRecorder.recordError(event: .send_attachment_blocked,
                                                     tipsType: .alert)
                return false
            } else {
                return recursiveCheckBlock(mailContent)
            }
        case .largeFilePermission:
            self.delegate?.checkDriveAttachmentPermissionBeforeSend(mailContent: mailContent, nextStepHandler: recursiveCheckBlock)
            return false
        case .docsUrlCheck:
            if !FeatureManager.open(.docAuthOpt, openInMailClient: false) {
                self.delegate?.checkDocsUrlBeforeSend(docsLinks: mailContent.docsConfigs, mailContent: mailContent, nextStepHandler: recursiveCheckBlock)
                return false
            } else {
                return recursiveCheckBlock(mailContent)
            }
        case .titleMissing:
            if mailContent.subject.isEmpty || mailContent.bodySummary.removeAllSpaceAndNewlines.isEmpty {
                alert.setContent(text: BundleI18n.MailSDK.Mail_Alert_NoSubAndConTipTitle, alignment: .center)
                delegate?.showAlert(alert: alert)
                return false
            } else {
                return recursiveCheckBlock(mailContent)
            }
        case .largeFileExternal:
            self.delegate?.checkDriveAttachmentExternalBeforeSend(mailContent: mailContent, nextStepHandler: recursiveCheckBlock)
            return false
        case .calendarHasBcc:
            if let _ = calendarEvent, mailContent.bcc.count > 0, sendSep == false {
                alert.setTitle(text: BundleI18n.MailSDK.Mail_Event_EventEmailCantBcc)
                alert.setContent(text: BundleI18n.MailSDK.Mail_Event_EventEmailCantBccDesc)
                delegate?.showAlert(alert: alert)
                return false
            } else {
                return recursiveCheckBlock(mailContent)
            }
        case .calendarExpired:
            if let event = calendarEvent,
               event.basicEvent.end < Int64(Date().timeIntervalSince1970) {
                alert.setContent(text: BundleI18n.MailSDK.Mail_Event_EventExpiredSendAnyway)
                delegate?.showAlert(alert: alert)
                return false
            } else {
                return recursiveCheckBlock(mailContent)
            }
        case .calendarSendSep:
            if let _ = calendarEvent, sendSep == true {
                alert.setTitle(text: BundleI18n.MailSDK.Mail_Event_UnableSendEventSeparately)
                alert.setContent(text: BundleI18n.MailSDK.Mail_Event_UnableSendEventSeparatelyDesc)
                delegate?.showAlert(alert: alert)
                return false
            } else {
                return recursiveCheckBlock(mailContent)
            }
        case .recipientOverLimit:
            if accountContext.featureManager.open(.massiveSendRemind, openInMailClient: false), isRecipientOverLimit {
                alert.setTitle(text: BundleI18n.MailSDK.Mail_Shared_MassEmail_MassReminderNotice_Title)
                alert.setContent(text: BundleI18n.MailSDK.Mail_Shared_MassEmail_MassReminderNotice_Text(recipientLimit))
                delegate?.showAlert(alert: alert)
                MailTracker.log(event: "email_large_mail_alert_view", params: ["mail_account_type": Store.settingData.getMailAccountType(),
                                                                               "target": "none"])
                return false
            } else {
                MailCountdownTaskManager.default.reset()
                return recursiveCheckBlock(mailContent)
            }
        case .documentShare:
            self.delegate?.checkDocLinkBeforeSend(mailContent: mailContent,
                                                  nextStepHandler: recursiveCheckBlock)
            return false
        }
    }

    /// 显示发送检查项的提示
    func showSendCheckResultAlert(_ result: SendEnableCheckResult, _ mailContent: MailContent, _ sendHandler: (() -> Void)?) -> Bool {
        var content = ""
        var title: String?
        var leftTitle: String?
        var rightTitle: String = BundleI18n.MailSDK.Mail_Alert_OK
        var rightHandler: (() -> Void)?
        switch result {
        case .avaliable:
            return false
        case .noRecipients:
            content = BundleI18n.MailSDK.Mail_Alert_NoRecipients
        case .invailEmailAddress:
            // 要明确告知用户是哪个地方的哪个地址出现问题了
            title = BundleI18n.MailSDK.Mail_Alert_TitleInvaildEmailAddress
            for item in mailContent.to {
                if !item.address.isLegalForEmail() && (item.larkID.isEmpty || item.larkID == "0") {
                    content = BundleI18n.MailSDK.Mail_Compose_InvalidSendTips(item.address, BundleI18n.MailSDK.Mail_Normal_To)
                    break
                }
            }

            if content.isEmpty {
                for item in mailContent.cc {
                    if !item.address.isLegalForEmail() && (item.larkID.isEmpty || item.larkID == "0") {
                        content = BundleI18n.MailSDK.Mail_Compose_InvalidSendTips(item.address, BundleI18n.MailSDK.Mail_Normal_Cc)
                        break
                    }
                }
            }

            if content.isEmpty {
                for item in mailContent.bcc {
                    if !item.address.isLegalForEmail() && (item.larkID.isEmpty || item.larkID == "0") {
                        content = BundleI18n.MailSDK.Mail_Compose_InvalidSendTips(item.address, BundleI18n.MailSDK.Mail_Normal_Bcc)
                        break
                    }
                }
            }

            // 兜底
            if content.isEmpty {
                content = BundleI18n.MailSDK.Mail_Alert_InvaildEmailAddress
            }
        case .restrictOutbound:
            content = BundleI18n.MailSDK.Mail_RestrictOutbound_NoteDesc
            leftTitle = BundleI18n.MailSDK.Mail_RestrictOutbound_Cancel
            rightTitle = BundleI18n.MailSDK.Mail_RestrictOutbound_Delete
            MailTracker.log(event: "email_restriction_popup_show", params: nil)
        case .overLimitRecipients:
            title = BundleI18n.MailSDK.Mail_Recipients_TooManyRecipients
            content = BundleI18n.MailSDK.Mail_Recipients_MaximumRecipients(recipientsLimit)
            rightTitle = BundleI18n.MailSDK.Mail_Edit_SenderLimitConfirm
        case .attachmentsSending, .imagesIsSending:
            //上传中也需要区分是图片上传 / 附件上传
            var subContent = ""
            if imgUploading && attachUploading {
                subContent = BundleI18n.MailSDK.Mail_Alert_QuitAttachmentUnfinished_ImageAndAttachment
            } else if imgUploading {
                subContent = BundleI18n.MailSDK.Mail_Alert_QuitAttachmentUnfinished_Image
            } else {
                subContent = BundleI18n.MailSDK.Mail_Alert_QuitAttachmentUnfinished_Attachment
            }
            content = BundleI18n.MailSDK.Mail_Cover_MobileUploadingNowDesc_Varibles(subContent)
        case .coverSending:
            title = BundleI18n.MailSDK.Mail_Cover_UploadingNow
            content = BundleI18n.MailSDK.Mail_Cover_UploadingNowDesc
            rightTitle = BundleI18n.MailSDK.Mail_Cover_MobileOK
        case .coverUploadError:
            title = BundleI18n.MailSDK.Mail_Cover_FailedToUpload
            content = BundleI18n.MailSDK.Mail_Cover_FailedToUploadDesc
            rightTitle = BundleI18n.MailSDK.Mail_Cover_MobileOK
        case .attachmentsUploadError, .imagesUploadError:
            var failedItem = ""
            if failedImgCount > 0 && failedAttachCount > 0 {
                failedItem = BundleI18n.MailSDK.Mail_Compose_SendAttachmentUploadFailedTitleBoth
                content = BundleI18n.MailSDK.Mail_Edit_FailedToUploadPicturesAttachmentsMobile(failedImgCount,failedAttachCount)
            }else if failedImgCount > 0 {
                failedItem = BundleI18n.MailSDK.Mail_Compose_SendAttachmentUploadFailedTitlePicture
                content = BundleI18n.MailSDK.Mail_Edit_FailedToUploadPicturesAttachmentsMobilePic(failedImgCount)
            }else if failedAttachCount > 0 {
                failedItem = BundleI18n.MailSDK.Mail_Compose_SendAttachmentUploadFailedTitleAttachments
                content = BundleI18n.MailSDK.Mail_Edit_FailedToUploadPicturesAttachmentsMobileAtt(failedAttachCount)
            }
            title = BundleI18n.MailSDK.Mail_Compose_SendAttachmentUploadFailedMobile(failedItem)
            leftTitle = BundleI18n.MailSDK.Mail_Edit_ViewDetailsMobile
            rightTitle = BundleI18n.MailSDK.Mail_Edit_UploadAgainMobile
        case .overLimitSize:
            if Store.settingData.mailClient {
                title = BundleI18n.MailSDK.Mail_ThirdClient_FailedToUpload
            }
            content = BundleI18n.MailSDK.Mail_Compose_OversizeDialog("\(mailLimitSize)MB")
        case .calendarMailGroup:
            title = BundleI18n.MailSDK.Mail_Event_MailingListUnableSendEvent
            content = BundleI18n.MailSDK.Mail_Event_MailingListUnableSendEventDesc
        }
        delegate?.saveContentAndShowAlert(result: result,
                                          mailContent: mailContent,
                                          title: title,
                                          leftTitle: leftTitle,
                                          rightTitle: rightTitle,
                                          content: content,
                                          sendHandler: rightHandler)
        return true
    }

    func selectInvailEmailAddress(_ mailContent: MailContent) {
        delegate?.refreshInputView(mailContent: mailContent)
    }
}
