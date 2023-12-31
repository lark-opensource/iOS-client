//
//  ReEditComponentFactory.swift
//  LarkMessageCore
//
//  Created by bytedance on 6/23/22.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSetting
import LarkContainer
import LarkSDKInterface

protocol MultiEditComponentContext: PageContext, ColorConfigContext {
    var scene: ContextScene { get }
}

extension PageContext: MultiEditComponentContext {}

public final class MultiEditComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public lazy var tenantUniversalSettingService: TenantUniversalSettingService? = {
        return try? self.context.resolver.resolve(assert: TenantUniversalSettingService.self)
    }()
    public override class var subType: SubType {
        return .multiEditStatus
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        let chat = metaModel.getChat()
        guard context.isMe(message.fromId, chat: chat),
              message.localStatus == .success,
              !message.isRecalled else {
            return false
        }
        if let requestStatus = message.editMessageInfo?.requestStatus {
            switch requestStatus {
            case .failed, .wating:
                return true
            @unknown default:
                break
            }
        }
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return MultiEditComponentViewModel(metaModel: metaModel,
                                        metaModelDependency: metaModelDependency,
                                        context: context,
                                           binder: MultiEditComponentBinder<M, D, C>(context: context,
                                                                                     requestStatus: metaModel.message.editMessageInfo?.requestStatus))
    }
}
