//
//  PageServiceContainer.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/16.
//

import Foundation
import Swinject
import LarkContainer

public protocol PageService {
    /// 对应init
    func pageInit()

    ///对应viewDidLoad
    func pageViewDidLoad()

    /// 对应viewWillAppear
    func pageWillAppear()

    /// 对应viewDidAppear
    func pageDidAppear()

    /// 对应viewWillDisappear
    func pageWillDisappear()

    /// 对应viewDidDisappear
    func pageDidDisappear()

    /// 对应deinit
    func pageDeinit()

    /// 拉取首屏消息前
    func beforeFetchFirstScreenMessages()

    /// 对应首屏消息渲染完成之后(目前只有普通会话页面支持这个时机回调)
    func afterFirstScreenMessagesRender()
}

public extension PageService {
    func pageInit() {}

    func pageWillAppear() {}

    func pageDidAppear() {}

    func pageWillDisappear() {}

    func pageDidDisappear() {}

    func pageViewDidLoad() {}

    func pageDeinit() {}

    func beforeFetchFirstScreenMessages() {}

    func afterFirstScreenMessagesRender() {}
}

public protocol PageContainer: AnyObject {
    /// 容器中注册页面级服务 (注册工厂)
    ///
    /// - Parameters:
    ///   - serviceType: 服务类
    ///   - factory: 服务构造工厂
    func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service)

    /// 容器中注册页面级服务 (注册Service实例)
    ///
    /// - Parameters:
    ///   - serviceType: 页面服务类
    ///   - factory: 服务构造工厂
    func register<Service: PageService>(_ serviceType: Service.Type, factory: @escaping () -> Service)

    /// 容器中获取页面级服务
    ///
    /// - Parameter serviceType: 服务类
    /// - Returns: 如果存在对应的实例，返回实例；如果找到对应的构造工厂，构造实例并返回
    func resolve<Service>(_ serviceType: Service.Type) -> Service?
}

public final class PageServiceContainer: PageService, PageContainer {
    private let container = Container()
    private var pageServices: [() -> PageService] = []
    private let lock = NSLock()

    public init() {
        self.register(KVStoreService.self) { KVStore() }
    }

    deinit {
        print("NewChat: PageServiceContainer deinit")
    }

    public func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service) {
        container.inObjectScope(.container).register(serviceType) { _ in
            return factory()
        }
    }

    public func register<Service: PageService>(_ serviceType: Service.Type, factory: @escaping () -> Service) {
        self.append(serviceType)
        container.inObjectScope(.container).register(serviceType) { _ in
            return factory()
        }
    }

    public func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return container.resolve(serviceType) //global
    }

    private func append<Service: PageService>(_ serviceType: Service.Type) {
        lock.lock()
        defer {
            lock.unlock()
        }

        pageServices.append { [unowned self] in
            return self.resolve(serviceType)!
        }
    }

    public func pageInit() {
        self.processLifeCycle { (service) in
            service.pageInit()
        }
    }

    public func pageWillAppear() {
        self.processLifeCycle { (service) in
            service.pageWillAppear()
        }
    }

    public func pageDidAppear() {
        self.processLifeCycle { (service) in
            service.pageDidAppear()
        }
    }

    public func pageDidDisappear() {
        self.processLifeCycle { (service) in
            service.pageDidDisappear()
        }
    }

    public func pageWillDisappear() {
        self.processLifeCycle { (service) in
            service.pageWillDisappear()
        }
    }

    public func pageViewDidLoad() {
        self.processLifeCycle { (service) in
            service.pageViewDidLoad()
        }
    }

    public func pageDeinit() {
        self.processLifeCycle { (service) in
            service.pageDeinit()
        }
    }

    public func beforeFetchFirstScreenMessages() {
        self.processLifeCycle { (service) in
            service.beforeFetchFirstScreenMessages()
        }
    }

    public func afterFirstScreenMessagesRender() {
        self.processLifeCycle { (service) in
            service.afterFirstScreenMessagesRender()
        }
    }

    private func processLifeCycle(_ action: (PageService) -> Void) {
        lock.lock()
        defer {
            lock.unlock()
        }

        pageServices.forEach { provider in
            action(provider())
        }
    }
}
