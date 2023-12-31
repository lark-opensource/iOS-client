//
//  AttachmentPreviewRouter.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/8/6.
//

import Foundation
import EENavigator
import Photos
import UIKit
import LarkAlertController
import LarkLocalizations
import RxSwift
import PocketSVG
import Reachability
import LarkStorage

protocol AttachmentPreviewImageItem {
    var token: String { get }
    /// 文件后缀
    var fileType: String { get }
}

class AttachmentPreviewRouter {

    struct DefaultImageItem: AttachmentPreviewImageItem {
        let token: String
        let fileType: String
    }
    enum Source {
        case readMail
        case sendMail
        case attachMentManager
    }

    /// space的url前缀，最后拼接token
    private let from = "thirdparty_attachment"
    private let businessId = "email_attachment"
    private let mountPoint = "email"
    let source: Source
    let accountContext: MailAccountContext
    init(accountContext: MailAccountContext, source: Source) {
        self.source = source
        self.accountContext = accountContext
    }

    private var disposeBag: DisposeBag = DisposeBag()
}

// 参考：https://bytedance.feishu.cn/space/doc/doccnnSfjAM439hJbX6HMZiCdsd#
extension AttachmentPreviewRouter {
    func startLocalPreviewViaDrive(typeStr: String, fileURL: URL, fileName: String, mailInfo: AuditMailInfo?, from: UIViewController, origin: String) {
        if typeStr == "eml" || typeStr == "msg" {
            // eml 预览.
            let vc = EmlPreviewViewController.localEmlPreview(accountContext: accountContext, localPath: fileURL)
            accountContext.navigator.push(vc, from: from)
        } else {
            let actions = getLocalPreviewActions(fromVC: from, mailInfo: mailInfo, localPath: fileURL.absoluteString, origin: origin)
            let entity = DriveLocalFileEntity(fileURL: fileURL,
                                              name: fileName,
                                              fileType: nil,
                                              canExport: true,
                                              actions: actions)
            accountContext.provider.attachmentPreview?.driveLocalFileController(files: [entity], index: 0, from: from)
        }
    }
    func saveToLocal(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController) {
        accountContext.provider.attachmentPreview?.saveToLocal(fileSize: fileSize, fileObjToken: fileObjToken, fileName: fileName, sourceController: sourceController)
    }
    
    func openDriveFileWithOtherApp(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController) {
        accountContext.provider.attachmentPreview?.openDriveFileWithOtherApp(fileSize: fileSize, fileObjToken: fileObjToken, fileName: fileName, sourceController: sourceController)
    }
    
    func saveToSpace(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController) {
        accountContext.provider.attachmentPreview?.saveToSpace(fileObjToken: fileObjToken, fileSize: fileSize, fileName: fileName, sourceController: sourceController)
    }
    
    func forwardShareMailAttachement(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController, isLargeAttachment: Bool) {
        MailTracker.log(event: "email_attachment_share", params: ["attachment_size_byte": fileSize])
        // 分享至会话限制在50M内
        let limieSize: UInt64 = 50
        guard fileSize < limieSize * 1024 * 1024 else {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_CantShareToChat_Toast(limieSize), on:sourceController.view)
            return
        }
        accountContext.provider
            .routerProvider?
            .forwardShareMailAttachementBody(title: fileName,
                                             img: UIImage.fileLadderIcon(with: fileName),
                                             token: fileObjToken,
                                             fromVC: sourceController,
                                             isLargeAttachment: isLargeAttachment) { forwardResult in
                guard let items = forwardResult.items, items.count > 0 else {
                    if let error = forwardResult.error {
                        MailLogger.error("shareAttachment error \(error)")
                    } else {
                        MailLogger.error("shareAttachment error without error")
                    }
                    return
                }
            }
    }
    
    func startOnlinePreview(fileToken: String, name: String = "unknown", fileSize: Int64 = 0, typeStr: String, isLarge: Bool, isRisk: Bool, isOwner: Bool, isBanned: Bool, isDeleted: Bool, mailInfo: AuditMailInfo?, fromVC: UIViewController, customMoreActionList: [CustomMoreActionProviderImpl]? = nil, origin: String) {
        guard !fileToken.isEmpty, let userId = accountContext.user.info?.userID else { return }
        // 二期新增删除态，其他处理同一期预览
        if accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: false), isDeleted {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_FileDeletedCantProcess, on: fromVC.view)
        } else {
            if typeStr == "eml" || typeStr == "msg" {
                // eml 预览.
                if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false), isBanned, !isOwner {
                    // 超大附件管理，非附件所有者，封禁附件不能预览
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ActionFailedFileExpired_Toast, on: fromVC.view)
                } else if accountContext.featureManager.open(.securityFile, openInMailClient: true), isRisk {
                    // 文件安全检测，高危Eml不能预览
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_UnableToOpenHighRisk_Title)
                    alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_InitiateAppeal_Button, dismissCompletion: { [weak self] in
                        let domain = self?.accountContext.provider.configurationProvider?.getDomainSetting(key: .securityWeb).first ?? ""
                        let locale = LanguageManager.currentLanguage.languageIdentifier
                        let urlString = "https://\(domain)/document-security-inspection/appeal?obj_token=\(fileToken)&locale=\(locale)&version=0&file_type=12"
                        guard let url = URL(string: urlString) else { return }
                        self?.accountContext.navigator.push(url, from: fromVC)
                        MailTracker.log(event: "email_risk_file_alert_window_click",
                                        params: ["click": "appeal",
                                                 "target": "none",
                                                 "window_type": "attachment_preview",
                                                 "mail_account_type": Store.settingData.getMailAccountType()])
                    })
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_UnableToDownloadHighRiskSingularGotIt_Button, dismissCompletion: {
                        MailTracker.log(event: "email_risk_file_alert_window_click",
                                        params: ["click": "i_known",
                                                 "target": "none",
                                                 "window_type": "attachment_preview",
                                                 "mail_account_type": Store.settingData.getMailAccountType()])
                    })
                    let text = BundleI18n.MailSDK.Mail_UnableToOpenHighRisk_Desc(BundleI18n.MailSDK.Mail_FeishuFileSecurityPolicy_Text)
                    let actionableText = BundleI18n.MailSDK.Mail_FeishuFileSecurityPolicy_Text
                    let textView = ActionableTextView.alertWithLinkTextView(text: text,
                                                                            actionableText: actionableText,
                                                                            action: { [weak self] in
                        let domain = self?.accountContext.provider.configurationProvider?.getDomainSetting(key: .securityWeb).first ?? ""
                        let locale = LanguageManager.currentLanguage.languageIdentifier
                        let urlString = "https://\(domain)/document-security-inspection/file-security-policy/\(locale)"
                        guard let url = URL(string: urlString) else { return }
                        UIApplication.shared.open(url)
                        MailTracker.log(event: "email_risk_file_alert_window_click",
                                        params: ["click": "open_doc_link",
                                                 "target": "none",
                                                 "window_type": "attachment_preview",
                                                 "mail_account_type": Store.settingData.getMailAccountType()])
                    })
                    alert.setContent(view: textView, padding: UIEdgeInsets(top: 12, left: 20, bottom: 24, right: 20))
                    accountContext.navigator.present(alert, from: fromVC)
                    MailTracker.log(event: "email_risk_file_alert_window_view",
                                    params: ["window_type": "attachment_preview",
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                } else if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false), isBanned, isOwner {
                    // 超大附件管理，附件所有者，封禁附件可以预览，需要展示 banner
                    let vc = EmlPreviewViewController.driveEmlPreview(accountContext: accountContext,
                                                                      fileToken: fileToken,
                                                                      name: name,
                                                                      fileSize: fileSize,
                                                                      isLarge: isLarge,
                                                                      needBanner: true)
                    accountContext.navigator.push(vc, from: fromVC)
                    MailTracker.log(event: "email_attachment_preview_risk_banner_view",
                                    params: ["attachment_id": fileToken.encriptUtils(),
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                } else {
                    let vc = EmlPreviewViewController.driveEmlPreview(accountContext: accountContext,
                                                                      fileToken: fileToken,
                                                                      name: name,
                                                                      fileSize: fileSize,
                                                                      isLarge: isLarge,
                                                                      needBanner: false)
                    accountContext.navigator.push(vc, from: fromVC)
                    if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false), isLarge {
                        // 超大附件才需要上报 PV
                        MailDataServiceFactory.commonDataService?.countLargeAttachmentPV(fileToken)
                            .subscribe(onNext: { _ in
                                MailLogger.info("countLargeAttachmentPV success.")
                            }, onError: { error in
                                MailLogger.info("countLargeAttachmentPV error: \(error)")
                            }).disposed(by: disposeBag)
                    }
                }
            } else {
                if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false), isBanned {
                    if isOwner {
                        // 超大附件管理，附件所有者，封禁附件可以预览，需要展示 banner
                        // 使用的drive提供的预览
                        let type = DriveFileType(fileExtension: typeStr)
                        let actions = getOnlinePreviewActions(fileToken: fileToken,
                                                              type: type,
                                                              isLarge: isLarge,
                                                              fromVC: fromVC,
                                                              mailInfo: mailInfo,
                                                              customMoreActionList: customMoreActionList,
                                                              origin: origin,
                                                              isBanned: isBanned)
                        let fileEntity = DriveThirdPartyFileEntity(fileToken: fileToken, docsType: .file, mountNodePoint: userId, mountPoint: mountPoint, actions: actions, handleBizPermission: { subject in
                            return { _ in
                                let bannerView = FilePreviewBannerView()
                                bannerView.termsAction = { [weak self] in
                                    let domain = self?.accountContext.provider.configurationProvider?.getDomainSetting(key: .suiteMainDomain).first ?? ""
                                    let lang = LanguageManager.currentLanguage.languageIdentifier
                                    let urlString = "https://\(domain)/terms?lang=\(lang)"
                                    if let url = URL(string: urlString) {
                                        self?.accountContext.navigator.push(url, from: fromVC)
                                        MailTracker.log(event: "email_attachment_preview_risk_banner_click",
                                                        params: ["click": "open_user_agreement",
                                                                 "target": "none",
                                                                 "mail_account_type": Store.settingData.getMailAccountType()])
                                    }
                                }
                                bannerView.supportAction = { [weak self] in
                                    if let urlString = ProviderManager.default.commonSettingProvider?.stringValue(key: "banned_customer_service_url"),
                                       let url = URL(string: urlString) {
                                        self?.accountContext.navigator.push(url, from: fromVC)
                                        MailTracker.log(event: "email_attachment_preview_risk_banner_click",
                                                        params: ["click": "customer_service",
                                                                 "target": "none",
                                                                 "mail_account_type": Store.settingData.getMailAccountType()])
                                    }
                                }
                                subject.onNext(MailDriveSDKUIAction.showBanner(banner: bannerView, bannerID: "MailShowBanner"))
                            }
                        })
                        accountContext.provider
                            .attachmentPreview?
                            .driveThirdPartyActtachController(files: [fileEntity], index: 0, from: fromVC)
                        MailTracker.log(event: "email_attachment_preview_risk_banner_view",
                                        params: ["attachment_id": fileToken.encriptUtils(),
                                                 "mail_account_type": Store.settingData.getMailAccountType()])
                    } else {
                        // 超大附件管理，非附件所有者，封禁附件不能预览
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ActionFailedFileExpired_Toast, on: fromVC.view)
                    }
                } else {
                    // 使用的drive提供的预览
                    openDriveFile(fileToken: fileToken,
                                  typeStr: typeStr,
                                  fileName: name,
                                  isLarge: isLarge,
                                  isBanned: isBanned,
                                  mailInfo: mailInfo,
                                  customMoreActionList: customMoreActionList,
                                  origin: origin,
                                  fromVC: fromVC)
                }
            }
        }
    }
    
    func openDriveFile(fileToken: String,
                       typeStr: String,
                       fileName: String,
                       isLarge: Bool,
                       isBanned: Bool,
                       mailInfo: AuditMailInfo?,
                       customMoreActionList: [CustomMoreActionProviderImpl]?,
                       origin: String,
                       fromVC: UIViewController) {
        if let filePath = shouldOpenLocalCache(fileToken: fileToken) {
            startLocalImagesReview(fileURL: filePath.url, fileType: typeStr, fileName: fileName, mailInfo: mailInfo, from: fromVC, origin: origin)
        } else {
            openOnlineDriveFile(fileToken: fileToken,
                                typeStr: typeStr,
                                isLarge: isLarge,
                                isBanned: isBanned,
                                mailInfo: mailInfo,
                                customMoreActionList: customMoreActionList,
                                origin: origin,
                                fromVC: fromVC)
        }
        if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false), isLarge {
            // 超大附件才需要上报 PV
            MailDataServiceFactory.commonDataService?.countLargeAttachmentPV(fileToken)
                .subscribe(onNext: { _ in
                    MailLogger.info("countLargeAttachmentPV success.")
                }, onError: { error in
                    MailLogger.info("countLargeAttachmentPV error: \(error)")
                }).disposed(by: disposeBag)
        }
    }
    
    func openOnlineDriveFile(fileToken: String,
                             typeStr: String,
                             isLarge: Bool,
                             isBanned: Bool,
                             mailInfo: AuditMailInfo?,
                             customMoreActionList: [CustomMoreActionProviderImpl]?,
                             origin: String,
                             fromVC: UIViewController)  {
        guard let userId = accountContext.user.info?.userID else { return }
        // 使用的drive提供的预览
        let type = DriveFileType(fileExtension: typeStr)
        let actions = getOnlinePreviewActions(fileToken: fileToken,
                                              type: type,
                                              isLarge: isLarge,
                                              fromVC: fromVC,
                                              mailInfo: mailInfo,
                                              customMoreActionList: customMoreActionList,
                                              origin: origin,
                                              isBanned: isBanned)
        let fileEntity = DriveThirdPartyFileEntity(fileToken: fileToken, docsType: .file, mountNodePoint: userId, mountPoint: mountPoint, actions: actions, handleBizPermission: { _ in return nil })
        accountContext.provider
            .attachmentPreview?
            .driveThirdPartyActtachController(files: [fileEntity], index: 0, from: fromVC)
    }
    
    // 无网络&本地已缓存
    func shouldOpenLocalCache(fileToken: String) -> IsoPath? {
        guard accountContext.featureManager.open(.offlineCache, openInMailClient: false),
                accountContext.featureManager.open(.offlineCacheImageAttach, openInMailClient: false) else {
            MailLogger.info("offline cache image and attachment disable")
            return nil
        }
        let attachCache = accountContext.sharedServices.preloadCacheManager.attachCache
        
        if let reachablility = Reachability(),
           reachablility.connection == .none,
           let result = attachCache.getFile(key: fileToken), result.path.exists {
            return result.path
        } else {
            return nil
        }
    }
    

    func startImagesPreview(targeToken: String, imageItems: [AttachmentPreviewImageItem], type: DriveFileType, mailInfo: AuditMailInfo?, from: UIViewController, origin: String, isBanned: Bool) {
        guard !targeToken.isEmpty, !imageItems.isEmpty, let userId = accountContext.user.info?.userID else {
            mailAssertionFailure("image preview something wrong")
            return
        }
        // find index
        let index = imageItems.firstIndex { (item) -> Bool in
            return item.token == targeToken
        }
        let actions = getOnlinePreviewActions(fileToken: targeToken, type: type, isLarge: false, fromVC: from, mailInfo: mailInfo, customMoreActionList: nil, origin: origin, isBanned: isBanned)
        // construct items
        let entities = imageItems.map { (item) -> DriveThirdPartyFileEntity in
            return DriveThirdPartyFileEntity(fileToken: item.token,
                                             docsType: .file,
                                             mountNodePoint: userId,
                                             mountPoint: mountPoint,
                                             fileType: item.fileType,
                                             actions: actions,
                                             handleBizPermission: { _ in return nil })
        }

        // 使用的drive提供的预览
        accountContext.provider.attachmentPreview?.driveThirdPartyActtachController(files: entities,
                                                                     index: index ?? 0,
                                                                     from: from)
        /*
        let body = DriveThirdPartyAttachControllerBody(files: entities,
                                                       index: index ?? 0,
                                                       actions: getActions(fileToken: targeToken, type: type, isLarge: false, fromVC: from),
                                                       bussinessId: "mail")
        navigator?.push(body: body, naviParams: nil, from: from, animated: true, completion: nil)
        */
    }

    func startLocalImagesReview(fileURL: URL, fileType: String, fileName: String, mailInfo: AuditMailInfo?, from: UIViewController, origin: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let actions = self.getLocalPreviewActions(fromVC: from, mailInfo: mailInfo, localPath: fileURL.absoluteString, origin: origin)
            let entity = DriveLocalFileEntity(fileURL: fileURL, name: fileName, fileType: fileType, canExport: true, actions: actions)
            self.accountContext.provider.attachmentPreview?.driveLocalFileController(files: [entity], index: 0, from: from)
        }
    }

    /// 本地附件预览Drive目前只支持其他应用打开 & 保存到文件
    func getLocalPreviewActions(fromVC: UIViewController, mailInfo: AuditMailInfo?, localPath: String?, origin: String) -> [DriveAlertVCAction] {
        var actions: [DriveAlertVCAction] = []
        actions.append(contentsOf: [.openWithOtherApp(callback: openWithOtherAppCallback(mailInfo: mailInfo, localPath: localPath, isLarge: false, origin: origin))])
        switch source {
        case .readMail:
            actions.append(.saveToLocal(handler: saveToLocalCallback(mailInfo: mailInfo, localPath: localPath, isLarge: false, origin: origin)))
        case .sendMail:
            ()
        case .attachMentManager:
            ()
        }
        return actions
    }
    

    func getOnlinePreviewActions(fileToken: String, type: DriveFileType, isLarge: Bool, fromVC: UIViewController, mailInfo: AuditMailInfo?, customMoreActionList: [CustomMoreActionProviderImpl]?, origin: String, isBanned: Bool) -> [DriveAlertVCAction] {
        let shareAttachmentAction: DriveAlertVCAction = .forward(handler: { [weak self] (vc, dic) in
            guard let self = self else { return }
            let limieSize: UInt64 = 50
            if dic.size > limieSize * 1024 * 1024 {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Attachment_LargeAttachmentCannotShareToChatToast, on: vc.view,
                                           event: ToastErrorEvent(event: .read_preview_largefile_send_to_chat_fail))
                return
            }
            MailTracker.log(event: "email_attachment_share", params: ["attachment_size_byte": dic.size])
            NewCoreEvent.messageListShareAttachment().post()
            self.accountContext.provider
                .routerProvider?
                .forwardShareMailAttachementBody(title: dic.name,
                                                 img: UIImage.fileLadderIcon(with: dic.name),
                                                 token: fileToken,
                                                 fromVC: fromVC,
                                                 isLargeAttachment: isLarge) { [weak self] forwardResult in
                    guard let mailInfo = mailInfo else {
                        return
                    }
                    guard let items = forwardResult.items, items.count > 0 else {
                        if let error = forwardResult.error {
                            MailLogger.error("shareAttachment error \(error)")
                        } else {
                            MailLogger.error("shareAttachment error without error")
                        }
                        return
                    }
                    self?.accountContext.securityAudit.audit(type: .driveFileShareToChat(mailInfo: mailInfo, isLarge: isLarge,
                                                                                         fileInfo: dic, shareInfo: AuditShareAttachmentInfo.fromForwardItems(items), origin: origin))
                }
        })
        var actions: [DriveAlertVCAction] = []
        if accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
            if !isBanned {
                actions.append(shareAttachmentAction)
            }
        } else if !isLarge {
            actions.append(shareAttachmentAction)
        }
        let openWithAppCallback = openWithOtherAppCallback(mailInfo: mailInfo, localPath: nil, isLarge: isLarge, origin: origin)
        actions.append(contentsOf: [.saveToSpace, .openWithOtherApp(callback: openWithAppCallback)])
        switch source {
        case .readMail:
            let callback = saveToLocalCallback(mailInfo: mailInfo, localPath: nil, isLarge: isLarge, origin: origin)
            actions.append(.saveToLocal(handler: callback))
        case .sendMail:
            break
        case .attachMentManager:
            let callback = saveToLocalCallback(mailInfo: mailInfo, localPath: nil, isLarge: isLarge, origin: origin)
            actions.append(.saveToLocal(handler: callback))
            if let custom = customMoreActionList {
                for customAction in custom {
                    actions.append(.customUserDefine(impl:customAction))
                }
            }
            break
        }
        return actions
    }

    private func openWithOtherAppCallback(mailInfo: AuditMailInfo?, localPath: String?, isLarge: Bool, origin: String) -> ((DriveAttachmentInfo, String, Bool) -> Void) {
        return { [weak self] info, appID, isSuccess in
            guard appID.count > 0 else {
                MailLogger.info("Mail openWithOtherAppCallback no appID")
                return
            }
            NewCoreEvent.messageListLocalOpenAttachment(fileType: info.type).post()
            if let mailInfo = mailInfo {
                var info = info
                if let localPath = localPath {
                    info = DriveAttachmentInfo.localAuditInfo(localPath: localPath, info: info)
                }
                self?.accountContext.securityAudit.audit(type: .driveFileOpenViaApp(mailInfo: mailInfo, isLarge: isLarge, appID: appID, isSuccess: isSuccess, fileInfo: info, origin: origin))
            }
        }
    }

    private func saveToLocalCallback(mailInfo: AuditMailInfo?, localPath: String?, isLarge: Bool, origin: String) -> ((UIViewController, DriveAttachmentInfo) -> Void) {
        return { [weak self] _, info in
            NewCoreEvent.messageListDownloadAttachment().post()
            if let mailInfo = mailInfo {
                var info = info
                if let localPath = localPath {
                    info = DriveAttachmentInfo.localAuditInfo(localPath: localPath, info: info)
                }
                self?.accountContext.securityAudit.audit(type: .driveFileDownload(mailInfo: mailInfo, isLarge: isLarge, fileInfo: info, origin: origin))
            }
        }
    }
}
