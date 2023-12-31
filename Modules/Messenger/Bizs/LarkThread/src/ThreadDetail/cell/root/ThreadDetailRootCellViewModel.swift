//
//  ThreadDetailRootCellViewModel.swift
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

final class ThreadDetailRootCellViewModel: ThreadDetailMessageCellViewModel {
    override var identifier: String {
        return [content.identifier, "root-message"].joined(separator: "-")
    }

    var topic: String {
        return thread.topic
    }

    override var isRootMessage: Bool {
        return true
    }

    private(set) var thread: RustPB.Basic_V1_Thread

    init(
        isPrivateThread: Bool,
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
            isPrivateThread: isPrivateThread,
            threadWrapper: threadWrapper,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            binder: ThreadDetailRootCellComponentBinder(message: metaModel.message, context: context),
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

    func shouldShowForwardDescription() -> Bool {
        return context.getStaticFeatureGating(.advancedForward)
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
            assertionFailure("缺少 From VC")
            return
        }
        let effectBody = TranslateEffectBody(
            chat: self.metaModel.getChat(),
            message: message
        )
        context.navigator.push(body: effectBody, from: fromVC)
    }

}

final class ThreadDetailRootCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    var props: ThreadDetailRootCellProps!
    private var _component: ThreadDetailRootCellComponent
    private var chatId: String

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    init(message: Message, context: ThreadDetailContext) {
        let userId = message.fromId
        let chatId = message.channel.id
        self.chatId = chatId
        props = ThreadDetailRootCellProps(
            message: message,
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
            reactionProvider: { nil },
            name: "",
            time: "",
            menuTapped: { _ in },
            statusTapped: { },
            children: []
        )
        props.fromChatter = message.fromChatter

        _component = ThreadDetailRootCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
        super.init()
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadDetailRootCellViewModel else {
            assertionFailure()
            return
        }
        let chatId = self.chatId
        if props.message.fromId != vm.message.fromId {
            let userId = vm.message.fromId
            props.avatarTapped = { [weak vm] in
                guard let context = vm?.context, let targetVC = context.pageAPI else { return }
                // 匿名点击返回
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
        }
        props.fromChatter = vm.message.fromChatter
        props.topic = vm.topic
        props.message = vm.message
        props.isDecryptoFail = vm.message.isDecryptoFail
        props.hasBorder = vm.hasBorder
        props.name = vm.displayName
        props.time = vm.time
        props.statusTapped = { [weak vm] in
            vm?.resend()
        }
        props.disableContentTouch = vm.disableContentTouch
        props.disableContentTapped = { [weak vm] in
            guard let window = vm?.context.targetVC?.view.window else { return }
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ForwardedCardPreviewOnly_Toast, on: window)
        }
        props.children = [vm.contentComponent]
        props.reactionProvider = { [weak vm] in
            return vm?.getSubComponent(subType: .reaction)
        }

        // pin
        var pinComponentTmp: ComponentWithContext<ThreadDetailContext>?
        if vm.metaModel.message.pinChatter != nil {
            pinComponentTmp = vm.getSubComponent(subType: .pin)
        }
        props.pinComponent = pinComponentTmp
        props.dlpTipComponent = vm.getSubComponent(subType: .dlpTip)
        // 文件安全检测
        props.fileRiskComponent = vm.getSubComponent(subType: .riskFile)
        props.tcPreviewComponent = vm.getSubComponent(subType: .tcPreview)

        // forward
        if vm.shouldShowForwardDescription() {
            props.forwardComponent = vm.getSubComponent(subType: .forward)
        }
        // flag
        props.flagComponent = vm.getSubComponent(subType: .flag)

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
    private func makeTranslateTrackInfo(with viewModel: ThreadDetailRootCellViewModel) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = viewModel.metaModel.getChat().id
        trackInfo["chat_type"] = viewModel.chatTypeForTracking
        trackInfo["msg_id"] = viewModel.message.id
        trackInfo["message_language"] = viewModel.message.messageLanguage
        return trackInfo
    }
}
