//
//  IMComposeKeyboardPictruePanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/25.
//

import UIKit
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkAssetsBrowser
import LarkKeyboardView
import LarkCore
import LarkAlertController
import EENavigator
import ByteWebImage
import LarkSetting
import AppReciableSDK
import LarkContainer

class IMComposeKeyboardPictruePanelSubModule: KeyboardPanelImageInsertSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>,
                                              ComposeKeyboardViewPageItemProtocol {
    /// 设置回调
    var hasOtherResponer: (() -> Bool)?

    var supportVideoContent: Bool = true {
        didSet {
            if supportVideoContent != oldValue {
                self.item = nil
                self.context.reloadPaneItems()
            }
        }
    }

    var onUpdateAttachmentResultCallBack: (() -> Void)?

    var didFinishInsertAllImagesCallBack: (() -> Void)?

    override var scene: Scene {
        guard let chat = self.metaModel?.chat else { return .Thread }
        if chat.chatMode == .threadV2 {
            return .Thread
        }
        return self.pageItem?.isFromMsgThread == true ? .Thread : .Chat
    }

    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    /// 图片发送逻辑统一FG
    lazy var IsCompressCameraPhotoFG: Bool = fgService?.staticFeatureGatingValue(with: "feature_key_camera_photo_compress") ?? false

    override var shouldEncryptImage: Bool { return self.metaModel?.chat.isPrivateMode ?? false }

    override var sendImageConfig: SendImageConfig {
        return SendImageConfig(isSkipError: false,
                               checkConfig: SendImageCheckConfig(isOrigin: !IsCompressCameraPhotoFG,
                                                                 needConvertToWebp: LarkImageService.shared.imageUploadWebP,
                                                                 scene: scene,
                                                                 biz: .Messenger,
                                                                 fromType: .post))
    }

    override func getPanelConfig() -> (UIColor?, LarkKeyboard.PictureKeyboardConfig)? {
        let config = LarkKeyboard.PictureKeyboardConfig(
            type: supportVideoContent ? PhotoPickerAssetType.default : .imageOnly(maxCount: 9),
            delegate: self,
            selectedBlock: { [weak self] () -> Bool in
                guard let self = self else {
                    return false
                }
                LarkMessageCoreTracker.trackComposePostInputItem(KeyboardItemKey.picture)
                if self.hasOtherResponer?() == true {
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
                    alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_Legacy_ComposePostTitlecannotinsertimage)
                    alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Sure)
                    self.context.nav.present(alertController, from: self.context.displayVC)
                    return false
                }
                IMTracker.Chat.Main.Click.ImageSelect(self.metaModel?.chat,
                                                      isFulllScreen: true,
                                                      nil,
                                                      self.pageItem?.chatFromWhere)
                return true
            },
            photoViewCallback: { _ in },
            originVideo: true,
            sendButtonTitle: BundleI18n.LarkMessageCore.Lark_Legacy_Sure
        )
        return (ComposeKeyboardPageItem.iconColor, config)
    }

    override func getPostAttachmentServer() -> PostAttachmentServer? {
        return self.pageItem?.attachmentServer
    }

    override func beforeInsertVideoInfo(_ info: VideoTransformInfo, uploadKey: String) {
       let isMultiEdit = self.context.keyboardStatusManager.currentKeyboardJob.isMultiEdit
        info.uploadID = isMultiEdit ? uploadKey : nil
    }

    override func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
        LarkMessageCoreTracker.trackAssetPickerSuiteClickType(clickType)
    }

    override func didFinishInsertAllImages() {
        self.didFinishInsertAllImagesCallBack?()
    }

    override func didUpdateImageAttachmentState(attributedText: NSAttributedString) {
        self.onUpdateAttachmentResultCallBack?()
    }
}
