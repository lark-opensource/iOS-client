//
//  ShareGroupContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/11.
//

import UIKit
import Foundation
import Swinject
import LarkModel
import AsyncComponent
import LarkMessageBase
import LarkSDKInterface
import LarkSetting
import RxSwift
import LarkAccountInterface
import ServerPB
import LarkMessengerInterface

public protocol ShareGroupContentContext: ViewModelContext {
    var scene: ContextScene { get }
    var threadMiniIconEnableFg: Bool { get }
    var currentUserID: String { get }
}

public class ShareGroupContentFactory<C: ShareGroupContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is ShareGroupChatContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ShareGroupContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ShareGroupContentComponentBinder<M, D, C>(context: context)
        )
    }
}

public final class ChatPinShareGroupContentFactory<C: ShareGroupContentContext>: ShareGroupContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ShareGroupContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ShareGroupContentComponentBinder<M, D, C>(context: context),
            shareGroupContentConfig: ShareGroupContentConfig(hasPaddingBottom: true)
        )
    }
}

public final class ThreadShareGroupContentFactory<C: ShareGroupContentContext>: ShareGroupContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ShareGroupContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ShareGroupWithBorderContentComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: ShareGroupContentContext {
    public var currentUserID: String { userID }

    public var threadAPI: ThreadAPI? {
        return try? resolver.resolve(assert: ThreadAPI.self, cache: true)
    }

    public var threadMiniIconEnableFg: Bool {
        return false
    }
}
