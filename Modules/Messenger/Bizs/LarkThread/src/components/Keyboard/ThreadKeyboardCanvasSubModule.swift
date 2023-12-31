//
//  ThreadKeyboardCanvasSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/11.
//

import UIKit
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkCore
import LarkCanvas
import EENavigator
import LarkKeyboardView
import RustPB
import LarkContainer
import LarkSendMessage
import LarkSDKInterface
import LarkModel
import LarkMessengerInterface
public class NormalThreadKeyboardCanvasSubModule: BaseThreadKeyboardCanvasSubModule {

    override func defaultInputSendCanvasWithText(parentMessage: Message?, useOriginal: Bool, imageMessageInfo: ImageMessageInfo, content: Basic_V1_RichText?, chatId: String) {
        guard let parentMessage = parentMessage,
        let thread = self.threadPageItem?.thread else {
            assertionFailure("error data")
            return
        }
        var stateHandler: ((SendMessageState) -> Void)?
        let threadId = thread.id
        guard let sendMessageAPI = self.sendMessageAPI else { return }
        if let content = content {
            stateHandler = { state in
                switch state {
                case .finishSendMessage:
                    sendMessageAPI.sendText(
                        context: nil,
                        content: content,
                        parentMessage: parentMessage,
                        chatId: chatId,
                        threadId: threadId,
                        stateHandler: nil
                    )
                default:
                    break
                }
            }
        }
        // 先发图片，发送成功后再跟一条文本，发送失败则取消发送文本，与转发对齐
        sendMessageAPI.sendImage(
            context: nil,
            parentMessage: parentMessage,
            useOriginal: useOriginal,
            imageMessageInfo: imageMessageInfo,
            chatId: chatId,
            threadId: threadId,
            stateHandler: stateHandler
        )

    }
}

public class MessageThreadKeyboardCanvasSubModule: BaseThreadKeyboardCanvasSubModule {
    override func defaultInputSendCanvasWithText(parentMessage: Message?, useOriginal: Bool, imageMessageInfo: ImageMessageInfo, content: Basic_V1_RichText?, chatId: String) {
        guard let sendMessageAPI = self.sendMessageAPI else { return }
        guard let parentMessage = parentMessage,
        let thread = self.threadPageItem?.thread else {
            assertionFailure("error data")
            return
        }
        var stateHandler: ((SendMessageState) -> Void)?
        let threadId = thread.id
        if let content = content {
            stateHandler = { [weak self] state in
                switch state {
                case .finishSendMessage:
                    sendMessageAPI.sendText(
                        context: self?.defaultSendContext(),
                        content: content,
                        parentMessage: parentMessage,
                        chatId: chatId,
                        threadId: threadId) { [weak self] state in
                            self?.trackReplyMsgSend(state: state, chatModel: self?.metaModel?.chat)
                    }
                default:
                    break
                }
            }
        }
        // 先发图片，发送成功后再跟一条文本，发送失败则取消发送文本，与转发对齐
        sendMessageAPI.sendImage(
            context: defaultSendContext(),
            parentMessage: parentMessage,
            useOriginal: useOriginal,
            imageMessageInfo: imageMessageInfo,
            chatId: chatId,
            threadId: threadId,
            stateHandler: stateHandler
        )
    }
}

public class BaseThreadKeyboardCanvasSubModule: KeyboardPanelCanvasSubModule<KeyboardContext, IMKeyboardMetaModel>, ThreadKeyboardViewPageItemProtocol {

    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?

    public override func getKeyboardPanelCanvasConfig() -> KeyboardPanelCanvasConfig? {
        guard let chat = self.metaModel?.chat else { return nil }
        let id = CanvasIdGenerator.generate(for: chat,
                                            replyMessage: threadPageItem?.getReplyMessage?(),
                                               multiEditMessage: threadPageItem?.keyboardStatusManager.getMultiEditMessage())

        return KeyboardPanelCanvasConfig(itemIconColor: ThreadKeyboardPageItem.iconColor,
                                        canvasId: id,
                                        bizTrancker: "im")
    }

    @available(iOS 13.0, *)
    public override func inputTextViewInputCanvas() {
        CoreTracker.trackCanvasEntrance(chatModel: self.metaModel?.chat,
                                        isComposePost: false,
                                        replyMessage: threadPageItem?.getReplyMessage?())
        super.inputTextViewInputCanvas()

    }

    @available(iOS 13.0, *)
    public override func canvasWillFinish(in controller: LKCanvasViewController, drawingImage: UIImage, canvasData: Data, canvasShouldDismissCallback: @escaping (Bool) -> Void) {
        guard let chat = self.metaModel?.chat else { return }
        let alertController = ShareCanvasAlertController(
            for: chat,
            drawingImage: drawingImage,
            dismissTitle: BundleI18n.LarkThread.Lark_Legacy_Sure,
            canvasShouldDismissCallback: canvasShouldDismissCallback,
            sendCanvasImageAndTextBlock: { [weak self] imageMessageInfo, text in
                guard let `self` = self else {
                    canvasShouldDismissCallback(false)
                    return
                }
                var content: RustPB.Basic_V1_RichText?
                if let text = text {
                    content = RustPB.Basic_V1_RichText.text(text)
                }
                // 准备信息
                canvasShouldDismissCallback(true)
                self.defaultInputSendCanvasWithText(
                    parentMessage: self.threadPageItem?.getReplyMessage?(), // ThreadDetail 不存在父消息的情况
                    useOriginal: true,
                    imageMessageInfo: imageMessageInfo,
                    content: content,
                    chatId: self.metaModel?.chat.id ?? ""
                )
                // update badge
                self.context.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
            }
        )
        context.nav.present(alertController, from: controller)
    }

    func defaultInputSendCanvasWithText(parentMessage: Message?,
                                        useOriginal: Bool,
                                        imageMessageInfo: ImageMessageInfo,
                                        content: RustPB.Basic_V1_RichText?,
                                        chatId: String) {

    }

}
