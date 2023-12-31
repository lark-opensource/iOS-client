//
//  BatchTransmitAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/22.
//

import RxSwift
import LarkUIKit
import EENavigator
import LarkMessengerInterface
import LKCommonsLogging
import LKCommonsTracker
import Homeric

final class BatchTransmitAlertConfig: ForwardMessageContentPreviewAlertConfig {
    private static let logger = Logger.log(BatchTransmitAlertConfig.self, category: "BatchTransmitAlertConfig")

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? BatchTransmitAlertContent != nil {
            return true
        }
        return false
    }

    // nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
    // TODO: 转发内容预览能力组件内置时优化该逻辑
    override func getContentView() -> UIView? {
        guard let messageContent = content as? BatchTransmitAlertContent else { return nil }
        var wrapperView: UIView?
        if messageContent.containBurnMessage {
            wrapperView = ForwardMessageBurnConfirmFooter()
        } else if !forwardDialogContentFG {
            wrapperView = BatchTransmitOldForwardConfirmFooter(title: messageContent.title)
        } else {
            wrapperView = BatchTransmitForwardConfirmFooter(title: messageContent.title, previewFg: forwardContentPreviewFG)
            var previewBodyInfo: ForwardContentPreviewBodyInfo?
            contentPreviewHandler?.generateForwardContentPreviewBodyInfo(messageIds: messageContent.messageIds, chatId: messageContent.fromChannelId)
                .subscribe(onNext: { (previewBody) in
                    guard let previewBody = previewBody else { return }
                    previewBodyInfo = previewBody
                }, onError: { (error) in
                    Self.logger.error("batch transmit forward alert generate messages: \(error)")
                }).disposed(by: self.disposeBag)
            guard let baseView = wrapperView as? BaseTapForwardConfirmFooter else { return wrapperView }
            baseView.didClickAction = { [weak self] in
                guard let self = self else { return }
                guard let bodyInfo = previewBodyInfo else {
                    self.contentPreviewHandler?.generateForwardContentPreviewBodyInfo(messageIds: messageContent.messageIds, chatId: messageContent.fromChannelId)
                        .subscribe(onNext: { [weak self] (previewBody) in
                            guard let self = self else { return }
                            guard let previewBody = previewBody else { return }
                            previewBodyInfo = previewBody
                            self.didClickMessageForwardAlert(bodyInfo: previewBodyInfo)
                        }, onError: { (error) in
                            Self.logger.error("batch transmit forward alert generate messages tap: \(error)")
                        }).disposed(by: self.disposeBag)
                    return
                }
                self.didClickMessageForwardAlert(bodyInfo: previewBodyInfo)
            }
        }
        return wrapperView
    }

    func didClickMessageForwardAlert(bodyInfo: ForwardContentPreviewBodyInfo?) {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "msg_detail",
                                       "target": "none"]))
        if !forwardContentPreviewFG {
            Self.logger.info("didClick forwardContentPreview \(forwardContentPreviewFG)")
            return
        }
        guard let bodyInfo = bodyInfo else { return }
        let body = MessageForwardContentPreviewBody(messages: bodyInfo.messages, chat: bodyInfo.chat, title: bodyInfo.title)
        guard let fromVC = self.targetVc else { return }
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    override func beforeShowAlertController() {
        guard let messageContent = content as? BatchTransmitAlertContent else { return }
        messageContent.finishCallback?()
    }
}
