//
//  ThreadDetailMessageCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/30.
//

import UIKit
import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkCore
import LarkUIKit
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkFeatureGating
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkExtensions
import RustPB
import UniverseDesignToast
import LarkRustClient
import LKCommonsLogging
import UniverseDesignDialog
import RxSwift
import LarkSearchCore
import LarkContainer
import LarkStorage
import LarkAlertController
import LarkOpenChat

protocol HasMessage {
    var message: Message { get }
}

protocol ThreadDetailCellVMGeneralAbility: HasMessage {
    func showMenu(_ sender: UIView,
                  location: CGPoint,
                  displayView: ((Bool) -> UIView?)?,
                  triggerGesture: UIGestureRecognizer?,
                  copyType: CopyMessageType,
                  selectConstraintKey: String?)
}

class ThreadDetailMessageCellViewModel: LarkMessageBase.ThreadDetailMessageCellViewModel<ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency>,
                                        ThreadDetailCellVMGeneralAbility,
                                        MessageMenuHideProtocol {
    private static let logger = Logger.log(ThreadDetailMessageCellViewModel.self, category: "LarkThread")
    override var identifier: String {
        return [content.identifier, "message"].joined(separator: "-")
    }
    @PageContext.InjectedLazy var tenantUniversalSettingService: TenantUniversalSettingService?
    @PageContext.InjectedLazy private var chatSecurityControlService: ChatSecurityControlService?

    var isRootMessage: Bool {
        //子类ThreadDetailRootCellViewModel里覆写成true
        return false
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

    var hasBorder: Bool {
        if self.message.type == .file || self.message.type == .folder {
            return true
        }
        return false
    }

    var isGroupAnnouncementType: Bool {
        return (self.message.content as? PostContent)?.isGroupAnnouncement ?? false
    }

    /// 翻译服务
    @PageContext.InjectedLazy private var translateService: NormalTranslateService?

    // UI属性
    var time: String {
        var formatTime = formatCreateTime
        if message.isMultiEdited {
            formatTime += BundleI18n.LarkThread.Lark_IM_EditMessage_EditedAtTime_Hover_Mobile(formatEditedTime)
        }
        return formatTime
    }

    private var formatCreateTime: String {
        return message.createTime.lf.cacheFormat("n_message", formater: { $0.lf.formatedTime_v2() })
    }

    private var formatEditedTime: String {
        return (message.editTimeMs / 1000).lf.cacheFormat("n_editMessage", formater: { $0.lf.formatedTime_v2() })
    }

    lazy private(set) var displayName: String = {
        return getFromChatterName()
    }()

    ///是否正在被二次编辑
    var isEditing: Bool = false {
        didSet {
            guard isEditing != oldValue else { return }
            calculateRenderer()
        }
    }

    //二次编辑请求状态
    lazy var editRequestStatus: Message.EditMessageInfo.EditRequestStatus? = self.message.editMessageInfo?.requestStatus
    lazy var multiEditRetryCallBack: (() -> Void) = { [weak self] in
        guard let self = self else { return }
        let message = self.message
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
                                                Self.logger.info("multiEditMessage fail, error: \(error)",
                                                                  additionalData: ["chatId": chat.id,
                                                                                  "messageId": message.id])
                                            }.disposed(by: self.disposeBag)
    }

    let isFromMe: Bool
    let threadWrapper: ThreadPushWrapper
    let isPrivateThread: Bool
    // 是否禁用content点击事件
    let messageTypeOfDisableAction: [Message.TypeEnum]
    var disableContentTouch: Bool {
        return messageTypeOfDisableAction.contains(message.type)
    }

    init(
        isPrivateThread: Bool,
        threadWrapper: ThreadPushWrapper,
        metaModel: ThreadDetailMetaModel,
        metaModelDependency: ThreadDetailCellMetaModelDependency,
        context: ThreadDetailContext,
        contentFactory: ThreadDetailSubFactory,
        getContentFactory: @escaping (ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency) -> MessageSubFactory<ThreadDetailContext>,
        subFactories: [SubType: ThreadDetailSubFactory],
        binder: ComponentBinder<ThreadDetailContext>,
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?,
        messageTypeOfDisableAction: [Message.TypeEnum]
    ) {
        self.threadWrapper = threadWrapper
        self.isPrivateThread = isPrivateThread
        // 跟产品确定这里不需要判断匿名，不做匿名判断
        self.isFromMe = context.isMe(metaModel.message.fromChatter?.id ?? "", chat: metaModel.getChat())
        self.messageTypeOfDisableAction = messageTypeOfDisableAction
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { _ in return binder },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
        super.calculateRenderer()
        context.chatPageAPI?.inSelectMode
            .subscribe(onNext: { [weak self] (inSelectMode) in
                self?.inSelectMode = inSelectMode
            }).disposed(by: self.disposeBag)
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
    }

    override func didSelect() {
        if self.hideSheetMenuIfNeedForMenuService(self.context.pageContainer.resolve(MessageMenuOpenService.self)) {
            return
        }
        if self.inSelectMode {
            self.toggleChecked()
        }
        super.didSelect()
    }

    override func update(metaModel: ThreadDetailMetaModel, metaModelDependency: ThreadDetailCellMetaModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        // TODO: 后续把判断逻辑抽离
        if message.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel(
                    metaModel: metaModel,
                    metaModelDependency: ThreadDetailCellMetaModelDependency(
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

        self.editRequestStatus = metaModel.message.editMessageInfo?.requestStatus
        self.displayName = getFromChatterName()

        super.calculateRenderer()
    }

    func getFromChatterName() -> String {
        let chat = metaModel.getChat()
        return self.message.fromChatter?
            .displayName(chatId: chat.id, chatType: chat.type, scene: .head) ?? ""
    }

    func showMenu(_ sender: UIView,
                  location: CGPoint,
                  displayView: ((Bool) -> UIView?)?,
                  triggerGesture: UIGestureRecognizer?,
                  copyType: CopyMessageType,
                  selectConstraintKey: String?) {
        guard let chatSecurityControlService, chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                           message: message,
                                                                           anonymousId: metaModel.getChat().anonymousId).authorityAllowed else { return }
        let source = MessageMenuLayoutSource(trigerView: sender,
                                             trigerLocation: location,
                                             displayViewBlcok: displayView,
                                             inserts: UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0))
        self.context.pageContainer.resolve(MessageMenuOpenService.self)?.showMenu(
            message: message,
            source: source,
            extraInfo: .init(isNewLayoutStyle: false,
                             copyType: copyType,
                             selectConstraintKey: selectConstraintKey,
                             isOpen: self.threadWrapper.thread.value.stateInfo.state == .open))
    }

    func resend() {
        switch message.type {
        case .media:
            guard let vc = self.context.targetVC else {
                assertionFailure("缺少路由跳转VC")
                return
            }
            try? context.resolver.resolve(assert: VideoMessageSendService.self).resendVideoMessage(message, from: vc)
        case .post:
            try? context.resolver.resolve(assert: PostSendService.self).resend(message: self.message)
        @unknown default:
            try? context.resolver.resolve(assert: SendMessageAPI.self).resendMessage(message: self.message)
        }
    }

    fileprivate func insertAt() {
        if context.userID != message.fromId {
            self.context.pageAPI?.insertAt(by: message.fromChatter)
        }
    }

    override func willDisplay() {
        super.willDisplay()
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: .common(id: message.id),
                                                       chat: metaModel.getChat())
        self.translateService?.checkLanguageAndDisplayRule(translateParam: translateParam, isFromMe: isFromMe)
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
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
            "fromMe": "\(context.isMe(message.fromId, chat: metaModel.getChat()))",
            "recalled": "\(message.isRecalled)",
            "crypto": "\(false)",
            "localStatus": "\(message.localStatus)"]
    }

    // MARK: - 翻译
    /// 显示原文、收起译文
    fileprivate func translateTapHandler() {
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.common(id: message.id),
                                                       chat: metaModel.getChat())
        translateService?.translateMessage(translateParam: translateParam, from: vc)
    }

    /// 消息被其他人自动翻译icon点击事件
    fileprivate func autoTranslateTapHandler() {
        guard let fromVC = self.context.chatPageAPI else {
            assertionFailure("缺少 From VC")
            return
        }
        let effectBody = TranslateEffectBody(chat: metaModel.getChat(), message: message)
        context.navigator.push(body: effectBody, from: fromVC)
    }

    // MARK: - 多选
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
        guard let chatSecurityControlService, chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                      message: self.message,
                                                                      anonymousId: metaModel.getChat().anonymousId).authorityAllowed else { return false }
        let supportMutiSelect = content.contentConfig?.supportMutiSelect ?? false
        return inSelectMode && supportMutiSelect
    }

    /// 点击cell触发多选
    private func toggleChecked() {
        guard let chatSecurityControlService, chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                      message: self.message,
                                                                      anonymousId: metaModel.getChat().anonymousId).authorityAllowed else { return }
        /// 超过选择数量上限
        if !self.checked,
           let chatPageAPI = context.chatPageAPI,
            chatPageAPI.selectedMessages.value.count >= MultiSelectInfo.maxSelectedMessageLimitCount {
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkThread.Lark_Chat_SelectMaximumMessagesToast)
            alertController.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Group_RevokeIKnow)
            chatPageAPI.present(alertController, animated: true)
            return
        }
        self.checked = !self.checked
        context.chatPageAPI?.toggleSelectedMessage(by: message.id)
    }

    private func isAnonymousMessageOwner() -> Bool {
        let threadAnonymousId = self.threadWrapper.thread.value.anonymousID
        return !threadAnonymousId.isEmpty && threadAnonymousId == self.message.fromId
    }
}

final class ThreadDetailCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    var props: ThreadDetailCellProps
    private var _component: ThreadDetailCellComponent
    private var chatId: String

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    init(message: Message, context: ThreadDetailContext) {
        let userId = message.fromId
        let chatId = message.channel.id
        self.chatId = chatId
        self.props = ThreadDetailCellProps(
            message: message,
            avatarTapped: { [weak context] in
                guard let context, let targetVC = context.pageAPI else { return }
                if let isAnonymous = message.fromChatter?.isAnonymous, isAnonymous {
                    return
                }
                let body = PersonCardBody(chatterId: userId,
                                          chatId: chatId,
                                          source: .chat)
                context.navigator.presentOrPush(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: targetVC,
                    prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            },
            reactionProvider: { nil },
            name: "",
            time: "",
            menuTapped: { _ in },
            statusTapped: { },
            children: []
        )
        props.fromChatter = message.fromChatter

        _component = ThreadDetailCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
        super.init()
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadDetailMessageCellViewModel else {
            assertionFailure()
            return
        }
        let chatId = self.chatId
        let userId = vm.message.fromId
        props.avatarTapped = { [weak vm] in
            guard let context = vm?.context, let targetVC = context.pageAPI else { return }
            if let isAnonymous = vm?.message.fromChatter?.isAnonymous, isAnonymous {
                return
            }
            let body = PersonCardBody(chatterId: userId,
                                      chatId: chatId,
                                      source: .chat)
            context.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        props.message = vm.message
        props.name = vm.displayName
        props.hasBorder = vm.hasBorder
        props.time = vm.time
        props.flagComponent = vm.getSubComponent(subType: .flag)
        props.avatarLongPressed = { [weak vm] in
            vm?.insertAt()
        }
        props.statusTapped = { [weak vm] in
            vm?.resend()
        }

        // TextContent Component
        props.disableContentTouch = vm.disableContentTouch
        props.disableContentTapped = { [weak vm] in
            guard let window = vm?.context.targetVC?.view.window else { return }
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ForwardedCardPreviewOnly_Toast, on: window)
        }
        props.children = [vm.contentComponent]

        // reaction
        props.reactionProvider = { [weak vm] in
            return vm?.getSubComponent(subType: .reaction)
        }
        // dlp发送失败提示
        props.dlpTipComponent = vm.getSubComponent(subType: .dlpTip)
        // 文件安全检测
        props.fileRiskComponent = vm.getSubComponent(subType: .riskFile)

        // 翻译
        props.isFromMe = vm.isFromMe
        props.translateStatus = vm.message.translateState
        props.translateTapHandler = { [weak vm] in
            vm?.translateTapHandler()
        }
        // 被其他人自动翻译
        props.isAutoTranslatedByReceiver = vm.message.isAutoTranslatedByReceiver
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
            if vm.message.messageLanguage.isEmpty { return false }
            if vm.message.messageLanguage == "not_lang" { return false }
            if vm.message.type == .audio { return false }
            if messageCharThreshold <= 0 { return false }
            if vm.message.characterLength <= 0 { return false }
            let isMainLanguage = mainLanguage == vm.message.messageLanguage
            let isBeyondCharThreshold = vm.message.characterLength >= messageCharThreshold
            let isAutoTranslate = vm.metaModel.getChat().isAutoTranslate
            return !vm.message.isRecalled && !vm.isFromMe && !isMainLanguage && isBeyondCharThreshold && !isAutoTranslate
        }
        props.canShowTranslateIcon = canShowTranslateIcon
        // 多选
        // checkbox
        props.showCheckBox = vm.showCheckBox
        props.checked = vm.checked
        props.inSelectMode = vm.inSelectMode
        props.fromChatter = vm.message.fromChatter
        //是否正在被二次编辑
        props.isEditing = vm.isEditing
        //二次编辑请求状态
        props.editRequestStatus = vm.editRequestStatus
        props.multiEditRetryCallBack = vm.multiEditRetryCallBack
        props.translateTrackInfo = makeTranslateTrackInfo(with: vm)

        _component.props = props
    }
    private func makeTranslateTrackInfo(with viewModel: ThreadDetailMessageCellViewModel) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = viewModel.metaModel.getChat().id
        trackInfo["chat_type"] = viewModel.chatTypeForTracking
        trackInfo["msg_id"] = viewModel.message.id
        trackInfo["message_language"] = viewModel.message.messageLanguage
        return trackInfo
    }
}
