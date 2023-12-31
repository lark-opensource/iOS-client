//
//  InputTextView+SelectImg.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/9/18.
// swiftlint:disable line_length

import SKFoundation
import SKUIKit
import LarkUIKit
import SKResource
import Kingfisher
import Photos
import LarkAssetsBrowser
import ByteWebImage
import UniverseDesignToast
import SpaceInterface
import SKCommon
import SKInfra

extension InputTextView {
    
    
    /// 是否正在展示非键盘UI
    var showNoKeyboardView: Bool {
        guard let inputView = self.textView.inputView else {
            return false
        }
        return inputView == voiceCommentView
             || inputView == selectImgView
    }
    
    func showSelectImageView() {
        selectImgView?.removeFromSuperview()
        let leftImageCount = CommentImageInfo.commentImageMaxCount - self.inputImageInfos.count
        let currentRootVC = self.window?.lu.visibleViewController()
        selectImgView = AssetPickerSuiteView(assetType: .imageOnly(maxCount: leftImageCount),
                                             cameraType: .custom(true),
                                             sendButtonTitle: BundleI18n.SKResource.Doc_Comment_ImageConfirm,
                                             presentVC: currentRootVC,
                                             modalPresentationStyle: .overFullScreen)
        
        selectImgView?.imagePickerVCDidCancel = { [weak self] in
            self?.resetFirstResponder()
        }
        
        selectImgView?.cameraVCDidDismiss = { [weak self] in
            self?.resetFirstResponder()
        }
        selectImgView?.delegate = self
        
        let width = self.window?.frame.width ?? 0
        let minimumHeight: CGFloat = 250
        var targetHeight = minimumHeight + self.safeAreaInsets.bottom
        if let keyBoardHeight = dependency?.keyboardDidShowHeight, keyBoardHeight > targetHeight {
            targetHeight = keyBoardHeight
        }

        let inputViewRect = CGRect(x: 0, y: 0, width: width, height: targetHeight)
        selectImgView?.frame = inputViewRect

        self.dependency?.updateImageSelectStatus(select: true)
        setupMaskButton()
        textView.inputView = selectImgView
        
        // 图片选择器不支持横屏，需要打开强制竖屏
        if !SKDisplay.pad {
            NotificationCenter.default.post(name: Notification.Name.commentForcePotraint, object: nil)
        }
        
        textView.reloadInputViews()
        if #available(iOS 17.0, *), SettingConfig.ios17CompatibleConfig?.fixKeyboardIssue == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { // iOS 17键盘唤起有bug, 需要稍微的骚操作
                self.textView.resignFirstResponder()
                self.textView.becomeFirstResponder()
            }
        } else {
            if !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        }
        fixiOS16InputViewShowInSplitScreen()
    }

    func fixiOS16InputViewShowInSplitScreen() {
        let superWidth = self.superview?.bounds.size.width ?? 0
        var padCondition = SKDisplay.isInSplitScreen
        if dependency?.iPadNewStyle == true {
            padCondition = true
        }
        if #available(iOS 16.0, *), fixPadKeyboardInputView, padCondition, superWidth > 0 {
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.textView.isFirstResponder == true else {
                    return
                }
                self.isIniOS16TemporaryReloadStage = true
                if self.textView.inputView?.superview?.frame.maxX ?? -1 < superWidth / 2.0 {
                    self.textView.resignFirstResponder()
                    self.textView.becomeFirstResponder()
                }
                self.isIniOS16TemporaryReloadStage = false
            }
        }
    }

    func updateAssetType(maxCount: Int) {
        if let selectImgView = selectImgView {
            selectImgView.updateAssetType(.imageOnly(maxCount: maxCount))
        }
    }
    
    func dismissSelectImageView(reload: Bool = true) {
        self.dependency?.updateImageSelectStatus(select: false)
        self.maskButton?.removeFromSuperview()
        textView.inputView = nil
        if reload {
            textView.reloadInputViews()
        }
        
        // 组件不支持横屏，关闭selectImgView后才能横屏
        NotificationCenter.default.post(name: Notification.Name.commentCancelForcePotraint, object: nil)
    }
    
    func dismissVoiceViewIfNeed(reload: Bool = true) {
        if textView.inputView is VoiceCommentViewV2 {
            textView.inputView = nil
            if reload {
                textView.reloadInputViews()
            }
        }
    }

    public func clearPreviewImage() {
        self.inputImageInfos.removeAll()
        self.updateContentStatus()
        imageInfosChange.accept(self.inputImageInfos.count)
        DocsLogger.info("clearAllPreViewImage", component: LogComponents.commentPic)
        imagesPreview.updateView(imageInfos: inputImageInfos)
    }

    public func updatePreviewWithImageInfos(_ imageInfos: [CommentImageInfo]) {
        inputImageInfos = imageInfos
        self.updateContentStatus()
        imageInfosChange.accept(self.inputImageInfos.count)
        imagesPreview.updateView(imageInfos: inputImageInfos)
    }

    func assetPickImageHandle(imagePreInfos: [SkPickImagePreInfo], isOriginal: Bool) {
        DispatchQueue.main.async {
            if self.selectImgView != nil, self.textView.inputView == self.selectImgView {
                self.dismissSelectImageView()
            }
        }
        DispatchQueue.global().async {
            let transformImageInfos = SKPickImageUtil.getTransformImageInfo(imagePreInfos, isOriginal: isOriginal)
            guard transformImageInfos.count > 0 else {
                DocsLogger.info("图片选择, 上传图片信息为空， assets=\(imagePreInfos.count)", component: LogComponents.pickImage)
                self.dependency?.finishTransformImageInfo()
                return
            }

            var imagePreViewInfos: [CommentImageInfo] = []
            transformImageInfos.forEach { (transformInfo) in
                CommentImageCache.shared.storeImage(transformInfo.resultData, forKey: transformInfo.cacheKey)
                let assetInfo = SKAssetInfo(objToken: nil, uuid: transformInfo.uuid, cacheKey: transformInfo.cacheKey, fileSize: transformInfo.dataSize, assetType: SKPickContentType.image.rawValue, source: "comment")
                CommentImageCache.shared.updateAsset(assetInfo)
                let imagePreViewInfo = CommentImageInfo(uuid: transformInfo.uuid, token: nil, src: transformInfo.srcUrl, originalSrc: nil)
                imagePreViewInfos.append(imagePreViewInfo)
            }
            DispatchQueue.main.async {
                var allPreviewInfos = self.inputImageInfos
                var tooMuchPic: Bool = false
                for info in imagePreViewInfos {
                    if allPreviewInfos.count < CommentImageInfo.commentImageMaxCount {
                        allPreviewInfos.append(info)
                    } else {
                        tooMuchPic = true
                        DocsLogger.info("select pic, too much pic", component: LogComponents.commentPic)
                    }
                }
                DocsLogger.info("select pic, count=\(transformImageInfos.count), allInfo=\(allPreviewInfos.count)", component: LogComponents.commentPic)
                self.updatePreviewWithImageInfos(allPreviewInfos)
                self.dependency?.imagePreviewDidChange()
                if tooMuchPic {
                    if let showTipsView = self.selectImgView {
                        UDToast.showTips(with: BundleI18n.SKResource.CCM_Comment_Image_Limitedconut(9), on: showTipsView)
                    }
                }
            }
        }
    }
}

extension InputTextView: CommentInputImagesPreviewProtocol {
    func didClickDeleteImgBtn(imageInfo: CommentImageInfo) {
        var allImageInfos = self.inputImageInfos
        allImageInfos.lf_remove(object: imageInfo)
        DocsLogger.info("delete pic, imageInfo=\(imageInfo), allInfo=\(allImageInfos)", component: LogComponents.commentPic)
        self.updatePreviewWithImageInfos(allImageInfos)
        self.dependency?.imagePreviewDidChange()
        
        let leftImageCount = CommentImageInfo.commentImageMaxCount - self.inputImageInfos.count
        self.updateAssetType(maxCount: leftImageCount)
    }

    func didClickPreviewImage(imageInfo: CommentImageInfo) {
        DocsLogger.info("didClickPreviewImage, imageInfo=\(imageInfo)", component: LogComponents.commentPic)
        var currentShowImage: ShowPositionData?
        var imageList = [PhotoImageData]()
        self.inputImageInfos.forEach { (tempImage) in
            if let srcUrl = URL(string: tempImage.src) {
                //这里同一用src.path做key,因为其他的值都可能为空
                let uuid = srcUrl.path
                let imageData = PhotoImageData(uuid: uuid, src: tempImage.src, originalSrc: tempImage.originalSrc ?? tempImage.src)
                imageList.append(imageData)
                if imageInfo == tempImage {
                    let fromPoint = self.imagesPreview.convert(self.imagesPreview.center, to: nil)
                    let position = PhotoPosition(height: 80, width: 80, x: fromPoint.x - 40, y: fromPoint.y - 40)
                    currentShowImage = ShowPositionData(uuid: uuid, src: tempImage.src, originalSrc: tempImage.originalSrc, position: position)
                }
            } else {
                DocsLogger.info("transform err, imageInfo=\(imageInfo)", component: LogComponents.commentPic)
            }
        }
        let toolStatus = PhotoToolStatus(comment: nil, copy: true, delete: nil, export: true)
        let openImageData = OpenImageData(showImageData: currentShowImage, imageList: imageList, toolStatus: toolStatus, callback: nil)
        openImagePlugin.openImage(openImageData: openImageData)
    }

}

extension InputTextView: AssetPickerSuiteViewDelegate {

    func resetFirstResponder() {
        if SKDisplay.phone {
            textView.canBecomeFirst = true
            textView.becomeFirstResponder()
        }
    }

    public func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
        if clickType == .view || clickType == .camera, SKDisplay.phone {
            DocsLogger.info("click imagePicker type:\(clickType)", component: LogComponents.commentPic)
            textView.resignFirstResponder()
            textView.canBecomeFirst = false
        }
    }
    
    public func assetPickerSuite(_ previewClickType: AssetPickerPreviewClickType) {
        if previewClickType == .previewImage, SKDisplay.phone {
            DocsLogger.info("click imagePicker preview:\(previewClickType)", component: LogComponents.commentPic)
            textView.resignFirstResponder()
            textView.canBecomeFirst = false
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        resetFirstResponder()
        handlePickAsset(assets: result.selectedAssets, isOriginal: result.isOriginal)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        resetFirstResponder()
        handlePickPhoto(photo: photo)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        resetFirstResponder()
    }
    
    func handleImagePickerResult(result: CommentImagePickerResult) {
        switch result {
        case let .pickPhoto(selectedAssets, isOriginal):
            handlePickAsset(assets: selectedAssets, isOriginal: isOriginal)
        case let .takePhoto(photo):
            handlePickPhoto(photo: photo)
        case .cancel:
            break
        }
    }
    
    func handlePickAsset(assets: [PHAsset], isOriginal: Bool) {
        self.dependency?.willTransformImageInfo()
        SKPickImageUtil.handleImageAsset(assets: assets, original: isOriginal, token: PSDATokens.Comment.comment_upload_image) { [weak self] info in
            guard let self else { return }
            if let info {
                self.assetPickImageHandle(imagePreInfos: info, isOriginal: isOriginal)
            } else {
                DocsLogger.info("comment select pic, reachMaxSize", component: LogComponents.comment)
                UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_Docs_DocCover_ExceedFileSize_Toast,
                                 on: self.window ?? self)
                self.dependency?.finishTransformImageInfo()
            }
        }
    }
    
    func handlePickPhoto(photo: UIImage) {
        let image = photo.sk.fixOrientation()
        let imageInfo = SkPickImagePreInfo(image: image, oriData: nil, picFormat: ImageFormat.unknown)
        assetPickImageHandle(imagePreInfos: [imageInfo], isOriginal: false)
    }
}
