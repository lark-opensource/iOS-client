//
//  MailImageBrowser.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/13.
//

import Foundation
import LarkAssetsBrowser
import LarkUIKit
import EENavigator
import UniverseDesignToast
import UniverseDesignActionPanel
import ByteWebImage
import LarkImageEditor
import Photos
import LarkCache
import RxSwift
import LarkActionSheet
import UniverseDesignIcon
import LarkSensitivityControl
import LarkStorage

class MailImageBrowser: LKAssetBrowser {
    private var qrCodeScanResult: String?
    private var editingAsset: LKAsset?
    let imageCache: MailImageCacheProtocol
    var auditHandler: ImageAuditHandler?
    var eventTracker: ImageEventTracker
    var serviceProvider: ServiceProvider?
    let scanQRAction: (String, LKDisplayAsset) -> Void
    var qrResults: [String: (hasQRCode: Bool, code: String?)] = [:]
    weak var fromVC: UIViewController?

    func hasQRCode() -> Bool {
        return qrResults.values.map({ $0.hasQRCode }).reduce(false, { $0 || $1 })
    }

    init(
        imageCache: MailImageCacheProtocol,
        auditHandler: ImageAuditHandler?,
        eventTracker: ImageEventTracker,
        serviceProvider: ServiceProvider?,
        scanQRAction: @escaping (String, LKDisplayAsset) -> Void
    ) {
        self.imageCache = imageCache
        self.auditHandler = auditHandler
        self.eventTracker = eventTracker
        self.serviceProvider = serviceProvider
        self.scanQRAction = scanQRAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showPluginsActionSheet(forAsset asset: LKAsset, page: LKAssetBrowserPage, isLongPress: Bool) {
        super.showPluginsActionSheet(forAsset: asset, page: page, isLongPress: isLongPress)
        // 添加埋点
        eventTracker.showMenu(hasQRCode: qrCodeScanResult != nil, enterType: isLongPress ? "hold_click" : "click_more")
    }

    /// 迁移代码：实现打开图片编辑器
    func showEditImageViewController(image: UIImage, asset: LKAsset?, from: NavigatorFrom) {
        guard image.size.width * image.size.height < CGFloat(2160 * 3840) else {
            if let window = self.view.window {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_UnableEditExtraLargeImage_Toast, on: window)
            }
            return
        }
        editingAsset = asset
        let imageEditVC = ImageEditorFactory.createEditor(with: image)
        imageEditVC.delegate = self
        let navigationVC = LkNavigationController(rootViewController: imageEditVC)
        navigationVC.modalPresentationStyle = .fullScreen
        serviceProvider?.resolver.navigator.present(navigationVC, from: from, animated: false)
    }

    /// 迁移代码：实现从其他 App 打开
    func openWithOtherApp(image: UIImage, asset: LKAsset, from viewController: UIViewController) {
        if LarkCache.isCryptoEnable() {
            if let window = viewController.view.window {
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_FileCantShareOrOpenViaThirdPartyApp_Toast, on: window)
            }
        }  else {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { [weak self] (type, completed, array, error) in
                guard completed, let type = type?.rawValue else { return }
                DispatchQueue.global().async {
                    self?.updateAuditInfo(for: asset, image: image, data: nil)
                    self?.auditHandler?.openWithOtherApp(asset: asset, appID: type)
                }
            }
            viewController.present(activityVC, animated: true, completion: nil)
        }
    }

    /// 迁移代码：实现分享到会话
    func shareToChat(image: UIImage, asset: LKAsset, from viewController: UIViewController, shouldDismissFromVC: Bool) {
        serviceProvider?.forwardProvider?.forwardImage(
            image,
            needFilterExternal: false,
            from: viewController,
            shouldDismissFromVC: shouldDismissFromVC,
            cancelCallBack: nil,
            forwardResultCallBack: { [weak self] result in
                guard let self = self else { return }
                if let result = result {
                    DispatchQueue.global().async { [weak self] in
                        self?.updateAuditInfo(for: asset, image: image, data: nil)
                        self?.auditHandler?.shareToChat(asset: asset, forwardResult: result)
                    }
                }
                if result?.error != nil {
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_ShareImageToChat_UnableToShare_Toast, on: self.view)
                } else {
                    UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_ShareImageToChat_Shared_Toast, on: self.view)
                }
        })
    }

    /// 迁移代码：实现保存图片到相册
    func saveImageToAlbum(imageAsset: LKAsset, image: UIImage?, tokenForAsset: String, tokenForCreationRequest: String, from: UIViewController?, saveImageCompletion: ((Bool) -> Void)?) {
        guard let window = from?.view.window, let image = image else {
            saveImageCompletion?(false)
            return
        }

        if LarkCache.isCryptoEnable() {
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_FileCantSaveLocally_Toast, on: window)
            saveImageCompletion?(false)
        } else {
            var saveImageSuccess = true
            var downloadedImageData: Data?
            PHPhotoLibrary.shared().performChanges { [weak self] in
                guard let self = self else { return }
                // 优先使用原图
                if let data = self.getData(from: imageAsset) {
                    do {
                        downloadedImageData = data
                        try AlbumEntry.forAsset(forToken: Token(tokenForAsset)).addResource(with: .photo, data: data, options: nil)
                    } catch {
                        saveImageSuccess = false
                    }
                } else if let data = (image as? ByteImage)?.animatedImageData {
                    do {
                        downloadedImageData = data
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
                        DispatchQueue.global().async {
                            self?.updateAuditInfo(for: imageAsset, image: image, data: downloadedImageData)
                            self?.auditHandler?.downloadImage(asset: imageAsset)
                        }
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

    private func updateAuditInfo(for asset: LKAsset, image: UIImage, data: Data?) {
        var imageData = data
        if imageData == nil {
            if let data = self.getData(from: asset) {
                imageData = data
            } else if let data = (image as? ByteImage)?.animatedImageData {
                imageData = data
            } else {
                imageData = image.pngData()
            }
        }
        guard let imageData = imageData else { return }
        auditHandler?.updateFileInfo(
            asset: asset,
            fileType: imageData.mail.imagePreviewType,
            fileSize: UInt64(imageData.count)
        )
    }

    private func getData(from imageAsset: LKAsset) -> Data? {
        if let localAsset = imageAsset as? MailLocalImageAsset { // 本地图片直接读路径
            return try? Data.read(from: URL(fileURLWithPath: localAsset.identifier).asAbsPath())
        } else {
            return imageCache.get(key: imageAsset.identifier, type: .transient)
        }
    }

    /// 迁移代码：实现扫描二维码
    func scanQRCode(_ code: String) {
        guard let fromVC = fromVC else { return }
        dismiss(animated: false) {
            self.serviceProvider?.qrCodeAnalysisProvider?.handle(code: code, fromVC: fromVC) { [weak fromVC] errorInfo in
                guard let window = fromVC?.view.window else { return }
                if let errorInfo = errorInfo {
                    UDToast.showFailure(with: errorInfo, on: window)
                } else {
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_ImageQRCodeError_Toast, on: window)
                }
            }
        }
    }
}

// 处理 ImageEditor 回调
extension MailImageBrowser: ImageEditViewControllerDelegate {
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
            // 这里没有传入真正的 imageAsset，原有逻辑如此，应该只影响到埋点，暂不处理
            self?.saveImageToAlbum(imageAsset: MailLocalImageAsset(url: ""),
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
        serviceProvider?.resolver.navigator.present(actionSheet, from: vc)
        eventTracker.showEditFinishMenu()
    }
}
