//
//  File.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import Swinject
import LKLoadable
// swiftlint:disable missing_docs

public protocol LarkAssemblyInterface {
#if SwinjectBuilder
    /// 容器注册 container.register
    @ContainerFactory
    func registContainer(container: Container)
#endif

#if EENavigatorBuilder
    /// 路由注册 Navigator.shared.registerMiddleware Navigator.shared.registerRoute
    @RouterFactory
    func registRouter(container: Container)

    /// 注册URLInterceptor URLInterceptorManager.shared.register
    @URLInterceptorFactory
    func registURLInterceptor(container: Container)
#endif

#if BootManagerBuilder
    /// 启动任务注册 NewBootManager.regist
    @BootManagerFactory
    func registLaunch(container: Container)
#endif

#if LarkAccountInterfaceBuilder
    /// 注册 passport delegate PassportDelegateRegistry.register
    @PassportStateDelegateFactory
    func registPassportDelegate(container: Container)

    /// 注册launcherDelegate LauncherDelegateRegistery.register
    @LaunchDelegateFactory
    func registLauncherDelegate(container: Container)

    /// 注册路由未登录跳转白名单 UnloginWhiteList.regist
    @UnloginWhitelistFactory
    func registUnloginWhitelist(container: Container)
#endif

#if LarkRustClientInBuilder
    /// 注册pushHandler PushHandlerRegistry.shared.register
    @available(*, deprecated, message: "should migrate to registRustPushHandlerInUserSpace")
    @PushHandlerFactory
    func registPushHandler(container: Container)

    /// 注册serverPush ServerPushHandler.regist
    @available(*, deprecated, message: "should migrate to registServerPushHandlerInUserSpace")
    @ServerPushHandlerFactory
    func registServerPushHandler(container: Container)

    /// 注册pushHandler RustPushHandlerRegistry.register
    @UserRustPushHandlerRegistryBuilder
    func registRustPushHandlerInUserSpace(container: Container)

    /// 注册serverPush ServerPushHandlerRegistry.register
    @UserServerPushHandlerRegistryBuilder
    func registServerPushHandlerInUserSpace(container: Container)

    /// 注册pushHandler RustPushHandlerRegistry.register
    @UserRustBgPushHandlerRegistryBuilder
    func registRustPushHandlerInBackgroundUserSpace(container: Container)

    /// 注册serverPush ServerPushHandlerRegistry.register
    @UserServerBgPushHandlerRegistryBuilder
    func registServerPushHandlerInBackgroundUserSpace(container: Container)
#endif

    func registLarkAppLink(container: Container)

#if AppContainerBuilder
    @BootLoaderFactory
    /// 注册BootLoader相关 BootLoader.regist
    func registBootLoader(container: Container)
#endif

#if LarkTabBuilder
    /// 注册Tab容器 TabRegistry.regist
    @TabRegistryFactory
    func registTabRegistry(container: Container)

    /// 注册Tab容器 TabRegistry.registMatcher
    @TabRegistryMatcherFactory
    func registMatcherTabRegistry(container: Container)
#endif

    /// 多scene注册 LarkSceneManager.shared.regist
    @available(iOS 13.0, *)
    func registLarkScene(container: Container)

#if LarkDebugExtensionPointBuilder
    /// 注册debug item DebugItem.regist
    @DebugItemFactory
    func registDebugItem(container: Container)
#endif

    /// if have subAssemblies
    @SubAssembliesFactory
    func getSubAssemblies() -> [LarkAssemblyInterface]?
}

public extension LarkAssemblyInterface {
    func registContainer(container: Container) {}
    func registRouter(container: Container) {}
    func registURLInterceptor(container: Container) {}
    func registLaunch(container: Container) {}
    func registPassportDelegate(container: Container) {}
    func registLauncherDelegate(container: Container) {}
    func registUnloginWhitelist(container: Container) {}
    func registPushHandler(container: Container) {}
    func registServerPushHandler(container: Container) {}
    func registRustPushHandlerInUserSpace(container: Container) {}
    func registServerPushHandlerInUserSpace(container: Container) {}
    func registRustPushHandlerInBackgroundUserSpace(container: Container) {}
    func registServerPushHandlerInBackgroundUserSpace(container: Container) {}
    func registLarkAppLink(container: Container) {}
    func registBootLoader(container: Container) {}
    func registTabRegistry(container: Container) {}
    func registMatcherTabRegistry(container: Container) {}
    @available(iOS 13.0, *)
    func registLarkScene(container: Container) {}
    func registDebugItem(container: Container) {}
    func getSubAssemblies() -> [LarkAssemblyInterface]? { return nil }
}

private extension LarkAssemblyInterface {
    /// 统一assemble（禁止自己实现）
    func assem(container: Container) {
        getSubAssemblies()?.forEach({ subAssembly in
            subAssembly.assem(container: container)
        })
        registContainer(container: container)
        registRouter(container: container)
        registURLInterceptor(container: container)
        registLaunch(container: container)
        registPassportDelegate(container: container)
        registLauncherDelegate(container: container)
        registUnloginWhitelist(container: container)
        registPushHandler(container: container)
        registServerPushHandler(container: container)
        registRustPushHandlerInUserSpace(container: container)
        registServerPushHandlerInUserSpace(container: container)
        registRustPushHandlerInBackgroundUserSpace(container: container)
        registServerPushHandlerInBackgroundUserSpace(container: container)
        registLarkAppLink(container: container)
        registBootLoader(container: container)
        registTabRegistry(container: container)
        registMatcherTabRegistry(container: container)
        if #available(iOS 13.0, *) {
            registLarkScene(container: container)
        }
        registDebugItem(container: container)
    }
}

extension Assembler {
    // 主工程执行，优化向下转型耗时
    convenience public init(assemblies assemblies: [Assembly], assemblyInterfaces: [LarkAssemblyInterface], container: Container = Container()) {
        self.init(container: container)
        self.setContainerCanCallResolve(false)
        assemblyInterfaces.forEach { assemblyInterface in
            assemblyInterface.assem(container: container)
        }
        assemblies.forEach { assembly in
            assembly.assemble(container: container)
        }
        self.setContainerCanCallResolve(true)
    }
    // Demo工程执行，用于适配接口兼容
    convenience public init(assemblies assemblies: [LarkAssemblyInterface], container: Container = Container()) {
        self.init(container: container)
        self.setContainerCanCallResolve(false)
        assemblies.forEach { assemblyInterface in
            assemblyInterface.assem(container: container)
        }
        self.setContainerCanCallResolve(true)
    }
}
