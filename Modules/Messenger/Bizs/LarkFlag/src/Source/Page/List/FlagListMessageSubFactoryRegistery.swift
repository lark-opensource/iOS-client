//
//  FlagListMessageSubFactoryRegistery.swift
//  LarkFlag
//
//  Created by ByteDance on 2022/10/17.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel

public typealias FlagListMessageSubFactory = MessageSubFactory<FlagListMessageContext>
public final class FlagListMessageContext: PageContext {
}

public final class FlagListMessageSubFactoryRegistery: MessageSubFactoryRegistery<FlagListMessageContext> {
    private static var factoryTypes: [FlagListMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: FlagListMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: FlagListMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: FlagListMessageContext, defaultFactory: MessageSubFactory<FlagListMessageContext>? = nil) {
        let factories = FlagListMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = FlagListMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}
