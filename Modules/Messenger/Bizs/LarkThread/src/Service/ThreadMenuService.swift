//
//  ThreadDeleteTopicService.swift
//  LarkThread
//
//  Created by shane on 2019/5/31.
//

import UIKit
import Foundation
import RxSwift
import LarkCore
import LarkModel
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkMessageBase
import LarkMessageCore
import LarkSDKInterface
import LarkFeatureGating
import LarkAlertController
import LarkAccountInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import RustPB
import LarkContainer
import LarkNavigation

/// - Parameter pointView: UIView
/// - Parameter targetVC: UIViewController
/// - Parameter menuAnimationBegin: (() -> Void)?
/// - Parameter menuAnimationEnd: (() -> Void)?
struct ThreadMenuUIConfig {
  let pointView: UIView
  let targetVC: UIViewController
  let menuAnimationBegin: (() -> Void)?
  let menuAnimationEnd: (() -> Void)?
}

protocol ThreadMenuService {
    /// delete memery data.
    var deleteMemeryTopic: ((String) -> Void)? { get set }

    /// show menu
    /// - Parameter threadMessage: ThreadMessage
    /// - Parameter chat: Chat
    /// - Parameter topNotice: 是否有置顶内容，除了话题页面, 其他都没有 传入nil
    /// - Parameter isEnterFromRecommendList: Bool
    /// - Parameter scene: ContextScene
    /// - Parameter uiConfig相关的配置
    func showMenu(threadMessage: ThreadMessage,
        chat: Chat,
        topNotice: BehaviorSubject<ChatTopNotice?>?,
        topicGroup: TopicGroup?,
        isEnterFromRecommendList: Bool,
        scene: ContextScene,
        uiConfig: ThreadMenuUIConfig
    )

    /// determine if there is a menu
    func hasMenu(
        threadMessage: ThreadMessage,
        chat: Chat,
        topNotice: BehaviorSubject<ChatTopNotice?>?,
        topicGroup: TopicGroup?,
        scene: ContextScene,
        isEnterFromRecommendList: Bool
    ) -> Bool

    /// Share topic
    func shareTopic(
        message: Message,
        targetVC: UIViewController
    )

    /// Forward topic
    func forwardTopic(
        originMergeForwardId: String?,
        message: Message,
        chat: Chat,
        targetVC: UIViewController
    )
}

final class ThreadMenuServiceImp: ThreadMenuService, UserResolverWrapper {
    let userResolver: UserResolver
    var deleteMemeryTopic: ((String) -> Void)?
    private let messageAPI: MessageAPI
    private let threadAPI: ThreadAPI
    private let pinAPI: PinAPI
    private let disposeBag = DisposeBag()
    private let adminService: ThreadAdminService
    private let todoDependency: MessageCoreTodoDependency
    private let modelService: ModelService
    private let tenantUniversalSettingService: TenantUniversalSettingService?
    /// 置顶服务
    private let topNoticeService: ChatTopNoticeService?
    private let navigationService: NavigationService?

    @ScopedInjectedLazy var userActionService: TopNoticeUserActionService?

    init(userResolver: UserResolver,
        messageAPI: MessageAPI,
        threadAPI: ThreadAPI,
        pinAPI: PinAPI,
        adminService: ThreadAdminService,
        todoDependency: MessageCoreTodoDependency,
        modelService: ModelService,
        tenantUniversalSettingService: TenantUniversalSettingService?,
        topNoticeService: ChatTopNoticeService?,
        navigationService: NavigationService?
        ) {
        self.userResolver = userResolver
        self.messageAPI = messageAPI
        self.threadAPI = threadAPI
        self.pinAPI = pinAPI
        self.adminService = adminService
        self.todoDependency = todoDependency
        self.modelService = modelService
        self.tenantUniversalSettingService = tenantUniversalSettingService
        self.topNoticeService = topNoticeService
        self.navigationService = navigationService
    }

    private func getItemTypes(
        with message: ThreadMessage,
        chat: Chat,
        topNotice: BehaviorSubject<ChatTopNotice?>?,
        topicGroup: TopicGroup?,
        scene: ContextScene,
        isEnterFromRecommendList: Bool = false
    ) -> [ThreadMenuType] {
        let isAdmin = adminService.getCurrentAdminInfo()?.isTopicGroupAdmin ?? false
        let isGroupAdmin = chat.isGroupAdmin
        // 话题拥有者
        var isTopicSender = userResolver.userID == message.rootMessage.fromId
        // 匿名的时候 原有的帖子判断逻辑不生效
        if !message.thread.anonymousID.isEmpty,
           message.thread.anonymousID == message.rootMessage.fromId {
            isTopicSender = true
        }
        // 群主
        let isTopicGroupOwner = userResolver.userID == chat.ownerId
        let isOwner = isTopicSender || isTopicGroupOwner || isAdmin
        let isMember = (topicGroup?.userSetting.topicGroupRole ?? .unknownRole) == .member

        // 消息发送状体是成功
        let messageSendSuccess = message.localStatus == .success

        var itemTypes = [ThreadMenuType]()
        // DLP状态不为.block && 推荐列表中不显示pin && isMember && 话题详情页中不是从推荐列表进入
        if message.rootMessage.dlpState != .dlpBlock && isMember && !isEnterFromRecommendList, !chat.isFrozen {
            // 消息发送成功 && chat支持pin && message 支持pin
            let cardSupportFg = self.userResolver.fg.staticFeatureGatingValue(with: "messagecard.pin.support")
            if messageSendSuccess && chat.isSupportPinMessage && message.rootMessage.isSupportPin(cardSupportFg: cardSupportFg)
                && ChatPinPermissionManager.hasPinPermissionInChat(chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg) {
                itemTypes.append(.pin(message.rootMessage.pinChatter != nil))
            }
        }

        /// 是否有置顶选项
        if scene == .threadChat,
           message.rootMessage.dlpState != .dlpBlock,
           !chat.isFrozen,
           let noticeService = self.topNoticeService,
           noticeService.isSupportTopNoticeChat(chat),
           let topNoticetype = topNoticeMenuTypeWith(message: message.rootMessage,
                                                     chat: chat,
                                                     currentTopNotice: topNotice) {
            itemTypes.append(topNoticetype)
        }

        if canTodo(message: message,
                   chat: chat,
                   scene: scene,
                   isMember: isMember,
                   messageSendSuccess: messageSendSuccess,
                   isEnterFromRecommendList: isEnterFromRecommendList) {
            // float actions
            itemTypes.append(.todo)
        }

        // messageSendSuccess && isOwner
        if messageSendSuccess && (isOwner || isGroupAdmin) {
            itemTypes.append(.markTopic(message.thread.stateInfo.state))
        }

        let isSpecialPerson = isAdmin || isGroupAdmin || isTopicGroupOwner //可以撤回他人帖子且不受时间配置管控的特殊角色
        // 不管消息是否发送成功 isOwner
        if (isTopicSender && tenantUniversalSettingService?.getIfMessageCanRecallBySelf() ?? false)
            || isSpecialPerson {
            itemTypes.append(.delete)
        }
        let isFromDetail = (scene == .threadDetail || scene == .replyInThread)
        let isEnterFromRecommendListForThreadDetail = (isFromDetail && isEnterFromRecommendList)
        if !isTopicSender && isEnterFromRecommendListForThreadDetail {
            var dislikeTypes: [ThreadMenuType] = [
                .dislikeThisTopic,
                .dislikeTopicFromAuthor(name: message.rootMessage.fromChatter?.displayName ?? "")
            ]
            // if topic from default topic group. hide dislike form topic menu item
            if !(topicGroup?.isDefaultTopicGroup ?? false) {
                dislikeTypes.append(.dislikeTopicFromTopicGroup(name: message.chat?.displayName ?? ""))
            }
            itemTypes.append(contentsOf: dislikeTypes)
        }
        return itemTypes
    }

    func hasMenu(
        threadMessage: ThreadMessage,
        chat: Chat,
        topNotice: BehaviorSubject<ChatTopNotice?>?,
        topicGroup: TopicGroup?,
        scene: ContextScene,
        isEnterFromRecommendList: Bool = false
    ) -> Bool {
        if threadMessage.isDecryptoFail { return false }
        let itemTypes = getItemTypes(
            with: threadMessage,
            chat: chat,
            topNotice: topNotice,
            topicGroup: topicGroup,
            scene: scene,
            isEnterFromRecommendList: isEnterFromRecommendList
        )
        return !itemTypes.isEmpty && (!chat.isTeamVisitorMode)
    }

    func showMenu(threadMessage: ThreadMessage,
                  chat: Chat,
                  topNotice: BehaviorSubject<ChatTopNotice?>?,
                  topicGroup: TopicGroup?,
                  isEnterFromRecommendList: Bool,
                  scene: ContextScene,
                  uiConfig: ThreadMenuUIConfig) {
        let pointView = uiConfig.pointView
        let targetVC = uiConfig.targetVC
        let itemTypes = getItemTypes(
            with: threadMessage,
            chat: chat,
            topNotice: topNotice,
            topicGroup: topicGroup,
            scene: scene,
            isEnterFromRecommendList: isEnterFromRecommendList
        )
        if itemTypes.isEmpty {
            return
        }

        let vc = ThreadFloatMenuController(
            pointView: pointView,
            itemTypes: itemTypes,
            actionFunc: { [weak targetVC, weak self] (type) in
                guard let `showVC` = targetVC, let self = self else { return }
                switch type {
                case .delete:
                    self.showDeleteAlertView(
                        with: threadMessage.rootMessage,
                        chat: chat,
                        scene: scene,
                        targetVC: showVC
                    )
                case .pin:
                    let isPin = threadMessage.rootMessage.pinChatter != nil ? false : true
                    if isPin {
                        IMTracker.Msg.Menu.More.Click.Pin(chat, threadMessage.rootMessage)
                        let isGroupOwner = self.userResolver.userID == chat.ownerId
                        self.pinAPI.createPin(messageId: threadMessage.rootMessage.id)
                            .subscribe(onNext: { (_) in
                                LarkMessageCoreTracker.trackAddPin(message: threadMessage.rootMessage,
                                                                   chat: chat,
                                                                   isGroupOwner: isGroupOwner,
                                                                   isSuccess: true)
                            }, onError: { (_) in
                                LarkMessageCoreTracker.trackAddPin(message: threadMessage.rootMessage,
                                                                   chat: chat,
                                                                   isGroupOwner: isGroupOwner,
                                                                   isSuccess: false)
                            })
                            .disposed(by: self.disposeBag)
                    } else {
                        let body = DeletePinAlertBody(
                            chat: chat,
                            message: threadMessage.rootMessage,
                            targetVC: showVC,
                            from: .inChat
                        )
                        self.navigator.push(body: body, from: showVC)
                    }
                case .shareTopic:
                    self.shareTopic(message: threadMessage.rootMessage, targetVC: showVC)
                case .markTopic(let state):
                    var newState: RustPB.Basic_V1_ThreadState = .unknownState
                    if state == .closed {
                        newState = .open
                        self.shwoUnMarkToast(
                            threadState: newState,
                            threadID: threadMessage.id,
                            targetVC: showVC
                        )
                        ThreadTracker.trackTopicReopenClick(
                            chatID: chat.id,
                            topicID: threadMessage.rootMessage.id,
                            uid: self.userResolver.userID
                        )
                    } else {
                        newState = .closed
                        self.showMarkAlertView(
                            threadState: newState,
                            chat: chat,
                            message: threadMessage.rootMessage,
                            threadID: threadMessage.id,
                            targetVC: showVC
                        )
                        ThreadTracker.trackTopicCloseClick(
                            chatID: chat.id,
                            topicID: threadMessage.rootMessage.id,
                            uid: self.userResolver.userID
                        )
                    }
                case .forward:
                    let originMergeForwardId = scene == .threadPostForwardDetail ? threadMessage.rootMessage.id : nil
                    self.forwardTopic(originMergeForwardId: originMergeForwardId, message: threadMessage.rootMessage, chat: chat, targetVC: showVC)
                case .dislikeThisTopic:
                    self.dislikeThisTopic(threadID: threadMessage.thread.id, messageId: threadMessage.thread.id)
                case .dislikeTopicFromAuthor:
                    self.dislikeTopicFromAuthor(userID: threadMessage.rootMessage.fromId, messageId: threadMessage.thread.id)
                case .dislikeTopicFromTopicGroup:
                    self.dislikeTopicFromTopicGroup(groupID: threadMessage.chatID, messageId: threadMessage.thread.id)
                case .todo:
                    IMTracker.Msg.Menu.More.Click.Todo(chat, threadMessage.rootMessage)
                    self.todo(message: threadMessage, chat: chat, topicGroup: topicGroup, targetVC: showVC)
                case .topThread(let isTop):
                    let value = try? topNotice?.value()
                    guard let userActionService = self.userActionService else { return }
                    if isTop {
                        TopMessageMenuAction.topMessage(chat: chat,
                                                       message: threadMessage.rootMessage,
                                                       userActionService: userActionService,
                                                       hasNotice: value != nil,
                                                       targetVC: showVC,
                                                       disposeBag: self.disposeBag,
                                                       chatFromWhere: nil)
                    } else {
                        TopMessageMenuAction.cancelTopMessage(chat: chat,
                                                              message: threadMessage.rootMessage,
                                                              userActionService: userActionService,
                                                              topNotice: value,
                                                              currentUserID: self.userResolver.userID,
                                                              nav: self.navigator,
                                                              targetVC: showVC,
                                                              disposeBag: self.disposeBag,
                                                              featureGatingService: self.userResolver.fg,
                                                              chatFromWhere: nil)
                    }
                    break
                case .subscribe, .unsubscribe, .muteMsgNotice, .msgNotice:
                    break
                }
            })

        vc.animationBegin = uiConfig.menuAnimationBegin
        vc.animationEnd = uiConfig.menuAnimationEnd
        vc.modalPresentationStyle = .overFullScreen
        targetVC.present(vc, animated: false)
        IMTracker.Msg.Menu.More.View(chat, threadMessage.rootMessage)
    }

    func forwardTopic(originMergeForwardId: String?, message: Message, chat: Chat, targetVC: UIViewController) {
        let body = MergeForwardMessageBody(
            originMergeForwardId: originMergeForwardId,
            fromChannelId: chat.id,
            messageIds: [message.id],
            threadRootMessage: message,
            title: BundleI18n.LarkThread.Lark_Legacy_ForwardGroupChatHistory,
            forwardThread: true,
            traceChatType: .thread,
            finishCallback: nil,
            supportToMsgThread: true
        )
        navigator.present(
            body: body,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    func shareTopic(message: Message, targetVC: UIViewController) {
        navigator.present(
            body: ShareThreadTopicBody(message: message, title: BundleI18n.LarkThread.Lark_Legacy_ForwardGroupChatHistory),
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    private func topNoticeMenuTypeWith(message: Message,
                                       chat: Chat,
                                       currentTopNotice: BehaviorSubject<ChatTopNotice?>?) -> ThreadMenuType? {
        guard let topNotice = currentTopNotice, let noticeService = self.topNoticeService else {
            return nil
        }
        let topNoticeInfo = try? topNotice.value()
        let menu = noticeService.topNoticeActionMenu(message,
                                                    chat: chat,
                                                     currentTopNotice: topNoticeInfo,
                                                     currentUserId: userResolver.userID)
        var threadMenuType: ThreadMenuType?
        if menu == .topMessage {
            threadMenuType = .topThread(true)
        } else if menu == .cancelTopMessage {
            threadMenuType = .topThread(false)
        }
        return threadMenuType
    }

    private func dislikeThisTopic(threadID: String, messageId: String) {
        // first response UI. 优先响应UI，点击后立即删除。
        self.deleteMemeryTopic?(messageId)
        threadAPI.dislikeTopic(threadID: threadID).subscribe().disposed(by: self.disposeBag)
    }

    private func dislikeTopicFromAuthor(userID: String, messageId: String) {
        // first response UI. 优先响应UI，点击后立即删除。
        self.deleteMemeryTopic?(messageId)
        threadAPI.dislikeUser(userID: userID).subscribe().disposed(by: self.disposeBag)
    }

    private func dislikeTopicFromTopicGroup(groupID: String, messageId: String) {
        // first response UI. 优先响应UI，点击后立即删除。
        self.deleteMemeryTopic?(messageId)
        threadAPI.dislikeTopicGroup(topicGroupID: groupID).subscribe().disposed(by: self.disposeBag)
    }

    private func canTodo(
        message: ThreadMessage,
        chat: Chat,
        scene: ContextScene,
        isMember: Bool,
        messageSendSuccess: Bool,
        isEnterFromRecommendList: Bool
    ) -> Bool {
        guard let navService = self.navigationService, navService.checkInTabs(for: .todo), !chat.isCrossWithKa else { return false }
        // float actions
        // 推荐列表中不显示todo && isMember && 话题详情页中不是从推荐列表进入
        if isMember && !isEnterFromRecommendList {
            // 消息发送成功 && chat支持pin && message 支持todo
            if messageSendSuccess && !chat.isOncall && !chat.isSuper {
                return true
            }
        }
        return false
    }

    private func todo(message: ThreadMessage, chat: Chat, topicGroup: TopicGroup?, targetVC: UIViewController) {
        self.doAction(message: message, chat: chat, from: targetVC)
    }

    private func doAction(message: ThreadMessage,
                          chat: Chat,
                          from: UIViewController) {
        let extra = ["source": "topic", "sub_source": "topic_point"]
        todoDependency.createTodo(
            from: from,
            chat: chat,
            threadID: message.rootMessage.id,
            threadMessage: message,
            title: modelService.messageSummerize(message.rootMessage),
            extra: extra
        )
    }

    // MARK: - private
    private func updateThreadState(
        _ threadState: RustPB.Basic_V1_ThreadState,
        threadID: String,
        targetVC: UIViewController,
        conpletion: ((Bool) -> Void)? = nil
        ) {
        let hud = UDToast.showLoading(
            with: BundleI18n.LarkThread.Lark_Legacy_BaseUiLoading,
            on: targetVC.view,
            disableUserInteraction: true
        )
        threadAPI.update(threadId: threadID, isFollow: nil, threadState: threadState)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                hud.remove()
                conpletion?(true)
            }, onError: { (error) in
                hud.remove()
                var errorMessage = BundleI18n.LarkThread.Lark_Legacy_NetworkOrServiceError
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .unknownBusinessError(let message):
                        errorMessage = message
                    default:
                        break
                    }
                }
                UDToast.showFailure(with: errorMessage, on: targetVC.view, error: error)
                conpletion?(false)
            }).disposed(by: disposeBag)
    }

    private func shwoUnMarkToast(
        threadState: RustPB.Basic_V1_ThreadState,
        threadID: String,
        targetVC: UIViewController
        ) {
        self.updateThreadState(
        threadState,
        threadID: threadID,
        targetVC: targetVC
        ) { (success) in
            if success {
                UDToast.showTips(
                    with: BundleI18n.LarkThread.Lark_Chat_TopicToolCloseToastTip,
                    on: targetVC.view
                )
            }
        }
    }

    private func showMarkAlertView(
        threadState: RustPB.Basic_V1_ThreadState,
        chat: Chat,
        message: Message,
        threadID: String,
        targetVC: UIViewController
        ) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkThread.Lark_Groups_TopicToolClose)
        alertController.setContent(text: BundleI18n.LarkThread.Lark_Chat_TopicToolCloseAlterTip)
        alertController.addSecondaryButton(text: BundleI18n.LarkThread.Lark_Chat_TopicToolDeleteTipCancel, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            ThreadTracker.trackTopicCloseCancelClick(
                chatID: chat.id,
                topicID: message.id,
                uid: self.userResolver.userID
            )
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkThread.Lark_Legacy_CloseConfirm, dismissCompletion: { [weak targetVC] in
            guard let targetVC = targetVC else {
                return
            }
            IMTracker.Msg.Menu.More.Click.Close(chat, message)
            ThreadTracker.trackTopicCloseConfirmClick(
                chatID: chat.id,
                topicID: message.id,
                uid: self.userResolver.userID
            )

            self.updateThreadState(
                threadState,
                threadID: threadID,
                targetVC: targetVC,
                conpletion: nil
            )
        })
        navigator.present(alertController, from: targetVC)
    }

    private func showDeleteAlertView(with message: Message, chat: Chat, scene: ContextScene, targetVC: UIViewController) {
        switch scene {
        case .threadChat:
             ThreadTracker.topicDelete(location: .group)
        case .threadDetail, .replyInThread:
            ThreadTracker.topicDelete(location: .topic)
        default:
            break
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkThread.Lark_Chat_RecallTopicConfirmationTitle)
        alertController.setContent(text: BundleI18n.LarkThread.Lark_Chat_RecallTopicConfirmationDesc)
        alertController.addSecondaryButton(text: BundleI18n.LarkThread.Lark_Chat_TopicToolDeleteTipCancel, dismissCompletion: {
            ThreadTracker.topicDeleteMenuCancel()
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkThread.Lark_Chat_RecallTopicConfirmationButton, dismissCompletion: { [weak targetVC] in
            ThreadTracker.topicDeleteMenuConfirm()
            IMTracker.Msg.Menu.More.Click.Withdraw(chat, message)
            guard let targetVC = targetVC else {
                return
            }

            if self.userResolver.userID == chat.ownerId {
                switch scene {
                case .threadChat:
                    ThreadTracker.trackMessageAdminDelete(chatID: chat.id, locationType: .threadChat)
                case .threadDetail, .replyInThread:
                    ThreadTracker.trackMessageAdminDelete(chatID: chat.id, locationType: .threadDetail)
                default:
                    break
                }
            }

            let hud = UDToast.showLoading(
                with: BundleI18n.LarkThread.Lark_Legacy_BaseUiLoading,
                on: targetVC.view,
                disableUserInteraction: true)
            // 删除假消息
            if message.localStatus != .success {
                self.messageAPI.delete(quasiMessageId: message.cid)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        hud.remove()
                        guard let `self` = self else { return }
                        self.deleteMemeryTopic?(message.id)
                    }, onError: { _ in
                        hud.remove()
                    }).disposed(by: self.disposeBag)
            }// 话题无痕删除
            else {
                self.messageAPI.deleteByNoTrace(with: message.id)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        hud.remove()
                        // also will pushThread() when delete success
                        // 删除成功后还会pushThread
                        self.deleteMemeryTopic?(message.id)
                    }, onError: { [weak self] error in
                        hud.remove()
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .notDeleteThreadWhenOverTime(let message):
                                hud.showFailure(with: message, on: targetVC.view, error: error)
                                self?.tenantUniversalSettingService?.loadTenantMessageConf(forceServer: true, onCompleted: nil)
                            default:
                                hud.showFailure(
                                    with: BundleI18n.LarkThread.Lark_Legacy_ChatViewFailHideMessage,
                                    on: targetVC.view,
                                    error: error
                                )
                            }
                        } else {
                            hud.showFailure(
                                with: BundleI18n.LarkThread.Lark_Legacy_ChatViewFailHideMessage,
                                on: targetVC.view,
                                error: error
                            )
                        }
                    }).disposed(by: self.disposeBag)
            }
        })
        navigator.present(alertController, from: targetVC)
    }
}
