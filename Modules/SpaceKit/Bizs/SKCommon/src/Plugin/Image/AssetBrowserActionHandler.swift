//
//  AssetBrowserActionHandler.swift
//  SpaceKit
//
//  Created by nine on 2019/2/1.
//

import Foundation
import LarkUIKit
import Photos
import SKResource
import LarkAssetsBrowser
import SKUIKit

public protocol AssetBrowserActionsDelegate {
    func willSwipeTo(_ index: Int)
    func checkDownloadPermission(_ showTips: Bool, isAttachment: Bool, imageDocsInfo: DocsInfo?) -> Bool
}

public final class AssetBrowserActionHandler: SKAssetBrowserActionHandler, SKAssetBrowserActionHandlerDelegate {
    public func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController) {
        actionDelegate?.skAssetBrowserVCWillDismiss(assetVC: assetVC)
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        actionDelegate?.callFunction(function, params: params, completion: completion)
    }

    public weak var actionDelegate: AssetBrowserActionDelegate?
    public var scanQR: ((String) -> Void)?
    override public init() {
        super.init()
        self.skActionDelegate = self
    }

    public override func handleSaveAsset(_ asset: LKDisplayAsset, relatedImage: UIImage?, saveImageCompletion: ((Bool) -> Void)?) {
        if let image = relatedImage {
            actionDelegate?.assetBrowserAction(self, statisticsAction: "icon_download")
            actionDelegate?.assetBrowserActionSaveImageStatistics(uuid: asset.key)
            savePhoto(image, asset: asset, saveImageCompletion: saveImageCompletion)
        }
    }

    public override func handleSaveSVG(_ asset: LKDisplayAsset) {
        guard asset.isSVG, asset.key.count > 0 else {
            skError("保存SVG图片失败，数据获取失败", extraInfo: nil, error: nil, component: nil)
            self.skActionDelegate?.savePhotoFail()
            return
        }

        // 权限管控
        guard checkDownloadPermission(true, isAttachment: false, imageDocsInfo: asset.imageDocsInfo) else {
            return
        }
        saveDiagramPhoto(uuid: asset.key)
    }

    public func saveDiagramPhoto(uuid: String) {
        //KACrypto
        if CacheService.isDiskCryptoEnable() {
            skError("[KACrypto] 开启KA加密不能保存图片", extraInfo: nil, error: nil, component: nil)
            self.skActionDelegate?.savePhotoWithTip(BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast)
            return
        }
        actionDelegate?.assetBrowserAction(self, statisticsAction: "icon_download")
        self.actionDelegate?.requestDiagramDataWith(uuid: uuid)
    }

    public func savePhotoSuccess() {
        self.actionDelegate?.showSuccessHub(message: BundleI18n.SKResource.Doc_Doc_SaveImage + BundleI18n.SKResource.Doc_Normal_Success)
    }

    public func savePhotoFail() {
        self.actionDelegate?.showFailHub(message: BundleI18n.SKResource.Doc_Doc_SaveImage + BundleI18n.SKResource.Doc_AppUpdate_FailRetry)
    }

    public func savePhotoWithTip(_ tip: String) {
        self.actionDelegate?.showTipHub(message: tip)
    }
    
    public func showFailHub(_ message: String) {
        self.actionDelegate?.showFailHub(message: message)
    }
    
    public func checkDownloadPermission(_ showTips: Bool, isAttachment: Bool, imageDocsInfo: DocsInfo?) -> Bool {
        return self.actionDelegate?.checkDownloadPermission(showTips, isAttachment: isAttachment, imageDocsInfo: imageDocsInfo) ?? false
    }

    public func photoWillBeSavedStatistics() {
        self.actionDelegate?.assetBrowserAction(self, statisticsAction: "press_download")
    }

    override public func willSwipeTo(_ index: Int) {
        self.actionDelegate?.willSwipeTo(index)
    }
}

extension AssetBrowserActionHandler {
    func qrItem(_ scanQR: @escaping ((String) -> Void), with code: String) -> LarkActionSheetItem {
        let qrItem = LarkActionSheetItem(title: BundleI18n.SKResource.Doc_Doc_ScanQRCode) { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.assetBrowserAction(self, statisticsAction: "press_scan_qrcode")
            scanQR(code)
        }
        return qrItem
    }

    func shareToLarkItem(with type: SKPhotoType, image: UIImage?, asset: LKDisplayAsset) -> LarkActionSheetItem {
        let shareToLarkItem = LarkActionSheetItem(title: BundleI18n.SKResource.Doc_Doc_SendToChat) { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.assetBrowserAction(self, statisticsAction: "press_send_lark")
            self.actionDelegate?.shareItem(with: type, image: image, uuid: asset.key)
        }
        return shareToLarkItem
    }

    public func customActionsForPhotoType(type: SKPhotoType, image: UIImage?, asset: LKDisplayAsset, in browser: LKAssetBrowserViewController) -> [LarkActionSheetItem] {
        guard !DocsSDK.isInDocsApp else { return [] }
        var items = [LarkActionSheetItem]()
        if !DocsSDK.isInLarkDocsApp { //在单品不显示分享至会话
            items.append(shareToLarkItem(with: type, image: image, asset: asset))
        }
        if let scanQR = scanQR {
            let qrCodeScanResult = browser.view.ext.screenshot()
                .flatMap { scan(from: $0) }
            if let code = qrCodeScanResult { items.append(qrItem(scanQR, with: code)) }
        }
        return items
    }
}

extension AssetBrowserActionHandler {
    private func scan(from img: UIImage) -> String? {
        var result: String?
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                        context: nil,
                                        options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
                                            return result
        }
        let ciImg = CIImage(cgImage: img.cgImage!)
        let features = detector.features(in: ciImg, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        if let featureTmp = features.first as? CIQRCodeFeature {
            result = featureTmp.messageString
        }
        return result
    }
}
