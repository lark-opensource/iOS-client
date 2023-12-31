//
//  Service.swift
//  LarkOpenChat
//
//  Created by qihongye on 2020/12/21.
//

import Foundation
import Swinject

/// Service Interface，下沉到LarkOpenChat的Service都必须继承此类
public protocol IService {}

/// Service Context Interface
public protocol IServiceContext {
    /// Resolver for providing DI ability.
    var resolver: Resolver { get }

    /// SignalTrap(replace to Combine later) for notification ability.
    var signalTrap: SignalTrap { get }
}

/// BaseService class，如果内部需要使用到Resolver和SignalTrap，则推荐继承此类
open class BaseService<C: IServiceContext>: IService {
    public let resolver: Resolver
    public let signalTrap: SignalTrap

    public init(context: C) {
        self.resolver = context.resolver
        self.signalTrap = context.signalTrap
    }
}
