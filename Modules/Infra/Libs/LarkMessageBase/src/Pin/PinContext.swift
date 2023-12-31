//
//  PinContext.swift
//  LarkMessageBase
//
//  Created by zc09v on 2019/9/16.
//

import Foundation

public typealias PinCellViewModel = LarkMessageBase.CellViewModel<PinContext>
public typealias PinMessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageCellViewModel<M, D, PinContext>
public typealias PinMessageSubFactory = MessageSubFactory<PinContext>
public typealias PinMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageSubViewModel<M, D, PinContext>

public final class PinContext: PageContext {
}

public final class PinMessageSubFactoryRegistery: MessageSubFactoryRegistery<PinContext> {
    private static var factoryTypes: [PinMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: PinMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: PinMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: PinContext, defaultFactory: MessageSubFactory<PinContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = PinMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = PinMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class PinCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
    private static var obseverGenerators: [() -> CellLifeCycleObsever] = []

    public static func register(obseverGenerator: @escaping () -> CellLifeCycleObsever) {
        Self.obseverGenerators.append(obseverGenerator)
    }

    public init() {
        let obsevers: [CellLifeCycleObsever] = Self.obseverGenerators.map({ generator in
            generator()
        })
        super.init(obsevers: obsevers)
    }
}
