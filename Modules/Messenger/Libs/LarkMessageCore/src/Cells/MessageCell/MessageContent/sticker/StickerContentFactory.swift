//
//  StickerContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkSetting
import LarkMessengerInterface
import LarkAssetsBrowser
import LarkSDKInterface

public protocol StickerContentContext: ViewModelContext {
    var canShowStickerSet: Bool { get }
    var scene: ContextScene { get }
    var maxCellWidth: CGFloat { get }
    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>]
    func isMe(_ id: String) -> Bool
    func getChatAlbumDataSourceImpl(chat: Chat, isMeSend: @escaping (String) -> Bool) -> LKMediaAssetsDataSource
    var userGeneralSettings: UserGeneralSettings? { get }
}

public class BaseStickerContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is StickerContent
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return StickerContentComponentBinder(
            stickerViewModel: ChatStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: ChatStickerContentActionHandler(context: context)
        )
    }
}

public final class MessageLinkStickerContentFactory<C: PageContext>: BaseStickerContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return StickerContentComponentBinder(
            stickerViewModel: MessageLinkStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: ChatStickerContentActionHandler(context: context)
        )
    }
}

public final class ThreadChatStickerContentFactory<C: PageContext>: BaseStickerContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadStickerContentComponentBinder(
            stickerViewModel: ThreadChatStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: ThreadChatStickerContentActionHandler(context: context)
        )
    }
}

public final class ThreadDetailStickerContentFactory<C: PageContext>: BaseStickerContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadStickerContentComponentBinder(
            stickerViewModel: ThreadDetailStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: ThreadDetailStickerContentActionHandler(context: context)
        )
    }
}

public final class MergeForwardStickerContentFactory<C: PageContext>: BaseStickerContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return StickerContentComponentBinder(
            stickerViewModel: MergeForwardDetailStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: MergeForwardDetailStickerContentActionHandler(context: context)
        )
    }
}

public final class MessageDetailStickerContentFactory<C: PageContext>: BaseStickerContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailStickerContentComponentBinder(
            stickerViewModel: MessageDetailStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: MessageDetailStickerContentActionHandler(context: context)
        )
    }
}

public final class PinStickerContentFactory<C: PageContext>: BaseStickerContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return PinStickerContentComponentBinder(
            stickerViewModel: PinStickerContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            stickerActionHandler: PinStickerContentActionHandler(context: context)
        )
    }
}

extension PageContext: StickerContentContext {
    public var canShowStickerSet: Bool {
        return true
    }
}
