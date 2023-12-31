//
//  MessageEngineSubFactoryRegistery.swift
//  LarkMessageBase
//
//  Created by Ping on 2023/4/2.
//

public final class MessageEngineSubFactoryRegistery: MessageSubFactoryRegistery<PageContext> {
    private static var factoryTypes: [MessageSubFactory<PageContext>.Type] = []
    private static var subFactoryTypes: [SubType: MessageSubFactory<PageContext>.Type] = [:]

    public static func register(_ factoryType: MessageSubFactory<PageContext>.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: PageContext, defaultFactory: MessageSubFactory<PageContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = MessageEngineSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = MessageEngineSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}
