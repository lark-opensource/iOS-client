//
//  FlagMessageDetailComponentViewModel.swift
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
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import LarkSDKInterface
import LarkExtensions
import LarkBizAvatar
import LKCommonsLogging
import UniverseDesignToast
import LarkRustClient
import UniverseDesignActionPanel
import LarkContainer

private let lastShowTimeMessageId = "lastShowTimeMessageId"

final class FlagMessageDetailComponentViewModel: MessageCellViewModel<FlagMessageDetailMetaModel, FlagMessageDetailCellMetaModelDependency, FlagMessageDetailContext> {
    private static let logger = Logger.log(FlagMessageDetailComponentViewModel.self, category: "Chat.FlagMessageDetailComponentViewModel")
    private lazy var chatSecurityControlService: ChatSecurityControlService? = {
        return try? self.context.resolver.resolve(assert: ChatSecurityControlService.self)
    }()
    private lazy var _identifier: String = {
        return [content.identifier, "message"].joined(separator: "-")
    }()

    override var identifier: String {
        return _identifier
    }

    var cellConfig: FlagMessageDetailChatCellConfig {
        return self.config
    }

    /// 当前cell是否被选中
    var checked: Bool = false {
        didSet {
            guard checked != oldValue else { return }
            calculateRenderer()
        }
    }
    /// 当前进入多选模式
    var inSelectMode: Bool = false {
        didSet {
            guard inSelectMode != oldValue else { return }
            calculateRenderer()
        }
    }

    /// 是否应该显示checkbox
    var showCheckBox: Bool {
        guard let chatSecurityControlService = chatSecurityControlService,
              chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                      message: self.message,
                                                                      anonymousId: metaModel.getChat().anonymousId).authorityAllowed else { return false }
        let supportMutiSelect = content.contentConfig?.supportMutiSelect ?? false
        return inSelectMode && supportMutiSelect
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

    var hasMessageStatus: Bool {
        let chatWithBot = metaModel.getChat().chatter?.type == .bot
        // 有消息状态首先是我发的消息，如果是和机器人的消息发送成功了也不显示
        // 或者不是我发的，但是有密聊倒计时
        return config.hasStatus && (isFromMe && !(chatWithBot && message.localStatus == .success))
    }

    var config: FlagMessageDetailChatCellConfig

    /// 针对系统消息，fromChatter需要特殊处理
    var fromChatter: Chatter? {
        return (message.content as? SystemContent)?.triggerUser ?? message.fromChatter
    }

    var formatTime: String {
        return message.createTime.lf.cacheFormat("message", formater: {
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

    /// Flag服务
    private lazy var flagAPI: FlagAPI? = {
        return try? self.context.resolver.resolve(assert: FlagAPI.self)
    }()
    var isFlag: Bool {
        return message.isFlag
    }

    var nameTag: [Tag] = []

    init(metaModel: FlagMessageDetailMetaModel,
         context: FlagMessageDetailContext,
         contentFactory: FlagMessageDetailSubFactory,
         getContentFactory: @escaping (FlagMessageDetailMetaModel, FlagMessageDetailCellMetaModelDependency) -> MessageSubFactory<FlagMessageDetailContext>,
         subFactories: [SubType: FlagMessageDetailSubFactory],
         metaModelDependency: FlagMessageDetailCellMetaModelDependency,
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
                return FlagMsgMessageCellComponentBinder(context: context, contentComponent: contentComponent)
            },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
        self.nameTag = nameTags(for: self.fromChatter)
        super.calculateRenderer()
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
    }

    private func nameTags(for chatter: Chatter?) -> [Tag] {
        guard let chatter = chatter, self.config.isSingle else { return [] }
        var result: [TagType] = []

        let passportUserService = try? context.resolver.resolve(assert: PassportUserService.self)
        let tenantId = passportUserService?.user.tenant.tenantID
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

    override func update(metaModel: FlagMessageDetailMetaModel, metaModelDependency: FlagMessageDetailCellMetaModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        // TODO: 后续把判断逻辑抽离
        if message.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel<FlagMessageDetailMetaModel, FlagMessageDetailCellMetaModelDependency, FlagMessageDetailContext>(
                    metaModel: metaModel,
                    metaModelDependency: FlagMessageDetailCellMetaModelDependency(
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
            let targetVC = self.context.flagMsgPageAPI else { return }

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

    /// 显示原文、收起译文
    func translateTapHandler() {}

    /// 消息被其他人自动翻译icon点击事件
    func autoTranslateTapHandler() {
        guard let vc = context.flagMsgPageAPI else {
            assertionFailure()
            return
        }

        let effectBody = TranslateEffectBody(
            chat: metaModel.getChat(),
            message: message
        )
        context.navigator.push(body: effectBody, from: vc)
    }

    func flagIconDidClick() {
        if let chat = self.context.chat,
           chat.role != .member,
           self.isFlag {
            let config = UDActionSheetUIConfig(isShowTitle: true)
            let actionSheet = UDActionSheet(config: config)
            actionSheet.setTitle(BundleI18n.LarkFlag.Lark_IM_Marked_CancelMarked_Desc)
            let item = UDActionSheetItem(
                title: BundleI18n.LarkFlag.Lark_IM_MarkAMessageToArchive_CancelButton,
                titleColor: UIColor.ud.functionDangerContentDefault,
                style: .default,
                isEnable: true,
                action: { [weak self] in
                    self?.requsetFlagOrUnFlag()
                })
            actionSheet.addItem(item)
            actionSheet.setCancelItem(text: BundleI18n.LarkFlag.Lark_IM_Marked_CancelMarked_HoldForNow_Button)
            guard let targetVC = self.context.flagMsgPageAPI else { return }
            context.navigator.present(actionSheet, from: targetVC)
        } else {
            self.requsetFlagOrUnFlag()
        }
    }

    private func requsetFlagOrUnFlag() {
        let logStr = self.isFlag ? "unflag" : "flag"
        flagAPI?.updateMessage(isFlaged: !self.isFlag, messageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            Self.logger.info("messageID >>> \(self.message.id) \(logStr) success!!!")
            guard let targetVC = self.context.flagMsgPageAPI else { return }
            targetVC.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            Self.logger.error("messageID >>> \(self.message.id) \(logStr) failed!!!")
            if case .businessFailure(errorInfo: let info) = error as? RCError {
                if let window = self.context.flagMsgPageAPI?.view {
                    UDToast.showFailure(with: info.displayMessage, on: window)
                }
            }
        }).disposed(by: self.disposeBag)
    }

    override func didSelect() {
        self.toggleTime()
        super.didSelect()
    }

    private func toggleTime() {
        let chatPageAPI = context.flagMsgPageAPI
        guard let store = context.pageContainer.resolve(KVStoreService.self) else {
            assertionFailure()
            return
        }
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
                }).first as? FlagMessageDetailComponentViewModel {
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

final class FlagMsgMessageCellComponentBinder: ComponentBinder<FlagMessageDetailContext> {
    private let props: FlagMessageDetailCellProps
    private let style = ASComponentStyle()
    private var _component: FlagMessageDetailCellComponent

    override var component: ComponentWithContext<FlagMessageDetailContext> {
        return _component
    }

    init(key: String? = nil, context: FlagMessageDetailContext? = nil, contentComponent: ComponentWithContext<FlagMessageDetailContext>) {
        props = FlagMessageDetailCellProps(
            config: .default,
            contentComponent: contentComponent
        )
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        _component = FlagMessageDetailCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? FlagMessageDetailComponentViewModel else {
            assertionFailure()
            return
        }
        // 配置
        props.config = vm.config
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
        // 时间
        props.hasTime = vm.hasTime
        props.bottomFormatTime = vm.formatTime
        // 消息状态
        props.hasMessageStatus = vm.hasMessageStatus
        // 加急
        props.isUrgent = vm.message.isUrgent
        // 内容
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
        props.contentComponent = vm.contentComponent
        props.contentConfig = vm.content.contentConfig
        // checkbox
        props.showCheckBox = vm.showCheckBox
        props.checked = vm.checked
        // 翻译状态
        props.translateStatus = vm.message.translateState
        // 翻译icon点击事件
        props.translateTapHandler = { [weak vm] in
            guard let vm = vm else { return }
            vm.translateTapHandler()
        }
        // 被其他人自动翻译
        props.isAutoTranslatedByReceiver = vm.message.isAutoTranslatedByReceiver
        // 被其他人自动翻译icon点击事件
        props.autoTranslateTapHandler = { [weak vm] in
            guard let vm = vm else { return }
            vm.autoTranslateTapHandler()
        }
        props.isFromMe = vm.isFromMe
        props.contentPadding = vm.metaModelDependency.contentPadding
        // 是否被标记
        props.isFlag = vm.isFlag
        props.flagTapEvent = { [weak vm] in
            vm?.flagIconDidClick()
        }
        // 子组件
        props.subComponents = vm.getSubComponents()

        _component.props = props
    }
}
