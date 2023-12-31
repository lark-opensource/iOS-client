//
//  ObjectScope.swift
//  SwinjectTest
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import EEAtomic

/// 基础的ObjectScope实现. 也可以作为对应scope的命名空间进行扩展
/// 共享存储使用子类实现，并需要保证线程安全
open class ObjectScope {
    /// called when service entry set the objectScope
    open func attach<Service>(to entry: ServiceEntry<Service>) {}
    /// 默认不提供storage，直接调用
    /// 如果提供共享存储，需要保证线程安全
    open func get<Service, Arguments>(entry: ServiceEntry<Service>, context: ResolverContext<Service, Arguments>) throws -> Service {
        try invoke(entry: entry, arguments: context.arguments(context.resolver))
    }
    /// 提供storage的子类，需要按对应storage进行对应的存储清理，并保证线程安全
    open func reset<Service>(entry: ServiceEntry<Service>) {}
    /// batch reset version
    open func reset(entries: [ServiceEntryProtocol]) {
        for entry in entries { entry.reset() }
    }

    /// helper method for invoke factory to create service
    public func invoke<Service, Arguments>(entry: ServiceEntry<Service>, arguments: Arguments) throws -> Service {
        guard let factory = entry.factory as? ((Arguments) throws -> Service) else {
            #if DEBUG || ALPHA
            fatalError("factory should match \(Arguments.self) -> \(Service.self)")
            #endif
            throw SwinjectError.factoryNotMatch(entry: entry)
        }
        return try factory(arguments)
    }
    public init() {}

    /// 默认Scope为graph
    public static var `default`: ObjectScope { .graph }
    /// Transient scope，resolve同一个service生成同一个对象返回不同的对象。
    public static let transient = ObjectScope()
    /// Graph scope，同一个resolve过程中保证生成同一对象。不同resolve过程生成不同对象。
    public static let graph = GraphObjectScope()
    /// Container scope，container生命周期内，保证resolve同一个service生成同一个对象。
    public static let container = PermanentObjectScope()
}

public final class GraphObjectScope: ObjectScope {
    public final class Storage {
        var innerDic: [ObjectIdentifier: Any] = [:]

        func removeAllObjects() {
            innerDic = [:]
        }
        public subscript(key: ObjectIdentifier) -> Any? {
            get { return innerDic[key] }
            set { innerDic[key] = newValue }
        }

        static var key: String { "SwinjectGraphStorage" }
        // clear by container Resolution finish
        public static var threadLocal: Storage {
            if let result = Thread.current.threadDictionary[Self.key] as? Storage {
                return result
            } else {
                let cache = Storage() // lazy init
                Thread.current.threadDictionary[Self.key] = cache
                return cache
            }
        }
    }
    public override func get<Service, Arguments>(entry: ServiceEntry<Service>, context: ResolverContext<Service, Arguments>) throws -> Service {
        let graph = Storage.threadLocal
        let key = ObjectIdentifier(entry)

        if let value = graph.innerDic[key] as? Service {
            return value
        } else {
            let result = try invoke(entry: entry, arguments: context.arguments(context.resolver))
            graph.innerDic[key] = result
            return result
        }
    }
    public override func reset<Service>(entry: ServiceEntry<Service>) {
        let graph = Storage.threadLocal
        let key = ObjectIdentifier(entry)
        graph.innerDic.removeValue(forKey: key)
    }
    public override func reset(entries: [ServiceEntryProtocol]) {
        let graph = Storage.threadLocal
        for entry in entries {
            graph.innerDic.removeValue(forKey: ObjectIdentifier(entry))
        }
    }
}

public final class PermanentObjectScope: ObjectScope {
    public override func get<Service, Arguments>(entry: ServiceEntry<Service>, context: ResolverContext<Service, Arguments>) throws -> Service {
        guard let storage = entry.storage else {
            #if DEBUG || ALPHA
            fatalError("entry storage should init when create")
            #else
            throw SwinjectError.storageNotFound
            #endif
        }
        return try storage.withLocking { (current) -> Service in
            if let value = current { return value }
            // container持久化的factory需要使用注册相同的container作为输入参数
            let value = try invoke(entry: entry, arguments: context.arguments(context.container ?? context.resolver))
            current = value
            return value
        }
    }
    public override func attach<Service>(to entry: ServiceEntry<Service>) {
        entry.storage = .init(wrappedValue: nil)
    }
    public override func reset<Service>(entry: ServiceEntry<Service>) {
        entry.storage?.wrappedValue = nil
    }
}
