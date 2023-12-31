//
//  KeyboardImageInsertManager.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/20.
//

import UIKit
import EditTextView
import ByteWebImage
import LarkStorage
import LarkContainer
import LarkAssetsBrowser
import LarkAttachmentUploader
import Photos
import UniverseDesignToast
import EENavigator
import LarkAlertController
import LarkKeyboardView
import AppReciableSDK

public enum VideoHandlerResult {
    case error(Error?)
    case success(VideoTransformInfo?, UIImage, String)
    case notSupport(String)
}

public enum ImageHandlerResult {
    case error(String)
    case success
}

public enum PanelVideoType {
    case asset(PHAsset)
    case fileURL(URL)
}

public struct ImageProcessInfo {
    public let image: UIImage
    public let imageKey: String
    public let useOrigin: Bool
    public init(image: UIImage, imageKey: String, useOrigin: Bool) {
        self.image = image
        self.imageKey = imageKey
        self.useOrigin = useOrigin
    }
}

/// 处理视频&图片的转码 + 上传
/// default imp all block is callback on main thread
public protocol KeyboardPanelPictureHandlerService: KeyboardPanelPictureService {
    func handlerInsertVideoFrom(_ type: PanelVideoType,
                               attachmentUploader: AttachmentUploader,
                               isOriginal: Bool,
                               extraParam: [String : Any]?,
                               callBack: ((VideoHandlerResult) -> Void)?)

    func handlerInsertImageAssetsFrom(_ assets: [PHAsset],
                               attachmentUploader: AttachmentUploader,
                               encrypt: Bool,
                               useOriginal: Bool,
                               scene: Scene,
                               process:((ImageProcessInfo) -> Void)?,
                               callBack: ((ImageHandlerResult) -> Void)?)
    /// processorId 图片库底层打日志用的
    func handlerInsertImageFrom(_ image: UIImage,
                               useOriginal: Bool,
                               attachmentUploader: AttachmentUploader,
                               sendImageConfig: SendImageConfig,
                               encrypt: Bool,
                               fromVC: UIViewController?,
                               processorId: String,
                               callBack:((ImageProcessInfo) -> Void)?)

    func handlerAssetPickerSuiteChange(result: AssetPickerSuiteSelectResult)

    func handlerVideoError(_ error: Error, fromVC: UIViewController?)

    func showAlert(_ message: String, from: UIViewController?, showCancel: Bool, onSure: (() -> Void)?)

    func computeResourceKey(key: String, isOrigin: Bool) -> String

    func handlerImageUploadError(error: Error?, fromVC: UIViewController)
}

public struct KeyboardImageInsertConfig {

    let contentTextView: LarkEditTextView
    let keyboardPanel: KeyboardPanel
    let encryptImage: Bool
    let sendImageConfig: SendImageConfig
    let sence: Scene
    let processorId: String

    var attachmentServer: PostAttachmentServer
    var pictureService: KeyboardPanelPictureHandlerService?
    weak var delegate: KeyboardImageInsertManagerDelegate?

    public init(contentTextView: LarkEditTextView,
                keyboardPanel: KeyboardPanel,
                encryptImage: Bool,
                attachmentServer: PostAttachmentServer,
                sendImageConfig: SendImageConfig,
                scene: Scene,
                processorId: String,
                pictureService: KeyboardPanelPictureHandlerService?,
                delegate: KeyboardImageInsertManagerDelegate?) {
        self.contentTextView = contentTextView
        self.keyboardPanel = keyboardPanel
        self.encryptImage = encryptImage
        self.attachmentServer = attachmentServer
        self.pictureService = pictureService
        self.delegate = delegate
        self.sence = scene
        self.sendImageConfig = sendImageConfig
        self.processorId = processorId
    }
}
/**
插入视频的流程
 1.获取视频的基础信息
 2.满足条件后可以直接插入，如果不满足则需要提示出错
 3.满足之后 将视频首帧插入输入框
插入图片的流程
 1. 图片转码
 2. 完成后插入输入框
 上述过程 除了图片的插入之外 其他基本都在LarkMessageSend中 or 其它业务库中
 */

public protocol KeyboardImageInsertManagerDelegate: AnyObject {
    func getDisPlayVC() -> UIViewController
    func beforeInsertVideoInfo(_ info: VideoTransformInfo, uploadKey: String)
    func afterInsertVideoInfo(_ info: VideoTransformInfo, uploadKey: String)
    func beforeInsertImageInfo()
    func afterInsertImageInfo()
    func didFinishInsertAllImages()
    func didUpdateAttachmentResultInfo(attributedText: NSAttributedString)
    func didUpdateImageAttachmentState(attributedText: NSAttributedString)
}

public class KeyboardImageInsertManager {

    @InjectedSafeLazy var userSpace: UserSpaceService

    public var pictureService: KeyboardPanelPictureHandlerService? {
        return self.config.pictureService
    }

    public var postAttachmentServer: PostAttachmentServer {
        return self.config.attachmentServer
    }

    public var delegate: KeyboardImageInsertManagerDelegate? {
        return self.config.delegate
    }

    public let config: KeyboardImageInsertConfig

    public init(config: KeyboardImageInsertConfig) {
        self.config = config
        let attachmentServer = config.attachmentServer
        attachmentServer.defaultCallBack = { [weak self, weak attachmentServer] (_, _, url, data, error) in
            guard let self = self else { return }
            let attributedText = self.config.contentTextView.attributedText ?? NSAttributedString()
            attachmentServer?.updateAttachmentResultInfo(attributedText)
            self.delegate?.didUpdateAttachmentResultInfo(attributedText: attributedText)
            attachmentServer?.updateImageAttachmentState(self.config.contentTextView)
            self.delegate?.didUpdateImageAttachmentState(attributedText: attributedText)
            if let imageData = data,
                let key = url,
                let image = try? ByteImage(imageData) {
                let originKey = self.pictureService?.computeResourceKey(key: key, isOrigin: true)
                self.config.attachmentServer.storeImageToCacheFromDraft(image: image, imageData: imageData, originKey: originKey ?? "")
            }
            if let from = self.delegate?.getDisPlayVC() {
                self.pictureService?.handlerImageUploadError(error: error, fromVC: from)
            }
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        guard let pictureService = self.config.pictureService,
              pictureService.checkMediaSendEnable(assets: result.selectedAssets,
                                                  on: self.config.delegate?.getDisPlayVC().view) else {
            return
        }
        if let first = result.selectedAssets.first, first.mediaType == .video {
            self.fetchVideoInfo(data: .asset(first))
        } else {
            self.pickedImageAssets(assets: result.selectedAssets, useOriginal: result.isOriginal)
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        guard let pictureService = self.config.pictureService,
              pictureService.checkImageSendEnable(image: photo, on: self.delegate?.getDisPlayVC().view) else {
            return
        }

        let hideHud = showLoadingHud(BundleI18n.LarkBaseKeyboard.Lark_Legacy_Processing)
        self.pictureService?.handlerInsertImageFrom(photo,
                                                   useOriginal: false,
                                                   attachmentUploader: self.config.attachmentServer.attachmentUploader,
                                                   sendImageConfig: self.config.sendImageConfig,
                                                   encrypt: self.config.encryptImage,
                                                   fromVC: self.delegate?.getDisPlayVC(),
                                                   processorId: self.config.processorId,
                                                   callBack: { [weak self] info in
            self?.insert(imageInfo: info)
            self?.config.contentTextView.lu.scrollToBottom(animated: true)
            self?.delegate?.didFinishInsertAllImages()
            hideHud()
        })
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didChangeSelection result: AssetPickerSuiteSelectResult) {
        self.pictureService?.handlerAssetPickerSuiteChange(result: result)
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        // 检测视频是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard let pictureService = self.pictureService,
              pictureService.checkVideoSendEnable(videoURL: url, on: self.delegate?.getDisPlayVC().view) else {
            return
        }
        fetchVideoInfo(data: .fileURL(url))
    }

    func pickedImageAssets(assets: [PHAsset], useOriginal: Bool) {
        guard !assets.isEmpty else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let hideHud = self.showLoadingHud(BundleI18n.LarkBaseKeyboard.Lark_Legacy_Processing)
            self.pictureService?.handlerInsertImageAssetsFrom(assets,
                                                             attachmentUploader: self.config.attachmentServer.attachmentUploader,
                                                             encrypt: self.config.encryptImage,
                                                             useOriginal: useOriginal,
                                                             scene: self.config.sence,
                                                             process: { [weak self] info in
                hideHud()
                self?.insert(imageInfo: info)
            },
                                                             callBack: { [weak self] result in
                switch result {
                case .success:
                    self?.config.contentTextView.lu.scrollToTop(animated: true)
                    self?.delegate?.didFinishInsertAllImages()
                case .error(let tips):
                    if let vc = self?.config.delegate?.getDisPlayVC() {
                        UDToast.showFailure(with: tips, on: vc.view.window ?? vc.view)
                    }
                }
            })
        }
    }

    fileprivate func fetchVideoInfo(data: PanelVideoType) {
        guard checkVideoNumber(), self.userSpace.currentUserDirectory != nil else {
            print("error info")
            return
        }
        self.pictureService?.handlerInsertVideoFrom(data,
                                                   attachmentUploader: self.config.attachmentServer.attachmentUploader,
                                                   isOriginal: false,
                                                   extraParam: nil,
                                                   callBack: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .error(let error):
                if let error = error {
                    self.pictureService?.handlerVideoError(error, fromVC: self.delegate?.getDisPlayVC())
                }
            case .notSupport(let message):
                self.pictureService?.showAlert(message, from: self.delegate?.getDisPlayVC(), showCancel: false, onSure: nil)
            case .success(let info, let image, let key):
                if let videoInfo = info {
                    let textView = self.config.contentTextView
                    self.delegate?.beforeInsertVideoInfo(videoInfo, uploadKey: key)
                    VideoTransformer.insert(content: (videoInfo, image, textView.bounds.width), textView: textView)
                    self.delegate?.afterInsertVideoInfo(videoInfo, uploadKey: key)
                    if !textView.isFirstResponder {
                        self.config.keyboardPanel.closeKeyboardPanel(animation: true)
                        textView.becomeFirstResponder()
                    }
                }
            }
        })
    }

    func insert(imageInfo: ImageProcessInfo) {
        self.delegate?.beforeInsertImageInfo()
        ImageTransformer.insert(image: imageInfo.image,
                                key: imageInfo.imageKey,
                                imageSize: imageInfo.image.size,
                                textView: self.config.contentTextView,
                                useOrigin: imageInfo.useOrigin)
        let textView = self.config.contentTextView
        if !textView.isFirstResponder {
            self.config.keyboardPanel.closeKeyboardPanel(animation: true)
            textView.becomeFirstResponder()
        }
        self.config.attachmentServer.updateImageAttachmentState(textView)
        self.delegate?.afterInsertImageInfo()
    }

    private func getAllVideoIds() -> [String] {
        guard let attributedText = self.config.contentTextView.attributedText else {
            return []
        }
        return VideoTransformer.fetchAllVideoKey(attributedText: attributedText) + VideoTransformer.fetchAllRemoteVideoKey(attributedText: attributedText)
    }

    private func checkVideoNumber() -> Bool {
        // 检查是否超过视频数目限制
        if !getAllVideoIds().isEmpty {
            showVideoLimitError()
            return false
        }
        return true
    }

    func showVideoLimitError() {
        if let window = self.delegate?.getDisPlayVC().currentWindow() {
            UDToast.showFailure(with: BundleI18n.LarkBaseKeyboard.Lark_Chat_TopicCreateSelectVideoError, on: window)
        }
    }

    public func showLoadingHud(_ title: String) -> (() -> Void) {
        guard let vc = self.delegate?.getDisPlayVC() else { return {} }
        let hud = UDToast.showLoading(with: title, on: vc.view.window ?? vc.view, disableUserInteraction: true)
        return {
            hud.remove()
        }
    }

    /// 正常发送图片你的时候 也应该check一下
    public func uploadFailsImageIfNeed(finish: ((Bool) -> Void)?) {
        if postAttachmentServer.checkAttachmentAllUploadSuccessFor(attruibuteStr: self.config.contentTextView.attributedText) {
            finish?(true)
            return
        }

        guard let fromVC = self.delegate?.getDisPlayVC() else { return }
        let hud = UDToast.showLoading(with: BundleI18n.LarkBaseKeyboard.Lark_Legacy_ComposePostUploadPhoto,
                                      on: fromVC.view, disableUserInteraction: true)
        postAttachmentServer.retryUploadAttachment(textView: self.config.contentTextView) { [weak fromVC] in
            fromVC?.view.endEditing(true)
        } finish: { success in
            hud.remove()
            finish?(success)
        }
    }
}
