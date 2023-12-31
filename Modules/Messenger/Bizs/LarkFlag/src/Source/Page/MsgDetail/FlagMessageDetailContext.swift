//
//  FlagContext.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/25.
//

import UIKit
import Foundation
import RxSwift
import AsyncComponent
import LarkMessageBase
import LarkModel

public typealias FlagMessageDetailCellViewModel = LarkMessageBase.CellViewModel<FlagMessageDetailContext>
public typealias FlagMessageDetailSubFactory = MessageSubFactory<FlagMessageDetailContext>

public protocol FlagMsgPageAPI: UIViewController {
    /// reload多行
    ///
    /// - Parameters:
    ///   - current: 当前行的消息id
    ///   - others: 其他行一起更新的行的消息ids
    func reloadRows(current: String, others: [String])
}

public final class FlagMessageDetailContext: PageContext {
    public weak var flagMsgPageAPI: FlagMsgPageAPI?
    public weak var chat: Chat?
}

public final class FlagMessageDetailSubFactoryRegistery: MessageSubFactoryRegistery<FlagMessageDetailContext> {
    private static var factoryTypes: [FlagMessageDetailSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: FlagMessageDetailSubFactory.Type] = [:]

    public static func register(_ factoryType: FlagMessageDetailSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: FlagMessageDetailContext, defaultFactory: MessageSubFactory<FlagMessageDetailContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = FlagMessageDetailSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = FlagMessageDetailSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class FlagMsgCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
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
