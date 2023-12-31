//
//  MailImageViewerViewController.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/11/11.
//

import Foundation
import LarkAssetsBrowser
import LarkUIKit
import EENavigator
import UniverseDesignToast
import UniverseDesignActionPanel
import ByteWebImage
import QRCode
import LarkImageEditor
import Photos
import LarkCache
import RxSwift
import LarkActionSheet
import LarkSensitivityControl

final class MailImageViewerViewController: LKAssetBrowserViewController { }

final class MailAssetBrowserActionHandler: LKAssetBrowserActionHandler {
    
    weak var browser: LKAssetBrowserViewController?
    
    private let navigator: Navigatable
    private var qrCodeScanResult: String?
    private var editingAsset: LKDisplayAsset?
    private var auditHandler: ImageAuditHandler?
    private var eventTracker: ImageEventTracker
    private var forwardProvider: MailForwardProxy?
    private let scanQRAction: (String, LKDisplayAsset) -> Void
    
    init(
        navigator: Navigatable,
        auditHandler: ImageAuditHandler?,
        eventTracker: ImageEventTracker,
        forwardProvider: MailForwardProxy?,
        scanQRAction: @escaping (String, LKDisplayAsset) -> Void
    ) {
        self.navigator = navigator
        self.auditHandler = auditHandler
        self.eventTracker = eventTracker
        self.forwardProvider = forwardProvider
        self.scanQRAction = scanQRAction
        super.init()
    }

    override func handleClickMoreButton(image: UIImage, asset: LKDisplayAsset, browser: LKAssetBrowserViewController, sourceView: UIView?) {
        presentActionSheet(image: image, asset: asset, browser: browser, sourceView: sourceView, isFromLongPress: false)
    }

    override func handleClickPhotoEditting(image: UIImage, asset: LKDisplayAsset, from browser: LKAssetBrowserViewController) {
        eventTracker.clickOuterAction("edit_image", at: browser.currentPageIndex)
        showEditImageViewController(image: image, asset: asset, from: browser)
    }

    override func handleLongPressFor(image: UIImage, asset: LKDisplayAsset, browser: LKAssetBrowserViewController, sourceView: UIView?) {
        presentActionSheet(image: image, asset: asset, browser: browser, sourceView: sourceView, isFromLongPress: true)
    }
    
    override func handleSavePhoto(image: UIImage, saveImageCompletion: ((Bool) -> Void)?) {
        eventTracker.clickOuterAction("save_image", at: browser?.currentPageIndex ?? 0)
        saveImageToAlbum(imageAsset: LKDisplayAsset(),
                         image: image,
                         tokenForAsset: MailSensitivityApiToken.saveImageForAsset,
                         tokenForCreationRequest: MailSensitivityApiToken.saveImageCreationRequestForAsset,
                         from: browser,
                         saveImageCompletion: saveImageCompletion)
    }
}

extension MailAssetBrowserActionHandler: ImageEditViewControllerDelegate {
    func closeButtonDidClicked(vc: EditViewController) {
        vc.exit()
        editingAsset = nil
    }

    func finishButtonDidClicked(vc: EditViewController, editImage: UIImage) {
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig())

        // 分享图片
        actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_ShareToChat_Button) { [weak self] in
            guard let asset = self?.editingAsset else {
                MailLogger.error("Click share image while editingAsset is nil")
                return
            }
            self?.editingAsset = nil
            self?.shareToChat(image: editImage, asset: asset, from: vc, shouldDismissFromVC: true)
            self?.eventTracker.clickEditFinishMenu(action: "share_image")
        }
        
        // 保存到相册
        actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_SaveImage_Button) { [weak self] in
            self?.eventTracker.clickEditFinishMenu(action: "save_image")
            self?.saveImageToAlbum(imageAsset: LKDisplayAsset(),
                                   image: editImage,
                                   tokenForAsset: MailSensitivityApiToken.editImageSaveForAsset,
                                   tokenForCreationRequest: MailSensitivityApiToken.editImageSaveCreationRequestForAsset,
                                   from: vc,
                                   saveImageCompletion: { [weak vc] success in
                guard success else { return }
                vc?.exit()
            })
        }

        actionSheet.setCancelItem(text: BundleI18n.MailSDK.Mail_Common_Cancel)
        navigator.present(actionSheet, from: vc)
        
        eventTracker.showEditFinishMenu()
    }
}

private extension MailAssetBrowserActionHandler {
    private func presentActionSheet(image: UIImage,
                                    asset: LKDisplayAsset,
                                    browser: LKAssetBrowserViewController,
                                    sourceView: UIView?,
                                    isFromLongPress: Bool) {
        guard let currentPageView = browser.currentPageView else { return }
        self.browser = browser
        let topmostFrom = WindowTopMostFrom(vc: browser)

        let source: UIView
        let sourceRect: CGRect
        if let sourceView = sourceView {
            source = sourceView
            sourceRect = CGRect(origin: .zero, size: sourceView.bounds.size)
        } else {
            source = currentPageView
            sourceRect = CGRect(origin: currentPageView.longGesture.location(in: currentPageView), size: .zero)
        }

        let popSource = UDActionSheetSource(sourceView: source,
                                            sourceRect: sourceRect)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))

        actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_SaveImage_Button) { [weak self] in
            self?.eventTracker.clickMenuAction("save_image", hasQRCode: self?.qrCodeScanResult != nil)
            self?.saveImageToAlbum(imageAsset: asset,
                                   image: image,
                                   tokenForAsset: MailSensitivityApiToken.saveImageForAsset,
                                   tokenForCreationRequest: MailSensitivityApiToken.saveImageCreationRequestForAsset,
                                   from: browser,
                                   saveImageCompletion: nil)
        }

        // 分享至会话
        actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_ShareToChat_Button) { [weak self] in
            self?.eventTracker.clickMenuAction("share_image", hasQRCode: self?.qrCodeScanResult != nil)
            self?.shareToChat(image: image, asset: asset, from: browser, shouldDismissFromVC: false)
        }
        
        actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_OpenInAnotherApp_Button) { [weak self] in
            self?.eventTracker.clickMenuAction("other_app_open", hasQRCode: self?.qrCodeScanResult != nil)
            self?.openWithOtherApp(image: image, asset: asset, from: browser)
        }

        // 编辑，gif不支持编辑
        if (image as? ByteImage)?.animatedImageData == nil {
            actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_EditImage_Button) { [weak self] in
                guard let self = self else { return }
                self.eventTracker.clickMenuAction("edit_image", hasQRCode: self.qrCodeScanResult != nil)
                self.showEditImageViewController(image: image, asset: asset, from: topmostFrom)
            }
        }

        qrCodeScanResult = browser.view.lu.screenshot().flatMap { QRCodeTool.scan(from: $0) }
        if let code = qrCodeScanResult {
            actionSheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_ViewImage_ScanQRCode_Button) { [weak self] in
                self?.eventTracker.clickMenuAction("qr_code", hasQRCode: self?.qrCodeScanResult != nil)
                self?.delegate?.dismissViewController { self?.scanQRAction(code, asset) }
            }
        }

        actionSheet.setCancelItem(text: BundleI18n.MailSDK.Mail_Common_Cancel)
        navigator.present(actionSheet, from: browser)
        
        eventTracker.showMenu(hasQRCode: qrCodeScanResult != nil, enterType: isFromLongPress ? "hold_click" : "click_more")
    }
    
    private func showEditImageViewController(image: UIImage, asset: LKDisplayAsset?, from: NavigatorFrom) {
        guard image.size.width * image.size.height < 2160 * 3840 else {
            if let window = self.browser?.view.window {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_UnableEditExtraLargeImage_Toast, on: window)
            }
            return
        }
        editingAsset = asset
        let imageEditVC = ImageEditorFactory.createEditor(with: image)
        imageEditVC.delegate = self
        let navigationVC = LkNavigationController(rootViewController: imageEditVC)
        navigationVC.modalPresentationStyle = .fullScreen
        navigator.present(navigationVC, from: from, animated: false)
    }

    private func openWithOtherApp(image: UIImage, asset: LKDisplayAsset, from viewController: UIViewController) {
        if LarkCache.isCryptoEnable() {
            if let window = viewController.view.window {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_FileCantShareOrOpenViaThirdPartyApp_Toast, on: window)
            }
        }  else {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { [weak self] (type, completed, array, error) in
                guard completed, let type = type?.rawValue else { return }
                self?.auditHandler?.openWithOtherApp(asset: asset, appID: type)
            }
            viewController.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func shareToChat(image: UIImage, asset: LKDisplayAsset, from viewController: UIViewController, shouldDismissFromVC: Bool) {
        forwardProvider?.forwardImage(
            image,
            needFilterExternal: false,
            from: viewController,
            shouldDismissFromVC: shouldDismissFromVC,
            cancelCallBack: nil,
            forwardResultCallBack: { [weak self] result in
                guard let self = self, let presentVC = self.viewController else { return }
                if let result = result {
                    self.auditHandler?.shareToChat(asset: asset, forwardResult: result)
                }
                if result?.error != nil {
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_ShareImageToChat_UnableToShare_Toast, on: presentVC.view)
                } else {
                    UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_ShareImageToChat_Shared_Toast, on: presentVC.view)
                }
        })
    }

    private func saveImageToAlbum(imageAsset: LKDisplayAsset, image: UIImage?, tokenForAsset: String, tokenForCreationRequest: String, from: UIViewController?, saveImageCompletion: ((Bool) -> Void)?) {
        guard let window = from?.view.window, let image = image else {
            saveImageCompletion?(false)
            return
        }
        
        if LarkCache.isCryptoEnable() {
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_FileCantSaveLocally_Toast, on: window)
            saveImageCompletion?(false)
        } else {
            var saveImageSuccess = true
            PHPhotoLibrary.shared().performChanges {
                if let data = (image as? ByteImage)?.animatedImageData {
                    do {
                        try AlbumEntry.forAsset(forToken: Token(tokenForAsset)).addResource(with: .photo, data: data, options: nil)
                    } catch {
                        saveImageSuccess = false
                    }
                } else {
                    do {
                        _ = try AlbumEntry.creationRequestForAsset(forToken: Token(tokenForCreationRequest), fromImage: image)
                    } catch {
                        saveImageSuccess = false
                    }
                }
            } completionHandler: { [weak self] (success, _) in
                DispatchQueue.main.async {
                    if success, saveImageSuccess {
                        self?.auditHandler?.downloadImage(asset: imageAsset)
                        UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_ViewImage_SavedToAlbum_Toast, on: window)
                        saveImageCompletion?(true)
                    } else {
                        UDToast.showFailure(with: BundleI18n.MailSDK.Mail_ViewImage_UnableToSave_Toast, on: window)
                        saveImageCompletion?(false)
                    }
                }
            }
        }
    }
}
