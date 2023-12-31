//
//  SyncToChatComponentFactory.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/15.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import LarkCore
import EEFlexiable
import LKCommonsLogging

public protocol SyncToChatContext: SyncToChatComponentContext & ReplyViewModelContext { }

public class SyncToChatComponentFactory<C: SyncToChatContext>: MessageSubFactory<C> {
    private var logger = Logger.log(SyncToChatComponentFactory.self, category: "LarkMessage.SyncToChatComponentFactory")
    public override class var subType: SubType {
        return .syncToChat
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.syncToChatThreadRootMessage != nil
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        switch context.scene {
        case .mergeForwardDetail:
            return SyncToChatCompontentBinder(
                syncToChatViewModel: SyncToChatComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                syncToChatActionHandler: MergeForwardDetailSyncToChatComponentActionHandler(context: context)
            )
        default:
            return SyncToChatCompontentBinder(
                syncToChatViewModel: SyncToChatComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                syncToChatActionHandler: SyncToChatComponentActionHandler(context: context)
            )
        }
    }
}

public final class MessageLinkSyncToChatComponentFactory<C: SyncToChatContext>: SyncToChatComponentFactory<C> {
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if let syncToChatThreadRootMessage = metaModel.message.syncToChatThreadRootMessage, syncToChatThreadRootMessage.cryptoToken.isEmpty {
            return syncToChatThreadRootMessage.isDeleted || syncToChatThreadRootMessage.isVisible
        }
        return false
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        // 消息链接场景的message不更新，可以在create时判断
        // 1: SyncToChat左边竖线会被截断，暂时没查到原因，此处给个1的间距（本身padding应该是0）
        let padding = metaModel.message.showInThreadModeStyle ? ChatCellUIStaticVariable.bubblePadding : 1
        return SyncToChatCompontentBinder(
            syncToChatViewModel: SyncToChatComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            syncToChatActionHandler: nil,
            padding: CSSValue(cgfloat: padding)
        )
    }
}
