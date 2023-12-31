//
//  MergeForwardAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/19.
//

import RxSwift
import LarkUIKit
import EENavigator
import LarkMessengerInterface
import LKCommonsLogging
import LKCommonsTracker
import Homeric

final class MergeForwardAlertConfig: ForwardMessageContentPreviewAlertConfig {
    private static let logger = Logger.log(MergeForwardAlertConfig.self, category: "MergeForwardAlertConfig")

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? MergeForwardAlertContent != nil {
            return true
        }
        return false
    }

    // nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
    // TODO: 转发内容预览能力组件内置时优化该逻辑
    override func getContentView() -> UIView? {
        guard let messageContent = content as? MergeForwardAlertContent else { return nil }
        /// 小组转发的thread 都是卡片样式
        if messageContent.containBurnMessage {
            return ForwardMessageBurnConfirmFooter()
        }
        if messageContent.forwardThread {
            if !forwardDialogContentFG {
                return nil
            }
            /// 私有话题详情 or 消息话题详情 转发
            let baseView = ForwardConfirmFooterGenerator(userResolver: userResolver).generatorThreadDetailConfirmFooter(message: messageContent.threadRootMessage)
            baseView.didClickAction = { [weak self] in
                guard let self = self else { return }
                self.didClickThreadDetailForwardAlert()
            }
            return baseView
        }
        var wrapperView: UIView?
        if !forwardDialogContentFG {
            wrapperView = ForwardMergeMessageOldConfirmFooter(title: messageContent.title)
        } else {
            wrapperView = ForwardMergeMessageConfirmFooter(title: messageContent.title, previewFg: forwardContentPreviewFG)
            var previewBodyInfo: ForwardContentPreviewBodyInfo?
            contentPreviewHandler?.generateForwardContentPreviewBodyInfo(messageIds: messageContent.messageIds, chatId: messageContent.fromChannelId)
                .subscribe(onNext: { (previewBody) in
                    guard let previewBody = previewBody else { return }
                    previewBodyInfo = previewBody
                }, onError: { (error) in
                    Self.logger.error("merge forward alert generate messages: \(error)")
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
                            Self.logger.error("merge forward alert generate messages tap: \(error)")
                        }).disposed(by: self.disposeBag)
                    return
                }
                self.didClickMessageForwardAlert(bodyInfo: previewBodyInfo)
            }
        }
        return wrapperView
    }

    func didClickThreadDetailForwardAlert() {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "msg_detail",
                                       "target": "none"]))
        guard let messageContent = content as? MergeForwardAlertContent else { return }
        Self.logger.info("Forward.ContentPreview: PrivateOrMsgThreadDetail Preview, threadID: \(messageContent.threadRootMessage?.threadId) isMsgThread: \(messageContent.isMsgThread)")
        if !forwardContentPreviewFG { return }
        if messageContent.isMsgThread {
            showMsgThreadDetailContentPreview()
        } else {
            showTopicGroupThreadDetailContentPreview()
        }
    }

    func showMsgThreadDetailContentPreview() {
        guard let messageContent = content as? MergeForwardAlertContent,
              let threadID = messageContent.threadRootMessage?.threadId,
              let fromVC = self.targetVc
        else { return }
        let body = MsgThreadDetailPreviewByIDBody(threadId: threadID, loadType: .root)
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    func showTopicGroupThreadDetailContentPreview() {
        guard let messageContent = content as? MergeForwardAlertContent,
              let threadID = messageContent.threadRootMessage?.threadId,
              let fromVC = self.targetVc
        else { return }
        let body = ThreadDetailPreviewByIDBody(threadId: threadID, loadType: .root)
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    func didClickMessageForwardAlert(bodyInfo: ForwardContentPreviewBodyInfo?) {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "msg_detail",
                                       "target": "none"]))
        if !forwardContentPreviewFG { return }
        guard let bodyInfo = bodyInfo else {
            Self.logger.info("didClick forwardContentPreview \(forwardContentPreviewFG)")
            return
        }
        let body = MessageForwardContentPreviewBody(messages: bodyInfo.messages, chat: bodyInfo.chat, title: bodyInfo.title)
        guard let fromVC = self.targetVc else { return }
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    override func beforeShowAlertController() {
        guard let messageContent = content as? MergeForwardAlertContent else { return }
        messageContent.finishCallback?()
    }

    override func allertCancelAction() {
        Tracer.trackMergeForwardCancel()
    }
}
