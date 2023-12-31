//
//  ThreadReplyMessageCellViewModel.swift
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
import LKCommonsLogging
import LarkRustClient
import UniverseDesignToast
import UniverseDesignDialog
import RxSwift
import LarkSearchCore
import LarkContainer
import LarkStorage
import LarkAlertController
import LarkOpenChat

class ThreadReplyMessageCellViewModel: LarkMessageBase.ThreadDetailMessageCellViewModel<ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency>,
                                        ThreadDetailCellVMGeneralAbility,
                                       MessageMenuHideProtocol {
    static let logger = Logger.log(ThreadReplyMessageCellViewModel.self, category: "LarkThread")
    @PageContext.InjectedLazy var tenantUniversalSettingService: TenantUniversalSettingService?
    @PageContext.InjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    @PageContext.Provider var flagAPI: FlagAPI?

    override var identifier: String {
        return [content.identifier, "message"].joined(separator: "-")
    }

    // 是否禁用content点击事件
    let messageTypeOfDisableAction: [Message.TypeEnum]
    var disableContentTouch: Bool {
        return messageTypeOfDisableAction.contains(message.type)
    }

    var isRootMessage: Bool {
        //子类ThreadReplyRootCellViewModel里覆写成true
        return false
    }

    var hideContent: Bool {
        if let contentConfig = self.content.contentConfig {
            return contentConfig.hideContent
        }
        return false
    }

    var hasBorder: Bool {
        if self.message.type == .file || self.message.type == .folder {
            return true
        }
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

    var contentPreferMaxWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(message)
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
    let isPrivateMsgThread: Bool

     init(
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
        // 跟产品确定这里不需要判断匿名，不做匿名判断
        self.isFromMe = context.isMe(metaModel.message.fromChatter?.id ?? "", chat: metaModel.getChat())
        self.isPrivateMsgThread = metaModel.isPrivateThread
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
        } else if message.isDeleted && !(content is DeletedContentViewModel) {
            let vm = DeletedContentViewModel(metaModel: metaModel,
                                             metaModelDependency: ThreadDetailCellMetaModelDependency(
                                                contentPadding: self.metaModelDependency.contentPadding,
                                                contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                                             ),
                                             context: context)
            self.updateContent(content: vm)
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

    func showMessageMenu(message: Message,
                         source: MessageMenuLayoutSource,
                         copyType: CopyMessageType,
                         selectConstraintKey: String?) {
        self.context.pageContainer.resolve(MessageMenuOpenService.self)?.showMenu(message: message,
                                                                                  source: source,
                                                                                  extraInfo: .init(isNewLayoutStyle: false,
                                                                                                   copyType: copyType,
                                                                                                   selectConstraintKey: selectConstraintKey))
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
        self.showMessageMenu(message: self.message,
                             source: source,
                             copyType: copyType,
                             selectConstraintKey: selectConstraintKey)
    }

    func resend() {
        switch message.type {
        case .media:
            guard let vc = self.context.targetVC else {
                assertionFailure("miss context.targetVC")
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
            assertionFailure("miss From VC")
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
        if !self.showCheckBox {
            return
        }
        /// 超过选择数量上限
        if !self.checked,
            let chatPageAPI = context.chatPageAPI,
           chatPageAPI.selectedMessages.value.count >= MultiSelectInfo.maxSelectedMessageLimitCount {
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkThread.Lark_Chat_SelectMaximumMessagesToast)
            alertController.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Group_RevokeIKnow)
            context.chatPageAPI?.present(alertController, animated: true)
            return
        }

        self.checked = !self.checked
        context.chatPageAPI?.toggleSelectedMessage(by: message.id)
    }

    func flagIconDidClick() {
        let logStr = self.message.isFlag ? "unflag" : "flag"
        flagAPI?.updateMessage(isFlaged: !self.message.isFlag, messageId: message.id).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            Self.logger.info("messageID >>> \(self.message.id), \(logStr) success!!!")
        }, onError: { [weak self] error in
            guard let self = self else { return }
            Self.logger.error("messageID >>> \(self.message.id), \(logStr) failed!!!")
            if case .businessFailure(errorInfo: let info) = error as? RCError {
                DispatchQueue.main.async {
                    if let window = self.context.targetVC?.view {
                        UDToast.showFailure(with: info.displayMessage, on: window)
                    }
                }
            }
        })
    }
}

final class ThreadReplyCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    var props: ThreadReplyCellProps!
    private var _component: ThreadReplyCellComponent
    private var chatId: String

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    init(message: Message, context: ThreadDetailContext) {
        let userId = message.fromId
        let chatId = message.channel.id
        self.chatId = chatId
        props = ThreadReplyCellProps(
            message: message,
            children: [],
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
            avatarLongPressed: nil,
            reactionProvider: { nil },
            name: "",
            time: "",
            menuTapped: { _ in },
            statusTapped: { }
        )
        props.fromChatter = message.fromChatter

        _component = ThreadReplyCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
        super.init()
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadReplyMessageCellViewModel else {
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
        props.time = vm.time
        props.hasBorder = vm.hasBorder
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
        let contentComponent = vm.contentComponent
        contentComponent._style.display = vm.hideContent ? .none : .flex
        props.children = [contentComponent]

        // reaction
        props.reactionProvider = { [weak vm] in
            return vm?.getSubComponent(subType: .reaction)
        }

        var subComponents: [SubType: ComponentWithContext<ThreadDetailContext>] = [:]
        if let chatterStatusVM = vm.getSubViewModel(subType: .chatterStatus) as? ChatterStatusLabelViewModel,
           let chatterStatusComponent = vm.getSubComponent(subType: .chatterStatus) {
            subComponents[.chatterStatus] = chatterStatusComponent
            let nameContainer = self._component.nameContainer
            chatterStatusVM.refreshBlock = { [weak vm] in
                vm?.renderer.update(component: nameContainer)
            }
        }

        if let tcPreview = vm.getSubComponent(subType: .tcPreview) {
            subComponents[.tcPreview] = tcPreview
        }
        props.subComponents = subComponents

        // pin
        var pinComponentTmp: ComponentWithContext<ThreadDetailContext>?
        if let chatPinComponent = vm.getSubComponent(subType: .chatPin) {
            pinComponentTmp = chatPinComponent
        } else if vm.metaModel.message.pinChatter != nil {
            pinComponentTmp = vm.getSubComponent(subType: .pin)
        }
        props.pinComponent = pinComponentTmp

        // dlp
        props.dlpTipComponent = vm.getSubComponent(subType: .dlpTip)
        // 文件安全检测
        props.fileRiskComponent = vm.getSubComponent(subType: .riskFile)

        // 保密消息
        props.restrictComponent = vm.getSubComponent(subType: .restrict)

        // 话题已同步发送到群的提示
        props.syncToChatComponent = vm.getSubComponent(subType: .syncToChat)

        props.isFlag = vm.message.isFlag
        props.flagTapEvent = { [weak vm] in
            vm?.flagIconDidClick()
        }

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
        props.contentPreferMaxWidth = vm.contentPreferMaxWidth
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

    private func makeTranslateTrackInfo(with viewModel: ThreadReplyMessageCellViewModel) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = viewModel.metaModel.getChat().id
        trackInfo["chat_type"] = viewModel.chatTypeForTracking
        trackInfo["msg_id"] = viewModel.message.id
        trackInfo["message_language"] = viewModel.message.messageLanguage
        return trackInfo
    }
}
