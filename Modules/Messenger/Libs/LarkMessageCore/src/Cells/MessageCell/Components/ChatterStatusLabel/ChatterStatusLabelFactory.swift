//
//  ChatterStatusLabelFactory.swift
//  Action
//
//  Created by KT on 2019/5/13.
//

import Foundation
import LarkCore
import LarkModel
import LarkMessageBase

public protocol ChatterStatusLabelContext: ChatterStatusLabelComponentContext
                                         & ChatterStatusLabelViewModelContext { }

extension PageContext: ChatterStatusLabelContext {
    public var inlineService: MessageTextToInlineService? {
        return pageContainer.resolve(MessageTextToInlineService.self)
    }

    public func getChatThemeScene() -> ChatThemeScene {
        return pageAPI?.getChatThemeScene() ?? .defaultScene
    }
}

public final class ChatterStatusLabelFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .chatterStatus
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        // 单聊时不显示签名
        guard let chatter = message.fromChatter, metaModel.getChat().chatter == nil else {
            return false
        }
        return !(chatter.description_p.text.isEmpty)
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {

        return ChatterStatusLabelViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ChatterStatusLabelBinder<M, D, C>(context: context)
        )
    }

    public override func registerServices(pageContainer: PageContainer) {
        if let messageTextToInlineService = try? context.resolver.resolve(assert: MessageTextToInlineService.self) {
            pageContainer.register(MessageTextToInlineService.self) { messageTextToInlineService }
        }
    }
}
