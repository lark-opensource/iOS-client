//
//  MomentSendPostKeyBoardExtension.swift
//
//  Created by llb on 2021/1/5.
//

import EENavigator
/// 键盘相关的代理实现
import Foundation
import LarkAlertController
import LarkContainer
import LarkCore
import LarkBaseKeyboard
import LarkKeyboardView
import LarkEmotion
import LarkEmotionKeyboard
import LarkFeatureGating
import LarkFoundation
import LarkKeyboardKit
import LarkMessageCore
import LarkSDKInterface
import LarkUIKit
import Photos
import UniverseDesignToast
import RxCocoa
import RxSwift
import LarkMessengerInterface
import UIKit
import ByteWebImage
import LKCommonsLogging
import RustPB
import LarkSendMessage

/**
 isVideo：为true:
 图片信息为corveimage的信息
 dirveToken 为视频上传后的标识
 isVideo：为false:
 图片信息为image的信息
 视频信息为空
 */
final class SelectImageInfoItem: Persistable {
    static let `default` = SelectImageInfoItem(imageSource: nil, originSize: .zero, useOriginal: false, isVideo: false)
    var videoInfo: VideoParseInfo?
    var imageSource: ImageSourceResult?
    // 图片基本信息
    var isVideo: Bool = false
    var originSize: CGSize = .zero
    var useOriginal: Bool = true
    // 本地的imageKey
    var localImageKey = ""
    // image的token
    var token = ""
    // 附件ID
    var attachmentKey = ""
    // 视频信息
    // 上传给服务端的Key
    var dirveToken = ""
    // 调用上传的文件ID
    var dirveKey = ""
    var photoItem: PhotoInfoItem?
    var compressInput: CompressInput?

    init(imageSource: ImageSourceResult?,
         originSize: CGSize,
         useOriginal: Bool,
         isVideo: Bool) {
        self.imageSource = imageSource
        self.originSize = originSize
        self.useOriginal = useOriginal
        self.isVideo = isVideo
    }

    init(unarchive: [String: Any]) {
        if let isVideo = unarchive["isVideo"] as? Bool,
           let originSize = unarchive["originSize"] as? [CGFloat],
           let useOriginal = unarchive["useOriginal"] as? Bool,
           let localImageKey = unarchive["localImageKey"] as? String,
           let dirveToken = unarchive["dirveToken"] as? String,
           let videoLocalPath = unarchive["videoLocalPath"] as? String,
           let duration = unarchive["duration"] as? TimeInterval,
           let videoNaturalSize = unarchive["videoNaturalSize"] as? [CGFloat],
           let attachmentKey = unarchive["attachmentKey"] as? String,
           let token = unarchive["token"] as? String,
           let compressPath = unarchive["compressPath"] as? String {
            self.isVideo = isVideo
            self.originSize = CGSize(width: originSize[0], height: originSize[1])
            self.useOriginal = useOriginal
            self.localImageKey = localImageKey
            self.dirveToken = dirveToken
            self.attachmentKey = attachmentKey
            self.token = token
            /// 视屏的时长需要大于0 才能保证是有效视频
            if duration > 0 {
                let info = VideoParseTask.VideoInfo()
                info.exportPath = videoLocalPath
                info.duration = duration
                info.naturalSize = CGSize(width: videoNaturalSize[0], height: videoNaturalSize[1])
                info.compressPath = compressPath
                videoInfo = info
            }
        }
    }

    func archive() -> [String: Any] {
        return [
            "isVideo": isVideo,
            "originSize": [originSize.width, originSize.height],
            "useOriginal": useOriginal,
            "localImageKey": localImageKey,
            "dirveToken": dirveToken,
            "videoLocalPath": videoInfo?.exportPath ?? "",
            "duration": videoInfo?.duration ?? 0,
            "videoNaturalSize": [videoInfo?.naturalSize.width ?? 0, videoInfo?.naturalSize.height ?? 0],
            "attachmentKey": attachmentKey,
            "token": token,
            "compressPath": videoInfo?.compressPath ?? ""
        ]
    }
}

extension MomentSendPostViewController: KeyboardPanelDelegate {

    public func keyboardItemOnTap(index: Int, key: String) -> (KeyboardPanelEvent) -> Void {
        return keyboardItems[index].onTapped
    }

    public func keyboardItemKey(index: Int) -> String {
        return keyboardItems[index].key
    }

    public func systemKeyboardPopup() {
    }

    public func keyboardContentHeightWillChange(_ height: Float) {
    }

    public func keyboardContentHeightDidChange(_ height: Float) {
    }

    public func keyboardViewCoverSafeArea(index: Int, key: String) -> Bool {
        return keyboardItems[index].coverSafeArea
    }

    public func numberOfKeyboard() -> Int {
        return keyboardItems.count
    }

    public func keyboardIcon(index: Int, key: String) -> (UIImage?, UIImage?, UIImage?) {
        return keyboardItems[index].keyboardIcon
    }

    public func willSelected(index: Int, key: String) -> Bool {
        if let action = keyboardItems[index].selectedAction {
            return action()
        }
        return true
    }

    public func didSelected(index: Int, key: String) {
        contentTextView.resignFirstResponder()
    }

    /// 这里地方 由于有多种类型 (only Video, only image, video or image) 这里不做缓存
    public func keyboardView(index: Int, key: String) -> (UIView, Float) {
        let item = keyboardItems[index]
        let height = item.keyboardHeightBlock()
        let keyboardView = item.keyboardViewBlock()
        keyboardViewCache[index] = keyboardView
        return (keyboardView, height)
    }

    public func keyboardSelectEnable(index: Int, key: String) -> Bool {
        switch key {
        case KeyboardItemKey.emotion.rawValue, KeyboardItemKey.picture.rawValue, KeyboardItemKey.at.rawValue:
            return contentTextView.isFirstResponder || KeyboardKit.shared.firstResponder == nil
        case KeyboardItemKey.send.rawValue:
            return sendPostEnable()
        default:
            return true
        }
    }

    public func keyboardIconBadge(index: Int, key: String) -> KeyboardIconBadgeType {
        return .none
    }

    public func keyboardIconViewCustomization(index: Int, key: String, iconView: UIView) {}
}

extension MomentSendPostViewController: EmojiEmotionItemDelegate {
    // 点击表情
    public func emojiEmotionInputViewDidTapCell(emojiKey: String) {
        let textView = contentTextView
        let emoji = "[\(emojiKey)]"
        let selectedRange = textView.selectedRange
        if textViewInputProtocolSet.textView(textView, shouldChangeTextIn: selectedRange, replacementText: emoji) {
            let emojiStr = EmotionTransformer.transformContentToString(emoji, attributes: contentTextView.defaultTypingAttributes)
            textView.insert(emojiStr, useDefaultAttributes: false)
            textChanged(isEmpty: false)
        }
        if let reactionKey = EmotionResouce.shared.reactionKeyBy(emotionKey: emojiKey) {
            reactionAPI?.updateRecentlyUsedReaction(reactionType: reactionKey).subscribe().disposed(by: disposeBag)
        }
        hashTagRecognizer.onTextDidChangeFor(textView: contentTextView)
    }

    // 点击撤退删除
    public func emojiEmotionInputViewDidTapBackspace() {
        let textView = contentTextView
        var range = textView.selectedRange
        if range.length == 0 {
            range.location -= 1
            range.length = 1
        }
        if textViewInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: "") {
            textView.deleteBackward()
        }
        hashTagRecognizer.onTextDidChangeFor(textView: contentTextView)
    }

    public func emojiEmotionInputViewDidTapSend() {
        return
    }

    public func emojiEmotionActionEnable() -> Bool {
        return true
    }

    public func isKeyboardNewStyleEnable() -> Bool {
        return false
    }

    public func supportSkinTones() -> Bool {
        return true
    }
}

extension MomentSendPostViewController: AssetPickerSuiteViewDelegate {
    func assetPickerSuiteShouldUpdateHeight(_ suiteView: AssetPickerSuiteView) {
        keyboardPanel.updateKeyboardHeightIfNeeded()
    }

    var mediaDiskUtil: MediaDiskUtil { .init(userResolver: userResolver) }
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        // 检测视频、图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard mediaDiskUtil.checkMediaSendEnable(assets: result.selectedAssets, on: self.view) else {
            return
        }
        assetPickerSuiteDidSelected(assets: result.selectedAssets, isOriginal: result.isOriginal)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didChangeSelection result: AssetPickerSuiteSelectResult) {
        guard assetManager.checkPreProcessEnable else { return }
        result.selectedAssets.forEach { asset in
            guard asset.mediaType == .image,
                  assetManager.checkMemoryIsEnough()
            else { return }
            let originAssetName = assetManager.getDefaultKeyFrom(phAsset: asset)
            // 区分是否原图
            let assetName = assetManager.combineImageKeyWithIsOriginal(imageKey: originAssetName, isOriginal: result.isOriginal)
            guard !assetManager.checkAssetHasOperation(assetName: assetName) else { return }
            let assetOperation = BlockOperation { [weak self] in
                guard let self = self, let sendImageProcessor = self.viewModel.sendImageProcessor else { return }
                let dependency = ImageInfoDependency(useOrigin: result.isOriginal, sendImageProcessor: sendImageProcessor)
                let imageSourceResult = asset.imageInfo(dependency)
                self.assetManager.addToFinishAssets(name: assetName, value: imageSourceResult)
            }
            assetManager.addAssetProcessOperation(assetOperation)
            assetManager.addToPendingAssets(name: assetName, value: asset)
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        // 检测图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard mediaDiskUtil.checkImageSendEnable(image: photo, on: self.view) else {
            return
        }
        let selectedImagesModel = viewModel.selectedImagesModel

        guard (selectedImagesModel.leftCount() ?? 0) > 0 || selectedImagesModel.selectedItems.isEmpty else {
            return
        }
        // 添加loading
        showLoadingHudForUpload()
        let sendImageProcessor = viewModel.sendImageProcessor
        let config = viewModel.imageCompressConfig
        DispatchQueue.global().async {
            let request = SendImageRequest(
                input: .image(photo),
                sendImageConfig: SendImageConfig(
                    checkConfig: SendImageCheckConfig(
                        isOrigin: !self.viewModel.IsCompressCameraPhotoFG, scene: .Moments, biz: .Messenger, fromType: .post),
                    compressConfig: SendImageCompressConfig(
                        compressRate: config.targetQuality,
                        destPixel: config.targetLength)),
                uploader: AttachmentImageUploader(encrypt: false, imageAPI: self.imageAPI))
            // upload内上传了埋点
            request.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            let process = AttachmentMomentProcessor(
                userResolver: self.userResolver,
                useOriginal: false,
                imageChecker: self.imageChecker,
                showFailedCallback: nil,
                insertCallback: { [weak self] selectItems, unSupportTips in
                    self?.userDidSelectImages(selectItems, unSupportTip: unSupportTips) ?? []
                })
            request.addProcessor(
                afterState: .compress,
                processor: process,
                processorId: "moments.post.sendImage.after.compress")
            SendImageManager.shared.sendImage(request: request)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] messageArray in
                    messageArray.forEach { message in
                        self?.viewModel.attachmentUploader.finishCustomUpload(key: message.key, result: message.result, data: message.data, error: message.error)
                    }
                }, onError: { error in
                    guard case .noItemsResult = error as? AttachmentMomentSendImageError else { return }
                    var tips = BundleI18n.Moment.Lark_Community_FailedToUploadPicture
                    if let imageError = error as? LarkSendImageError,
                        let compressError = imageError.error as? CompressError,
                        let err = AttachmentImageError.getCompressError(error: compressError) {
                        tips = err
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        UDToast.showFailure(with: tips, on: self.view.window ?? self.view)
                    }
                })
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        // 检测视频是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard mediaDiskUtil.checkVideoSendEnable(videoURL: url, on: self.view) else {
            return
        }
        let selectedImagesModel = viewModel.selectedImagesModel
        guard (selectedImagesModel.leftCount() ?? 0) > 0 || selectedImagesModel.selectedItems.isEmpty else {
            return
        }
        fetchVideoInfo(data: .fileURL(url))
    }

    func assetPickerSuiteDidSelected(assets: [PHAsset], isOriginal: Bool) {
        if let first = assets.first, first.mediaType == .video {
            fetchVideoInfo(data: .asset(first))
        } else {
            pickedImageAssets(assets: assets, useOriginal: isOriginal)
        }
    }

    fileprivate func fetchVideoInfo(data: SendVideoContent) {
        showLoadingHudForUpload()
        let item = MomentsUploadVideoItem(biz: .Moments,
                                          scene: .MoPost,
                                          event: .momentsUploadVideo,
                                          page: "publish")
        self.tracker.startTrackWithItem(item)
        item.startParse = CACurrentMediaTime()
        self.viewModel.videoSendService?.getVideoInfo(with: data, isOriginal: false, extraParam: nil) { [weak self] (info, error) in
            item.endParse()
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let info = info {
                    if info.status == .fillBaseInfo {
                        let item = SelectImageInfoItem(imageSource: ImageSourceResult(sourceType: .jpeg, data: nil, image: nil), originSize: info.preview.size, useOriginal: false, isVideo: true)
                        item.videoInfo = info
                        self.videoTranscodeWithItem(item)
                    } else {
                        self.removeUploadHUD()
                        var alertMessage = ""
                        guard let videoSendSetting = info.videoSendSetting else {
                            assertionFailure()
                            return
                        }
                        if info.status == .reachMaxSize {
                            alertMessage = BundleI18n.Moment.Lark_Community_SupportUploadVideoSize((Int)(videoSendSetting.fileSize / 1024 / 1024))
                        } else if info.status == .reachMaxDuration {
                            alertMessage = BundleI18n.Moment.Lark_Community_SupportUploadingVideosWithinFiveMinutes((Int)(videoSendSetting.duration / 60))
                        } else if info.status == .reachMaxResolution {
                            /// 视频分辨率参数过大
                            alertMessage = BundleI18n.Moment.Lark_Chat_VideoResolutionExceedLimitCancel
                        } else if info.status == .reachMaxBitrate {
                            /// 视频码率参数过大
                            alertMessage = BundleI18n.Moment.Lark_Chat_VideoBitRateExceedLimitCancel
                        } else if info.status == .reachMaxFrameRate {
                            /// 视频帧率参数过大
                            alertMessage = BundleI18n.Moment.Lark_Chat_VideoFrameRateExceedLimitCancel
                        } else if info.status == .videoTrackEmpty {
                            alertMessage = BundleI18n.Moment.Lark_IMVideo_InvalidVideoFormatUnableToSend_Text
                        }
                        self.showAlert(alertMessage, showCancel: false)
                    }
                } else if let error = error {
                    self.removeUploadHUD()
                    self.sendVideoOnError(error)
                }
            }
        }
    }

    private func videoTranscodeWithItem(_ item: SelectImageInfoItem) {
        guard let info = item.videoInfo else {
            return
        }
        let trackerItem = self.tracker.getItemWithEvent(.momentsUploadVideo) as? MomentsUploadVideoItem
        trackerItem?.startTranscodeCost = CACurrentMediaTime()
        viewModel.videoTranscodeServiceWith(info: info, finish: { [weak self] success in
            trackerItem?.endTranscode()
            if success {
                self?.userDidSelectVideo(item: item)
            } else {
                self?.removeUploadHUD()
            }
        })
    }

    func pickedImageAssets(assets: [PHAsset], useOriginal: Bool) {
        guard !assets.isEmpty else {
            return
        }
        showLoadingHudForUpload()
        DispatchQueue.main.async {
            self.fetchImages(assets: assets, useOriginal: useOriginal)
        }
    }

    func fetchImages(assets: [PHAsset], useOriginal: Bool) {
        guard let sendImageProcessor = viewModel.sendImageProcessor else { return }
        let dependency = ImageInfoDependency(useOrigin: useOriginal, sendImageProcessor: sendImageProcessor)
        let config = viewModel.imageCompressConfig
        assetManager.cancelAllOperation()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let process = AttachmentMomentProcessor(
                userResolver: self.userResolver,
                useOriginal: useOriginal,
                imageChecker: self.imageChecker,
                showFailedCallback: { [weak self] unSupportTip in
                    self?.removeUploadHUD()
                    self?.showFailureWithUnSupportTip(unSupportTip)
                }, insertCallback: { [weak self] selectItems, unSupportTip in
                    return self?.userDidSelectImages(selectItems, unSupportTip: unSupportTip) ?? []
                })
            let uploader = AttachmentImageUploader(encrypt: false, imageAPI: self.imageAPI)
            let request = SendImageRequest(
                input: .assets(assets),
                sendImageConfig: SendImageConfig(
                    checkConfig: SendImageCheckConfig(isOrigin: useOriginal, scene: .Moments, biz: .Messenger, fromType: .post),
                    compressConfig: SendImageCompressConfig(compressRate: config.targetQuality, destPixel: config.targetLength)),
                uploader: uploader)
            let preCompress: PreCompressResultBlock = { [weak self] asset in
                guard asset.editImage == nil,
                    let assetManager = self?.assetManager
                else { return nil }
                let originAssetName = assetManager.getDefaultKeyFrom(phAsset: asset)
                let assetName = assetManager.combineImageKeyWithIsOriginal(imageKey: originAssetName, isOriginal: useOriginal)
                return assetManager.getImageSourceResult(assetName: assetName)
            }
            // 因为是多图，所以设置业务方自定义上传埋点
            request.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            request.setContext(key: SendImageRequestKey.CompressResult.PreCompressResultBlock, value: preCompress)
            request.addProcessor(afterState: .compress, processor: process, processorId: "moments.keyboard.sendImage.afterCompress")
            SendImageManager.shared.sendImage(request: request).subscribe(onNext: { [weak self] messageArray in
                messageArray.forEach { message in
                    self?.viewModel.attachmentUploader.finishCustomUpload(key: message.key, result: message.result, data: message.data, error: message.error)
                }
                self?.assetManager.afterPreProcess(assets: assets)
            }, onError: { [weak self] error in
                guard let self = self, case .noItemsResult = error as? AttachmentMomentSendImageError else { return }
                var tips = BundleI18n.Moment.Lark_Community_FailedToUploadPicture
                if let imageError = error as? LarkSendImageError,
                    let compressError = imageError.error as? CompressError,
                    let err = AttachmentImageError.getCompressError(error: compressError) {
                    tips = err
                }
                DispatchQueue.main.async {
                    UDToast.showFailure(with: tips, on: self.view.window ?? self.view)
                }
                self.assetManager.afterPreProcess(assets: assets)
            })
        }
    }

    // 错误处理
    private func sendVideoOnError(_ error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let sendvideoError = error as? VideoParseTask.ParseError {
                switch sendvideoError {
                case let .fileReachMax(_, fileSizeLimit):
                    self?.showFileSizeLimitFailure(fileSizeLimit)
                case .loadAVAssetIsInCloudError:
                    self?.showAlert(BundleI18n.Moment.Lark_Chat_iCloudMediaUploadError, showCancel: false)
                case .userCancel: break
                default:
                    // 上传失败
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_VideoUploadFailed,
                                           on: self?.view ?? UIView())
                }
            } else {
                // 上传失败
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_VideoUploadFailed, on: self?.view ?? UIView())
            }
        }
    }

    /// 显示弹窗，请在主线程调用
    /// - Parameters:
    ///   - message: 信息
    ///   - showCancel: 是否显示“取消”
    ///   - onSure: 确定事件
    private func showAlert(_ message: String, showCancel: Bool = true, onSure: (() -> Void)? = nil) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Moment.Lark_Legacy_Hint)
        alertController.setContent(text: message)
        if showCancel {
            alertController.addCancelButton()
        }
        alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_Confirm, dismissCompletion: {
            onSure?()
        })
        userResolver.navigator.present(alertController, from: self)
    }

    /// 将文件大小限制转换为字符串
    /// 当限制小于1GB时，以MB为单位表示，否则以GB为单位表示
    private func fileSizeToString(_ fileSize: UInt64) -> String {
        let megaByte: UInt64 = 1024 * 1024
        let gigaByte = 1024 * megaByte
        if fileSize < gigaByte {
            let fileSizeInMB = Double(fileSize) / Double(megaByte)
            return String(format: "%.2fMB", fileSizeInMB)
        } else {
            let fileSizeInGB = Double(fileSize) / Double(gigaByte)
            return String(format: "%.2fGB", fileSizeInGB)
        }
    }

    private func showFileSizeLimitFailure(_ fileSizeLimit: UInt64) {
        if let window = view.window {
            UDToast.showFailure(with: BundleI18n
                .Moment
                .Lark_Community_SupportUploadVideoSize(fileSizeToString(fileSizeLimit)),
                on: window)
        }
    }
}

enum AttachmentMomentSendImageError: Error {
    // 从context中没有获取到compress的结果
    case getCompressResult
    // 在moment的图片校验中，没有图片幸存。已经针对错误类型在process中处理过
    case noItemsResult
}

// moment场景下，发帖子：选择图片、拍摄图片；评论帖子：选择图片、拍摄图片
// 拿到组件处理后的image结果，查看是否能通过moment检查，以及将图片插入进富文本中
final class AttachmentMomentProcessor: LarkSendImageProcessor {
    let userResolver: UserResolver
    private let imageChecker: MomentsImageChecker
    // 图片上传组件内部会先“检查”再“压缩”，然后给业务方。此处业务方拿到压缩后图片再次“检查”，是永远都会通过“检查”的。所以删除此处“检查”逻辑
    // FG开启：删除冗余逻辑。FG关闭：不删除冗余逻辑
    private lazy var removeRedundantLogicFG = userResolver.fg.staticFeatureGatingValue(with: "messenger.moments.removing_redundant_logic")
    // moment特有的图片检查，出错后告诉业务方
    private let showFailedCallback: ((String?) -> Void)?
    private let useOriginal: Bool
    private let insertCallback: (([SelectImageInfoItem], String?) -> [SelectImageInfoItem])?
    static let logger = Logger.log(AttachmentMomentProcessor.self, category: "moment.attachment.after.compress.processor")
    init(userResolver: UserResolver,
         useOriginal: Bool,
         imageChecker: MomentsImageChecker,
         showFailedCallback: ((String?) -> Void)?,
         insertCallback: (([SelectImageInfoItem], String?) -> [SelectImageInfoItem])?) {
        self.userResolver = userResolver
        self.useOriginal = useOriginal
        self.imageChecker = imageChecker
        self.showFailedCallback = showFailedCallback
        self.insertCallback = insertCallback
    }
    func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            let input = request.getInput()
            guard let `self` = self,
                  let imageSourceResultArray = request.getCompressResult()
            else {
                observer.onError(AttachmentMomentSendImageError.getCompressResult)
                return Disposables.create()
            }
            var compressError: CompressError?
            var items: [SelectImageInfoItem] = imageSourceResultArray.compactMap { compressResult -> SelectImageInfoItem? in
                switch compressResult.result {
                case .success(let imageResult):
                    switch compressResult.input {
                    case .phasset(let asset):
                        let size = asset.editImage?.size ?? asset.originSize
                        let item = SelectImageInfoItem(imageSource: imageResult, originSize: size, useOriginal: self.useOriginal, isVideo: false)
                        item.compressInput = .phasset(asset)
                        return item
                    case .image(let photo):
                        let item = SelectImageInfoItem(imageSource: imageResult, originSize: photo.size, useOriginal: false, isVideo: false)
                        item.compressInput = .image(photo)
                        return item
                    case .data(_):
                        return nil
                    }
                case .failure(let error):
                    compressError = error
                    return nil
                }
            }
            var unSupportTip: String?
            if !self.removeRedundantLogicFG {
                let checkResult = self.imageChecker.checkImageItems(items)
                items = checkResult.compactMap { result in
                    return result.isPass ? result.item : nil
                }
                unSupportTip = self.imageChecker.transformResultsToTipString(checkResult)
            }
            // 如果moment检查后，有需要展示的报错，则展示；如果没有，判断有没有组件压缩过程中要展示的报错信息
            // 因为moment的流程是，一组图片如果有检查不成功的图片，则展示错误，并正常上传其他图片。所以这里不能直接抛出error
            if unSupportTip == nil, let compressError = compressError {
                unSupportTip = AttachmentImageError.getCompressError(error: compressError)
            }
            if items.isEmpty {
                DispatchQueue.main.async {
                    self.showFailedCallback?(unSupportTip)
                }
                observer.onError(AttachmentMomentSendImageError.noItemsResult)
                return Disposables.create()
            }
            DispatchQueue.main.async { [weak self] in
                let attachmentMessages: [AttachmentMessage] = self?.insertCallback?(items, unSupportTip).compactMap { info -> AttachmentMessage? in
                    if let data = info.imageSource?.data, let imageSource = info.imageSource, let compressInput = info.compressInput {
                        return AttachmentMessage(
                            key: info.attachmentKey,
                            result: nil, data: data, error: nil,
                            compressResult: CompressResult(result: .success(imageSource), input: compressInput))
                    }
                    return nil
                } ?? []
                request.setContext(key: "send.image.post.attachment.key", value: attachmentMessages)
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
