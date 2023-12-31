//
//  KeyboardPanelImageInsertSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/20.
//

import UIKit
import LarkOpenKeyboard
import LarkAssetsBrowser
import LarkKeyboardView
import Photos
import LarkFoundation
import ByteWebImage
import LarkContainer
import LarkAttachmentUploader
import AppReciableSDK

open class KeyboardPanelImageInsertSubModule<C:KeyboardContext, M:KeyboardMetaModel>:
    KeyboardPanelPictureSubModule<C, M>, KeyboardImageInsertManagerDelegate {

    @InjectedSafeLazy var sendImageProcessor: SendImageProcessor

    public var onInserImageAttachment: ((_ isVideo: Bool) -> Void)?

    var mgr: KeyboardImageInsertManager?

    /// 图片库上报埋点需要 一个scene
    open var scene: Scene {
        assertionFailure("need to be override")
        return .Unknown
    }

    /// 图上上传需要使用attachmentUploader，attachmentUploader创建需要
    open var attachmentUploaderName: String {
        assertionFailure("need to be override")
        return ""
    }

    /// 图片库打印日志使用 区分常见 建议不同业务放分开
    open var processorId :String {
       return "post.sendImage.after.compress"
    }

    /// 图片是否需要加密
    open var shouldEncryptImage: Bool {
        assertionFailure("need to be override")
        return false
    }

    /// 图片上传流程需要的配置以及场景
    open var sendImageConfig: SendImageConfig {
        assertionFailure("need to be override")
        return SendImageConfig(isSkipError: true,
                               checkConfig: SendImageCheckConfig(scene: .Chat, fromType: .post))
    }

    /// postAttachmentServer 处理 图片上传 & 缓存
    private var postAttachmentServer: PostAttachmentServer?

    /// 当前的图片处理对象
    private var pictureHandler: KeyboardPanelPictureHandlerService?

    open override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        self.mgr?.assetPickerSuite(suiteView, didTakePhoto: photo)
    }

    open override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        self.mgr?.assetPickerSuite(suiteView, didTakeVideo: url)
    }

    /// 自动上传需要重新上传的图片，没有的话finish 会立即回调
    /// - Parameter finish: Bool 是否上传成功
    public func uploadFailsImageIfNeed(finish: ((Bool) -> Void)?) {
        self.mgr?.uploadFailsImageIfNeed(finish: finish)
    }

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let postAttachmentServer = self.getPostAttachmentServer() else {
            return nil
        }
        let config = KeyboardImageInsertConfig(contentTextView: context.inputTextView,
                                              keyboardPanel: context.keyboardPanel,
                                              encryptImage: shouldEncryptImage,
                                              attachmentServer: postAttachmentServer,
                                              sendImageConfig: sendImageConfig,
                                              scene: scene,
                                              processorId: processorId,
                                              pictureService: getPictureHandler(),
                                              delegate: self)
        self.mgr = KeyboardImageInsertManager(config: config)
        return super.didCreatePanelItem()
    }

    open override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        self.mgr?.assetPickerSuite(suiteView, didFinishSelect: result)
    }

    open override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didChangeSelection result: AssetPickerSuiteSelectResult) {
        self.mgr?.assetPickerSuite(suiteView, didChangeSelection: result)
    }

    open func getPictureHandler() -> KeyboardPanelPictureHandlerService? {
        if pictureHandler != nil {
            return pictureHandler
        }
        return self.context.resolver.resolve(KeyboardPanelPictureHandlerService.self)
    }

    open func getPostAttachmentServer() -> PostAttachmentServer? {
        /// 如果名字都一样的话 不需要重新创建
        if let postAttachmentServer = self.postAttachmentServer,
            postAttachmentServer.attachmentUploader.name == attachmentUploaderName {
            return postAttachmentServer
        }
        if let attachmentUploader = context.resolver.resolve(AttachmentUploader.self, argument: attachmentUploaderName) {
            self.postAttachmentServer = PostAttachmentManager(attachmentUploader: attachmentUploader)
        } else {
            assertionFailure("may be somethings error")
        }
        return self.postAttachmentServer
    }

    open func getDisPlayVC() -> UIViewController {
        return context.displayVC
    }

    open func beforeInsertVideoInfo(_ info: VideoTransformInfo, uploadKey: String) {
    }

    open func afterInsertVideoInfo(_ info: VideoTransformInfo, uploadKey: String) {
        self.onInserImageAttachment?(true)
    }

    open func beforeInsertImageInfo() {}

    open func afterInsertImageInfo() {
        self.onInserImageAttachment?(false)
    }

    open func didFinishInsertAllImages() {
    }

    open func didUpdateAttachmentResultInfo(attributedText: NSAttributedString) {
    }

    open func didUpdateImageAttachmentState(attributedText: NSAttributedString) {}
}
