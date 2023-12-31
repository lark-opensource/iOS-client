//
//  MessageDetailContext.swift
//  Action
//
//  Created by 赵冬 on 2019/7/22.
//

import Foundation
import RxSwift
import RxRelay

public typealias MessageDetailCellViewModel = LarkMessageBase.CellViewModel<MessageDetailContext>
public typealias MessageDetailMessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageCellViewModel<M, D, MessageDetailContext>
public typealias MessageDetailMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageSubViewModel<M, D, MessageDetailContext>
public typealias MessageDetailMessageSubFactory = MessageSubFactory<MessageDetailContext>

public final class MessageDetailContext: PageContext {
}

public final class MessageDetailMessageSubFactoryRegistery: MessageSubFactoryRegistery<MessageDetailContext> {
    private static var factoryTypes: [MessageDetailMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: MessageDetailMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: MessageDetailMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: MessageDetailContext, defaultFactory: MessageSubFactory<MessageDetailContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = MessageDetailMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = MessageDetailMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class CryptoMessageDetailMessageSubFactoryRegistery: MessageSubFactoryRegistery<MessageDetailContext> {
    private static var factoryTypes: [MessageDetailMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: MessageDetailMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: MessageDetailMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: MessageDetailContext, defaultFactory: MessageSubFactory<MessageDetailContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = CryptoMessageDetailMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = CryptoMessageDetailMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class NormalMessageDetailCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
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
