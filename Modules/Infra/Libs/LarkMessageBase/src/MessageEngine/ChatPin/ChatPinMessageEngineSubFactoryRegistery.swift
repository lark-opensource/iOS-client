//
//  ChatPinMessageEngineSubFactoryRegistery.swift
//  LarkMessageBase
//
//  Created by zhaojiachen on 2023/7/28.
//

public final class ChatPinMessageEngineSubFactoryRegistery: MessageSubFactoryRegistery<PageContext> {
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
        let factories = Self.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = Self.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}
