//
//  MergeForwardAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/4/2.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface
import AppReciableSDK
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import LarkSetting
import Homeric
import RustPB

struct MergeForwardAlertContent: ForwardAlertContent {
    let fromChannelId: String
    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    let originMergeForwardId: String?
    let messageIds: [String]
    // 话题详情转发时需要message实体获取poster name
    var threadRootMessage: Message?
    let title: String
    let forwardThread: Bool
    var finishCallback: (() -> Void)?
    var needQuasiMessage: Bool
    let traceChatType: ForwardAppReciableTrackChatType
    let containBurnMessage: Bool
    let afterForwardBlock: (() -> Void)?
    let isMsgThread: Bool
    var getForwardContentCallback: GetForwardContentCallback {
        let param = MergeForwardParam(messageIds: self.messageIds,
                                      quasiTitle: self.title,
                                      needQuasiMessage: self.needQuasiMessage,
                                      originMergeForwardId: self.originMergeForwardId,
                                      type: forwardThread ? Basic_V1_MergeFowardMessageType.mergeThread : Basic_V1_MergeFowardMessageType.mergeMessage,
                                      threadID: forwardThread ? self.messageIds.first ?? "" : nil,
                                      limited: false)
        let forwardContent = ForwardContentParam.transmitMergeMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }

    init(fromChannelId: String,
         originMergeForwardId: String?,
         messageIds: [String],
         threadRootMessage: Message? = nil,
         title: String,
         forwardThread: Bool = false,
         finishCallback: (() -> Void)?,
         needQuasiMessage: Bool,
         traceChatType: ForwardAppReciableTrackChatType,
         isMsgThread: Bool = false,
         containBurnMessage: Bool,
         afterForwardBlock: (() -> Void)? = nil) {
        self.fromChannelId = fromChannelId
        self.originMergeForwardId = originMergeForwardId
        self.messageIds = messageIds
        self.threadRootMessage = threadRootMessage
        self.title = title
        self.forwardThread = forwardThread
        self.finishCallback = finishCallback
        self.needQuasiMessage = needQuasiMessage
        self.traceChatType = traceChatType
        self.isMsgThread = isMsgThread
        self.containBurnMessage = containBurnMessage
        self.afterForwardBlock = afterForwardBlock
    }
}

// nolint: duplicated_code,magic_number -- 转发v2逻辑，转发v3全业务GA后可删除
final class MergeForwardAlertProvider: ForwardAlertProvider {
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    private var disposeBag = DisposeBag()
    private static let logger = Logger.log(MergeForwardAlertProvider.self, category: "MergeForwardAlertProvider")
    /// 转发内容一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    /// 转发内容二级预览FG开关
    private lazy var forwardContentPreviewFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core_forward_content_preview"))
    }()

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
        if content as? MergeForwardAlertContent != nil {
            return true
        }
        return false
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        // 所有类型都不过滤（包括myai）
        return [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig(),
            ForwardMyAiEntityConfig()
        ]
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        // 所有类型都不置灰（包括myai）
        return [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig(),
            ForwardThreadEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
    }

    override func containBurnMessage() -> Bool {
        guard let messageContent = content as? MergeForwardAlertContent else { return false }
        return messageContent.containBurnMessage
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let messageContent = content as? MergeForwardAlertContent else { return nil }
        /// 小组转发的thread 都是卡片样式
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
        userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    func showTopicGroupThreadDetailContentPreview() {
        guard let messageContent = content as? MergeForwardAlertContent,
              let threadID = messageContent.threadRootMessage?.threadId,
              let fromVC = self.targetVc
        else { return }
        let body = ThreadDetailPreviewByIDBody(threadId: threadID, loadType: .root)
        userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
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
        userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    override func beforeShowAction() {
        guard let messageContent = content as? MergeForwardAlertContent else { return }
        messageContent.finishCallback?()
    }

    override func cancelAction() {
        Tracer.trackMergeForwardCancel()
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? MergeForwardAlertContent else { return .just([]) }
        Tracer.trackMergeForwardConfirm()
        let ids = self.itemsToIds(items)
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }

        let ob = BehaviorSubject<[String]>(value: []).asObserver()

        if messageContent.forwardThread {
            Self.mergeForwardThread(
                resolver: self.resolver,
                checkChatIDs: ids.chatIds,
                to: items.filter { $0.type == .chat }.map { $0.id },
                to: threadIDAndChatIDs,
                userIDs: ids.userIds,
                originMergeForwardId: messageContent.originMergeForwardId,
                threadID: messageContent.messageIds.first ?? "",
                messageIds: messageContent.messageIds,
                title: messageContent.title,
                input: input,
                observer: ob,
                disposeBag: self.disposeBag,
                clearDisposeBag: { [weak self] in self?.clearDisposeBag() },
                afterForwardBlock: messageContent.afterForwardBlock,
                userResolver: self.userResolver,
                from: from
            ).subscribe().disposed(by: self.disposeBag)
        } else {
            mergeForwardMessage(
                messageContent: messageContent,
                checkChatIDs: ids.chatIds,
                to: items.filter { $0.type == .chat }.map { $0.id },
                to: threadIDAndChatIDs,
                userIDs: ids.userIds,
                input: input,
                observer: ob,
                from: from
            ).subscribe().disposed(by: self.disposeBag)
        }

        return ob.do(onError: { error in
            //失败埋点
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .mergeForwardMessage,
                    errorType: .SDK,
                    errorLevel: .Exception,
                    errorCode: (error as NSError).code,
                    userAction: nil,
                    page: "ForwardViewController",
                    errorMessage: (error as NSError).description,
                    extra: Extra(
                        isNeedNet: true,
                        category: [
                            "chat_type": "\(messageContent.traceChatType.rawValue)"
                        ],
                        extra: [
                            "chat_count": "\(ids.chatIds.count + ids.userIds.count)"
                        ]
                    )
                ))
        })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? MergeForwardAlertContent else { return .just([]) }
        Tracer.trackMergeForwardConfirm()
        let ids = self.itemsToIds(items)
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }

        let ob = BehaviorSubject<[String]>(value: []).asObserver()

        if messageContent.forwardThread {
            Self.mergeForwardThread(
               resolver: self.resolver,
               checkChatIDs: ids.chatIds,
               to: items.filter { $0.type == .chat }.map { $0.id },
               to: threadIDAndChatIDs,
               userIDs: ids.userIds,
               originMergeForwardId: messageContent.originMergeForwardId,
               threadID: messageContent.messageIds.first ?? "",
               messageIds: messageContent.messageIds,
               title: messageContent.title,
               attributeInput: attributeInput,
               observer: ob,
               disposeBag: self.disposeBag,
               clearDisposeBag: { [weak self] in self?.clearDisposeBag() },
               afterForwardBlock: messageContent.afterForwardBlock,
               userResolver: self.userResolver,
               from: from
            ).subscribe().disposed(by: self.disposeBag)
        } else {
            mergeForwardMessage(
                messageContent: messageContent,
                checkChatIDs: ids.chatIds,
                to: items.filter { $0.type == .chat }.map { $0.id },
                to: threadIDAndChatIDs,
                userIDs: ids.userIds,
                attributeInput: attributeInput,
                observer: ob,
                from: from
            ).subscribe().disposed(by: self.disposeBag)
        }

        return ob.do(onError: { error in
            //失败埋点
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .mergeForwardMessage,
                    errorType: .SDK,
                    errorLevel: .Exception,
                    errorCode: (error as NSError).code,
                    userAction: nil,
                    page: "ForwardViewController",
                    errorMessage: (error as NSError).description,
                    extra: Extra(
                        isNeedNet: true,
                        category: [
                            "chat_type": "\(messageContent.traceChatType.rawValue)"
                        ],
                        extra: [
                            "chat_count": "\(ids.chatIds.count + ids.userIds.count)"
                        ]
                    )
                ))
        })
    }

    private func mergeForwardMessage(
        messageContent: MergeForwardAlertContent,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIDs: [String],
        input: String?,
        observer: BehaviorSubject<[String]>,
        from: UIViewController
        ) -> Observable<Void> {
        guard let window = from.view.window,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self)
        else {
            assertionFailure()
            return Observable<Void>.empty()
        }
        let topmostFrom = WindowTopMostFrom(vc: from)

        let hud = UDToast.showLoading(on: window)
        return forwardService
            .mergeForward(originMergeForwardId: messageContent.originMergeForwardId,
                          messageIds: messageContent.messageIds,
                          checkChatIDs: checkChatIDs,
                          to: chatIDs,
                          to: threadIDAndChatIDs,
                          userIds: userIDs,
                          title: messageContent.title,
                          extraText: input ?? "",
                          needQuasiMessage: messageContent.needQuasiMessage)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self, weak window] (chatIds, filePermCheck) in
                hud.remove()
                if let window = window,
                   let filePermCheck = filePermCheck {
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                }
                observer.onNext(chatIds)
                observer.onCompleted()
                self?.clearDisposeBag()
                messageContent.afterForwardBlock?()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                observer.onError(error)
                self.clearDisposeBag()
            //这里做了一个类型转换 将Observable<String> 转换到 Observable<Void>
            }).flatMap({ (_) -> Observable<Void> in
                return .just(())
            })
    }

    private func mergeForwardMessage(
        messageContent: MergeForwardAlertContent,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIDs: [String],
        attributeInput: NSAttributedString?,
        observer: BehaviorSubject<[String]>,
        from: UIViewController
        ) -> Observable<Void> {
        guard let window = from.view.window,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self)
        else {
            assertionFailure()
            return Observable<Void>.empty()
        }
        let topmostFrom = WindowTopMostFrom(vc: from)

        let hud = UDToast.showLoading(on: window)
        return forwardService
            .mergeForward(originMergeForwardId: messageContent.originMergeForwardId,
                          messageIds: messageContent.messageIds,
                          checkChatIDs: checkChatIDs,
                          to: chatIDs,
                          to: threadIDAndChatIDs,
                          userIds: userIDs,
                          title: messageContent.title,
                          attributeExtraText: attributeInput ?? NSAttributedString(string: ""),
                          needQuasiMessage: messageContent.needQuasiMessage)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self, weak window] (chatIds, filePermCheck) in
                hud.remove()
                if let window = window,
                   let filePermCheck = filePermCheck {
                    UDToast.showTips(with: filePermCheck.toast, on: window)
                }
                observer.onNext(chatIds)
                observer.onCompleted()
                self?.clearDisposeBag()
                messageContent.afterForwardBlock?()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                observer.onError(error)
                self.clearDisposeBag()
            //这里做了一个类型转换 将Observable<String> 转换到 Observable<Void>
            }).flatMap({ (_) -> Observable<Void> in
                return .just(())
            })
    }
}

// swiftlint:disable function_parameter_count
extension MergeForwardAlertProvider {
    static func mergeForwardThread(
        resolver: Resolver,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIDs: [String],
        originMergeForwardId: String?,
        threadID: String,
        messageIds: [String],
        title: String,
        input: String?,
        observer: BehaviorSubject<[String]>,
        disposeBag: DisposeBag,
        clearDisposeBag: @escaping () -> Void,
        afterForwardBlock: (() -> Void)?,
        userResolver: UserResolver,
        from: UIViewController
        ) -> Observable<Void> {
        guard let window = from.view.window,
              let forwardService = try? resolver.resolve(assert: ForwardService.self)
        else {
            assertionFailure()
            return Observable<Void>.empty()
        }

        let hud = UDToast.showLoading(on: window)
        return forwardService.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIDs)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                forwardErrorHandler(userResolver: userResolver, hud: hud, on: from, error: error)
            })
            .flatMap({ (chatModels) -> Observable<Void> in
                var threadModeChatIds: [String] = []
                let sendChatIDs = chatModels
                .filter {
                    // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                    // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                    let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIDs.contains($0.id)
                    if $0.displayInThreadMode {
                        threadModeChatIds.append($0.id)
                    }
                    return onlySendChatIDsFilter
                }
                .map { $0.id }
                return forwardService.mergeForward(
                    originMergeForwardId: originMergeForwardId,
                    threadID: threadID,
                    needCopyReaction: true,
                    checkChatIDs: checkChatIDs,
                    to: sendChatIDs,
                    to: threadIDAndChatIDs.filter { chatModels.map { $0.id }.contains($1) },
                    threadModeChatIds: threadModeChatIds,
                    title: title,
                    isLimit: false,
                    extraText: input ?? ""
                    )
                    .observeOn(MainScheduler.instance)
                    .do(onNext: { [weak window] (chatIds, filePermCheck) in
                        hud.remove()
                        if let window = window,
                           let filePermCheck = filePermCheck {
                            UDToast.showTips(with: filePermCheck.toast, on: window)
                        }
                        observer.onNext(chatIds)
                        observer.onCompleted()
                        clearDisposeBag()
                        afterForwardBlock?()
                    }, onError: { (error) in
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .banned(let message), .forwardThreadTooLargeFail(let message):
                                hud.showFailure(with: message, on: window, error: error)
                            case .forwardThreadReachLimit(let message):
                                hud.remove()
                                observer.onNext([""])
                                // 稍微延后，等上一个AlertController隐藏后再显示。
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                    showForwardThreadLimitAlert(
                                        resolver: resolver,
                                        with: message,
                                        originMergeForwardId: originMergeForwardId,
                                        messageIds: messageIds,
                                        checkChatIDs: checkChatIDs,
                                        chatIDs: sendChatIDs,
                                        title: title,
                                        extraText: input ?? "",
                                        observer: observer,
                                        disposeBag: disposeBag,
                                        clearDisposeBag: clearDisposeBag,
                                        userResolver: userResolver,
                                        from: from
                                    )
                                })
                                return
                            default:
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
                        observer.onError(error)
                        clearDisposeBag()
                    })
                    .flatMap({ (_) -> Observable<Void> in
                        return .just(())
                    })
            })
    }

    private static func showForwardThreadLimitAlert(
        resolver: Resolver,
        with message: String,
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        chatIDs: [String],
        title: String,
        extraText: String,
        observer: BehaviorSubject<[String]>,
        disposeBag: DisposeBag,
        clearDisposeBag: @escaping () -> Void,
        userResolver: UserResolver,
        from: UIViewController
    ) {
        guard let window = from.view.window,
              let forwardService = try? resolver.resolve(assert: ForwardService.self)
        else {
            assertionFailure()
            return
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForward, alignment: .center)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForwardErrorCancel, dismissCompletion: {
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForwardErrorContinue, dismissCompletion: { () in
            let hud = UDToast.showLoading(on: window)
            forwardService.mergeForward(
                originMergeForwardId: originMergeForwardId,
                threadID: messageIds.first ?? "",
                needCopyReaction: true,
                checkChatIDs: checkChatIDs,
                to: chatIDs,
                to: [],
                title: title,
                isLimit: true,
                extraText: extraText)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak window] (chatIds, filePermCheck) in
                    hud.remove()
                    if let window = window,
                       let filePermCheck = filePermCheck {
                        UDToast.showTips(with: filePermCheck.toast, on: window)
                    }
                    observer.onNext(chatIds)
                    observer.onCompleted()
                    clearDisposeBag()
                }, onError: { (error) in
                    if let error = error.underlyingError as? APIError {
                        switch error.type {
                        case .banned(let message), .forwardThreadTooLargeFail(let message):
                            hud.showFailure(with: message, on: window, error: error)
                        default:
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
                    observer.onError(error)
                    observer.onCompleted()
                    clearDisposeBag()
                }, onDisposed: {
                    observer.dispose()
                    hud.remove()
                }).disposed(by: disposeBag)
        })
        userResolver.navigator.present(alertController, from: from)
    }

    static func mergeForwardThread(
        resolver: Resolver,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIDs: [String],
        originMergeForwardId: String?,
        threadID: String,
        messageIds: [String],
        title: String,
        attributeInput: NSAttributedString?,
        observer: BehaviorSubject<[String]>,
        disposeBag: DisposeBag,
        clearDisposeBag: @escaping () -> Void,
        afterForwardBlock: (() -> Void)?,
        userResolver: UserResolver,
        from: UIViewController
    ) -> Observable<Void> {
        guard let window = from.view.window,
              let forwardService = try? resolver.resolve(assert: ForwardService.self)
        else {
            assertionFailure()
            return .empty()
        }
        let hud = UDToast.showLoading(on: window)
        return forwardService.checkAndCreateChats(chatIds: checkChatIDs, userIds: userIDs)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                forwardErrorHandler(userResolver: userResolver, hud: hud, on: from, error: error)
            })
            .flatMap({ (chatModels) -> Observable<Void> in
                var threadModeChatIds: [String] = []
                let sendChatIDs = chatModels
                .filter {
                    // chatModels.id里面会包括chat.id以及帖子对应的chat.id 需要做筛选
                    // 另外也需要考虑到chat.id以及帖子对应的chat.id可能会重合
                    let onlySendChatIDsFilter = !threadIDAndChatIDs.map { $1 }.contains($0.id) || chatIDs.contains($0.id)
                    if $0.displayInThreadMode {
                        threadModeChatIds.append($0.id)
                    }
                    return onlySendChatIDsFilter
                }
                .map { $0.id }
                return forwardService.mergeForward(
                    originMergeForwardId: originMergeForwardId,
                    threadID: threadID,
                    needCopyReaction: true,
                    checkChatIDs: checkChatIDs,
                    to: sendChatIDs,
                    to: threadIDAndChatIDs.filter { chatModels.map { $0.id }.contains($1) },
                    threadModeChatIds: threadModeChatIds,
                    title: title,
                    isLimit: false,
                    attributeExtraText: attributeInput ?? NSAttributedString(string: "")
                    )
                    .observeOn(MainScheduler.instance)
                    .do(onNext: { [weak window] (chatIds, filePermCheck) in
                        hud.remove()
                        if let window = window,
                           let filePermCheck = filePermCheck {
                            UDToast.showTips(with: filePermCheck.toast, on: window)
                        }
                        observer.onNext(chatIds)
                        observer.onCompleted()
                        clearDisposeBag()
                        afterForwardBlock?()
                    }, onError: { (error) in
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .banned(let message), .forwardThreadTooLargeFail(let message):
                                hud.showFailure(with: message, on: window, error: error)
                            case .forwardThreadReachLimit(let message):
                                hud.remove()
                                observer.onNext([""])
                                // 稍微延后，等上一个AlertController隐藏后再显示。
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                    showForwardThreadLimitAlert(
                                        resolver: resolver,
                                        with: message,
                                        originMergeForwardId: originMergeForwardId,
                                        messageIds: messageIds,
                                        checkChatIDs: checkChatIDs,
                                        chatIDs: sendChatIDs,
                                        title: title,
                                        attributeExtraText: attributeInput ?? NSAttributedString(string: ""),
                                        observer: observer,
                                        disposeBag: disposeBag,
                                        clearDisposeBag: clearDisposeBag,
                                        userResolver: userResolver,
                                        from: from
                                    )
                                })
                                return
                            default:
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
                        observer.onError(error)
                        clearDisposeBag()
                    })
                    .flatMap({ (_) -> Observable<Void> in
                        return .just(())
                    })
            })
    }

    private static func showForwardThreadLimitAlert(
        resolver: Resolver,
        with message: String,
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        chatIDs: [String],
        title: String,
        attributeExtraText: NSAttributedString,
        observer: BehaviorSubject<[String]>,
        disposeBag: DisposeBag,
        clearDisposeBag: @escaping () -> Void,
        userResolver: UserResolver,
        from: UIViewController
    ) {
        guard let window = from.view.window,
              let forwardService = try? resolver.resolve(assert: ForwardService.self)
        else {
            assertionFailure()
            return
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForward, alignment: .center)
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForwardErrorCancel, dismissCompletion: {
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkForward.Lark_Chat_TopicToolForwardErrorContinue, dismissCompletion: { () in
            let hud = UDToast.showLoading(on: window)
            forwardService.mergeForward(
                originMergeForwardId: originMergeForwardId,
                threadID: messageIds.first ?? "",
                needCopyReaction: true,
                checkChatIDs: checkChatIDs,
                to: chatIDs,
                to: [],
                title: title,
                isLimit: true,
                attributeExtraText: attributeExtraText)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak window] (chatIds, filePermCheck) in
                    hud.remove()
                    if let window = window,
                       let filePermCheck = filePermCheck {
                        UDToast.showTips(with: filePermCheck.toast, on: window)
                    }
                    observer.onNext(chatIds)
                    observer.onCompleted()
                    clearDisposeBag()
                }, onError: { (error) in
                    if let error = error.underlyingError as? APIError {
                        switch error.type {
                        case .banned(let message), .forwardThreadTooLargeFail(let message):
                            hud.showFailure(with: message, on: window, error: error)
                        default:
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
                    observer.onError(error)
                    observer.onCompleted()
                    clearDisposeBag()
                }, onDisposed: {
                    observer.dispose()
                    hud.remove()
                }).disposed(by: disposeBag)
        })
        userResolver.navigator.present(alertController, from: from)
    }
}
// swiftlint:enable function_parameter_count
