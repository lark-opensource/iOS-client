//
//  ThreadReplyRootCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/21.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkModel
import LarkCore
import EENavigator
import LarkFeatureGating
import LarkMessageCore
import LarkMessageBase
import LarkUIKit
import LarkMessengerInterface
import RustPB
import LarkSDKInterface
import LarkContainer
import LarkStorage
import LarkSearchCore
import UniverseDesignToast

final class ThreadReplyRootCellViewModel: ThreadReplyMessageCellViewModel {
    override var identifier: String {
        return [content.identifier, "root-message"].joined(separator: "-")
    }

    var title: String {
        guard let textPostContent = self.content as? TextPostContentViewModel,
              !textPostContent.isGroupAnnouncement else {
            return ""
        }
        return textPostContent.postTitle ?? ""
    }

    override var isRootMessage: Bool {
        return true
    }

    private(set) var thread: RustPB.Basic_V1_Thread

    init(
        threadWrapper: ThreadPushWrapper,
        metaModel: ThreadDetailMetaModel,
        metaModelDependency: ThreadDetailCellMetaModelDependency,
        context: ThreadDetailContext,
        contentFactory: ThreadDetailSubFactory,
        getContentFactory: @escaping (ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency) -> MessageSubFactory<ThreadDetailContext>,
        subFactories: [SubType: ThreadDetailSubFactory],
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?,
        messageTypeOfDisableAction: [Message.TypeEnum]
    ) {
        self.thread = threadWrapper.thread.value
        super.init(
            threadWrapper: threadWrapper,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            binder: ThreadReplyRootCellComponentBinder(message: metaModel.message, context: context),
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister,
            messageTypeOfDisableAction: messageTypeOfDisableAction
        )
    }

    override func update(metaModel: ThreadDetailMetaModel, metaModelDependency: ThreadDetailCellMetaModelDependency? = nil) {
        // 无痕删除的消息 不再更新。因为消息中没有数据。
        if metaModel.message.isNoTraceDeleted {
            return
        }
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    func update(thread: RustPB.Basic_V1_Thread) {
        self.thread = thread
        self.calculateRenderer()
    }

    /// 显示原文、收起译文
    fileprivate func translateTapHandler() {
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        guard let translateService = try? context.resolver.resolve(assert: NormalTranslateService.self) else { return }
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.common(id: message.id),
                                                       chat: metaModel.getChat())
        translateService.translateMessage(translateParam: translateParam, from: vc)
    }

    /// 消息被其他人自动翻译icon点击事件
    fileprivate func autoTranslateTapHandler() {
        guard let fromVC = self.context.chatPageAPI else {
            assertionFailure("miss From VC")
            return
        }
        let effectBody = TranslateEffectBody(
            chat: self.metaModel.getChat(),
            message: message
        )
        context.navigator.push(body: effectBody, from: fromVC)
    }
}

final class ThreadReplyRootCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    var props: ThreadReplyRootCellProps!
    private var _component: ThreadReplyRootCellComponent
    private var chatId: String

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    init(message: Message, context: ThreadDetailContext) {
        let userId = message.fromId
        let chatId = message.channel.id
        self.chatId = chatId
        props = ThreadReplyRootCellProps(
            message: message,
            children: [],
            avatarTapped: { [weak context] in
                guard let context, let targetVC = context.pageAPI else { return }
                // 匿名点击无效
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

        _component = ThreadReplyRootCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
        super.init()
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadReplyRootCellViewModel else {
            assertionFailure()
            return
        }
        let chatId = self.chatId
        if props.message.fromId != vm.message.fromId {
            let userId = vm.message.fromId
            props.avatarTapped = { [weak vm] in
                guard let vm, let targetVC = vm.context.pageAPI else { return }
                // 匿名点击返回
                if let isAnonymous = vm.message.fromChatter?.isAnonymous, isAnonymous {
                    return
                }
                let body = PersonCardBody(chatterId: userId,
                                          chatId: chatId,
                                          source: .chat)
                vm.context.navigator.presentOrPush(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: targetVC,
                    prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
        }
        props.fromChatter = vm.message.fromChatter
        props.title = vm.title
        props.message = vm.message
        props.isDecryptoFail = vm.message.isDecryptoFail
        props.name = vm.displayName
        props.time = vm.time
        props.hasBorder = vm.hasBorder
        props.statusTapped = { [weak vm] in
            vm?.resend()
        }

        props.disableContentTouch = vm.disableContentTouch
        props.disableContentTapped = { [weak vm] in
            guard let window = vm?.context.targetVC?.view.window else { return }
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ForwardedCardPreviewOnly_Toast, on: window)
        }
        let contentComponent = vm.contentComponent
        contentComponent._style.display = vm.hideContent ? .none : .flex
        props.children = [contentComponent]
        props.reactionProvider = { [weak vm] in
            return vm?.getSubComponent(subType: .reaction)
        }

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

        var subComponents: [SubType: ComponentWithContext<ThreadDetailContext>] = [:]
        if let subUrgent = vm.getSubComponent(subType: .urgent) {
            subComponents[.urgent] = subUrgent
        }

        if let subUrgentTip = vm.getSubComponent(subType: .urgentTip) {
            subComponents[.urgentTip] = subUrgentTip
        }

        if let chatterStatus = vm.getSubComponent(subType: .chatterStatus) {
            subComponents[.chatterStatus] = chatterStatus
        }

        if let tcPreview = vm.getSubComponent(subType: .tcPreview) {
            subComponents[.tcPreview] = tcPreview
        }
        props.subComponents = subComponents

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
        // 话题状态
        props.state = vm.thread.stateInfo.state

        // 多选
        // checkbox
        props.showCheckBox = vm.showCheckBox
        props.checked = vm.checked
        props.inSelectMode = vm.inSelectMode
        // 群公告不展示翻译功能
        props.showTranslate = !vm.isGroupAnnouncementType
        //是否正在被二次编辑
        props.isEditing = vm.isEditing
        //二次编辑请求状态
        props.editRequestStatus = vm.editRequestStatus
        props.multiEditRetryCallBack = vm.multiEditRetryCallBack
        props.translateTrackInfo = makeTranslateTrackInfo(with: vm)
        _component.props = props
    }
}

private func makeTranslateTrackInfo(with viewModel: ThreadReplyRootCellViewModel) -> [String: Any] {
    var trackInfo = [String: Any]()
    trackInfo["chat_id"] = viewModel.metaModel.getChat().id
    trackInfo["chat_type"] = viewModel.chatTypeForTracking
    trackInfo["msg_id"] = viewModel.message.id
    trackInfo["message_language"] = viewModel.message.messageLanguage
    return trackInfo
}
