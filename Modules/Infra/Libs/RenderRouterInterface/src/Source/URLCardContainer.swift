//
//  URLCardContainer.swift
//  RenderRouterInterface
//
//  Created by Ping on 2023/8/9.
//

import Swinject

// URL SDK级别容器
public final class URLCardContainer {
    private let container = Container()

    public init() {}

    public func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service) {
        container.inObjectScope(.container).register(serviceType) { _ in
            return factory()
        }
    }

    public func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return container.resolve(serviceType)
    }
}
