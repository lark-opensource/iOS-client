//
//  KeyboardPanelInsertCanvasSubModel.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/26.
//

import LarkFoundation
import LarkKeyboardView
import LarkOpenKeyboard
import LarkOpenIM
import LarkCanvas
import LarkAttachmentUploader
import ByteWebImage
import UniverseDesignToast

public protocol KeyboardPanelInsertCanvasService: AnyObject {
    func handlerInsertImageFrom(_ image: UIImage,
                               useOriginal: Bool,
                               attachmentUploader: AttachmentUploader,
                               sendImageConfig: SendImageConfig,
                               encrypt: Bool,
                               fromVC: UIViewController?,
                               processorId: String,
                               callBack:((ImageProcessInfo) -> Void)?)
}

open class KeyboardPanelInsertCanvasSubModel<C:KeyboardContext, M:KeyboardMetaModel>:
    KeyboardPanelCanvasSubModule<C, M> {

    lazy var pictureHandler: KeyboardPanelInsertCanvasService? = {
        return self.context.resolver.resolve(KeyboardPanelInsertCanvasService.self)
    }()

    /// ByteWebImage 用来打印日志的
    open var processorId: String {
        return "composePost canvas"
    }

    open var attachmentServer: PostAttachmentServer? {
        assertionFailure("must be override")
        return nil
    }

    open var sendImageConfig: SendImageConfig {
        assertionFailure("need to be override")
        return SendImageConfig(checkConfig: SendImageCheckConfig(scene: .Chat, fromType: .post))
    }

    open var shouldEncryptImage: Bool {
        assertionFailure("need to be override")
        return false
    }

    @available(iOS 13.0, *)
    open override func canvasWillFinish(in controller: LKCanvasViewController, drawingImage: UIImage, canvasData: Data, canvasShouldDismissCallback: @escaping (Bool) -> Void) {

        defer {
            canvasShouldDismissCallback(true)
            self.context.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
        }

        guard let attachmentServer = attachmentServer else {
            return
        }
        let hideHud = self.showLoadingHud(BundleI18n.LarkBaseKeyboard.Lark_Legacy_Processing)
        pictureHandler?.handlerInsertImageFrom(drawingImage,
                                             useOriginal: true,
                                             attachmentUploader: attachmentServer.attachmentUploader,
                                             sendImageConfig: sendImageConfig,
                                             encrypt: shouldEncryptImage,
                                             fromVC: context.displayVC,
                                             processorId: processorId,
                                             callBack: {  [weak self] info in
            hideHud()
            self?.insert(imageInfo: info)
            self?.context.inputTextView.lu.scrollToBottom(animated: true)
            self?.didInsertImage()
        })
    }

   open func didInsertImage() {}

   open func insert(imageInfo: ImageProcessInfo) {
        ImageTransformer.insert(image: imageInfo.image,
                                key: imageInfo.imageKey,
                                imageSize: imageInfo.image.size,
                                textView: self.context.inputTextView,
                                useOrigin: true)
        let textView = self.context.inputTextView

        if !textView.isFirstResponder {
            self.context.keyboardPanel.closeKeyboardPanel(animation: true)
            textView.becomeFirstResponder()
        }

        attachmentServer?.updateImageAttachmentState(textView)
   }

    func showLoadingHud(_ title: String) -> (() -> Void) {
        let hud = UDToast.showLoading(with: title,
                                      on: self.context.displayVC.view.window ?? self.context.displayVC.view,
                                      disableUserInteraction: true)
        return {
            hud.remove()
        }
    }
}
