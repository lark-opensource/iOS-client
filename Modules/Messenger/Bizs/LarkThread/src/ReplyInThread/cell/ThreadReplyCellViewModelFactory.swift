//
//  ThreadReplyMessageCellViewModelFactory.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/30.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore
import Swinject
import EEFlexiable
import LarkMessageCore
import LarkContainer
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkFeatureGating
import LarkSearchCore

/// 创建 TextPostContent，包括根消息和回复消息。
final class ReplyInThreadTextPostContentFactory: TextPostContentFactory<ThreadDetailContext> {
    override public func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return super.canCreate(with: metaModel)
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> ThreadDetailSubViewModel<M, D> {
        var config = TextPostConfig()
        config.needPostViewTapHandler = false
        // 支持独立卡片：独立卡片时内容会隐藏，需要搭配TCPreviewContainerComponentFactory使用
        config.supportSinglePreview = true

        // 根消息
        if metaModel.message.threadId == metaModel.message.id {
            config.contentLineSpacing = 4
            config.isShowTitle = false
            config.isAutoExpand = true
            config.translateIsAutoExpand = config.isAutoExpand
        }// 回复消息
        else {
            config.isShowTitle = false
            config.isAutoExpand = false
            config.translateIsAutoExpand = config.isAutoExpand
            config.contentLineSpacing = 4
            config.maxWidthOfImageContent = { _ in
                return 300
            }
        }

        let binder = TextPostContentComponentBinder<M, D, ThreadDetailContext>(context: context)
        binder.component._style.width = 100%

        return ThreadTextPostContentViewModel(
            content: metaModel.message.content,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            config: config
        )
    }
}

final class ThreadReplyMessageCellViewModelFactory: CellViewModelFactory<ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency, ThreadDetailContext> {
    private let threadWrapper: ThreadPushWrapper
    private let threadMessage: ThreadMessage
    private let messageTypeOfDisableAction: [Message.TypeEnum]

    init(threadWrapper: ThreadPushWrapper,
         context: ThreadDetailContext,
         registery: MessageSubFactoryRegistery<ThreadDetailContext>,
         threadMessage: ThreadMessage,
         cellLifeCycleObseverRegister: CellLifeCycleObseverRegister,
         messageTypeOfDisableAction: [Message.TypeEnum] = []) {
        self.threadWrapper = threadWrapper
        self.threadMessage = threadMessage
        self.messageTypeOfDisableAction = messageTypeOfDisableAction
        super.init(context: context, registery: registery, cellLifeCycleObseverRegister: cellLifeCycleObseverRegister)
    }

    /// 话题详情内容预览底部提示消息
    func createDetailPreviewTip(copyWriting: String) -> ThreadDetailCellViewModel {
        return ThreadDetailPreviewTipCellViewModel(copyWriting: copyWriting, context: context)
    }

    override func createMessageCellViewModel(
        with model: ThreadDetailMetaModel,
        metaModelDependency: ThreadDetailCellMetaModelDependency,
        contentFactory: ThreadDetailSubFactory,
        subFactories: [SubType: ThreadDetailSubFactory]
    ) -> ThreadDetailCellViewModel {
        let message = model.message
        /// 跟消息一定是发送成功的
        if message.threadId == message.id, message.localStatus == .success {
            return ThreadReplyRootCellViewModel(
                threadWrapper: threadWrapper,
                metaModel: model,
                metaModelDependency: metaModelDependency,
                context: context,
                contentFactory: contentFactory,
                getContentFactory: self.getContentFactory,
                subFactories: subFactories,
                cellLifeCycleObseverRegister: cellLifeCycleObseverRegister,
                messageTypeOfDisableAction: messageTypeOfDisableAction
            )
        }

        // thread replyMessageVM
        return ThreadReplyMessageCellViewModel(
            threadWrapper: threadWrapper,
            metaModel: model,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            binder: ThreadReplyCellComponentBinder(message: message, context: context),
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister,
            messageTypeOfDisableAction: messageTypeOfDisableAction
        )
    }

    override func createSystemCellViewModel(with model: ThreadDetailMetaModel, metaModelDependency: ThreadDetailCellMetaModelDependency) -> ThreadDetailCellViewModel {
        return ThreadDetailSystemCellViewModel(
            metaModel: model,
            context: context,
            binder: ThreadDetailSystemCellComponentBinder(context: context)
        )
    }

    override func registerServices() {
        let r = context.resolver
        context.pageContainer.register(DeleteMessageService.self) { [unowned self] in
            return DeleteMessageServiceImpl(
                controller: self.context.pageAPI ?? UIViewController(),
                messageAPI: try? r.resolve(assert: MessageAPI.self),
                nav: self.context.navigator
            )
        }
        context.pageContainer.register(ColorConfigService.self) {
            return ThreadColorConfig()
        }
    }
}
