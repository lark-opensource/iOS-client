//
//  ThreadDetailMessageCellViewModelFactory.swift
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

/// 创建 ThreadDetail 的 TextPostContent，包括根消息和回复消息。
final class ThreadDetailMessageTextPostContentFactory: TextPostContentFactory<ThreadDetailContext> {
    override public func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return super.canCreate(with: metaModel)
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> ThreadDetailSubViewModel<M, D> {
        var config = TextPostConfig()
        config.needPostViewTapHandler = false
        // 根消息
        if metaModel.message.threadId == metaModel.message.id {
            let titleFont = UIFont.ud.title3
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = titleFont.rowHeight
            paragraphStyle.maximumLineHeight = titleFont.rowHeight
            paragraphStyle.lineBreakMode = .byTruncatingTail
            config.titleRichAttributes = [
                .foregroundColor: UIColor.ud.N900,
                .font: titleFont,
                .paragraphStyle: paragraphStyle
            ]

            config.contentLineSpacing = 4
            config.isShowTitle = true
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

struct ThreadDetailCellMetaModelDependency: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    let config: ThreadDetailCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: ThreadDetailCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

struct ThreadDetailCellConfig {
    public static let `default` = ThreadDetailCellConfig()
}

final class ThreadDetailMessageCellViewModelFactory: CellViewModelFactory<ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency, ThreadDetailContext> {
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
        // 撤回 vm
        if message.isRecalled {
            return ThreadDetailRecallCellViewModel(metaModel: model, context: context)
        }

        // thread 根消息vm
        // rootId为空表示根消息
        if message.rootId.isEmpty {
            return ThreadDetailRootCellViewModel(
                isPrivateThread: model.isPrivateThread,
                threadWrapper: threadWrapper,
                metaModel: model,
                metaModelDependency: metaModelDependency,
                context: context,
                contentFactory: contentFactory,
                getContentFactory: self.getContentFactory,
                subFactories: subFactories,
                cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister,
                messageTypeOfDisableAction: messageTypeOfDisableAction
            )
        }

        // thread replyMessageVM
        return ThreadDetailMessageCellViewModel(
            isPrivateThread: model.isPrivateThread,
            threadWrapper: threadWrapper,
            metaModel: model,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            binder: ThreadDetailCellComponentBinder(message: message, context: context),
            cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister,
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
        context.pageContainer.register(ColorConfigService.self) {
            return ThreadColorConfig()
        }
    }

}

// MARK: - TranslateMenuDelegate
