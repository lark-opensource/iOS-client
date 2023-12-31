//
//  BatchTransmitAlertProvider.swift
//  LarkForward
//
//  Created by bytedance on 2020/8/19.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface
import AppReciableSDK
import Swinject
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import LarkSetting
import Homeric

struct BatchTransmitAlertContent: ForwardAlertContent {
    let fromChannelId: String
    let messageIds: [String]
    let title: String
    let traceChatType: ForwardAppReciableTrackChatType
    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    let originMergeForwardId: String?
    let containBurnMessage: Bool
    var finishCallback: (() -> Void)?
    var getForwardContentCallback: GetForwardContentCallback {
        let param = BatchForwardParam(messageIds: self.messageIds, originMergeForwardId: self.originMergeForwardId)
        let forwardContent = ForwardContentParam.transmitBatchMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }
    init(fromChannelId: String,
         originMergeForwardId: String?,
         messageIds: [String],
         title: String,
         traceChatType: ForwardAppReciableTrackChatType,
         containBurnMessage: Bool,
         finishCallback: (() -> Void)?) {
        self.fromChannelId = fromChannelId
        self.originMergeForwardId = originMergeForwardId
        self.messageIds = messageIds
        self.title = title
        self.finishCallback = finishCallback
        self.traceChatType = traceChatType
        self.containBurnMessage = containBurnMessage
    }
}

// nolint: duplicated_code -- 转发v2代码，转发v3全业务GA后可删除
final class BatchTransmitAlertProvider: ForwardAlertProvider {
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    private var disposeBag = DisposeBag()
    private static let logger = Logger.log(BatchTransmitAlertProvider.self, category: "BatchTransmitAlertProvider")
    /// 转发内容一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    /// 转发内容二级预览FG开关
    private lazy var forwardContentPreviewFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core_forward_content_preview"))
    }()

    required init(userResolver: UserResolver, content: ForwardAlertContent) {
        super.init(userResolver: userResolver, content: content)
        var param = ForwardFilterParameters()
        param.includeThread = false
        self.filterParameters = param
    }
    private func clearDisposeBag() {
        disposeBag = DisposeBag()
    }

    lazy var contentPreviewHandler: LarkForwardContentPreviewHandler? = {
        guard let chatAPI = self.chatAPI,
              let messageAPI = self.messageAPI,
              let chatterAPI = self.chatterAPI
        else { return nil }
        let contentPreviewHandler = LarkForwardContentPreviewHandler(chatAPI: chatAPI,
                                                                     messageAPI: messageAPI,
                                                                     chatterAPI: chatterAPI,
                                                                     userResolver: userResolver)
        return contentPreviewHandler
    }()

    override var isSupportMention: Bool {
        return true
    }

    override var pickerTrackScene: String? {
        return "msg_forward"
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? BatchTransmitAlertContent != nil {
            return true
        }
        return false
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        // 所有类型都不过滤
        return [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig(),
            ForwardMyAiEntityConfig()
        ]
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let messageContent = content as? BatchTransmitAlertContent else { return nil }
        // 话题群和话题置灰
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(chatType: .normal),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func containBurnMessage() -> Bool {
        guard let messageContent = content as? BatchTransmitAlertContent else { return false }
        return messageContent.containBurnMessage
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let messageContent = content as? BatchTransmitAlertContent else { return nil }
        var wrapperView: UIView?
        if !forwardDialogContentFG {
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
        userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    override func beforeShowAction() {
        guard let messageContent = content as? BatchTransmitAlertContent else { return }
        messageContent.finishCallback?()
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let content = self.content as? BatchTransmitAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just([])
        }
        //ids.chatIds(群聊和话题) ids.userIds(机器人和单聊)
        let ids = self.itemsToIds(items)
        //threadIDAndChatIDs 话题群
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let hud = UDToast.showLoading(on: window)
        return forwardService.batchTransmitForward(originMergeForwardId: content.originMergeForwardId,
                                                   messageIds: content.messageIds,
                                                   checkChatIDs: ids.chatIds,
                                                   to: items.filter { $0.type == .chat }.map { $0.id },
                                                   to: threadIDAndChatIDs,
                                                   userIds: ids.userIds,
                                                   extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak window] (_, filePermCheck) in
                guard let window = window else { return }
                if let filePermCheck = filePermCheck {
                    hud.remove()
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                    return
                }
                //转发成功 给予用户反馈
                hud.showSuccess(with: BundleI18n.LarkForward.Lark_Legacy_Success, on: window)
            }, onError: { (error) in
                ///错误文案提示方式 同步安卓和PC
                if let error = error.underlyingError as? APIError {
                    if !error.displayMessage.isEmpty {
                        hud.showFailure(
                            with: error.displayMessage,
                            on: window,
                            error: error
                        )
                    } else {
                        hud.showFailure(
                            with: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    hud.showFailure(
                        with: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed,
                        on: window,
                        error: error
                    )
                }
                //失败埋点
                AppReciableSDK.shared.error(
                    params: ErrorParams(
                        biz: .Messenger,
                        scene: .Chat,
                        event: .batchTransmitMessage,
                        errorType: .SDK,
                        errorLevel: .Exception,
                        errorCode: (error as NSError).code,
                        userAction: nil,
                        page: "ForwardViewController",
                        errorMessage: (error as NSError).description,
                        extra: Extra(
                            isNeedNet: true,
                            category: [
                                "chat_type": "\(content.traceChatType.rawValue)"
                            ],
                            extra: [
                                "chat_count": "\(ids.chatIds.count + ids.userIds.count)"
                            ]
                        )
                    )
                )
            }).map({ (chatIds, _) in return chatIds })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let content = self.content as? BatchTransmitAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just([])
        }
        //ids.chatIds(群聊和话题) ids.userIds(机器人和单聊)
        let ids = self.itemsToIds(items)
        //threadIDAndChatIDs 话题群
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let hud = UDToast.showLoading(on: window)
        return forwardService.batchTransmitForward(originMergeForwardId: content.originMergeForwardId,
                                                   messageIds: content.messageIds,
                                                   checkChatIDs: ids.chatIds,
                                                   to: items.filter { $0.type == .chat }.map { $0.id },
                                                   to: threadIDAndChatIDs,
                                                   userIds: ids.userIds,
                                                   attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak window] (_, filePermCheck) in
                guard let window = window else { return }
                if let filePermCheck = filePermCheck {
                    hud.remove()
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                    return
                }
                //转发成功 给予用户反馈
                hud.showSuccess(with: BundleI18n.LarkForward.Lark_Legacy_Success, on: window)
            }, onError: { (error) in
                ///错误文案提示方式 同步安卓和PC
                if let error = error.underlyingError as? APIError {
                    if !error.displayMessage.isEmpty {
                        hud.showFailure(
                            with: error.displayMessage,
                            on: window,
                            error: error
                        )
                    } else {
                        hud.showFailure(
                            with: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    hud.showFailure(
                        with: BundleI18n.LarkForward.Lark_Legacy_ChatViewForwardingFailed,
                        on: window,
                        error: error
                    )
                }
                //失败埋点
                AppReciableSDK.shared.error(
                    params: ErrorParams(
                        biz: .Messenger,
                        scene: .Chat,
                        event: .batchTransmitMessage,
                        errorType: .SDK,
                        errorLevel: .Exception,
                        errorCode: (error as NSError).code,
                        userAction: nil,
                        page: "ForwardViewController",
                        errorMessage: (error as NSError).description,
                        extra: Extra(
                            isNeedNet: true,
                            category: [
                                "chat_type": "\(content.traceChatType.rawValue)"
                            ],
                            extra: [
                                "chat_count": "\(ids.chatIds.count + ids.userIds.count)"
                            ]
                        )
                    )
                )
            }).map({ (chatIds, _) in return chatIds })
    }
}
