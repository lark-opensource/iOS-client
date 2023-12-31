//
//  DocsContainer.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/8/5.
//

import Foundation
import Swinject
import LarkAppConfig
import LarkContainer
import SpaceInterface
import SKFoundation

//https://bytedance.feishu.cn/space/doc/doccnkFSTT0gzb8njXirP1QKYqc#
public final class DocsContainer {

    public static let shared = DocsContainer()
    private let container: Container
    // 用来标记DocsContainer内部是否使用LarkContainer
    public let useLarkContainer = !DocsContainer.isUnitTestEnv
    
    // 单测环境
    private static var isUnitTestEnv: Bool = {
    #if DEBUG
        return ProcessInfo.processInfo.environment["IS_TESTING_DOCS_SDK"] == "1"
    #else
        return false
    #endif
    }()

    init() {
        if useLarkContainer {
            self.container = Container.shared
        } else {
            self.container = Container()
        }
        NSLog("DocsContainer - useLarkContainer:\(useLarkContainer)")
    }

//    init(container: Container) {
//        // 不要register，因为外部已经注册好了
//        self.container = container
//    }
    
    public var pushCenter: LarkContainer.PushNotificationCenter { return self.container.pushCenter }
    
    public func userDidLogin() {
        if !useLarkContainer {
            container.resetObjectScope(.user)
        }
    }

    public func inObjectScope(_ objectScope: Swinject.ObjectScope) -> LarkContainer.ContainerWithScope<LarkContainer.Resolver> {
        self.container.inObjectScope(objectScope)
    }
    
    public func inObjectScope(_ objectScope: LarkContainer.UserSpaceScope) -> LarkContainer.ContainerWithScope<LarkContainer.UserResolver> {
        self.container.inObjectScope(objectScope)
    }
    
    @discardableResult
    public func register<Service>(
        _ serviceType: Service.Type,
        name: String? = nil,
        factory: @escaping (Resolver) -> Service
        ) -> ServiceEntry<Service> {
        return container.register(serviceType, factory: factory)
    }

    @discardableResult
    public func register<Service, Arg1>(
        _ serviceType: Service.Type,
        name: String? = nil,
        factory: @escaping (Resolver, Arg1) -> Service
        ) -> ServiceEntry<Service> {
        return container.register(serviceType, factory: factory)
    }

    @discardableResult
    public func register<Service, Arg1, Arg2>(
        _ serviceType: Service.Type,
        name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2) -> Service
    ) -> ServiceEntry<Service> {
        return container.register(serviceType, factory: factory)
    }

    @discardableResult
    public func register<Service, Arg1, Arg2, Arg3>(
        _ serviceType: Service.Type,
        name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3) -> Service
    ) -> ServiceEntry<Service> {
        return container.register(serviceType, factory: factory)
    }
}

public protocol DocsResolver: AnyObject {
    func resolve<Service>(_ serviceType: Service.Type) -> Service?
    func resolve<Service, Arg1>(_ serviceType: Service.Type, argument: Arg1) -> Service?
    func resolve<Service, Arg1, Arg2>(_ serviceType: Service.Type, argument1: Arg1, argument2: Arg2) -> Service?
    func resolve<Service, Arg1, Arg2, Arg3>(_ serviceType: Service.Type, argument1: Arg1, argument2: Arg2, argument3: Arg3) -> Service?
}

extension DocsContainer: DocsResolver {
    public func resolve<Service, Arg1, Arg2>(_ serviceType: Service.Type, argument1: Arg1, argument2: Arg2) -> Service? {
        return container.resolve(serviceType, arguments: argument1, argument2)
    }

    public func resolve<Service, Arg1, Arg2, Arg3>(_ serviceType: Service.Type, argument1: Arg1, argument2: Arg2, argument3: Arg3) -> Service? {
        return container.resolve(serviceType, arguments: argument1, argument2, argument3)
    }

    public func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return container.resolve(serviceType)
    }

    public func resolve<Service, Arg1>(_ serviceType: Service.Type, argument: Arg1) -> Service? {
        return container.resolve(serviceType, argument: argument)
    }
}
