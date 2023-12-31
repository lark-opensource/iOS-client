//
//  ChatCellViewModelFactory.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/3/31.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkGuide
import LarkContainer
import LKLoadable
import LarkSearchCore

struct ChatCellMetaModelDependency: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    var config: ChatCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: ChatCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

public struct ChatCellConfig {
    // 默认
    static let `default` = ChatCellConfig()

    /// 非吸附消息
    var isSingle: Bool
    /// 是否有名字和状态(isSingle的优先级更高)
    var hasHeader: Bool
    /// 是否显示消息状态
    var hasStatus: Bool
    /// 是否改变气泡上半部分的圆角
    var changeTopCorner: Bool
    /// 是否改变气泡下半部分的圆角
    var changeBottomCorner: Bool

    init(isSingle: Bool = true,
         hasHeader: Bool = true,
         hasStatus: Bool = true,
         changeTopCorner: Bool = false,
         changeBottomCorner: Bool = false) {
        self.isSingle = isSingle
        self.hasHeader = hasHeader
        self.hasStatus = hasStatus
        self.changeTopCorner = changeTopCorner
        self.changeBottomCorner = changeBottomCorner
    }
}

public protocol ChatCellViewModelFactoryDependency {
    func canDisplayCreateWorkItemEntrance(chat: Chat, from: String) -> Bool
}

class ChatCellViewModelFactory: CellViewModelFactory<ChatMessageMetaModel, ChatCellMetaModelDependency, ChatContext> {
    func createSign() -> ChatCellViewModel {
        return ChatSignCellViewModel(context: context)
    }

    func createSign(signDate: TimeInterval) -> ChatCellViewModel {
        return ChatSignDateCellViewModel(signDate: signDate, context: context)
    }

    func create(date: TimeInterval) -> ChatCellViewModel {
        return ChatDateCellViewModel(date: date, context: context)
    }

    func create(time: TimeInterval) -> ChatCellViewModel {
        return ChatTimeCellViewModel(time: time, context: context)
    }

    func createFeatureIntroduction(copyWriting: String, hasHeader: Bool) -> ChatCellViewModel {
        return ChatFeatureIntroductionCellViewModel(copyWriting: copyWriting, hasHeader: hasHeader, context: context)
    }

    func createTopMsgTip(tip: String) -> ChatCellViewModel {
        return ChatTopMsgTipCellViewModel(tip: tip, context: context)
    }
}

final class NormalChatCellViewModelFactory: ChatCellViewModelFactory {
    @PageContext.InjectedLazy private var chatterManager: ChatterManagerProtocol?
    @PageContext.InjectedLazy private var dependency: ChatCellViewModelFactoryDependency?

    override func createMessageCellViewModel(
        with model: ChatMessageMetaModel,
        metaModelDependency: ChatCellMetaModelDependency,
        contentFactory: ChatMessageSubFactory,
        subFactories: [SubType: ChatMessageSubFactory]
    ) -> ChatCellViewModel {
        return NormalChatMessageCellViewModel(
            metaModel: model,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subfactories: subFactories,
            metaModelDependency: metaModelDependency,
            cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister
        )
    }

    override func canCreateSystemDirectly(with model: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency) -> Bool {
        /// Thread in Chat模式在撤回时不需要直接转换成为系统消息
        return context.canCreateSystemRecalledCell(model.message)
    }

    override func createSystemCellViewModel(with model: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency) -> ChatCellViewModel {
        /// 撤回消息留痕优化，UI表现变成系统消息
        if context.canCreateSystemRecalledCell(model.message) {
            var config = RecallContentConfig()
            config.isShowReedit = true
            return RecalledSystemCellViewModel(metaModel: model, context: context, config: config)
        }
        var viewModel: ChatCellViewModel = ChatSystemCellViewModel(metaModel: model, context: context)
        if let content = model.message.content as? SystemContent {
            /// 红包
            if SystemContent.SystemType.redPaketTypes.contains(content.systemType) {
                viewModel = ChatRedPacketSystemCellViewModel(metaModel: model, context: self.context)
            }
            /// 新话题系统消息分割线
            if case SystemContent.SystemType.myAiNewTopicTip = content.systemType {
                // content.systemExtraContent.hasNewTopicSystemMessageExtraContent
                viewModel = ChatAIToolSystemCellViewModel(metaModel: model, context: self.context)
            }
            /// 场景系统消息分割线
            if case SystemContent.SystemType.myAiSceneTopicDynamicTip = content.systemType {
                viewModel = MyAISceneSystemCellViewModel(metaModel: model, context: self.context)
            }
            /// 群引导，服务端可能会下发空内容，导致渲染空白
            if content.systemExtraContent.hasGuideContent, !content.systemExtraContent.guideContent.items.isEmpty {
                viewModel = ChatGroupGuideSystemCellViewModel(metaModel: model, context: self.context)
            }
        }
        return viewModel
    }

    override func registerServices() {
        let r = context.resolver
        context.pageContainer.register(DeleteMessageService.self) { [unowned self] in
            return DeleteMessageServiceImpl(
                controller: self.context.pageAPI ?? UIViewController(),
                messageAPI: try? r.resolve(assert: MessageAPI.self, cache: true),
                nav: self.context.navigator
            )
        }
        context.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }
    }
}

extension RecalledSystemCellViewModel: HasMessage {
}

final class ChatRedPacketSystemCellViewModel: RedPacketSystemCellViewModel<ChatContext>, HasMessage, HasCellConfig {
    var cellConfig: ChatCellConfig = ChatCellConfig()
}

final class ChatGroupGuideSystemCellViewModel: GroupGuideSystemCellViewModel<ChatContext>, HasMessage, HasCellConfig {
    var cellConfig: ChatCellConfig = ChatCellConfig()
}

final class ChatAIToolSystemCellViewModel: MyAIToolSystemCellViewModel<ChatContext>, HasMessage, HasCellConfig {
    var cellConfig: ChatCellConfig = ChatCellConfig()
}
