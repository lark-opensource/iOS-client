//
//  ThreadMessageCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import UIKit
import Foundation
import Homeric
import RxSwift
import LarkTab
import RustPB
import LarkCore
import LarkUIKit
import RichLabel
import LarkModel
import EENavigator
import EEFlexiable
import LarkEmotion
import LarkNavigator
import TangramService
import AsyncComponent
import LarkExtensions
import LarkContainer
import LarkMessageCore
import LarkMessageBase
import LKCommonsTracker
import LarkSDKInterface
import LKCommonsLogging
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import LarkSendMessage
import UniverseDesignToast
import ThreadSafeDataStructure
import UniverseDesignDialog
import LarkSearchCore
import LarkStorage
import LarkOpenChat
import EEAtomic

protocol HasThreadMessage {
    func getThreadMessage() -> ThreadMessage
    func getThread() -> RustPB.Basic_V1_Thread
    func getRootMessage() -> Message
}

final class ThreadMessageCell: MessageCommonCell {
    private let duration: TimeInterval = 0.25
    //使用自定义的点击高亮是因为系统的无法满足需求，要求点击cell进入detail时高亮渐显，回到threadChat时高亮渐隐。且不会和长按手势冲突
    private lazy var didSelectedHightView: UIView = {
        return self.getView(by: ThreadMessageCellComponent.hightViewKey) ?? UIView()
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func showHighlightView(animation: Bool = true) {
        didSelectedHightView.isHidden = false
        didSelectedHightView.alpha = 0

        if animation {
            UIView.animate(withDuration: duration, animations: {
                self.didSelectedHightView.alpha = 1
            }, completion: { (_) in
                self.didSelectedHightView.alpha = 1
            })
        } else {
            self.didSelectedHightView.alpha = 1
        }
    }

    func hideHighlightView(completion: ((Bool) -> Void)? = nil, animation: Bool) {
        didSelectedHightView.isHidden = false
        didSelectedHightView.alpha = 1

        if animation {
            UIView.animate(withDuration: duration, animations: {
                self.didSelectedHightView.alpha = 0
            }, completion: { finish in
                self.didSelectedHightView.alpha = 0
                self.didSelectedHightView.isHidden = true
                completion?(finish)
            })
        } else {
            self.didSelectedHightView.alpha = 0
            self.didSelectedHightView.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ThreadMessageCellViewModelLogger {
    static let logger = Logger.log(ThreadMessageCellViewModelLogger.self, category: "LarkThread")
}

final class ThreadMessageCellViewModel: LarkMessageBase.ThreadMessageCellViewModel<ThreadMessageMetaModel, ThreadCellMetaModelDependency>, MessageMenuHideProtocol {
    final override var identifier: String {
        return [content.identifier, "message"].joined(separator: "-")
    }
    var tenantUniversalSettingService: TenantUniversalSettingService? {
        try? context.resolver.resolve(assert: TenantUniversalSettingService.self)
    }
    var chatSecurityControlService: ChatSecurityControlService? {
        try? context.resolver.resolve(assert: ChatSecurityControlService.self)
    }
    fileprivate let isFromMe: Bool

    //二次编辑请求状态
    lazy var editRequestStatus: Message.EditMessageInfo.EditRequestStatus? = self.threadMessage.rootMessage.editMessageInfo?.requestStatus
    lazy var multiEditRetryCallBack: (() -> Void) = { [weak self] in
        guard let self = self else { return }
        let message = self.threadMessage.rootMessage
        let chat = self.metaModel.getChat()
        guard let messageId = Int64(message.id),
              let editInfo = message.editMessageInfo else { return }
        if !chat.isAllowPost {
            guard let window = self.context.targetVC?.view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkThread.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat.name), on: window)
            return
        }
        if message.isRecalled || message.isDeleted || message.isNoTraceDeleted {
            guard let vc = self.context.targetVC else { return }
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkThread.Lark_IM_EditMessage_UnableToSaveChanges_Text)
            let content = message.isRecalled ? BundleI18n.LarkThread.Lark_IM_EditMessage_MessageRecalledUnableToSave_Title : BundleI18n.LarkThread.Lark_IM_EditMessage_MessageDeletedUnableToSave_Title
            dialog.setContent(text: content)
            dialog.addPrimaryButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_UnableToSave_GotIt_Button)
            self.context.navigator.present(dialog, from: vc)
            return
        }
        try? self.context.resolver.resolve(assert: MultiEditService.self).multiEditMessage(messageId: messageId,
                                                                                       chatId: chat.id,
                                                                                       type: editInfo.messageType,
                                                                                       richText: editInfo.content.richText,
                                                                                       title: editInfo.content.title,
                                                                                       lingoInfo: editInfo.content.lingoOption)
        .observeOn(MainScheduler.instance)
                                            .subscribe { _ in
                                            } onError: { [weak self] error in
                                                if let window = self?.context.targetVC?.view.window {
                                                    UDToast.showFailureIfNeeded(on: window, error: error)
                                                }
                                                ThreadMessageCellViewModelLogger.logger.info("multiEditMessage fail, error: \(error)",
                                                                  additionalData: ["chatId": chat.id,
                                                                                  "messageId": message.id])
                                            }.disposed(by: self.disposeBag)
    }

    public override func dequeueReusableCell(_ tableView: UITableView, cellId: String) -> ThreadMessageCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ThreadMessageCell ?? ThreadMessageCell(style: .default, reuseIdentifier: identifier)
        cell.contentView.tag = 0
        cell.update(with: renderer, cellId: cellId)
        cell.tkDescription = { [weak self] in
            self?.buildDescription() ?? [:]
        }
        if selectedHighlight {
            cell.showHighlightView(animation: false)
        } else {
            cell.hideHighlightView(completion: nil, animation: false)
        }
        return cell
    }

    /// translate Tracking
    var chatTypeForTracking: String {
        if metaModel.getChat().chatMode == .threadV2 {
            return "topic"
        } else if metaModel.getChat().type == .group {
            return "group"
        } else {
            return "single"
        }
    }

    /// 翻译服务
    private lazy var translateService: NormalTranslateService? = {
        return try? self.context.resolver.resolve(assert: NormalTranslateService.self)
    }()

    /// 帖子发送服务
    private lazy var postSendService: PostSendService? = {
        return try? self.context.resolver.resolve(assert: PostSendService.self)
    }()

    // UI属性
    var time: String {
        var formatTime = formatCreateTime
        if threadMessage.rootMessage.isMultiEdited {
            formatTime += BundleI18n.LarkThread.Lark_IM_EditMessage_EditedAtTime_Hover_Mobile(formatEditedTime)
        }
        return formatTime
    }

    private var formatCreateTime: String {
        return threadMessage.createTime.lf.cacheFormat("n_message", formater: { $0.lf.formatedTime_v2() })
    }

    private var formatEditedTime: String {
        return (threadMessage.rootMessage.editTimeMs / 1000).lf.cacheFormat("n_editMessage", formater: { $0.lf.formatedTime_v2() })
    }

    var isGroupAnnouncementType: Bool {
        return (self.threadMessage.content as? PostContent)?.isGroupAnnouncement ?? false
    }

    var hasBorder: Bool {
        if self.threadMessage.type == .file || self.threadMessage.type == .folder {
            return true
        }
        return false
    }

    var selectedHighlight = false

    var threadMessage: ThreadMessage {
        return metaModel.threadMessage
    }
    @SafeLazy private var thumbsupService: ThumbsupReactionService?

    fileprivate let userId: String
    private let modelService: ModelService?
    private var threadMenuService: ThreadMenuService?
    fileprivate var replyInfos = [(nameCount: Int, replyAttributedString: NSAttributedString, height: CGFloat)]()
    fileprivate var hasMenu: Bool {
        return threadMenuService?.hasMenu(
            threadMessage: threadMessage,
            chat: metaModel.getChat(),
            topNotice: self.context.dataSourceAPI?.currentTopNotice(),
            topicGroup: metaModel.getTopicGroup(),
            scene: self.context.scene,
            isEnterFromRecommendList: false
        ) ?? false
    }

    private var isDisplay: Bool = false
    private var inlineRenderTrack: SafeAtomic<InlinePreviewRenderTrack> = .init(.init(), with: .readWriteLock)

    init(metaModel: ThreadMessageMetaModel,
         metaModelDependency: ThreadCellMetaModelDependency,
         context: ThreadContext,
         contentFactory: ThreadMessageSubFactory,
         getContentFactory: @escaping (ThreadMessageMetaModel, ThreadCellMetaModelDependency) -> MessageSubFactory<ThreadContext>,
         subFactories: [SubType: ThreadMessageSubFactory],
         cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?
    ) {
        self._thumbsupService = SafeLazy {
            try? context.resolver.resolve(assert: ThumbsupReactionService.self)
        }
        self.threadMenuService = try? context.resolver.resolve(assert: ThreadMenuService.self)
        self.modelService = try? context.resolver.resolve(assert: ModelService.self)
        self.userId = context.userID
        self.isFromMe = context.isMe(metaModel.message.fromChatter?.id ?? "", chat: metaModel.getChat())
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { _ in return ThreadMessageCellComponentBinder(context: context) },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
        self.replyInfos = self.createReplyInfos(messages: threadMessage.replyMessages, chatID: threadMessage.channel.id)
        super.calculateRenderer()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
    }

    override func update(metaModel: ThreadMessageMetaModel, metaModelDependency: ThreadCellMetaModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if metaModel.threadMessage.isNoTraceDeleted {
            if let content = self.content as? ThreadTextPostContentViewModel {
                content.isNoTraceDeleted = true
            }
            return
        }
        let rootMessage = metaModel.threadMessage.rootMessage
        // TODO: 后续把判断逻辑抽离
        if rootMessage.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel(
                    metaModel: metaModel,
                    metaModelDependency: ThreadCellMetaModelDependency(
                        contentPadding: self.metaModelDependency.contentPadding,
                        contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                    ),
                    context: context
                ),
                actionHandler: RecalledMessageActionHandler(context: context)
            ))
        } else {
            self.updateContent(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
        // 更新
        self.replyInfos = self.createReplyInfos(messages: threadMessage.replyMessages, chatID: threadMessage.channel.id)

        self.editRequestStatus = metaModel.message.editMessageInfo?.requestStatus
        self.calculateRenderer()
    }

    func update(thread: RustPB.Basic_V1_Thread) {
        var metaModel = self.metaModel
        metaModel.threadMessage.thread = thread
        self.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    func update(threadMessage: ThreadMessage) {
        var metaModel = self.metaModel
        metaModel.threadMessage = threadMessage
        self.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    func update(rootMessage: Message) {
        var metaModel = self.metaModel
        metaModel.threadMessage.rootMessage = rootMessage
        self.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    override func didSelect() {
        if self.hideSheetMenuIfNeedForMenuService(self.context.pageContainer.resolve(MessageMenuOpenService.self)) {
            return
        }
        super.didSelect()
        if self.threadMessage.rootMessage.localStatus != .success {
            return
        }

        ThreadTracker.topicEnter(location: .card)
        trackUserInteraction(by: .click)
        self.showThreadDetail(
           chat: self.metaModel.getChat(),
           threadMessage: self.threadMessage,
           loadType: .root
       )
    }

    func showMessageMenu(message: Message,
                                source: MessageMenuLayoutSource,
                         copyType: CopyMessageType,
                         selectConstraintKey: String?) {
        self.context.pageContainer.resolve(MessageMenuOpenService.self)?.showMenu(message: message,
                                                                                  source: source,
                                                                                  extraInfo: .init(copyType: copyType, selectConstraintKey: selectConstraintKey, messageOffset: 0))
    }

    func showMenu(_ sender: UIView,
                  location: CGPoint,
                  displayView: ((Bool) -> UIView?)?,
                  triggerGesture: UIGestureRecognizer?,
                  copyType: CopyMessageType,
                  selectConstraintKey: String?) {
        guard let chatSecurityControlService = self.chatSecurityControlService,
            chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                    message: threadMessage.message,
                                                                    anonymousId: metaModel.getChat().anonymousId).authorityAllowed
        else { return }
        let source = MessageMenuLayoutSource(trigerView: sender,
                                             trigerLocation: location,
                                             displayViewBlcok: displayView,
                                             inserts: UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0))
        self.showMessageMenu(message: self.threadMessage.rootMessage,
                             source: source,
                             copyType: copyType,
                             selectConstraintKey: selectConstraintKey)
    }

    func pushThreadDetailToRoot() {

        if self.threadMessage.rootMessage.localStatus != .success {
            return
        }

        self.trackUserInteraction(by: .reply)

        var keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .inputView)

        if self.threadMessage.thread.stateInfo.state == .closed {
            keyboardStartupState = KeyboardStartupState(type: .none)
        }

        self.showThreadDetail(
            chat: self.metaModel.getChat(),
            threadMessage: self.threadMessage,
            loadType: .root,
            keyboardStartupState: keyboardStartupState
        )
        IMTracker.Chat.Main.Click.TopicReply(self.metaModel.getChat(), self.threadMessage.thread.id)
    }

    func pushThreadDetailToReply() {
        if self.threadMessage.rootMessage.localStatus != .success {
            return
        }

        self.showThreadDetail(
           chat: self.metaModel.getChat(),
           threadMessage: self.threadMessage,
           loadType: .justReply
       )
    }

    func showMenuView(pointView: UIView) {
        if threadMessage.isNoTraceDeleted {
            showMessageRecalledToast()
            return
        }
        if let pageVC = self.context.pageAPI {
            let uiConfig = ThreadMenuUIConfig(pointView: pointView,
                                              targetVC: pageVC) { [weak self] in
                self?.context.dataSourceAPI?.pauseDataQueue(true)
            } menuAnimationEnd: { [weak self] in
                self?.context.dataSourceAPI?.pauseDataQueue(false)
            }

            self.threadMenuService?.showMenu(
                threadMessage: self.threadMessage,
                chat: self.metaModel.getChat(),
                topNotice: self.context.dataSourceAPI?.currentTopNotice(),
                topicGroup: self.metaModel.getTopicGroup(),
                isEnterFromRecommendList: false,
                scene: self.context.scene,
                uiConfig: uiConfig)

            self.threadMenuService?.deleteMemeryTopic = { [weak self] (messageID) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.context.deleteRow(by: messageID)
            }
        }
    }

    func shouldShowForwardButton() -> Bool {
        return threadMessage.localStatus == .success
    }

    func shouldShowForwardDescription() -> Bool {
        return context.getStaticFeatureGating(.advancedForward)
    }

    /// 获取重新排序后的reactireactions按照message中topReactions
    private func getTopReactions() -> [String]? {
        let message = self.threadMessage.rootMessage
        guard let reactionService = try? context.resolver.resolve(assert: ReactionService.self) else { return nil }
        // 处理用户的表情：最常使用fg打开返回最常使用，反之返回最近使用
        var userReactions = reactionService.getRecentReactions().map { $0.key }
        // 小组 话题卡片上点击已有的reactions，根据message中的reactions数量进行排序。
        if userReactions.count >= 3 {
            var insertTopReactions = [String]()
            for index in 0..<min(message.reactions.count, 3) {
                let reaction = message.reactions[index]
                // recentReactions已有则去重
                if let i = userReactions.firstIndex(where: { (type) -> Bool in
                    return type == reaction.type
                }) {
                    userReactions.remove(at: i)
                    insertTopReactions.append(reaction.type)
                } // 没有，则移除recentReactions最后一个
                else {
                    userReactions.removeLast()
                    insertTopReactions.append(reaction.type)
                }
            }
            if !insertTopReactions.isEmpty {
                userReactions.insert(contentsOf: insertTopReactions, at: 0)
            }
        }

        return userReactions
    }

    func toggleFollowThread() {
        if threadMessage.isNoTraceDeleted {
            showMessageRecalledToast()
            return
        }
        try? self.context.resolver.resolve(assert: ThreadAPI.self)
            .update(threadId: self.threadMessage.id, isFollow: !self.threadMessage.thread.isFollow, threadState: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                if let apiError = error.underlyingError as? APIError, let targetVC = self?.context.pageAPI {
                    UDToast.showFailure(with: apiError.displayMessage, on: targetVC.view, error: error)
                }
            })
            .disposed(by: disposeBag)

        self.trackUserInteraction(by: .follow)
        ThreadTracker.trackFollowTopicClick(
            isFollow: !self.threadMessage.thread.isFollow,
            locationType: .threadChat,
            chatId: metaModel.getChat().id,
            messageId: self.threadMessage.id
        )
        IMTracker.Chat.Main.Click.TopicSubscribe(self.metaModel.getChat(), self.threadMessage.thread.id)
    }

    func resend() {
        let rootMessage = self.metaModel.threadMessage.rootMessage
        switch rootMessage.type {
        case .media:
            guard let vc = self.context.pageAPI else {
                assertionFailure("can not find vc")
                return
            }
            try? context.resolver.resolve(assert: VideoMessageSendService.self).resendVideoMessage(rootMessage, from: vc)
        case .post:
            let sendThreadType: SendThreadToType = .threadChat
            self.postSendService?.resend(thread: self.threadMessage, to: sendThreadType)
        @unknown default:
            try? context.resolver.resolve(assert: SendMessageAPI.self).resendMessage(message: rootMessage)
        }
    }

    func alreadyThumbsUP() -> Bool {
        let userId = self.userId
        let thumbsup = self.thumbsupService?.thumbsupKey
        return threadMessage.rootMessage.reactions.contains(where: { (reaction) -> Bool in
            return reaction.type == thumbsup && reaction.chatterIds.contains(userId)
        })
    }

    func thumbsUp() {
        /// 被删除的帖子 不支持操作
        if threadMessage.isNoTraceDeleted {
            self.showMessageRecalledToast()
            return
        }
        guard let reactionAPI = try? self.context.resolver.resolve(assert: ReactionAPI.self) else {
            return
        }
        let ob: Observable<Void>
        let thumbsup = self.thumbsupService?.thumbsupKey ?? ""
        if alreadyThumbsUP() {
            ob = reactionAPI.deleteISendReaction(messageId: self.threadMessage.id, reactionType: thumbsup)
        } else {
            ob = reactionAPI.sendReaction(messageId: self.threadMessage.id, reactionType: thumbsup)
            reactionAPI.updateRecentlyUsedReaction(reactionType: thumbsup).subscribe().disposed(by: disposeBag)
        }
        trackUserInteraction(by: .reaction)
        if threadMessage.message.type == .hongbao ||
            threadMessage.message.type == .commercializedHongbao {
            Tracker.post(TeaEvent(Homeric.MOBILE_HONGBAO_REACTION))
        }
        ob.subscribe().disposed(by: disposeBag)
        IMTracker.Chat.Main.Click.ReactionClick(self.metaModel.getChat(), self.threadMessage.thread.id, nil)
    }

    func forward() {
        if threadMessage.isNoTraceDeleted {
            showMessageRecalledToast()
            return
        }
        self.trackUserInteraction(by: .transmit)
        guard let targetVC = context.pageAPI else { return }
        threadMenuService?.forwardTopic(originMergeForwardId: nil, message: threadMessage.rootMessage, chat: metaModel.getChat(), targetVC: targetVC)
        IMTracker.Chat.Main.Click.TopicForward(self.metaModel.getChat(), self.threadMessage.thread.id)
    }

    func share() {
        if threadMessage.isNoTraceDeleted {
            showMessageRecalledToast()
            return
        }
        guard let targetVC = context.pageAPI else { return }
        threadMenuService?.shareTopic(message: threadMessage.rootMessage, targetVC: targetVC)
        IMTracker.Chat.Main.Click.TopicForward(self.metaModel.getChat(), self.threadMessage.thread.id)
    }

    fileprivate func pushThreadDetailVC(clickedIndex: Int) {
        ThreadTracker.topicEnter(location: .area)
        ThreadTracker.trackClickReplyArea()
        if self.threadMessage.rootMessage.localStatus != .success {
            return
        }

        if let menuOpenService = self.context.pageContainer.resolve(MessageMenuOpenService.self), menuOpenService.hasDisplayMenu,
            menuOpenService.isSheetMenu {
            return
        }

        guard clickedIndex < self.threadMessage.replyMessages.count else {
            self.pushThreadDetailToReply()
            return
        }

        let message = self.threadMessage.replyMessages[clickedIndex]

        self.showThreadDetail(
            chat: self.metaModel.getChat(),
            threadMessage: self.threadMessage,
            loadType: .position,
            position: message.threadPosition
        )
    }

    private func showMessageRecalledToast() {
        if let targetVC = context.pageAPI {
            UDToast.showFailure(with: BundleI18n.LarkThread.Lark_Chat_TopicWasRecalledToast,
                                on: targetVC.view)
        }
    }

    private func trackUserInteraction(by type: ThreadTracker.ThreadInteractionType) {
        ThreadTracker.trackThreadUserInteraction(
            chatID: threadMessage.chatID,
            threadID: threadMessage.thread.id,
            interactionType: type,
            impressionID: self.threadMessage.impressionID,
            threadLocation: getThreadLocation()
        )
    }

    private func getThreadLocation() -> ThreadTracker.ThreadLocation {
        return .threadChat
    }

    private func showThreadDetail(
        chat: Chat,
        threadMessage: ThreadMessage,
        loadType: ThreadDetailLoadType,
        position: Int32? = -1,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none)
    ) {
        guard let fromVC = self.context.pageAPI else {
            assertionFailure("缺少 From VC")
            return
        }

        self.threadMenuService?.deleteMemeryTopic = { [weak self, weak fromVC] messageId in
            guard let self, let from = fromVC else {
                assertionFailure("缺少 From VC")
                return
            }
            self.context.navigator.pop(from: from)
            self.context.deleteRow(by: messageId)
        }

        let sourceType: ThreadDetailFromSourceType
        switch self.context.scene {
        case .threadChat:
            sourceType = .chat
        default:
            sourceType = .other
        }
        if let topicGroup = metaModel.getTopicGroup() {
            let chat = metaModel.getChat()
            let body = ThreadDetailByModelBody(
                chat: chat,
                topicGroup: topicGroup,
                sourceType: sourceType,
                threadMessage: threadMessage,
                needUpdateBlockData: true,
                loadType: loadType,
                position: position,
                keyboardStartupState: keyboardStartupState
            )
            context.navigator.push(body: body, from: fromVC)
            return
        }

        let body = ThreadDetailByIDBody(
            threadId: threadMessage.thread.id,
            loadType: loadType,
            position: position,
            keyboardStartupState: keyboardStartupState,
            sourceType: sourceType
        )
        context.navigator.push(body: body, from: fromVC)
    }

    fileprivate func pushChatVC() {
        let chat = metaModel.getChat()
        let isFromeDefaultTopicGroup = metaModel.getTopicGroup()?.isDefaultTopicGroup ?? false
        if isFromeDefaultTopicGroup {
            ThreadTracker.trackEnterDefaultGroup(entranceType: .momentsFeed)
        } else {
            ThreadTracker.trackEnterGroup(entranceType: .momentsFeed)
        }

        try? self.context.resolver.resolve(assert: ChatAPI.self).fetchChat(by: chat.id, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatModel) in
                guard let `self` = self, let chat = chatModel else {
                    return
                }

                guard let fromVC = self.context.pageAPI else {
                    assertionFailure("缺少 From VC")
                    return
                }

                if chat.role != .member {
                    let body = JoinGroupApplyBody(
                        chatId: chat.id,
                        way: .viaSearch
                    )
                    self.context.navigator.open(body: body, from: fromVC)
                } else {
                    self.showThreadChatVC(by: chat)
                }
            }).disposed(by: self.disposeBag)
    }

    private func showThreadChatVC(by chat: Chat) {
        guard let fromVC = self.context.pageAPI else {
            assertionFailure("缺少 From VC")
            return
        }
        let body = ThreadChatByChatBody(chat: chat)
        context.navigator.push(body: body, from: fromVC)
    }

    public override func buildDescription() -> [String: String] {
        let rootMessage = threadMessage.rootMessage
        let isPin = rootMessage.pinChatter != nil
        return ["id": "\(rootMessage.id)",
            "cid": "\(rootMessage.cid)",
            "type": "\(rootMessage.type)",
            "channelId": "\(rootMessage.channel.id)",
            "channelType": "\(rootMessage.channel.type)",
            "rootId": "\(rootMessage.rootId)",
            "parentId": "\(rootMessage.parentId)",
            "position": "\(rootMessage.position)",
            "urgent": "\(rootMessage.isUrgent)",
            "pin": "\(isPin)",
            "burned": "\(context.isBurned(message: rootMessage))",
            "fromMe": "\(context.isMe(rootMessage.fromId, chat: metaModel.getChat()))",
            "recalled": "\(rootMessage.isRecalled)",
            "crypto": "\(false)",
            "localStatus": "\(rootMessage.localStatus)"]
    }

    /// 显示原文、收起译文
    fileprivate func translateTapHandler() {
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        let translateParam = MessageTranslateParameter(message: threadMessage.rootMessage,
                                                       source: MessageSource.common(id: threadMessage.rootMessage.id),
                                                       chat: metaModel.getChat())
        translateService?.translateMessage(translateParam: translateParam, from: vc)
    }

    /// 消息被其他人自动翻译icon点击事件
    fileprivate func autoTranslateTapHandler() {
        guard let fromVC = self.context.pageAPI else {
            assertionFailure("缺少 From VC")
            return
        }
        let effectBody = TranslateEffectBody(chat: metaModel.getChat(), message: threadMessage.rootMessage)
        context.navigator.push(body: effectBody, from: fromVC)
    }

    override func willDisplay() {
        super.willDisplay()
        isDisplay = true
        // 对thread中的rootMessage和replyMessages进行自动检查
        let translateParam = MessageTranslateParameter(message: threadMessage.rootMessage,
                                                       source: .common(id: threadMessage.rootMessage.id),
                                                       chat: metaModel.getChat())
        translateService?.checkLanguageAndDisplayRule(translateParam: translateParam, isFromMe: isFromMe)
        threadMessage.replyMessages.forEach { (message) in
            let replyTranslateParam = MessageTranslateParameter(message: message,
                                                                source: .common(id: threadMessage.id),
                                                                chat: metaModel.getChat())
            translateService?.checkLanguageAndDisplayRule(translateParam: replyTranslateParam, isFromMe: isFromMe)
        }
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
        }
        trackInlineRender()
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        isDisplay = false
    }
}

extension ThreadMessageCellViewModel {
    func createReplyInfos(messages: [Message], chatID: String) -> [(nameCount: Int, replyAttributedString: NSAttributedString, height: CGFloat)] {
        var replyInfos = [(nameCount: Int, replyAttributedString: NSAttributedString, height: CGFloat)]()

        if messages.isEmpty {
            return replyInfos
        }

        for message in messages {
            let name = getDispalyName(message: message)
            let replyFormattedName = getReplyNameFormatted(name: name, message: message)
            let messageSummerize = getSummerize(message: message, replyName: replyFormattedName)
            let tmpHeight = ceil(
                messageSummerize.componentTextSize(
                    for: CGSize(
                        width: UIScreen.main.bounds.width - 24 * 2,
                        height: CGFloat.greatestFiniteMagnitude
                    ),
                    limitedToNumberOfLines: 2
                ).height
            )
            replyInfos.append((replyFormattedName.count, messageSummerize, tmpHeight))
        }

        return replyInfos
    }

    func getReplyNameFormatted(name: String, message: Message) -> String {
        var userName = ""
        /// 是否译文逻辑统一
        if message.translateContent == nil {
            userName = "\(name): "
        } else {
            userName = "\(name): \(BundleI18n.LarkThread.Lark_Legacy_TranslateInChat)"
        }

        return userName
    }

    func getDispalyName(message: Message) -> String {
        let displayName = message.fromChatter?
            .displayName(chatId: message.channel.id, chatType: .group, scene: .head) ?? ""
        if displayName.isEmpty {
            let chatter = message.fromChatter
            ThreadMessageCellViewModelLogger.logger.error(
                """
                reply displayName is empty:
                \(chatter == nil)
                \(chatter?.chatExtraChatID ?? "chatExtraChatID is empty")
                \(message.channel.id)
                \(chatter?.id ?? "chatter.id is empty")
                \(chatter?.alias.count ?? 0)
                \(chatter?.localizedName.count ?? 0)
                \(chatter?.nickName?.count ?? 0)
                """
            )
        }
        return displayName
    }

    func getSummerize(message: Message, replyName: String) -> NSAttributedString {
        let textColor = UIColor.ud.textTitle
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byWordWrapping
        let textFont = UIFont.ud.body2
        let attribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: textFont,
            .paragraphStyle: paragraphStyle
        ]
        let replyNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.ud.body1,
            .foregroundColor: UIColor.ud.N700
        ]
        let replyNameAttributeString = NSAttributedString(string: replyName, attributes: replyNameAttributes)
        func assemblyReplyAttributeString(parseRichString: NSMutableAttributedString, replyNameAttributeString: NSAttributedString, isEdited: Bool) -> NSAttributedString {
            var attrString = NSMutableAttributedString()
            if parseRichString.length > 0 {
                parseRichString.insert(replyNameAttributeString, at: 0)
                attrString.append(parseRichString)
            } else {
                attrString.append(replyNameAttributeString)
            }
            if isEdited {
                let editedText = NSAttributedString(string: BundleI18n.LarkThread.Lark_IM_EditMessage_Edited_Label, attributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.ud.textCaption
                ])
                attrString.append(editedText)
            }
            return attrString
        }
        func getDocsToTitleAttributedString(
            richText: RustPB.Basic_V1_RichText,
            docEntity: RustPB.Basic_V1_DocEntity?
        ) -> NSMutableAttributedString {
            let textDocsVM = TextDocsViewModel(userResolver: context.userResolver, richText: richText, docEntity: docEntity, hangPoint: message.urlPreviewHangPointMap)
            let customAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColor,
                                                                   .font: textFont,
                                                                   MessageInlineViewModel.iconColorKey: textColor,
                                                                   MessageInlineViewModel.tagTypeKey: TagType.normal]
            setInlineStartTime(message: message)
            let parseRichText = textDocsVM.parseRichText(
                checkIsMe: nil,
                needNewLine: false,
                iconColor: textColor,
                customAttributes: customAttributes,
                urlPreviewProvider: { elementID, _ in
                    let inlinePreviewVM = MessageInlineViewModel()
                    return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
                }
            )
            parseRichText.attriubuteText.addAttributes(attribute, range: NSRange(location: 0, length: parseRichText.attriubuteText.length))
            trackInlineRender(message: message)
            return parseRichText.attriubuteText
        }

        if message.type == .text {
            var textContent: TextContent
            if let content = message.translateContent as? TextContent {
                textContent = content
            } else if let content = message.content as? TextContent {
                textContent = content
            } else {
                return NSAttributedString(string: BundleI18n.LarkThread.Lark_Legacy_UnknownMessageTypeTip(),
                                          attributes: [.font: textFont])
            }
            let parseRichString = getDocsToTitleAttributedString(richText: textContent.richText, docEntity: textContent.docEntity)
            return assemblyReplyAttributeString(parseRichString: parseRichString, replyNameAttributeString: replyNameAttributeString, isEdited: message.isMultiEdited)
        } else if message.type == .post {
            var postContent: PostContent
            if let content = message.translateContent as? PostContent {
                postContent = content
            } else if let content = message.content as? PostContent {
                postContent = content
            } else {
                return NSAttributedString(string: BundleI18n.LarkThread.Lark_Legacy_UnknownMessageTypeTip(),
                                          attributes: [.font: textFont])
            }
            // 无标题帖子展示内容
            if postContent.isUntitledPost {
                let fixRichText = postContent.richText.lc.convertText(tags: [.img, .media])
                let parseRichString = getDocsToTitleAttributedString(richText: fixRichText, docEntity: postContent.docEntity)
                return assemblyReplyAttributeString(parseRichString: parseRichString, replyNameAttributeString: replyNameAttributeString, isEdited: message.isMultiEdited)
            } else {
                let attributeText = NSMutableAttributedString(string: postContent.title, attributes: attribute)
                return assemblyReplyAttributeString(parseRichString: attributeText, replyNameAttributeString: replyNameAttributeString, isEdited: message.isMultiEdited)
            }
        } else {
            let messageInfo = self.modelService?.messageSummerize(message) ?? ""
            let attributeText = NSMutableAttributedString(string: messageInfo, attributes: attribute)
            return assemblyReplyAttributeString(parseRichString: attributeText, replyNameAttributeString: replyNameAttributeString, isEdited: message.isMultiEdited)
        }
    }
}

extension ThreadMessageCellViewModel {
    var isFollow: Bool {
        return threadMessage.thread.isFollow
    }
    var avatarKey: String {
        return threadMessage.rootMessage.fromChatter?.avatarKey ?? ""
    }
    var displayName: String {
        let chat = metaModel.getChat()
        return threadMessage.rootMessage.fromChatter?
            .displayName(chatId: chat.id, chatType: chat.type, scene: .head) ?? ""
    }
    var replyCount: Int32 {
        return threadMessage.thread.replyCount
    }

    var fromId: String {
        return threadMessage.rootMessage.fromId
    }
    var localStatus: Message.LocalStatus {
        return threadMessage.rootMessage.localStatus
    }
}

extension ThreadMessageCellViewModel: HasThreadMessage {
    func getThreadMessage() -> ThreadMessage {
        return threadMessage
    }

    func getThread() -> RustPB.Basic_V1_Thread {
        return threadMessage.thread
    }

    func getRootMessage() -> Message {
        return threadMessage.rootMessage
    }
}

extension ThreadMessageCellViewModel: LKLabelExpensionIndexDelegate {
    public func attributedLabel(_ label: LKLabel, index: Int, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard index < self.replyInfos.count,
            index >= 0 else {
                return true
        }
        let replyInfo = self.replyInfos[index]

        if NSIntersectionRange(range, NSRange(location: 0, length: replyInfo.replyAttributedString.string.count - replyInfo.nameCount)).length > 0 {
            pushThreadDetailVC(clickedIndex: index)
            return false
        }
        return false
    }
}

// MARK: - Inline Render Track
extension ThreadMessageCellViewModel {
    func setInlineStartTime(message: Message) {
        guard !message.urlPreviewHangPointMap.isEmpty else { return }
        inlineRenderTrack.value.setStartTime(message: message)
    }

    func trackInlineRender() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, self.isDisplay else { return }
            self.inlineRenderTrack.value.trackRender(contextScene: self.context.scene)
        }
    }

    func trackInlineRender(message: Message) {
        guard !message.urlPreviewHangPointMap.isEmpty else { return }
        let endTime = CACurrentMediaTime()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.inlineRenderTrack.value.setEndTime(message: message, endTime: endTime)
            if self.isDisplay {
                self.inlineRenderTrack.value.trackRender(contextScene: self.context.scene)
            }
        }
    }
}

final class ThreadMessageCellComponentBinder: ComponentBinder<ThreadContext> {
    private var props: ThreadMessageCellProps = {
        return ThreadMessageCellProps(
            chatterID: "",
            avatarKey: "",
            avatarTapped: { },
            name: "",
            time: "",
            chatName: "",
            showChatName: false,
            showChatNameOnNextLine: false,
            chatNameOnTap: { },
            latestAtMessages: [],
            isFollow: false,
            followTapped: { },
            replyCount: 0,
            replyInfos: [(nameCount: Int, replyAttributedString: NSAttributedString, height: CGFloat)](),
            messageStatus: .fail,
            statusTapped: { },
            dlpState: .unknownDlpState,
            thumbsUpUseAnimation: false,
            thumbsUpTapped: { },
            addReplyTapped: { },
            forwardButtonTapped: { },
            shouldShowForwardButton: false,
            hasMenu: false,
            isFromMe: false,
            state: RustPB.Basic_V1_ThreadState.unknownState,
            menuTapped: { (_) in },
            children: []
        )
    }()
    private var _component: ThreadMessageCellComponent?

    override var component: ComponentWithContext<ThreadContext> {
        guard let _component else {
            fatalError("should never go here")
        }
        return _component
    }

    override func buildComponent(key: String? = nil, context: ThreadContext? = nil) {
        _component = ThreadMessageCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadMessageCellViewModel else {
            assertionFailure()
            return
        }
        let chat = vm.metaModel.getChat()
        let userId = vm.fromId
        let chatId = chat.id
        props.avatarKey = vm.avatarKey
        props.chatterID = userId
        props.avatarTapped = { [weak vm] in
            guard let vm = vm, let targetVC = vm.context.pageAPI else { return }
            // 匿名点击无效
            if let isAnonymous = vm.threadMessage.rootMessage.fromChatter?.isAnonymous, isAnonymous {
                return
            }
            let body = PersonCardBody(chatterId: userId,
                                      chatId: chatId,
                                      fromWhere: .thread,
                                      source: .chat)
            vm.context.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        props.name = vm.displayName
        props.time = vm.time
        props.isFollow = vm.isFollow
        props.isDecryptoFail = vm.threadMessage.isDecryptoFail
        props.latestAtMessages = vm.threadMessage.latestAtMessages
        props.followTapped = { [weak vm] in
            vm?.toggleFollowThread()
        }
        props.replyCount = Int(vm.replyCount)
        props.replyInfos = vm.replyInfos

        props.messageStatus = vm.localStatus
        props.statusTapped = { [weak vm] in
            vm?.resend()
        }
        props.dlpState = vm.threadMessage.rootMessage.dlpState
        props.addReplyTapped = { [weak vm] in
            ThreadTracker.topicEnter(location: .icon)
            vm?.pushThreadDetailToRoot()
        }

        var pinComponentTmp: ComponentWithContext<ThreadContext>?
        if vm.threadMessage.rootMessage.pinChatter != nil {
            pinComponentTmp = vm.getSubComponent(subType: .pin)
        }

        props.dlpTipComponent = vm.getSubComponent(subType: .dlpTip)

        // 文件安全检测
        props.fileRiskComponent = vm.getSubComponent(subType: .riskFile)

        props.pinComponent = pinComponentTmp
        props.delegate = vm
        props.hasMenu = vm.hasMenu
        props.menuTapped = { [weak vm] (view) in
            vm?.showMenuView(pointView: view)
        }

        props.children = [vm.contentComponent]

        //二次编辑请求状态
        props.editRequestStatus = vm.editRequestStatus
        props.multiEditRetryCallBack = vm.multiEditRetryCallBack
        // 翻译
        props.isFromMe = vm.isFromMe
        props.hasBorder = vm.hasBorder
        props.translateStatus = vm.threadMessage.rootMessage.translateState
        props.translateTapHandler = { [weak vm] in
            vm?.translateTapHandler()
        }
        // 被其他人自动翻译
        props.isAutoTranslatedByReceiver = vm.threadMessage.rootMessage.isAutoTranslatedByReceiver
        // 被其他人自动翻译icon点击事件
        props.autoTranslateTapHandler = { [weak vm] in
            vm?.autoTranslateTapHandler()
        }
        // 是否展示翻译 icon
        let mainLanguage = KVPublic.AI.mainLanguage.value()
        let messageCharThreshold = KVPublic.AI.messageCharThreshold.value()
        var canShowTranslateIcon: Bool {
            guard AIFeatureGating.translationOptimization.isEnabled else { return false }
            guard vm.metaModel.getChat().role == .member else { return false }
            if mainLanguage.isEmpty { return false }
            if vm.metaModel.message.messageLanguage.isEmpty { return false }
            if vm.metaModel.message.messageLanguage == "not_lang" { return false }
            if vm.threadMessage.type == .audio { return false }
            if messageCharThreshold <= 0 { return false }
            if vm.metaModel.message.characterLength <= 0 { return false }
            let isMainLanguage = mainLanguage == vm.message.messageLanguage
            let isBeyondCharThreshold = vm.metaModel.message.characterLength >= messageCharThreshold
            let isAutoTranslate = vm.metaModel.getChat().isAutoTranslate
            return !vm.metaModel.message.isRecalled && !vm.isFromMe && !isMainLanguage && isBeyondCharThreshold && !isAutoTranslate
        }
        props.canShowTranslateIcon = canShowTranslateIcon
        props.thumbsUpTapped = { [weak vm] in
            vm?.thumbsUp()
        }
        props.thumbsUpUseAnimation = !vm.alreadyThumbsUP()
        props.state = vm.threadMessage.thread.stateInfo.state

        if vm.shouldShowForwardDescription() {
            props.forwardDescriptionComponent = vm.getSubComponent(subType: .forward)
        }
        props.tcPreviewComponent = vm.getSubComponent(subType: .tcPreview)

        props.forwardButtonTapped = { [weak vm] in
            if chat.isPublic {
                vm?.share()
            } else {
                vm?.forward()
            }
        }
        props.shouldShowForwardButton = vm.shouldShowForwardButton()

        props.reactionComponent = vm.getSubComponent(subType: .reaction)
        props.identifier = vm.threadMessage.id
        // 群公告不展示翻译功能
        props.showTranslate = !vm.isGroupAnnouncementType

        // 个人状态需要用到 chatter 中的字段，所以将 fromChatter 传入
        props.fromChatter = vm.threadMessage.rootMessage.fromChatter
        props.translateTrackInfo = makeTranslateTrackInfo(with: vm)
        _component?.props = props
    }

    private func makeTranslateTrackInfo(with viewModel: ThreadMessageCellViewModel) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = viewModel.metaModel.getChat().id
        trackInfo["chat_type"] = viewModel.chatTypeForTracking
        trackInfo["msg_id"] = viewModel.threadMessage.id
        trackInfo["message_language"] = viewModel.threadMessage.messageLanguage
        return trackInfo
    }
}
