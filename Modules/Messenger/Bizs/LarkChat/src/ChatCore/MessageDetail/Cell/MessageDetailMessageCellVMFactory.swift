//
//  MessageDetailMessageCellVMFactory.swift
//  Action
//
//  Created by 赵冬 on 2019/7/18.
//

import UIKit
import Foundation
import LarkModel
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

/// 创建 MessageDetail 的 TextPostContent，包括根消息和回复消息。
final class MessageDetailTextPostContentFactory: TextPostContentFactory<MessageDetailContext> {

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageDetailMessageSubViewModel<M, D> {
        var config = TextPostConfig()
        config.needPostViewTapHandler = false
        config.supportSinglePreview = true

        // 根消息
        if metaModel.message.rootId.isEmpty {
            // TODO: 此处 paragraphStyle 没有用到 @王海栋
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = 24
            paragraphStyle.maximumLineHeight = 24
            paragraphStyle.lineBreakMode = .byTruncatingTail
        }

        config.isShowTitle = false
        config.isAutoExpand = true
        config.contentLineSpacing = 4
        config.attacmentImageCornerRadius = 0
        config.translateIsAutoExpand = config.isAutoExpand

        let binder = TextPostContentComponentBinder<M, D, MessageDetailContext>(context: context)
        binder.component._style.width = 100%

        return MessageDetailTextPostContentViewModel(
            content: metaModel.message.content,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            config: config
        )
    }
}

final class CryptoMessageDetailTextPostContentFactory: CryptoTextContentFactory<MessageDetailContext> {
    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageDetailMessageSubViewModel<M, D> {
        var config = TextPostConfig()
        config.needPostViewTapHandler = false

        // 根消息
        if metaModel.message.rootId.isEmpty {
            // TODO: 此处 paragraphStyle 没有用到 @王海栋
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = 24
            paragraphStyle.maximumLineHeight = 24
            paragraphStyle.lineBreakMode = .byTruncatingTail
        }

        config.isShowTitle = false
        config.isAutoExpand = true
        config.contentLineSpacing = 4
        config.attacmentImageCornerRadius = 0
        config.translateIsAutoExpand = config.isAutoExpand

        let binder = CryptoTextContentComponentBinder<M, D, MessageDetailContext>(context: context)
        binder.component._style.width = 100%

        return CryptoChatTextContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            config: config
        )
    }
}

struct MessageDetailCellModelDependency: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    let config: MessageDetailCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: MessageDetailCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

struct MessageDetailCellConfig {
    public static let `default` = MessageDetailCellConfig()
    public static let `rootMessage` = MessageDetailCellConfig(isRootMessage: true)
    /// 是否是根消息
    var isRootMessage: Bool
    init(isRootMessage: Bool = false) {
        self.isRootMessage = isRootMessage
    }
}

class MessageDetailMessageCellViewModelFactory: CellViewModelFactory<MessageDetailMetaModel, MessageDetailCellModelDependency, MessageDetailContext> {

    override init(context: MessageDetailContext,
                  registery: MessageSubFactoryRegistery<MessageDetailContext>,
                  cellLifeCycleObseverRegister: CellLifeCycleObseverRegister? = nil) {
        super.init(context: context, registery: registery, cellLifeCycleObseverRegister: cellLifeCycleObseverRegister)
    }

    func createPlaceholderTipCell(copyWriting: String) -> CellViewModel<MessageDetailContext> {
        return MessageDetailPlaceholderTipCellViewModel(copyWriting: copyWriting, context: context)
    }

    func createMessageInVisibleTipCell(copyWriting: String) -> CellViewModel<MessageDetailContext> {
        return MessageDetailMessageInVisibleTipCellViewModel(copyWriting: copyWriting, context: context)
    }
}

final class NormalChatMessageDetailMessageCellViewModelFactory: MessageDetailMessageCellViewModelFactory {
    override func createMessageCellViewModel(
        with model: MessageDetailMetaModel,
        metaModelDependency: MessageDetailCellModelDependency,
        contentFactory: MessageDetailMessageSubFactory,
        subFactories: [SubType: MessageDetailMessageSubFactory]
    ) -> MessageDetailMessageCellViewModel {
        return NormalChatMessageDetailMessageCellViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            metaModelDependency: metaModelDependency,
            subFactories: subFactories,
            cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister
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
            return ChatColorConfig()
        }
    }
}
