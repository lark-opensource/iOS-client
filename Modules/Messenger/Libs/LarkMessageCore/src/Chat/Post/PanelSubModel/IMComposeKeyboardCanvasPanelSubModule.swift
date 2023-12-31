//
//  IMComposeKeyboardCanvasPanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/26.
//

import UIKit
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkKeyboardView
import LarkCore
import ByteWebImage

class IMComposeKeyboardCanvasPanelSubModule: KeyboardPanelInsertCanvasSubModel<IMComposeKeyboardContext, IMKeyboardMetaModel>, ComposeKeyboardViewPageItemProtocol {

    override var attachmentServer: PostAttachmentServer? {
        return pageItem?.attachmentServer
    }

    override var sendImageConfig: SendImageConfig {
        return SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: true, scene: .Chat, biz: .Messenger, fromType: .post))
    }

    override var shouldEncryptImage: Bool {
        return self.metaModel?.chat.isPrivateMode ?? false
    }

    public override func getKeyboardPanelCanvasConfig() -> KeyboardPanelCanvasConfig? {
        guard let chat = self.metaModel?.chat else { return nil }
        let id = CanvasIdGenerator.generate(for: chat,
                                            replyMessage: context.getReplyMessage(),
                                               multiEditMessage: context.keyboardStatusManager.getMultiEditMessage())
        return KeyboardPanelCanvasConfig(itemIconColor: ComposeKeyboardPageItem.iconColor,
                                          canvasId: id,
                                          bizTrancker: "im")
     }

    @available(iOS 13.0, *)
    public override func inputTextViewInputCanvas() {
        CoreTracker.trackCanvasEntrance(chatModel: self.metaModel?.chat,
                                        isComposePost: true,
                                        replyMessage: context.keyboardStatusManager.getRelatedDispalyMessage())
        super.inputTextViewInputCanvas()
    }

    public override func didInsertImage() {
        IMTracker.Chat.Main.Click.ImageMediaInsert(self.metaModel?.chat,
                                                   isFullScreen: true,
                                                   isImage: true,
                                                   self.pageItem?.chatFromWhere ?? .ignored)
    }
}
