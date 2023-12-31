//
//  IMChatKeyboardCanvasPanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkCore
import EENavigator
import LarkCanvas
import LKCommonsLogging
import LarkMessageCore
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkKeyboardView
import LarkChatKeyboardInterface

public class IMChatKeyboardCanvasPanelSubModule: KeyboardPanelCanvasSubModule<KeyboardContext, IMKeyboardMetaModel>, ChatKeyboardViewPageItemProtocol {

    static let logger = Logger.log(IMChatKeyboardCanvasPanelSubModule.self, category: "Module.Inputs")
    @ScopedInjectedLazy var messageAPI: MessageAPI?

    private var itemConfig: ChatKeyboardCanvasItemConfig? {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }

    public override func didTapItem() {
        self.itemConfig?.uiConfig?.tappedBlock?()
    }

    @available(iOS 13.0, *)
    public override func canvasWillFinish(in controller: LKCanvasViewController, drawingImage: UIImage, canvasData: Data, canvasShouldDismissCallback: @escaping (Bool) -> Void) {
        guard let chat = self.metaModel?.chat else { return }
        // 弹出确认弹窗
        // Alert Controller
        let alertController = ShareCanvasAlertController(
            for: chat,
            drawingImage: drawingImage,
            dismissTitle: BundleI18n.LarkChat.Lark_Legacy_Sure,
            canvasShouldDismissCallback: canvasShouldDismissCallback,
            sendCanvasImageAndTextBlock: { [weak self] imageMessageInfo, text in
                guard let `self` = self else {
                    Self.logger.error("Cannot find self(NormalChatInputKeyboard) on alertController dismissing")
                    canvasShouldDismissCallback(false)
                    return
                }
                // 准备信息
                let info = self.chatPageItem?.getReplyInfo?()
                let parentMessage = info?.message
                let chatId = chat.id
                let position = chat.lastMessagePosition
                let messageSender = self.itemConfig?.sendConfig?.sendService
                let messageAPI = self.messageAPI
                messageSender?.sendImages(
                    parentMessage: parentMessage,
                    useOriginal: true,
                    imageMessageInfos: [imageMessageInfo],
                    chatId: chatId,
                    lastMessagePosition: position,
                    quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
                    extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                          ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.other.rawValue],
                    stateHandler: { _, state in
                        switch state {
                        case .finishSendMessage(_, _, let messageId, _, _):
                            guard let text = text else {
                                return
                            }
                            guard let messageId = messageId else {
                                Self.logger.error("Didn't get messageId from server")
                                return
                            }

                            let content = RustPB.Basic_V1_RichText.text(text)
                            _ = messageAPI?.fetchMessage(id: messageId).subscribe(onNext: { (message) in
                                messageSender?.sendText(
                                    content: content,
                                    lingoInfo: nil,
                                    parentMessage: message,
                                    chatId: chatId,
                                    position: position,
                                    scheduleTime: nil,
                                    quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
                                    callback: nil
                                )
                            })
                        default: break
                        }
                    }
                )
                self.chatPageItem?.keyboardStatusManager.switchToDefaultJob()
                canvasShouldDismissCallback(true)
                // update badge
                self.context.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
            }
        )
        navigator.present(alertController, from: controller)
    }

    public override func getKeyboardPanelCanvasConfig() -> KeyboardPanelCanvasConfig? {
        guard let chat = self.metaModel?.chat else { return nil }
        let id = CanvasIdGenerator.generate(for: chat,
                                            replyMessage: chatPageItem?.keyboardStatusManager.getReplyMessage(),
                                               multiEditMessage: chatPageItem?.keyboardStatusManager.getMultiEditMessage())
        return KeyboardPanelCanvasConfig(itemIconColor: UIColor.ud.iconN2,
                                          canvasId: id,
                                          bizTrancker: "im")
     }
}
