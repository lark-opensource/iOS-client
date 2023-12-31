//
//  MessageLinkSubFactoryRegistery.swift
//  LarkMessageBase
//
//  Created by Ping on 2023/6/28.
//

public final class MessageLinkSubFactoryRegistery: MessageSubFactoryRegistery<PageContext> {
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
        let factories = MessageLinkSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = MessageLinkSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class MessageLinkDetailSubFactoryRegistery: MessageSubFactoryRegistery<MergeForwardContext> {
    private static var factoryTypes: [MessageSubFactory<MergeForwardContext>.Type] = []
    private static var subFactoryTypes: [SubType: MessageSubFactory<MergeForwardContext>.Type] = [:]

    public static func register(_ factoryType: MessageSubFactory<MergeForwardContext>.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: MergeForwardContext, defaultFactory: MessageSubFactory<MergeForwardContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = MessageLinkDetailSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = MessageLinkDetailSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}
