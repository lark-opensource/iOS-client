//
//  UrgentComponentFactory.swift
//  LarkMessageCore
//
//  Created by 赵冬 on 2020/4/7.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface
import LarkSetting

extension PageContext: UrgentComponentViewModelContext {
}

public class UrgentComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .urgent
    }

    private lazy var groupPermissionLimit: Bool = {
        return self.context.getStaticFeatureGating("im.chat.only.admin.can.pin.vc.buzz")
    }()

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if metaModel.message.isDecryptoFail { return false }
        return metaModel.message.isUrgent && !metaModel.message.isCleaned
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return UrgentComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: UrgentComponentBinder<M, D, C>(context: context)
        )
    }

    private func hasUrgentPermissionInChat(_ chat: Chat) -> Bool {
        guard groupPermissionLimit else { return true }
        // single chat not limit
        if chat.type == .p2P { return true }
        // 服务台不支持加急
        if chat.isOncall { return false }
        if chat.type == .group || chat.chatMode == .threadV2 {
            // 群里有其他人才能发起加急
            if chat.userCount <= 1 { return false }
            switch chat.createUrgentSetting {
            case .allMembers:
                return true
            case .onlyManager:
                // owner or admin
                return chat.isGroupAdmin || chat.ownerId == context.currentUserID
            case .none, .some(_):
                assertionFailure("unknown type")
                return true
            @unknown default:
                return true
            }
        }
        assertionFailure("unknown chat type")
        return true
    }
}

public final class MessageDetailUrgentComponentFactory<C: PageContext>: UrgentComponentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return UrgentComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageDetailUrgentComponentBinder<M, D, C>(context: context)
        )
    }
}
