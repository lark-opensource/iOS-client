//
//  MailImageViewerService.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/11/21.
//

import Foundation
import LarkUIKit
import EENavigator
import LarkAssetsBrowser
import UniverseDesignToast
import ByteWebImage
import RxSwift
import LarkStorage

struct ImageAuditHandler {
    let mailInfo: AuditMailInfo
    let securityAudit: MailSecurityAudit
    var fileInfos = [DriveAttachmentInfo]()
    let origin: String

    init(mailInfo: AuditMailInfo, securityAudit: MailSecurityAudit, origin: String) {
        self.mailInfo = mailInfo
        self.securityAudit = securityAudit
        self.origin = origin
    }

    mutating func updateFileInfo(asset: LKAsset, fileType: String, fileSize: UInt64) {
        guard let fileInfo = fileInfo(for: asset),
              let index = fileInfos.firstIndex(of: fileInfo) else { return }
        if fileInfos[index].type.isEmpty {
            fileInfos[index].type = fileType
        }
        if fileInfos[index].size == 0 {
            fileInfos[index].size = fileSize
        }
    }

    func downloadImage(asset: LKDisplayAsset) {
        guard let fileInfo = fileInfo(for: asset) else { return }
        securityAudit.audit(type: .driveFileDownload(mailInfo: mailInfo, isLarge: false, fileInfo: fileInfo, origin: origin))
    }
    // 新版本图片查看器适配
    func downloadImage(asset: LKAsset) {
        guard let fileInfo = fileInfo(for: asset) else { return }
        securityAudit.audit(type: .driveFileDownload(mailInfo: mailInfo, isLarge: false, fileInfo: fileInfo, origin: origin))
    }
    
    func openWithOtherApp(asset: LKDisplayAsset, appID: String) {
        guard let fileInfo = fileInfo(for: asset) else { return }
        securityAudit.audit(type: .driveFileOpenViaApp(mailInfo: mailInfo, isLarge: false, appID: appID, isSuccess: true, fileInfo: fileInfo, origin: origin))
    }
    // 新版本图片查看器适配
    func openWithOtherApp(asset: LKAsset, appID: String) {
        guard let fileInfo = fileInfo(for: asset) else { return }
        securityAudit.audit(type: .driveFileOpenViaApp(mailInfo: mailInfo, isLarge: false, appID: appID, isSuccess: true, fileInfo: fileInfo, origin: origin))
    }
    
    func shareToChat(asset: LKDisplayAsset, forwardResult: MailAttachmentForwardResult) {
        guard let fileInfo = fileInfo(for: asset) else { return }
        guard let items = forwardResult.items, items.count > 0 else {
            if let error = forwardResult.error {
                MailLogger.error("shareAttachment error \(error)")
            } else {
                MailLogger.error("shareAttachment error without error")
            }
            return
        }
        securityAudit.audit(type: .driveFileShareToChat(
            mailInfo: mailInfo,
            isLarge: false,
            fileInfo: fileInfo,
            shareInfo: AuditShareAttachmentInfo.fromForwardItems(items),
            origin: origin)
        )
    }

    // 新版本图片查看器适配
    func shareToChat(asset: LKAsset, forwardResult: MailAttachmentForwardResult) {
        guard let fileInfo = fileInfo(for: asset) else { return }
        guard let items = forwardResult.items, items.count > 0 else {
            if let error = forwardResult.error {
                MailLogger.error("shareAttachment error \(error)")
            } else {
                MailLogger.error("shareAttachment error without error")
            }
            return
        }
        securityAudit.audit(type: .driveFileShareToChat(
            mailInfo: mailInfo,
            isLarge: false,
            fileInfo: fileInfo,
            shareInfo: AuditShareAttachmentInfo.fromForwardItems(items),
            origin: origin)
        )
    }
    
    private func fileInfo(for asset: LKDisplayAsset) -> DriveAttachmentInfo? {
        if let fileInfo = fileInfos.first(where: { $0.token == asset.originalUrl } ), !fileInfo.token.isEmpty {
            return fileInfo
        } else {
            return nil
        }
    }
    // 新版本图片查看器适配
    private func fileInfo(for asset: LKAsset) -> DriveAttachmentInfo? {
        let assetToken: String
        if let url = (asset as? MailDriveImageAsset)?.url {
            assetToken = url
        } else if let url = (asset as? MailLocalImageAsset)?.url {
            assetToken = url
        } else {
            return nil
        }
        if let fileInfo = fileInfos.first(where: { $0.token == assetToken } ), !fileInfo.token.isEmpty {
            return fileInfo
        } else {
            return nil
        }
    }
}

struct ImageEventTracker {
    let labelItem: String
    var previousEnterType: String = ""
    var totalImageCount: Int = 0

    func openViewer(at index: Int) {
        post(event: .email_image_detail_view,
             params: ["image_order": index,
                      "image_num": totalImageCount])
    }
    
    func clickOuterAction(_ action: String, at index: Int) {
        post(event: .email_image_detail_click,
             params: ["click": action,
                      "target": "none",
                      "image_order": index,
                      "image_num": totalImageCount])
    }
    
    mutating func showMenu(hasQRCode: Bool, enterType: String) {
        previousEnterType = enterType
        post(event: .email_image_action_menu_view,
             params: ["is_qrcode_show": hasQRCode ? "true" : "false",
                      "enter_type": enterType])
    }
    
    func clickMenuAction(_ action: String, hasQRCode: Bool) {
        post(event: .email_image_action_menu_click,
             params: ["click": action,
                      "target": "none",
                      "is_qrcode_show": hasQRCode ? "true" : "false",
                      "enter_type": previousEnterType])
    }
    
    func showEditFinishMenu() {
        post(event: .email_image_edit_finish_menu_view, params: [:])
    }
    
    func clickEditFinishMenu(action: String) {
        post(event: .email_image_edit_finish_menu_click,
             params: ["click": action,
                      "target": "none"])
    }
    
    private func post(event: NewCoreEvent.EventName, params: [String: Any]) {
        let event = NewCoreEvent(event: event)
        var params = params
        params["label_item"] = labelItem
        event.params = params
        event.post()
    }
}

final class MailImageViewerService {
    let accountContext: MailAccountContext
    
    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
    }
    
    func openDriveImageViewer(
        tokens: [String],
        pageIndex: Int = 0,
        from viewController: UIViewController,
        auditHandler: ImageAuditHandler?,
        eventTracker: ImageEventTracker
    ) {
        if accountContext.featureManager.open(.loadThumbImageEnable) {
            // 接入新图片查看器
            let assets = tokens.map({
                MailDriveImageAsset(
                    url: $0,
                    userID: accountContext.user.userID,
                    driveProvider: accountContext.sharedServices.driveDownloader,
                    imageCache: accountContext.imageService.cache,
                    featureManager: accountContext.featureManager
                )
            })
            openNewImageBrowser(
                assets: assets,
                pageIndex: pageIndex,
                from: viewController,
                auditHandler: auditHandler,
                eventTracker: eventTracker
            )
        } else {
            let assets = tokens.map {
                let asset = LKDisplayAsset()
                asset.originalUrl = $0
                return asset
            }


            openViewer(
                assets: assets,
                pageIndex: pageIndex,
                from: viewController,
                auditHandler: auditHandler,
                eventTracker: eventTracker
            ) { [weak self] asset in
                if let imageData = self?.accountContext.imageService.cache.get(key: asset.originalUrl),
                   let image = try? ByteImage(imageData) {
                    return image
                }
                return nil
            }
        }
    }

    func openLocalImageViewer(
        filePaths: [String],
        pageIndex: Int = 0,
        from viewController: UIViewController,
        auditHandler: ImageAuditHandler?,
        eventTracker: ImageEventTracker
    ) {
        if accountContext.featureManager.open(.loadThumbImageEnable) {
            // 接入新图片查看器
            openNewImageBrowser(
                assets: filePaths.map({ MailLocalImageAsset(url: $0) }),
                pageIndex: pageIndex,
                from: viewController,
                auditHandler: auditHandler,
                eventTracker: eventTracker
            )
        } else {
            let assets = filePaths.map {
                let asset = LKDisplayAsset()
                asset.originalUrl = $0
                return asset
            }
            openViewer(
                assets: assets,
                pageIndex: pageIndex,
                from: viewController,
                auditHandler: auditHandler,
                eventTracker: eventTracker
            ) { asset in
                let url = URL(fileURLWithPath: asset.originalUrl)
                if let imageData = try? Data.read(from: url.asAbsPath()),
                   let image = try? ByteImage(imageData) {
                    return image
                }
                return nil
            }
        }
    }

    private func openViewer(
        assets: [LKDisplayAsset],
        pageIndex: Int,
        from viewController: UIViewController,
        auditHandler: ImageAuditHandler?,
        eventTracker: ImageEventTracker,
        setImageBlock: @escaping (LKDisplayAsset) -> UIImage?
    ) {
        guard !assets.isEmpty else {
            MailLogger.error("Open image viewer with empty asset")
            return
        }
        
        var eventTracker = eventTracker
        eventTracker.totalImageCount = assets.count
        eventTracker.openViewer(at: pageIndex)
        
        MailLogger.info("Open image viewer, assets count: \(assets.count), page index: \(pageIndex)")
        
        let config = LKAssetBrowserViewController.ExtensionsConfiguration(getAllAlbumsBlock: nil)
        let handler = MailAssetBrowserActionHandler(
            navigator: accountContext.navigator,
            auditHandler: auditHandler,
            eventTracker: eventTracker,
            forwardProvider: accountContext.provider.forwardProvider,
            scanQRAction: { [weak viewController, weak self] code, _ in
                guard let viewController = viewController else { return }
                self?.accountContext.provider.qrCodeAnalysisProvider?.handle(code: code, fromVC: viewController) { [weak viewController] errorInfo in
                    guard let window = viewController?.view.window else { return }
                    if let errorInfo = errorInfo {
                        UDToast.showFailure(with: errorInfo, on: window)
                    } else {
                        UDToast.showFailure(with: BundleI18n.MailSDK.Mail_ImageQRCodeError_Toast, on: window)
                    }
                }
            })
        let vc = MailImageViewerViewController(assets: assets, pageIndex: pageIndex, actionHandler: handler, buttonType: .stack(config: config))
        vc.isPhotoIndexLabelHidden = false
        handler.browser = vc
        vc.setImageBlock = { (asset, view, _, complete) -> CancelImageBlock? in
            if let image = setImageBlock(asset) {
                complete?(image, nil, nil)
            } else {
                complete?(nil, nil, nil)
            }

            return nil
        }
        accountContext.navigator.present(vc, from: viewController)
    }

    private func openNewImageBrowser(
        assets: [LKAsset],
        pageIndex: Int,
        from viewController: UIViewController,
        auditHandler: ImageAuditHandler?,
        eventTracker: ImageEventTracker
    ) {
        guard !assets.isEmpty else {
            MailLogger.error("Open image viewer with empty asset")
            return
        }

        var eventTracker = eventTracker
        eventTracker.totalImageCount = assets.count
        eventTracker.openViewer(at: pageIndex)

        MailLogger.info("Open image viewer, assets count: \(assets.count), page index: \(pageIndex)")

        let browser = MailImageBrowser(
            imageCache: accountContext.imageService.cache,
            auditHandler: auditHandler,
            eventTracker: eventTracker,
            serviceProvider: accountContext.provider,
            scanQRAction: { _,_ in })
        browser.displayAssets = assets
        browser.currentPageIndex = pageIndex
        browser.pageIndicator = LKAssetNumericPageIndicator()
        browser.plugins = [
            MailImageBrowserSaveImagePlugin(),
            MailImageBrowserShareToChatPlugin(),
            MailImageBrowserOpenInAnotherAppPlugin(),
            MailImageBrowserEditImagePlugin(),
            MailImageBrowserDetectQRCodePlugin()
        ]
        browser.fromVC = viewController
        browser.modalPresentationStyle = .custom
        browser.modalPresentationCapturesStatusBarAppearance = true
        browser.transitioningDelegate = browser
        accountContext.navigator.present(browser, from: viewController)
    }
}
