//
//  MessageEngineCellViewModelFactory.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/3/28.
//

import RustPB
import LarkModel
import AsyncComponent
import LarkMessageBase

public struct ChatCellUIStaticVariable {
    public static let cellPadding: CGFloat = 16
    public static let bubblePadding: CGFloat = 12
    public static var bubbleLeft: CGFloat { 16 + 30.auto() + 6 } // left container width
    public static let messageStatusSize: CGFloat = StatusComponentLayoutConstraints.statusSize.width + StatusComponentLayoutConstraints.margin

    public static func maxCellContentWidth(hasStatusView: Bool, maxCellWidth: CGFloat) -> CGFloat {
        let maxBubbleWidth = maxCellWidth - bubbleLeft - cellPadding
        return maxBubbleWidth - (hasStatusView ? messageStatusSize : 0)
    }

    public static func getContentPreferMaxWidth(
        message: Message,
        maxCellWidth: CGFloat,
        maxContentWidth: CGFloat,
        bubblePadding: CGFloat
    ) -> CGFloat {
        // 红包图片最大宽度为235，带边框情况下最大宽度为 content 235 + padding 12 * 2
        if message.type == .hongbao {
            return maxContentWidth - bubblePadding
        }

        // 帖子中图片最大宽度为 300，群公告中只有一张图片且没有 inset，所以图片宽度相当于群公告宽度
        // 为了处理群公告被 reaction 撑开的 bug，这里设置最大宽度为 400
        if let content = message.content as? PostContent,
           content.isGroupAnnouncement {
            return min(GroupAnnouncementConfig.contentMaxWidth, maxContentWidth) - bubblePadding
        }

        /// 视频卡片最大宽度为 400
        if message.content is VChatMeetingCardContent {
            return min(400, maxContentWidth) - bubblePadding
        }

        /// 文件/文件夹卡片最大宽度为 400
        if message.type == .file || message.type == .folder {
            return min(FileAndFolderViewConfig.contentMaxWidth, maxContentWidth) - bubblePadding
        }

        /// 投票卡片最大宽度为 400
        if (message.content as? CardContent)?.type == .vote {
            return min(VoteContentConfig.contentMaxWidth, maxContentWidth) - bubblePadding
        }

        /// shareGroupChat 类型的 cell 最大宽度为 400
        if message.type == .shareGroupChat {
            return min(ShareGroupContentConfig.contentMaxWidth, maxContentWidth) - bubblePadding
        }

        /// shareUserCard 类型的 cell 最大宽度为 400
        if message.type == .shareUserCard {
            return min(ShareUserCardContentConfig.contentMaxWidth, maxContentWidth) - bubblePadding
        }

        /// 私有话题群卡片最大宽度为 600
        if (message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
            return min(MergeForwardPostCardContentConfig.contentMaxWidth, maxContentWidth) - bubblePadding
        }
        /// 折叠卡片的宽度默认左右间距 24
        if message.isFoldRootMessage {
            return maxCellWidth - 24 * 2
        }

        // iPad 模式下内容最大长度为 752
        return min(752, maxContentWidth) - bubblePadding
    }
}

public class MessageEngineCellViewModelFactory<C: PageContext>: CellViewModelFactory<MessageEngineMetaModel, MessageEngineCellMetaModelDependency, C> {
    public let initBinder: (ComponentWithContext<C>) -> ComponentBinder<C>

    public init(
        context: C,
        registery: MessageSubFactoryRegistery<C>,
        initBinder: @escaping (ComponentWithContext<C>) -> ComponentBinder<C>,
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister? = nil
    ) {
        self.initBinder = initBinder
        super.init(context: context, registery: registery, cellLifeCycleObseverRegister: cellLifeCycleObseverRegister)
    }

    public override func createMessageCellViewModel(
        with model: MessageEngineMetaModel,
        metaModelDependency: MessageEngineCellMetaModelDependency,
        contentFactory: MessageSubFactory<C>,
        subFactories: [SubType: MessageSubFactory<C>]
    ) -> CellViewModel<C> {
        return MessageEngineCellViewModel(
            metaModel: model,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            initBinder: self.initBinder,
            cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister,
            renderer: metaModelDependency.renderer
        )
    }
}
