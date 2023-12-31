//
//  Container.swift
//  SwinjectTest
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import EEAtomic

/// https://bytedance.feishu.cn/wiki/V7pywAkyWi7q1SkHcgTcO24SnId
///
/// The `Container` class represents a dependency injection container, which stores registrations of services
/// and retrieves registered services with dependencies injected.
///
/// **Example to register:**
///
///     let container = Container()
///     container.register(A.self) { _ in B() }
///     container.register(X.self) { r in Y(a: r.resolve(A.self)!) }
///
/// **Example to retrieve:**
///
///     let x = container.resolve(X.self)!
///
/// where `A` and `X` are protocols, `B` is a type conforming `A`, and `Y` is a type conforming `X`
/// and depending on `A`.
public final class Container: Resolver {
    // TODO: 考虑优化锁，是否可以提供批量注册的无锁版本? 但要注意避免无锁版本被持有导致的冲突问题..
    private var _services = [ServiceKey: ServiceEntryProtocol]()
    private let parent: Container?

    private func getServices(key: ServiceKey) -> ServiceEntryProtocol? {
        enum Either {
        case service(ServiceEntryProtocol?)
        case wait(DispatchSemaphore)
        }
        while true {
            let ret = rwlock.withRDLocking {
                if !canCallResolve {
                    #if DEBUG || ALPHA
                    if String(describing: key.serviceType) == "AccountServiceUG", Thread.isMainThread {
                        print("[Container] should migrate AccountServiceUG")
                        return Either.service(_services[key])
                    }
                    fatalError("can not resolve \(key.serviceType) before All all assembler loaded, please contact commiter to fix (assemble初始化完成之前不能调用resove,清联系对应resolve代码调用的提交者修改)")
                    #endif
                    // 集成是在主线程，所以主线程不能等待避免死锁
                    if let _waitCanResolve {
                        if Thread.isMainThread {
                            print("[ERROR][Container] resolve in mainThread before canResolve \(key.serviceType)")
                        } else {
                            return Either.wait(_waitCanResolve)
                        }
                    }
                }
                return Either.service(_services[key])
            }
            switch ret {
            case .service(let v):
                return v
            case .wait(let v):
                // 这里都是极端还没有集成的场景，也打印不了日志..
                print("[ERROR][Container] wait \(key.serviceType)")
                v.wait()
                v.signal() // 不消耗count, 只是等待一次性的信号，保证多线程正常等待
                // new loop and retry get
            }
        }
    }
    private func getServicesRecursively(key: ServiceKey) -> (ServiceEntryProtocol, Container)? {
        if let v = getServices(key: key) { return (v, self) }
        return parent?.getServicesRecursively(key: key)
    }

    private var _canCallResolve = true
    private var _waitCanResolve: DispatchSemaphore? {
        didSet {
            if let oldValue, oldValue != _waitCanResolve {
                oldValue.signal()
            }
        }
    }
    public var canCallResolve: Bool {
        get { _canCallResolve }
        set {
            rwlock.withWRLocking {
                if _canCallResolve == newValue { return }
                _canCallResolve = newValue
                if newValue {
                    self._waitCanResolve = nil
                } else {
                    _waitCanResolve = DispatchSemaphore(value: 0)
                }
            }
        }
    }
    fileprivate let rwlock = RWLock()

    /// Instantiates a `Container`
    ///
    /// - Parameters
    ///     - parent: The optional parent `Container`.
    public init(parent: Container? = nil) {
        self.parent = parent
    }

    /// Lark环境可以不用调用，Container默认线程安全
    /// 但非Lark环境可能需要注意和开源库兼容
    public func synchronize() -> Resolver { return self }

    /// Discards instances for services registered in the given `ObjectsScope`. It performs the same operation
    ///
    /// **Example usage:**
    ///     container.resetObjectScope(.container)
    ///
    /// - Parameters:
    ///     - objectScope: All instances registered in given `ObjectsScope` will be discarded.
    public func resetObjectScope(_ objectScope: ObjectScope) {
        let entries = rwlock.withRDLocking {
            _services.values.filter { $0.objectScope === objectScope }
        }
        objectScope.reset(entries: entries)
        // 和原实现兼容，parent也一起重置
        parent?.resetObjectScope(objectScope)
    }
}

// MARK: Register
extension Container {
    // 注册和获取时需要注意按类型严格匹配..
    // TODO: 考虑是否提供UserResolver的Register接口
    /// 提供给外部插件使用的原始接口. factory的第一个参数需要是Resolver才能正常匹配
    public func _register<Service, Arguments>( // swiftlint:disable:this all
        _ serviceType: Service.Type,
        name: String?,
        inObjectScope scope: ObjectScope? = nil,
        factory: @escaping (Arguments) throws -> Service
    ) -> ServiceEntry<Service> {
        let key = ServiceKey(serviceType: serviceType,
                             argumentsType: Arguments.self,
                             name: name)
        let entry = ServiceEntry(serviceType: serviceType,
                                 argumentsType: Arguments.self,
                                 factory: factory)
        if let scope = scope {
            entry.inObjectScope(scope)
        }
        rwlock.withWRLocking {
            _services[key] = entry
        }
        return entry
    }
}

// MARK: Resolve
extension Container {
    public func _resolve<Service, Arguments>(context: ResolverContext<Service, Arguments>) throws -> Service { // swiftlint:disable:this all
        // swiftlint:disable force_try
        // let old = AnyResolverContext.replaceCurrent(with: context)
        do {
            try incrementResolutionDepth()
        } catch {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            throw error
            #endif
        }
        defer {
            #if DEBUG || ALPHA
            do {
                try decrementResolutionDepth()
            } catch {
                fatalError("unexpected decrementResolutionDepth exception: \(error)")
            }
            #else
            try? decrementResolutionDepth()
            #endif
            // AnyResolverContext.replaceCurrent(with: old) // restore old context
        }
        // swiftlint:enable force_try

        let key = context.key
        guard case let (entry as ServiceEntry<Service>, container)? = getServicesRecursively(key: key) else {
            throw SwinjectError.noMatchEntry(key: key)
        }
        context.container = container
        // 让外部可以注入验证逻辑，可以拦截不符号预期的调用..
        if let validator = context[.entryValidator] as? (ServiceEntry<Service>) throws -> Void {
            try validator(entry)
        }

        return try entry.objectScope.get(entry: entry, context: context)
    }
}

// MARK: GraphScope
extension Container {
    fileprivate var maxResolutionDepth: Int { return 200 }

    static var resolutionDepthThreadDicKey: String {
        "SwinjectResolutionDepthThreadDicKey"
    }

    var resolutionDepth: Int {
        get { (Thread.current.threadDictionary[Self.resolutionDepthThreadDicKey] as? Int) ?? 0 }
        set { Thread.current.threadDictionary[Self.resolutionDepthThreadDicKey] = newValue }
    }

    var cachedGraphObjects: GraphObjectScope.Storage { GraphObjectScope.Storage.threadLocal }

    func incrementResolutionDepth() throws {
        // depth取的线程local变量。所以即时有多个container，深度也是共享的。最外层的调用结束才算resolve结束。
        // 主要用于Graph的Storage，一次Resolve中共享instance
        let resolutionDepth = self.resolutionDepth
        #if DEBUG || ALPHA
        if resolutionDepth == 0, case let graph = cachedGraphObjects, !graph.innerDic.isEmpty {
            fatalError("graph storage should be empty when resolutionDepth is 0")
            graph.removeAllObjects()
        }
        #endif
        guard resolutionDepth < maxResolutionDepth else {
            throw SwinjectError.maxResolutionDepth
        }
        self.resolutionDepth = resolutionDepth + 1
    }

    func decrementResolutionDepth() throws {
        let resolutionDepth = self.resolutionDepth
        guard resolutionDepth > 0 else {
            throw SwinjectError.depthCannotBeNegative
        }

        self.resolutionDepth = resolutionDepth - 1
        if resolutionDepth - 1 == 0 {
            let graph = cachedGraphObjects
            if Thread.current === Thread.main {
                let allValues = graph.innerDic
                if !allValues.isEmpty {
                    graph.removeAllObjects()
                    DispatchQueue.global().async { _ = allValues }
                }
            } else {
                graph.removeAllObjects()
            }
        }
    }
}

public enum SwinjectError: Error {
    // - call Error
    case noMatchEntry(key: ServiceKey)
    case maxResolutionDepth
    // - fatal Error
    case depthCannotBeNegative
    case factoryNotMatch(entry: ServiceEntryProtocol) // key都匹配上了话，factory没理由不匹配
    case storageNotFound
}
