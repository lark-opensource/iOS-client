//
//  MailSendController+replyAttachment.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/3/14.
//

import UIKit
import RxSwift
import RustPB
import UniverseDesignActionPanel
import UniverseDesignToast
import EENavigator
import LarkAlertController
import LarkUIKit
import LarkStorage

extension MailSendController {
    func attachmentItemClicked() {
        requestHideKeyBoardIfNeed()
        findReplyAttachments()
    }
    
    private func findReplyAttachments() {
        func findAttachment(msgId: String) {
            MailDataSource.shared.getMassageItem(messageId: msgId).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (messageItem) in
                guard let `self` = self else { return }
                self.replyAttachments = messageItem.message.attachments
                self.processAttachment()
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("find reply att error \(error)")
                self.processAttachment()
            }).disposed(by: disposeBag)
        }
        if self.replyAttachments != nil {
            self.processAttachment()
            return
        }
        let messageId = self.baseInfo.messageID
        
        if let messageItems: [MailMessageItem] = self.baseInfo.mailItem?.messageItems,
           let item: MailMessageItem = messageItems.first(where: {
               $0.message.id == messageId })  {
            self.replyAttachments = item.message.attachments
            self.processAttachment()
        } else if let msgId = self.baseInfo.messageID,
                    !msgId.isEmpty {
            findAttachment(msgId: msgId)
        } else if let replyId = self.draft?.replyToMailID,
                    !replyId.isEmpty {
            findAttachment(msgId: replyId)
        } else {
            self.processAttachment()
        }
    }
    
    private func processAttachment() {
        var showReplyAttBtn = false
        if let atts = self.replyAttachments,
            atts.count > 0,
            accountContext.featureManager.open(.replyAttachment) &&
            !Store.settingData.mailClient {
            showReplyAttBtn = true
        }
        // present actionsheet
        let pop = UDActionSheet(config: UDActionSheetUIConfig(style: .autoAlert, isShowTitle: false))
        if showReplyAttBtn {
            pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Attachments_ReplyOriginalEmailAttachments) { [weak self] in
                self?.addAttachmentActionClick()
            }
        }
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Attachments_FeishuFiles()) { [weak self] in
            self?.receivedFileActionClick()
        }
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_Attachments_ReplyLocalFilesMobile) { [weak self] in
            self?.localFileActionClick()
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Attachments_ReplyCancel) {
        }
        navigator?.present(pop, from: self)
    }

    // 筛选掉的有 已过期、已封禁、有害附件，超大附件管理2期应该还有已删除
    private func filterAttachment(expired: Bool) -> [Email_Client_V1_Attachment]? {
        return self.replyAttachments?.filter({ att in
            // 已过期
            let expiredFlag = att.type == .large &&
            att.expireTime != 0 &&
            att.expireTime / 1000 < Int64(Date().timeIntervalSince1970)
            // 已封禁
            let bannedFlag = self.baseInfo.fileBannedInfos?[att.fileToken]?.isBanned == true
            // 有害附件
            let attachmentType = String(att.fileName.split(separator: ".").last ?? "")
            let type = DriveFileType(rawValue: attachmentType)
            let harmfulFlag = type?.isHarmful == true
            
            // 已删除
            let deletedFlag = self.baseInfo.fileBannedInfos?[att.fileToken]?.status == .deleted
            
            let flag = expiredFlag || bannedFlag || harmfulFlag || deletedFlag
            return expired ? flag : !flag
        })
    }
    private func localFileActionClick() {
        self.requestHideKeyBoard()
        let types = ["public.content",
                     "public.data",
                     "public.item",
                     "public.text",
                     "public.source-code",
                     "public.image",
                     "public.audiovisual-content",
                     "com.adobe.pdf",
                     "com.apple.keynote.key",
                     "com.microsoft.word.doc",
                     "com.microsoft.excel.xls",
                     "com.microsoft.powerpoint.ppt"]
        let vc = UIDocumentPickerViewController(documentTypes: types, in: .import)
        vc.delegate = self
        vc.transitioningDelegate = self
        vc.view.tag = needFocus
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal, execute: {
            self.navigator?.present(vc, from: self)
        })
    }
    private func receivedFileActionClick() {
        self.didClickAttachment()
    }
    private func addAttachmentActionClick() {
        guard var replyatts = self.replyAttachments else { return }
        replyatts = self.filterAttachment(expired: false) ?? []
        // caculate mail size
        self.draft?.content.attachments = getSuccessUploadedAttachments()
        let size = self.draft?.content.calculateMailSize() ?? 0
        let leftSize: Float = Float(contentChecker.mailLimitSize) - size
        replyatts = self.removeDuplicate(originAtts: replyatts,
                                         uploadedAtts: getSuccessUploadedAttachments())
        let (atts, needChangeTokens) = self.checkReplaceToken(replyatts: replyatts,
                                                              leftSize: leftSize)
        for att in atts {
            let event = NewCoreEvent(event: .email_email_edit_click)
            event.params = ["target": "none",
                            "click": "attachment",
                            "attachment_type": "mail_attachment",
                            "is_large": att.needReplaceToken == true ? "true" : "false"]
            event.post()
        }
        
        self.renderAttachment(attachments: atts,
                              replaceTokens: needChangeTokens,
                              toBottom: true)
        if let expired = self.filterAttachment(expired: true), expired.count > 0 {
            
            if expired.count == self.replyAttachments?.count {
                //展示全部失效的提示，全部失效每次都展示
                self.showAlertView(allAlert: true, expired: expired)
            } else if !self.showedExipredAlert {
                // 展示部分失效的提示，部分失效只展示一次
                self.showedExipredAlert = true
                self.showAlertView(allAlert: false, expired: expired)
            }
        }
    }
    private func removeDuplicate(originAtts: [Email_Client_V1_Attachment],
                                 uploadedAtts: [MailAttachment]) -> [Email_Client_V1_Attachment] {
        return originAtts.filter { att in
            return !uploadedAtts.contains(where: {
                $0.fileName == att.fileName &&
                $0.fileSize == att.fileSize
            })
        }
    }
    private func checkReplaceToken(replyatts: [Email_Client_V1_Attachment],
                                   leftSize: Float) -> ([MailAttachment], [String]) {
        var size = leftSize
        var needChangeTokens = [String]()
        var processedAtts = [Email_Client_V1_Attachment]()
        for att in replyatts {
            if att.type == .small {
                let MSize = Float(att.fileSize) / (1024 * 1024)
                if Float(MSize) <= size {
                    processedAtts.append(att)
                    size = size - Float(MSize)
                } else {
                    // need convert to large
                    var copy = att
                    copy.type = .large
                    processedAtts.append(copy)
                    needChangeTokens.append(att.fileToken)
                }
            } else {
                processedAtts.append(att)
            }
        }
        let atts = processedAtts.map { att -> MailAttachment in
            var tem = MailAttachment(fileName: att.fileName,
                                                      fileKey: att.fileToken,
                                                      type: att.type,
                                                      fileSize: att.fileSize,
                                                      largeFilePermission: att.largeFilePermission,
                                                      expireTime: att.expireTime,
                                                      needConvertToLarge: att.needConvertToLarge)
            if needChangeTokens.contains(att.fileToken) {
                tem.needReplaceToken = true
            }
            return tem
        }
        return (atts, needChangeTokens)
    }
    private func showAlertView(allAlert: Bool,
                               expired: [Email_Client_V1_Attachment]) {
        requestHideKeyBoard()
        scrollContainer.webView.endEditing(true)
        let alert = LarkAlertController()
        if allAlert {
            alert.setTitle(text: BundleI18n.MailSDK.Mail_UnableToAddAttachmentsAll_Title(expired.count))
        } else {
            alert.setTitle(text: BundleI18n.MailSDK.Mail_UnableToAddAttachmentsNum_Title(expired.count))
        }
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Attachments_ReplyViewDetails, dismissCompletion: { [weak self] in
            self?.showExpiredPage(expired: expired)
        })
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Attachments_ReplyOK)
        navigator?.present(alert, from: self)
    }
    private func showExpiredPage(expired: [Email_Client_V1_Attachment]) {
        let expiredPage = MailExpiredAttachmentViewController(attachments: expired, bannedInfo: baseInfo.fileBannedInfos, accountContext: accountContext)
        navigator?.push(expiredPage, from: self)
    }
}

extension MailSendController {
    func _documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        urls.forEach { (url) in
            insertAttachment(url: url)
        }
    }
    func _documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        insertAttachment(url: url)
    }
    func insertAttachment(url: URL) {
        let path = url.lastPathComponent
        let name = String(path)
        let type = DriveFileType(fileExtension: String(name.split(separator: ".").last ?? ""))
        guard !type.isHarmful else {
            showHarmfulAlert()
            return
        }

        let fileSize = url.asAbsPath().fileSize ?? 0

        let fileModel = MailSendFileModel(name: name, fileURL: url, size: UInt(fileSize))
        self.insertAttachment(fileModel: fileModel)
    }
    func showHarmfulAlert() {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_AttachmentsBlockedNum_Title(1))
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_UnableToDownloadHighRiskSingularGotIt_Button)
        let text = BundleI18n.MailSDK.Mail_AttachmentsBlockedCompose_Desc(1) + BundleI18n.MailSDK.Mail_AttachmentsBlockedLearnMore_Button
        let actionableText = BundleI18n.MailSDK.Mail_AttachmentsBlockedLearnMore_Button
        let textView = ActionableTextView.alertWithLinkTextView(text: text,
                                                                actionableText: actionableText,
                                                                action: {
            guard let configString = ProviderManager.default.commonSettingProvider?.stringValue(key: "attachment-harmful"),
                  let url = URL(string: configString) else { return }
            UIApplication.shared.open(url)
        })
        alert.setContent(view: textView, padding: UIEdgeInsets(top: 12, left: 20, bottom: 24, right: 20))
        navigator?.present(alert, from: self)
        InteractiveErrorRecorder.recordError(event: .send_attachment_blocked,
                                             tipsType: .alert)
    }
    func firstAddAttachment(subject: String) {
        guard !subject.isEmpty else { return }
        guard self.emlFilledSubject == false else { return }
        if let text = self.scrollContainer.getSubjectText(),
            text.isEmpty {
            self.scrollContainer.setSubjectText(subject)
            self.emlFilledSubject = true
        }
    }
}
// emlAsAttachment相关
extension MailSendController {
    func insertEmlAttachment(infos: [EmlAsAttachmentInfo]) {
        guard !infos.isEmpty else {
            MailLogger.info("[eml_as_attachment] infos is empty")
            return
        }
        guard let draftId = self.draft?.id, !draftId.isEmpty else {
            MailLogger.info("[eml_as_attachment] draftId is empty")
            return
        }
        let bizIds = infos.map { $0.bizId }
        let limitSize = String("\((contentChecker.mailLimitSize)) MB")

        func insertAttachments(attachments: [MailSendAttachment]) {
            self.scrollContainer.attachmentsContainer.addAttachments(attachments, permCode: Optional.none)
            self.scrollContainer.frame = self.view.bounds
            self.attachmentViewModel.appendAttachments(attachments,
                                                       needUpload: false,
                                                       needEmlUpload: true,
                                                       toBottom: true)
        }
        
        MailDataServiceFactory
            .commonDataService?.getEmlSizeRequest(bizIds: bizIds,
                                                  uuid: draftId).subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                var infosWithSize: [EmlAsAttachmentInfo] = []
                for info in infos {
                    var copyInfo = info
                    copyInfo.fileSize = resp.sizeInfo[info.bizId]
                    infosWithSize.append(copyInfo)
                }
                let (attachments, showLargeFileAlert) = self.genEmlAttachment(infos: infosWithSize)
                if attachments.count == 0 {
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_FailedUploadAttachmentRetry_Error,
                                        on: self.view)
                    return
                }
                if showLargeFileAlert {
                    if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
                        LarkAlertController.showAttachmentAlert(accountContext: self.accountContext, from: self, navigator: self.accountContext.navigator, limitSize: limitSize, userStore: self.accountContext.userKVStore) {
                            insertAttachments(attachments: attachments)
                        }
                    } else {
                        let alert = self.largeFileAlert(num: attachments.count)
                        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Common_Confirm, dismissCompletion: {
                            insertAttachments(attachments: attachments)
                        })
                        self.accountContext.navigator.present(alert, from: self)
                    }
                } else {
                    insertAttachments(attachments: attachments)
                }
            }, onError: { (error) in
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_FailedUploadAttachmentRetry_Error,
                                    on: self.view)
                MailLogger.error("[eml_as_attachment] emlSizeRequest error: \(error).")
            }).disposed(by: disposeBag)
    }
    
    private func genEmlAttachment(infos: [EmlAsAttachmentInfo]) -> ([MailSendAttachment], Bool) {
        var res: [MailSendAttachment] = []
        var leftSize = attachmentViewModel.availableSize
        var showLargeAlert = false
        for info in infos {
            if let size = info.fileSize, size >= 0 {
                let type: MailClientAttachement.AttachmentType = (leftSize - Int(size) >= 0) ? .small : .large
                var subject = info.subject
                if subject.isEmpty {
                    subject = BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty
                }
                var attachment = MailSendAttachment.init(displayName: subject + ".eml", fileExtension: .unknown, fileSize: Int(size), type: type)
                if let draftId = self.draft?.id, !draftId.isEmpty, !info.bizId.isEmpty {
                    attachment.emlUploadTask = EmlUploadTask(uuid: draftId,
                                                             bizId: info.bizId,
                                                             retryCnt: MailEmlUploader.maxRetryCnt)
                }
                if type == .large && !accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
                    attachment.expireTime = MailSendAttachment.genExpireTime()
                    showLargeAlert = true
                }
                if type == .large && accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
                    showLargeAlert = true
                }
                res.append(attachment)
                if type == .small {
                    leftSize = leftSize - Int(size)
                }
            } else {
                MailLogger.info("[eml_as_attachment] file size is \(String(describing: info.fileSize)) ")
            }
        }
        return (res, showLargeAlert)
    }
}

class MailNavigationController: LkNavigationController {
    private weak var picker: UIDocumentPickerViewController? = nil
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if picker != nil && picker == self.presentedViewController {
            picker = nil
            // 对于UIDocumentPickerViewController，有dismiss两次的bug，阻止第二次
            return
        } else if let presentedVC = self.presentedViewController,
                  presentedVC.isKind(of: UIDocumentPickerViewController.self) {
            picker = presentedVC as? UIDocumentPickerViewController
        } else {
            picker = nil
        }
        super.dismiss(animated: flag, completion: completion)
    }
}

