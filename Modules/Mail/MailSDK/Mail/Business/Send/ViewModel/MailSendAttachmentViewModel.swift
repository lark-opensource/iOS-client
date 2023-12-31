//
//  MailSendAttachmentViewModel.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/6.
//

import Foundation
import LarkAlertController
import EENavigator
import LKCommonsLogging
import RxSwift
import ServerPB
import LarkStorage

protocol MailSendAttachmentDelegate: AnyObject {
    var threadID: String? { get }
}

class MailSendAttachmentViewModel {
    static let singleAttachemntMaxSize = 1024 * 1024 * 1024 * 3
    private static let logger = Logger.log(MailSendAttachmentViewModel.self, category: "Module.MailSendAttachmentViewModel")
    lazy var attachmentPreviewRouter = AttachmentPreviewRouter(accountContext: accountContext, source: .sendMail)
    weak var attachmentsContainer: MailSendAttachmentContainer?
    weak var delegate: MailUploaderDelegate?
    weak var viewController: MailSendController?

    var updateAttachmentContainerLayout: (Bool) -> Void = { (Bool) in }
    var didDeleteAttachment: ((MailSendAttachment) -> Void)?
    var didInsertAttachment: ((MailSendAttachment) -> Void)?
    var navigationPush: (_ vc: UIViewController) -> Void = { (vc) in }
    private var failedAttachCount: Int = 0

    private var selectedAttachFiles: [MailSendAttachment] = []
    private var failedAttachFiles: [MailSendAttachment] = []
    private(set) lazy var attachmentUploader: MailUploader = {
        let loader = MailUploader(commonUploader: accountContext.provider.attachmentUploader)
        loader.delegate = self
        return loader
    }()
    private lazy var emlUploader: MailEmlUploader = {
        let loader = MailEmlUploader()
        loader.delegate = self
        return loader
    }()
    private let disposeBag = DisposeBag()
    var downloadDisposeBag = DisposeBag()
    private var downloadRespKeys = [String]()

    private var auditDraftInfo: AuditMailInfo {
        return AuditMailInfo(smtpMessageID: draftID ?? "", subject: viewController?.draft?.content.subject ?? "",
                             sender: viewController?.draft?.fromAddress ?? "", ownerID: nil, isEML: false)
    }

    let accountContext: MailAccountContext

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        attachmentUploader.addObserver(self)
    }

    deinit {
        // 取消下载
        cancelDownload()
    }
}

extension MailSendAttachmentViewModel: MailUploaderDelegate {
    var draftID: String? {
        return delegate?.draftID
    }

    var threadID: String? {
        return delegate?.threadID
    }
    func isSharedAccount() -> Bool {
        return delegate?.isSharedAccount() ?? false
    }
    var sharedAccountId: String? {
        return delegate?.sharedAccountId
    }

    var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }
}

extension MailSendAttachmentViewModel: MailSendAttachmentContainerDelegate {



    func mailSendUploadAttachmentFailed(attachment: MailSendAttachment) {
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "attachment_error",
                        "is_large": attachment.type == .large ? "true" : "false"]
        event.post()
    }
    func mailSendRetryAllAttachments(){
        failedAttachFiles = selectedAttachFiles.filter { (item) -> Bool in
            if let fileToken = item.fileToken,
                !fileToken.isEmpty,
                !item.needReplaceToken { // 成功的都不要
                return false
            }
            // filter harmful
            if item.fileExtension.isHarmful {
                return false
            }
            return true
        }

        for attachFile in failedAttachFiles{//失败的附件全部重传
            let (_, oriAttachment) = getAttachmentIndexInselectedAttachFiles(attachment: attachFile)
            if let oriAttachment = oriAttachment {
                attachmentsContainer?.updateUploadState(attachment: oriAttachment, state: .ready)
            }
            reUploadAttachment(attachFile)
        }

    }
    func mailSendDidClickAttachmentStateIcon(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment) {
        // TODO: 重试逻辑，将上传失败的附件重新加到上传队列末尾
        let (_, oriAttachment) = getAttachmentIndexInselectedAttachFiles(attachment: attachment)
        if let oriAttachment = oriAttachment {
            attachmentsContainer?.updateUploadState(attachment: oriAttachment, state: .ready)
        }
        reUploadAttachment(attachment)
    }

    func mailSendDidClickAttachment(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment) {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = ["target": "none",
                        "click": "attachment_preview",
                        "is_large": attachment.type == .large ? "true" : "false",
                        "attachment_position": Store.settingData.getCachedPrimaryAccount()?.mailSetting.attachmentLocation == .top ? "message_top": "message_bottom",
                        "label_item": "DRAFT"]
        event.post()
        let expireTime = attachment.expireTime / 1000
        if let fileToken = attachment.fileToken, !Store.settingData.mailClient {
            if attachment.type == .large, expireTime != 0, expireTime < Int64(Date().timeIntervalSince1970), let view = viewController?.view {
                let timeStr = ProviderManager.default.timeFormatProvider?.mailAttachmentTimeFormat(expireTime) ?? ""
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Attachment_CantViewDesc(timeStr), on: view)
                return
            }
            // 云端打开
            viewController?.resignEditorFocus()
            let tyeStr = String(attachment.displayName.split(separator: ".").last ?? "")
            if let vc = viewController {
                let delayTime: Double = 0.2
                // delay a little bit avoid push animation error when webview is first responder
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    self.attachmentPreviewRouter.startOnlinePreview(
                        fileToken: fileToken,
                        name: attachment.displayName,
                        fileSize: Int64(attachment.fileSize),
                        typeStr: tyeStr,
                        isLarge: attachment.type == .large,
                        isRisk: attachmentView.isRiskFile,
                        isOwner: attachmentView.bannedInfo?.isOwner == true,
                        isBanned: attachmentView.bannedInfo?.isBanned == true,
                        isDeleted: attachmentView.bannedInfo?.status == .deleted,
                        mailInfo: self.auditDraftInfo,
                        fromVC: vc,
                        origin: "mailDetail")
                }
            }

        } else if let fileURL = attachment.fileInfo?.fileURL, fileURL.asAbsPath().exists {
            // 本地打开
            MailLogger.info("client_attach: \(fileURL) \(fileURL.absoluteString)")
            self.openAttachment(fileURL.relativePath, attachment.displayName)
        } else if let token = attachment.fileToken, let msgID = delegate?.draftID, Store.settingData.mailClient {
            // 调下载接口
            downloadDisposeBag = DisposeBag()
            attachmentView.downloadState = .ready
            MailLogger.info("[mail_client_att] download attachment for preview token: \(token) msgid: \(msgID)")
            let event = MailAPMEvent.MessageImageLoad()
            event.markPostStart()
            MailDataSource.shared.mailDownloadRequest(token: token, messageID: msgID, isInlineImage: false)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    MailLogger.info("[mail_client_att] download attachment for preview resp key: \(resp.key)")
                    if !resp.filePath.isEmpty {
                        MailLogger.info("[mail_client_att] resp filePath: \(resp.filePath)")
                        self.openAttachment(resp.filePath, attachment.displayName)
                        let cost = MailTracker.getCurrentTime() - Int(1000 * event.recordDate.timeIntervalSince1970)
                        event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.upload_ms(cost))
                        event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.resource_content_length(((try? Data.read(from: AbsPath(resp.filePath))) ?? Data()).count))
                        event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_cache(1))
                        event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                        event.postEnd()
                    } else {
                        self.downloadRespKeys.append(resp.key)
                        let taskWrapper = RustSchemeTaskWrapper(task: nil, webURL: nil)
                        taskWrapper.key = resp.key
                        taskWrapper.inlineImage = false
                        taskWrapper.downloadChange = MailDownloadPushChange(status: .pending, key: resp.key)
                        taskWrapper.fileToken = token
                        taskWrapper.apmEvent = event
                        self.accountContext.imageService.startDownTask((resp.key, taskWrapper))
                    }

                    self.accountContext.imageService.downloadTask.asObservable().subscribe(onNext: { [weak self] (key, task) in
                        guard let `self` = self else { return }
                        guard let change = task?.downloadChange, key == resp.key else {
                            MailLogger.info("[mail_client_attach] webview mail download attachment for preview taskTable key: \(resp.key) not exist")
                            return
                        }
                        MailLogger.info("[mail_client_attach] webview mail download attachment rustTaskTable asObservable \(change.key), \(change.status), \(change.path?.fileName ?? "")")
                        // 如果已经开始下载
                        switch change.status {
                        case .success:
                            guard let path = change.path else {
                                MailLogger.error("vvImage webview mail download attachment for preview mailDownloadPushChange success-- key: \(change.key) but path is nil")
                                return
                            }
                            attachmentView.downloadState = .success
                            self.downloadRespKeys.append(change.key)
                        case .inflight, .pending:
                            MailLogger.info("[mail_client_attach] webview mail download for attachment preview mailDownloadPushChange-- key: \(change.key) status: \(change.status) transferSize: \(change.transferSize) totalSize: \(change.totalSize)")
                            let progress = Float(change.transferSize ?? 0) / Float(change.totalSize ?? 1)
                            attachmentView.updateUploadProgress(progress, fakeProgress: false) // 下载不需要假进度
                        case .failed:
                            MailLogger.info("[mail_client_image] webview mail download for attachment preview mailDownloadPushChange-- key: \(change.key) status: \(change.status)")
                            if let v = self.viewController?.view, attachmentView.downloadState != .fail {
                                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_UnableToOpenAttachments , on: v)
                            }
                            attachmentView.downloadState = .fail
                            self.downloadRespKeys.append(change.key)
                        case .cancel:
                            MailLogger.info("[mail_client_image] webview mail download for attachment preview mailDownloadPushChange-- key: \(change.key) status: \(change.status)")
                        default:
                            mailAssertionFailure("[mail_client_image] webview mail download unknown status: \(change.status)")
                        }
                    }).disposed(by: self.disposeBag)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailLogger.info("vvImage webview mail download attachment error: \(error)")
                    if let v = self.viewController?.view {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_UnableToOpenAttachments , on: v)
                    }
                    event.endParams.appendError(errorCode: error.mailErrorCode, errorMessage: error.getMessage())
                    event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_cache(0))
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
                    event.postEnd()
                }).disposed(by: self.downloadDisposeBag)
        } else {
            mailAssertionFailure("preview attachment error")
            return
        }
    }

    private func cancelDownload() {
        for respKey in downloadRespKeys {
            accountContext.imageService.removeRespKey(respKey)
            MailDataSource.shared.fetcher?.mailCancelDownload(respKey: respKey)
                .subscribe(onNext: { _ in
                    MailLogger.info("[mail_client_att] mailCancelDownload attachment success: \(respKey)")
                }, onError: { (error) in
                    MailLogger.error("[mail_client_att] mailCancelDownload error: \(error)")
                }).disposed(by: self.disposeBag)
        }
    }

    private func openAttachment(_ path: String, _ displayName: String = "") {
        viewController?.resignEditorFocus()
        if let vc = viewController {
            let delayTime: Double = 0.2
            // delay a little bit avoid push animation error when webview is first responder
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                MailRoundedHUD.remove(on: vc.view)
                var fileName = path.fileName
                if fileName.isEmpty {
                    fileName = displayName
                }
                self.attachmentPreviewRouter.startLocalPreviewViaDrive(
                    typeStr: path.extension,
                    fileURL: URL(fileURLWithPath: path),
                    fileName: fileName,
                    mailInfo: self.auditDraftInfo,
                    from: vc,
                    origin: "mailDetail")
            }
        }
    }

    func mailSendDidClickDeleteAttachment(_ attachmentView: MailSendAttachmentView, attachment: MailSendAttachment) {
        // check超大附件
        if !accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false),
           let token = attachment.fileToken, attachment.type == .large, attachment.expireTime == 0 {
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_Compose_LFPermissionChangeFailed)
            alert.addCancelButton()
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Compose_LFActionDelete, dismissCompletion: { [weak self] in
                self?.deleteLocalFile(attachment: attachment)
                MailDataServiceFactory.commonDataService?.deleteDriveFiles(tokens: [token]).subscribe(onNext: { [weak self] (res) in
                    if res.failedTokens.count > 0 {
                        MailSendAttachmentViewModel.logger.error("delete file failed token=\(res.failedTokens)")
                    }}, onError: { (err) in
                        MailSendAttachmentViewModel.logger.error("delete file failed token=\(token)", error: err)
                        if let window = attachmentView.window {
                            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Compose_LFDeleteFailed, on: window,
                                                       event: ToastErrorEvent(event: .send_compose_largefile_delete_fail))
                        }
                    })
            })
            if let vc = viewController {
                accountContext.navigator.present(alert, from: vc)
            }
        } else {
            deleteLocalFile(attachment: attachment)
            // 二期 删除草稿箱的附件时，超大附件管理列表也要删除
            if accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: false), attachment.type == .large {
                if let fileToken = attachment.fileToken {
                    self.accountContext.securityAudit.audit(type:.largeAttachmentDelete(mailInfo: auditDraftInfo, fileID: attachment.fileToken ?? "", fileSize: attachment.fileSize, fileName: attachment.fileInfo?.name ?? ""))
                    MailDataServiceFactory.commonDataService?.deleteLargeAttachmentRequest([fileToken], isDraftDelete: true, meessageBizID: draftID ?? "").subscribe(onError: { err in
                        MailSendAttachmentViewModel.logger.error("delete file failed token=\(fileToken)", error: err)
                        if let window = attachmentView.window {
                            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Compose_LFDeleteFailed, on: window,
                                                       event: ToastErrorEvent(event: .send_compose_largefile_delete_fail))
                        }
                    })
                }
            }
        }

        // event
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "attachment_delete",
                        "is_large": attachment.type == .large ? "true" : "false"]
        event.post()
    }
    private func deleteLocalFile(attachment: MailSendAttachment) {
        didDeleteAttachment?(attachment)
        attachmentsContainer?.removeAttachment(attachment)
        selectedAttachFiles = selectedAttachFiles.filter({ (element) -> Bool in
            element != attachment
        })
        if attachment.emlUploadTask == nil {
            attachmentUploader.cancel(attachment: attachment)
        } else {
            if let bizId = attachment.emlUploadTask?.bizId,
                !bizId.isEmpty,
                let uuid = attachment.emlUploadTask?.uuid,
                !uuid.isEmpty {
                emlUploader.cancelAttachment(tasks: [EmlUploadTask(uuid: uuid,
                                                                   bizId:bizId,
                                                                   retryCnt: MailEmlUploader.maxRetryCnt)])
            }
        }
        updateAttachmentContainerLayout(false)
    }
    func getVCWidth() -> CGFloat {
        return viewController?.view.bounds.width ?? 0
    }
}

extension MailSendAttachmentViewModel: MailSendUploaderObserver {
    func mailUploader(_ uploader: MailUploader, didUploadFinishHasFailedState hasFailed: Bool, attachmentsSize: Int64) {
        if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
            MailDataSource.shared.fetcher?.checkAttachmentMountPermissionRequest(attachmentsSize: attachmentsSize).subscribe{[weak self] resp in
                guard let `self` = self else { return }
                if resp.overQuotaLimit {
                    let alert = LarkAlertController()
                    var content = ""
                    var confirmText = ""
                    if resp.isAdminUser {
                        content = BundleI18n.MailSDK.Mail_Billing_StorageIsFullPleaseUpgradeThePlan
                        confirmText = BundleI18n.MailSDK.Mail_Billing_ContactServiceConsultant
                    } else {
                        content = BundleI18n.MailSDK.Mail_Billing_PleaseContactTheAdministrator
                        confirmText = BundleI18n.MailSDK.Mail_Billing_Confirm
                    }
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_Billing_ServiceSuspension)
                    alert.setContent(text: content, alignment: .center)
                    alert.addButton(text: confirmText, newLine: true, numberOfLines: 2, dismissCompletion: {
                        guard resp.isAdminUser else { return }
                        if let vc = self.viewController {
                            MailStorageLimitHelper.contactServiceConsultant(from: vc, navigator: self.accountContext.navigator)
                        }
                    })
                    if resp.isAdminUser {
                        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Billing_Later, newLine: true)
                    }
                    if let vc = self.viewController {
                        self.accountContext.navigator.present(alert, from: vc)
                    }
                }
            } onError: { err in
                MailLogger.info("[mail_client_upload] didUploadFinishHasFailedState hasFailed: \(hasFailed) attachmentsSize: \(String(attachmentsSize)), err \(err)")
            }.disposed(by: self.disposeBag)
        }
    }

    func mailUploader(_ uploader: MailUploader, didUploadProgressUpdate progress: Float, attachment: MailSendAttachment, fileToken: String) {
        let (_, oriAttachment) = getAttachmentIndexInselectedAttachFiles(attachment: attachment)
        if let oriAttachment = oriAttachment {
            attachmentsContainer?.updateUploadProgress(attachment: oriAttachment, progress: progress)
        }
    }

    func mailUploader(_ uploader: MailUploader, didUploadStatusChange status: MailSendAttachmentUploadStatus, attachment: MailSendAttachment, fileToken: String, respKey: String?) {
        MailLogger.info("[mail_client_upload] didUploadStatusChange attachment: \(attachment) respKey: \(String(describing: respKey))")
        switch status {
        case .success:
            MailLogger.info("[mail_client_upload] upload success ✅ \(respKey ?? "")")
            let (index, oriAttachment) = getAttachmentIndexInselectedAttachFiles(attachment: attachment)
            if Store.settingData.mailClient, let respKey = respKey {
                uploader.uploadTask
                    .asObservable().subscribe(onNext: { [weak self] (key, change) in
                    MailLogger.info("[mail_client_upload] attachmentUploader.uploadTask.asObservable respKey: \(String(describing: respKey))")
                    guard let `self` = self, let change = change, key == respKey else {
                        MailLogger.info("[mail_client_upload] webview mail upload attachment for preview taskTable key: \(respKey) not exist")
                        return
                    }
                    MailLogger.info("[mail_client_upload] webview mail download upload rustTaskTable asObservable \(change.key), \(change.status)")
                    if change.status == .inflight {
                        if let oriAttachment = oriAttachment, let totalSize = change.totalSize, totalSize != 0 {
                            self.attachmentsContainer?.updateUploadProgress(attachment: oriAttachment, progress: Float(change.transferSize ?? 0 / totalSize) * 1.0)
                        }
                    } else if change.status == .success {
                        if var oriAttachment = oriAttachment {
                            oriAttachment.fileToken = change.token
                            self.didInsertAttachment?(oriAttachment)
                            if index < self.selectedAttachFiles.count {
                                self.selectedAttachFiles[index] = oriAttachment
                            }
                            self.attachmentsContainer?.updateUploadState(attachment: oriAttachment, state: .success)
                            // 上传成功自动保存一下
                            self.viewController?.doSaveDraft(param: .auto_save)
                        }
                    }
                }).disposed(by: self.disposeBag)
            } else if var oriAttachment = oriAttachment {
                oriAttachment.fileToken = fileToken
                didInsertAttachment?(oriAttachment)
                if index < self.selectedAttachFiles.count {
                    self.selectedAttachFiles[index] = oriAttachment
                }
                attachmentsContainer?.updateUploadState(attachment: oriAttachment, state: .success)
                // 上传成功自动保存一下
                self.viewController?.doSaveDraft(param: .auto_save)
            }

        case .failed:
            MailLogger.error("[mail_client_upload] upload fail ❌")
            let (index, oriAttachment) = getAttachmentIndexInselectedAttachFiles(attachment: attachment)
            if var oriAttachment = oriAttachment {
                oriAttachment.cachePath = attachment.cachePath
                oriAttachment.fileToken = fileToken
                if index < self.selectedAttachFiles.count {
                    self.selectedAttachFiles[index] = oriAttachment
                }
                attachmentsContainer?.updateUploadState(attachment: oriAttachment, state: .fail)
            }
        @unknown default:
            break
        }
    }
}

extension MailSendAttachmentViewModel {

    private func getAttachmentIndexInselectedAttachFiles(attachment: MailSendAttachment) -> (Int, MailSendAttachment?) {
        for (index, element) in selectedAttachFiles.enumerated()
        where element == attachment {
            return (index, element)
        }
        return (-1, nil)
    }
}

// MARK: uploader 暴露出去的接口
extension MailSendAttachmentViewModel {
    func cancelAll() {
        attachmentUploader.cancellAll()
        emlUploader.cancelAll()
    }

    /// 剩余可选附件大小
    var availableSize: Int {
        guard let viewController = viewController, let draft = viewController.draft else { return 0 }
        let currentContentSize = draft.content.calculateMailSize(ignoreAttachment: true)
        let sizeLimit = Int(1024 * 1024 * (Float(viewController.contentChecker.mailLimitSize) - currentContentSize))
        var selectedSize = 0
        selectedSize = selectedAttachFiles.filter({ $0.type != .large }).reduce(0) { (res, file) -> Int in
            return res + Int(file.fileSize)
        }
        if !Store.settingData.mailClient {
        }
        MailLogger.info("[mail_client_attach] currentContentSize: \(currentContentSize) selectedSize: \(selectedSize) selectedAttachFiles count: \(selectedAttachFiles.count)")
        return sizeLimit - selectedSize
    }

    func convertToLargeAttachment() {
        let atts = selectedAttachFiles.map { (attItem) -> MailSendAttachment in
            var tem = attItem
            if tem.type != .large {
                if !accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
                    tem.expireTime = MailSendAttachment.genExpireTime()
                }
                tem.needConvertToLarge = true
            }
            return tem
        }
        selectedAttachFiles = atts
    }

    /// 上传任务是否完成
    var isFinished: Bool {
        let replaceTokenFiles = selectedAttachFiles.filter({ att in
            if let fileToken = att.fileToken, !fileToken.isEmpty, att.needReplaceToken {
                return true
            }
            return false
        })
        return attachmentUploader.isFinished &&
        replaceTokenFiles.isEmpty &&
        emlUploader.AllTaskFinished()
    }

    /// 是否存在上传失败的场景
    var isExistError: Bool {
        failedAttachCount = 0
        let errorItem = selectedAttachFiles.filter { (item) -> Bool in
            if let fileToken = item.fileToken,
                !fileToken.isEmpty,
                !item.needReplaceToken { // 成功的都不要
                return false
            }
            // filter harmful
            if item.fileExtension.isHarmful {
                return false
            }
            failedAttachCount += 1  //记录失败的个数
            return true
        }
        return !errorItem.isEmpty
    }

    /// 是否存在无法发送的场景，目前包括过期、封禁、有害
    /// 二期新增已删除
    var isExistInvalid: Bool {
        let harmfulFlag = selectedAttachFiles.contains(where: { $0.fileExtension.isHarmful })
        let expiredFlag = selectedAttachFiles.contains(where: {
            $0.type == .large && $0.expireTime > 0 && ($0.expireTime / 1000) < Int64(Date().timeIntervalSince1970)
        })
        let bannedAttachmentTokens = attachmentsContainer?.attachmentViews.filter({ $0.bannedInfo?.isBanned == true }).map { $0.fileToken }
        let bannedFlag = selectedAttachFiles.contains(where: { bannedAttachmentTokens?.contains($0.fileToken) == true })
        let deletedAttachmentTokens = attachmentsContainer?.attachmentViews.filter({$0.bannedInfo?.status == .deleted }).map {$0.fileToken }
        let deletedFlag = selectedAttachFiles.contains(where: {
            deletedAttachmentTokens?.contains($0.fileToken) == true })
        return harmfulFlag || expiredFlag || bannedFlag || deletedFlag == true
    }

    var invalidFileCount: Int {
        let bannedAttachmentTokens = attachmentsContainer?.attachmentViews.filter({ $0.bannedInfo?.isBanned == true }).map { $0.fileToken }
        let deletedAttachmentTokens = attachmentsContainer?.attachmentViews.filter({
            $0.bannedInfo?.status == .deleted }).map { $0.fileToken }
        return selectedAttachFiles.filter({
            $0.fileExtension.isHarmful ||
            $0.type == .large && $0.expireTime > 0 && ($0.expireTime / 1000) < Int64(Date().timeIntervalSince1970) ||
            bannedAttachmentTokens?.contains($0.fileToken) == true ||
            deletedAttachmentTokens?.contains($0.fileToken) == true
        }).count
    }

    /// 是否全部附件都无法发送
    var isAllInvalid: Bool {
        return selectedAttachFiles.count == invalidFileCount
    }

    /// 获取上传成功的附件
    var successUploadedItems: [MailSendAttachment] {
        return self.selectedAttachFiles.filter({ (item) -> Bool in
            if let token = item.fileToken, !token.isEmpty, !item.needReplaceToken {
                return true
            }
            return false
        })
    }

    /// 附件列表是否有附件
    var hasAttachments: Bool {
        return !selectedAttachFiles.isEmpty
    }

    //上传失败计数
    func getFailedAttachCount() -> Int{
        if isExistError {
            return failedAttachCount
        }else{
            return 0
        }
    }

    func removeAllAttachments() {
        selectedAttachFiles.removeAll()
    }

    func getFirstFailedAttachment() -> Int{
        if getFailedAttachCount() <= 0 {
            return -1
        }
        for (idx, item) in selectedAttachFiles.enumerated() {
            if let fileToken = item.fileToken, !fileToken.isEmpty, !item.needReplaceToken {//该Item上传成功
            } else {
                return idx
            }
        }
        return -1
    }
    /// 添加需要上传的附件
    func appendAttachments(_ attachments: [MailSendAttachment],
                           needUpload: Bool = true,
                           needEmlUpload: Bool = false,
                           toBottom: Bool = false) {
        if accountContext.featureManager.open(.emlAsAttachment, openInMailClient: false) {
            if needUpload || needEmlUpload {
                // 第一次添加附件，需要检查是否填充主题
                let subject = ((attachments.first?.displayName ?? "") as NSString).deletingPathExtension
                self.viewController?.firstAddAttachment(subject: subject)
            }
        }
        selectedAttachFiles.append(contentsOf: attachments)
        updateAttachmentContainerLayout(toBottom)
        if needUpload {
            attachmentUploader.upload(attachments: attachments)
        } else if needEmlUpload {
            var tasks = attachments.filter { attachment in
                attachment.emlUploadTask != nil
            }.map { attachment in
                return EmlUploadTask(uuid: attachment.emlUploadTask?.uuid ?? "",
                                     bizId: attachment.emlUploadTask?.bizId ?? "",
                                     retryCnt: MailEmlUploader.maxRetryCnt)
            }.filter { task in
                !task.bizId.isEmpty && !task.uuid.isEmpty
            }
            emlUploader.addAttachments(tasks: tasks)
        }
    }
    func removedulplicate(_ attachments: [MailSendAttachment]) -> [MailSendAttachment] {
        // remove same token or (same name & size & type)
        return attachments.filter { att in
            let flag1 = !selectedAttachFiles.contains(att)
            let flag2 = !selectedAttachFiles.contains(where: {
                $0.displayName == att.displayName &&
                $0.fileSize == att.fileSize
            })
            return flag1 && flag2
        }
    }

    /// 重新上传附件内
    func reUploadAttachment(_ attachment: MailSendAttachment) {
        updateAttachmentContainerLayout(true)
        if let task = attachment.emlUploadTask {
            emlUploader.retryTask(task: task)
        } else {
            attachmentUploader.upload(attachments: [attachment])
            let event = NewCoreEvent(event: .email_email_edit_click)
            event.params = ["target": "none",
                            "click": "attachment_reload",
                            "is_large": attachment.type == .large ? "true" : "false"]
            event.post()
        }
    }
    func replaceToken(tokenMap:[String: String], messageBizId: String) {
        self.selectedAttachFiles = self.selectedAttachFiles.map { item -> MailSendAttachment in
            if let token = item.fileToken,
                !token.isEmpty,
                tokenMap[token] != nil {
                var newItem = item
                newItem.fileToken = tokenMap[token]
                newItem.needReplaceToken = false
                return newItem
            }
            return item
        }
    }
    func replaceTokenFail(tokenList: [String]) {
        // nothing
    }
}

extension MailSendAttachmentViewModel: MailEmlUploaderDelegate {
    func emlUploadStarted(bizId: String, uuid: String) {
        self.attachmentsContainer?.updateEmlAttachmentProgress(tasks:
                                                                [EmlUploadTask(uuid: uuid,
                                                                               bizId: bizId,
                                                                               retryCnt: MailEmlUploader.maxRetryCnt)],
                                                               state: .half)
    }
    func emlUploadFailed(bizId: String, uuid: String, errorText: String) {
        self.attachmentsContainer?.updateEmlAttachmentProgress(tasks:
                                                                [EmlUploadTask(uuid: uuid,
                                                                               bizId: bizId,
                                                                               retryCnt: MailEmlUploader.maxRetryCnt)],
                                                               state: .fail)
    }
    func emlUploadSuccess(bizId: String,
                          uuid: String,
                          fileToken: String,
                          status: ServerPB_Mails_UploadEmlAsAttachmentStatus) {
        self.attachmentsContainer?.updateEmlAttachmentProgress(tasks:
                                                                [EmlUploadTask(uuid: uuid,
                                                                               bizId: bizId,
                                                                               retryCnt: MailEmlUploader.maxRetryCnt)],
                                                               state: .done)
        // replace token
        self.setEmlAttachmentToken(bizId: bizId, token: fileToken)

        // 审计统计
        self.emlAuditReport(bizId: bizId, token: fileToken)
    }
    private func emlAuditReport(bizId: String, token: String) {
        if let att = self.selectedAttachFiles.first(where: { $0.fileToken == token }) {
            var subject = att.displayName.replacingOccurrences(of: ".eml", with: "")
            let size = att.fileSize
            MailDataServiceFactory.commonDataService?.getSmtpMessageId(bizIds: [bizId]).subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                if let smtpId = res.messageSmtpIds.first {
                    let info = AuditMailInfo(smtpMessageID: smtpId, subject: subject, sender: "", ownerID: nil, isEML: false)
                    self.accountContext.securityAudit.audit(type: .emlAsAttachment(mailInfo: info,
                                                                          fileId: token,
                                                                          fileSize: size))
                } else {
                    MailLogger.info("[eml_as_attachment] get smtp empty")
                }
            }, onError: { (err) in
                MailLogger.info("[eml_as_attachment] get smtp fail \(err)")
            })
        }
    }
    private func setEmlAttachmentToken(bizId: String, token: String) {
        guard !bizId.isEmpty && !token.isEmpty else { return }
        self.selectedAttachFiles = self.selectedAttachFiles.map { attachment in
            var copy = attachment
            if let task = copy.emlUploadTask, task.bizId == bizId {
                copy.fileToken = token
            }
            return copy
        }
        if let attachmentViews = self.attachmentsContainer?.attachmentViews {
            self.attachmentsContainer?.attachmentViews = attachmentViews.map({ view in
               var copy = view.attachment
               if let task = copy.emlUploadTask, task.bizId == bizId {
                   copy.fileToken = token
               }
               view.attachment = copy
               return view
           })
        }
    }
    func emlUploadPending(tasks: [EmlUploadTask]) {
        self.attachmentsContainer?.updateEmlAttachmentProgress(tasks: tasks, state: .pending)
    }
}
