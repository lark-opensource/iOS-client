//
//  MergeForwardMessageCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkTag
import LarkUIKit
import LarkCore
import RxRelay
import LarkMessageBase
import EENavigator
import LarkNavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import LarkSDKInterface
import LarkExtensions
import LarkBizAvatar
import LKCommonsLogging
import LarkSearchCore
import LarkContainer
import LarkOpenChat

private let lastShowTimeMessageId = "lastShowTimeMessageId"

final class MergeForwardMessageCellViewModel:
    LarkMessageBase.MergeForwardMessageCellViewModel<MergeForwardMessageMetaModel, MergeForwardCellMetaModelDependency>,
        HasCellConfig, MessageMenuHideProtocol {
    private static let logger = Logger.log(MergeForwardMessageCellViewModel.self, category: "Chat.MergeForwardMessageCellViewModel")
    @PageContext.InjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    private lazy var _identifier: String = {
        return [content.identifier, "message"].joined(separator: "-")
    }()

    override var identifier: String {
        return _identifier
    }

    var cellConfig: ChatCellConfig {
        return self.config
    }

    var hasTime: Bool = false {
        didSet {
            guard hasTime != oldValue else { return }
            calculateRenderer()
        }
    }

    var isFromMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    var bubbleStyle: BubbleStyle {
        if self.message.showInThreadModeStyle {
            return .thread
        }
        return .normal
    }

    var hasMessageStatus: Bool {
        let chatWithBot = metaModel.getChat().chatter?.type == .bot
        // 有消息状态首先是我发的消息，如果是和机器人的消息发送成功了也不显示
        // 或者不是我发的，但是有密聊倒计时
        return config.hasStatus && (isFromMe && !(chatWithBot && message.localStatus == .success))
    }

    var config: ChatCellConfig

    /// 针对系统消息，fromChatter需要特殊处理
    var fromChatter: Chatter? {
        return (message.content as? SystemContent)?.triggerUser ?? message.fromChatter
    }

    var formatTime: String {
        var formatTime = formatCreateTime
        if message.isMultiEdited {
            formatTime += BundleI18n.LarkChat.Lark_IM_EditMessage_EditedAtTime_Hover_Mobile(formatEditedTime)
        }
        return formatTime
    }

    var isUserInteractionEnabled: Bool {
        return self.context.mergeForwardType == .normal ? true : false
    }

    private var formatCreateTime: String {
        return message.createTime.lf.cacheFormat("message", formater: {
            $0.lf.formatedTime_v2(accurateToSecond: true)
        })
    }

    private var formatEditedTime: String {
        return (message.editTimeMs / 1000).lf.cacheFormat("editMessage", formater: {
            $0.lf.formatedTime_v2(accurateToSecond: true)
        })
    }

    var contentPreferMaxWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(message)
    }

    /// 服务端时间服务
    private lazy var serverNTPTimeService: ServerNTPTimeService? = {
        return try? self.context.resolver.resolve(assert: ServerNTPTimeService.self)
    }()

    var nameTag: [Tag] = []

    init(metaModel: MergeForwardMessageMetaModel,
         context: MergeForwardContext,
         contentFactory: MergeForwardMessageSubFactory,
         getContentFactory: @escaping (MergeForwardMessageMetaModel, MergeForwardCellMetaModelDependency) -> MessageSubFactory<MergeForwardContext>,
         subFactories: [SubType: MergeForwardMessageSubFactory],
         metaModelDependency: MergeForwardCellMetaModelDependency,
         cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?) {
        self.config = metaModelDependency.config
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { contentComponent in
                return MergeForwardMessageCellComponentBinder(context: context, contentComponent: contentComponent)
            },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
        self.nameTag = nameTags(for: self.fromChatter)
        super.calculateRenderer()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
    }

    public func showMessageMenu(message: Message,
                                source: MessageMenuLayoutSource,
                                copyType: CopyMessageType,
                                selectConstraintKey: String?) {
        self.context.pageContainer.resolve(MessageMenuOpenService.self)?.showMenu(message: message,
                                                                                  source: source,
                                                                                  extraInfo: .init(copyType: copyType, selectConstraintKey: selectConstraintKey))
    }

    func showMenu(_ sender: UIView,
                  location: CGPoint,
                  displayView: ((Bool) -> UIView?)?,
                  triggerGesture: UIGestureRecognizer?,
                  copyType: CopyMessageType,
                  selectConstraintKey: String?) {

        // 如果是折叠消息(消息聚合需求)，屏蔽Menu的操作
        guard self.chatSecurityControlService?.getDynamicAuthorityFromCache(event: .receive,
                                                                           message: message,
                                                                           anonymousId: metaModel.getChat().anonymousId
                                                                           ).authorityAllowed == true
        else { return }

        let source = MessageMenuLayoutSource(trigerView: sender,
                                             trigerLocation: location,
                                             displayViewBlcok: displayView,
                                             inserts: UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0))
        self.showMessageMenu(message: message,
                             source: source,
                             copyType: copyType,
                             selectConstraintKey: selectConstraintKey)
    }

    private func needAddTranslateItem () -> Bool {
        // 子合并转发消息目前支持卡片和富文本
        return AIFeatureGating.multiLayerTranslate.isEnabled && (message.type == .text || message.type == .post)
    }
    private func nameTags(for chatter: Chatter?) -> [Tag] {
        guard let chatter = chatter, self.config.isSingle,
            let passportUserService = try? self.context.resolver.resolve(assert: PassportUserService.self)
        else { return [] }
        var result: [TagType] = []

        let tenantId = passportUserService.user.tenant.tenantID
        let isShowBotIcon = (chatter.type == .bot && !chatter.withBotTag.isEmpty)
        if chatter.workStatus.status == .onLeave, chatter.tenantId == tenantId {
            result = [.onLeave]
        } else {
            result = isShowBotIcon ? [.robot] : []
        }
        /// 判断勿扰模式
        if serverNTPTimeService?.afterThatServerTime(time: chatter.doNotDisturbEndTime) == true {
            result.append(.doNotDisturb)
        }
        var resultTags = result.map({ Tag(type: $0) })
        resultTags.append(contentsOf: chatter.eduTags)
        return resultTags
    }

    override func update(metaModel: MergeForwardMessageMetaModel, metaModelDependency: MergeForwardCellMetaModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        // TODO: 后续把判断逻辑抽离
        if message.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel<MergeForwardMessageMetaModel, MergeForwardCellMetaModelDependency, MergeForwardContext>(
                    metaModel: metaModel,
                    metaModelDependency: MergeForwardCellMetaModelDependency(
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
        self.nameTag = nameTags(for: message.fromChatter)
        self.calculateRenderer()
    }

    func getDisplayName(chatter: Chatter, chat: Chat, scene: GetChatterDisplayNameScene) -> String {
        return context.getDisplayName(chatter: chatter, chat: chat, scene: scene)
    }

    func onAvatarTapped(avator: BizAvatar) {
        // 匿名的话 点击头像无效
        guard let chatter = fromChatter,
            chatter.profileEnabled,
            !chatter.isAnonymous,
            let targetVC = self.context.pageAPI else { return }

        let body = PersonCardBody(chatterId: chatter.id,
                                  chatId: metaModel.getChat().id,
                                  fromWhere: .chat,
                                  source: .chat)
        context.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    override func willDisplay() {
        super.willDisplay()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
        }
    }

    override func didSelect() {
        if self.hideSheetMenuIfNeedForMenuService(self.context.pageContainer.resolve(MessageMenuOpenService.self)) {
            return
        }
        self.toggleTime()
        super.didSelect()
    }

    private func toggleTime() {
        let chatPageAPI = context.chatPageAPI
        guard let store = context.pageContainer.resolve(KVStoreService.self) else { return }
        let key = lastShowTimeMessageId
        if let lastShowTimeMessageId: String = store.getValue(for: key) {
            if self.message.id == lastShowTimeMessageId {
                self.hasTime = !self.hasTime
                let value = self.hasTime ? self.message.id : nil
                store.setValue(value, for: key)
                chatPageAPI?.reloadRows(current: self.message.id, others: [])
            } else {
                self.hasTime = true
                store.setValue(self.message.id, for: key)
                // swiftlint:disable first_where
                if let lastVM = context.dataSourceAPI?.filter({ (vm) -> Bool in
                    return vm.content.message.id == lastShowTimeMessageId
                }).first as? MergeForwardMessageCellViewModel {
                    lastVM.hasTime = false
                }
                // swiftlint:enable first_where
                chatPageAPI?.reloadRows(current: self.message.id, others: [lastShowTimeMessageId])
            }
        } else {
            self.hasTime = true
            store.setValue(self.message.id, for: key)
            chatPageAPI?.reloadRows(current: self.message.id, others: [])
        }
    }

    func toReplyInThread() {
        guard self.message.showInThreadModeStyle else {
            return
        }
        // 同ReplyThreadInfoComponentViewModel.replyDidTapped逻辑
        let isMergeForwardScene: Bool = message.mergeForwardInfo != nil
        let originChat = isMergeForwardScene ? message.mergeForwardInfo?.originChat : metaModel.getChat()
        if originChat?.role == .member {
            let body = ReplyInThreadByModelBody(message: message,
                                                chat: originChat ?? metaModel.getChat(),
                                                loadType: .unread,
                                                position: nil,
                                                sourceType: .chat,
                                                chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
            context.navigator(type: .push, body: body, params: nil)
        } else {
            //如果拿不到chat，也说明自己不在会话里。此时mock一个
            let chat = originChat ?? ReplyInThreadMergeForwardDataManager.getMockP2pChat(id: String(message.mergeForwardInfo?.originChatID ?? 0))
            let body = ThreadPostForwardDetailBody(originMergeForwardId: message.id, message: message, chat: chat)
            context.navigator(type: .push, body: body, params: nil)
        }
    }

    public override func buildDescription() -> [String: String] {
        let isPin = message.pinChatter != nil
        return ["id": "\(message.id)",
            "cid": "\(message.cid)",
            "type": "\(message.type)",
            "channelId": "\(message.channel.id)",
            "channelType": "\(message.channel.type)",
            "rootId": "\(message.rootId)",
            "parentId": "\(message.parentId)",
            "position": "\(message.position)",
            "urgent": "\(message.isUrgent)",
            "pin": "\(isPin)",
            "burned": "\(context.isBurned(message: message))",
            "fromMe": "\(isFromMe)",
            "recalled": "\(message.isRecalled)",
            "crypto": "\(false)",
            "localStatus": "\(message.localStatus)"]
    }
}

final class MergeForwardMessageCellComponentBinder: ComponentBinder<MergeForwardContext> {
    private let props: MergeForwardMessageCellProps
    private let style = ASComponentStyle()
    private var _component: MergeForwardMessageCellComponent

    override var component: ComponentWithContext<MergeForwardContext> {
        return _component
    }

    init(key: String? = nil, context: MergeForwardContext, contentComponent: ComponentWithContext<MergeForwardContext>) {
        props = MergeForwardMessageCellProps(
            context: context,
            config: .default,
            contentComponent: contentComponent
        )
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        _component = MergeForwardMessageCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MergeForwardMessageCellViewModel else {
            assertionFailure()
            return
        }
        // 配置
        props.config = vm.config
        // 气泡样式
        props.bubbleStyle = vm.bubbleStyle
        props.displayInThreadMode = vm.metaModel.message.displayInThreadMode

        // 头像和名字
        props.fromChatter = vm.fromChatter
        props.nameTag = vm.nameTag
        props.isScretChat = false
        props.avatarTapped = { [weak vm] in
            guard let vm = vm else { return }
            vm.onAvatarTapped(avator: $0)
        }
        props.getDisplayName = { [weak vm] chatter in
            guard let vm = vm else { return "" }
            return vm.getDisplayName(chatter: chatter, chat: vm.metaModel.getChat(), scene: .head)
        }
        props.isUserInteractionEnabled = vm.isUserInteractionEnabled
        // 时间
        props.hasTime = vm.hasTime
        props.bottomFormatTime = vm.formatTime
        // 消息状态
        props.hasMessageStatus = vm.hasMessageStatus
        // 加急
        props.isUrgent = vm.message.isUrgent
        // 消息类型
        props.messageType = vm.message.type
        // 内容
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.contentComponent = vm.contentComponent
        props.contentConfig = vm.content.contentConfig
        // checkbox
        props.showCheckBox = false
        props.checked = false
        // 翻译状态
        props.translateStatus = vm.message.translateState
        // 被其他人自动翻译
        props.isAutoTranslatedByReceiver = vm.message.isAutoTranslatedByReceiver
        props.isFromMe = vm.isFromMe
        props.contentPadding = vm.metaModelDependency.contentPadding
        props.contenTapHandler = { [weak vm] in
            vm?.toReplyInThread()
        }
        // 子组件
        props.subComponents = vm.getSubComponents()

        _component.props = props
    }
}
