//
//  LarkMessageCore
//
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSetting

public protocol ForwardComponentContext: ForwardComponentViewModelContext {}

public final class ForwardComponentFactory<C: ForwardComponentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .forward
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if message.originalSender == nil {
            return false
        }
        if message.isRecalled || message.isDecryptoFail {
            return false
        }
        if !context.enableAdvancedForward && !(message.content is AudioContent) {
            return false
        }
        if message.originalSenderID != message.fromId && !message.originalSenderID.isEmpty {
            return true
        }
        if let content = message.content as? AudioContent,
            content.originSenderID != metaModel.message.fromId,
            !content.originSenderID.isEmpty {
            return true
        }
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ForwardComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ForwardComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: ForwardComponentContext {
    public var currentTenantId: String {
        return (try? self.resolver.resolve(assert: PassportUserService.self).userTenant.tenantID) ?? ""
    }

    public var enableAdvancedForward: Bool {
        return self.getStaticFeatureGating(.advancedForward)
    }
}
