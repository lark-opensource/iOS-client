//
//  SKImageActionHandler.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/17.
//  

import Foundation
import LarkUIKit
import LarkFoundation
import UniverseDesignActionPanel
import Photos
import EENavigator
import SKResource
import LarkAssetsBrowser
import SKUIKit
import SKFoundation
import ByteWebImage
import LarkSensitivityControl
import SKInfra

// swiftlint:disable class_delegate_protocol
public protocol SKAssetBrowserActionHandlerDelegate: SKExecJSFuncService {
// swiftlint:enable class_delegate_protocol
    func savePhotoWithTip(_ tip: String)
    func savePhotoFail()
    func savePhotoSuccess()
    func photoWillBeSavedStatistics()
    func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController)
    ///除了save和取消外，自定义的action
    func customActionsForPhotoType(type: SKPhotoType, image: UIImage?, asset: LKDisplayAsset, in browser: LKAssetBrowserViewController) -> [LarkActionSheetItem]

    func willSwipeTo(_ index: Int)

    ///请求DiagramPhoto照片数据
    func saveDiagramPhoto(uuid: String)
    func showFailHub(_ message: String)
    func checkDownloadPermission(_ showTips: Bool, isAttachment: Bool, imageDocsInfo: DocsInfo?) -> Bool
}

open class SKAssetBrowserActionHandler: LKAssetBrowserActionHandler {
    public weak var skActionDelegate: SKAssetBrowserActionHandlerDelegate?

    override open func handleSavePhoto(image: UIImage, saveImageCompletion: ((Bool) -> Void)?) {
        savePhoto(image, saveImageCompletion: saveImageCompletion)
    }

    public func savePhoto(_ image: UIImage, asset: LKDisplayAsset? = nil, saveImageCompletion: ((Bool) -> Void)?) {
        // 权限管控
        guard let canDownload = skActionDelegate?.checkDownloadPermission(true, isAttachment: true, imageDocsInfo: asset?.imageDocsInfo), canDownload else {
            saveImageCompletion?(false)
            return
        }
        var storeImage = image
        let isGif = asset?.isGif ?? false
        if isGif, let cropData = asset?.crop {
            let (needCrop, _) = SKImagePreviewUtils.cropRect(cropScale: cropData)
            if needCrop, let cgImage = image.cgImage {
                //与PC、Android对齐，裁剪过的动图仅取首帧
                storeImage = UIImage(cgImage: cgImage)
            }
        }
        SKAssetBrowserActionHandler.savePhoto(image: storeImage) { [weak self] (success, granted, isCrypto) in
            guard let self = self else { return }
            if isCrypto == true {
                self.skActionDelegate?.savePhotoWithTip(BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast)
                saveImageCompletion?(false)
            } else if granted == false {
                self.delegate?.photoDenied()
                saveImageCompletion?(false)
            } else if success {
                self.skActionDelegate?.savePhotoSuccess()
                saveImageCompletion?(true)
            } else {
                self.skActionDelegate?.savePhotoFail()
                saveImageCompletion?(false)
            }
        }
    }

    open override func handleLongPressFor(image: UIImage, asset: LKDisplayAsset, browser: LKAssetBrowserViewController) {
        let sourceView = browser.currentPageView ?? UIView()
        let sourceRect = CGRect(origin: browser.currentPageView?.longGesture.location(in: browser.currentPageView) ?? .zero, size: .zero)
        let popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceRect)
        let actionSheet = UDActionSheet.actionSheet(popSource: popSource)
        let additonActionSheetItems = self.skActionDelegate?.customActionsForPhotoType(type: .normal, image: image, asset: asset, in: browser) ?? []
        for item in additonActionSheetItems {
            actionSheet.addItem(text: item.title, action: item.action)
        }
        
        let canDownload = skActionDelegate?.checkDownloadPermission(false, isAttachment: true, imageDocsInfo: asset.imageDocsInfo) ?? false
        
        let textColor = !canDownload ? UIColor.ud.N900.withAlphaComponent(0.3) : UIColor.ud.N900
        let savePicItem = saveItem(with: .normal, image: image, asset: asset)
        actionSheet.addItem(text: savePicItem.title, textColor: textColor, action: savePicItem.action)
        
        let canceItem = cancelItem()
        actionSheet.addItem(text: canceItem.title, action: canceItem.action)
        browser.present(actionSheet, animated: true, completion: nil)
    }

    open override func handleLongPressForSVG(asset: LKDisplayAsset, browser: LKAssetBrowserViewController) {
        let sourceView = browser.currentPageView ?? UIView()
        let sourceRect = CGRect(origin: browser.currentPageView?.longGesture.location(in: browser.currentPageView) ?? .zero, size: .zero)
        let popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceRect)
        let actionSheet = UDActionSheet.actionSheet(popSource: popSource)
        let additonActionSheetItems = self.skActionDelegate?.customActionsForPhotoType(type: .diagramSVG, image: nil, asset: asset, in: browser) ?? []
        
        for item in additonActionSheetItems {
            actionSheet.addItem(text: item.title, action: item.action)
        }
        let canDownload = skActionDelegate?.checkDownloadPermission(false, isAttachment: false, imageDocsInfo: asset.imageDocsInfo) ?? false
        let textColor = !canDownload ? UIColor.ud.N900.withAlphaComponent(0.3) : UIColor.ud.N900
        let savePicItem = saveItem(with: .diagramSVG, image: nil, asset: asset)
        if canDownload {
            actionSheet.addItem(text: savePicItem.title, textColor: textColor, action: savePicItem.action)
        }
        
        let canceItem = cancelItem()
        actionSheet.addItem(text: canceItem.title, action: canceItem.action)
        browser.present(actionSheet, animated: true, completion: nil)
    }

    func saveItem(with type: SKPhotoType, image: UIImage?, asset: LKDisplayAsset) -> LarkActionSheetItem {
        let saveItem = LarkActionSheetItem(title: BundleI18n.SKResource.Doc_Doc_SaveImage) { [weak self] in
            guard let self = self else { return }
            switch type {
            case .normal:
                if let image = image {
                    self.savePhoto(image, asset: asset, saveImageCompletion: nil)
                }
            case .diagramSVG:
                self.skActionDelegate?.saveDiagramPhoto(uuid: asset.key)
            }
            self.skActionDelegate?.photoWillBeSavedStatistics()
        }
        return saveItem
    }

    func cancelItem() -> LarkActionSheetItem {
        let cancelItem = LarkActionSheetItem(title: BundleI18n.SKResource.Doc_Facade_Cancel) {
        }
        return cancelItem
    }

    func willExit(assetVC: SKAssetBrowserViewController) {
        skActionDelegate?.skAssetBrowserVCWillDismiss(assetVC: assetVC)

        skActionDelegate?.callFunction(DocsJSCallBack.closeImg, params: nil, completion: nil)
    }

    open func willSwipeTo(_ index: Int) {
        skActionDelegate?.willSwipeTo(index)
    }
}

extension SKAssetBrowserActionHandler {
    static func savePhoto(image: UIImage, handler: @escaping (_ success: Bool, _ granted: Bool, _ isCrypto: Bool) -> Void) {
        if CacheService.isDiskCryptoEnable() {
                //KACrypto
                DocsLogger.error("[KACrypto] 开启KA加密不能保存图片")
                handler(false, false, true)
                return
        }
        do {
            try Utils.savePhoto(token: Token(PSDATokens.Comment.comment_preview_image_click_download), image: image, handler: { success, granted in
                handler(success, granted, false)
            })
        } catch {
            DocsLogger.error("Utils savePhoto error")
            handler(false, false, false)
        }
    }
    
    static func savePhoto(img: UIImage, callback: @escaping (_ success: Bool, _ granted: Bool) -> Void) {
        Utils.savePhoto(image: img, handler: callback)
    }
}
