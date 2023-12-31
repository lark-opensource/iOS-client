//
//  CoreAPI.swift
//  Swinject
//
//  Created by SolaWing on 2022/5/31.
//

import Foundation

/// Resolver期间的环境信息
public struct ResolverContextKey: Hashable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public static let oldAPI = ResolverContextKey(rawValue: "oldAPI")
    public static let entryValidator = ResolverContextKey(rawValue: "entryValidator")
}

public class AnyResolverContext {
    public var key: ServiceKey
    /// caller resolver
    public var resolver: Resolver
    /// inner container set after find entry
    public var container: Container?
    private var _storage = [ResolverContextKey: Any]()
    /// 用户扩展属性
    public subscript(key: ResolverContextKey) -> Any? {
        get { return _storage[key] }
        set { _storage[key] = newValue }
    }
    /// same as setter, except return oldValue. nil means new
    public func replace(key: ResolverContextKey, value: Any?) -> Any? {
        if let value {
            return _storage.updateValue(value, forKey: key)
        } else {
            return _storage.removeValue(forKey: key)
        }
    }
    init(key: ServiceKey, resolver: Resolver) {
        self.key = key
        self.resolver = resolver
    }
    // /// 获取当前调用栈对应的ResolverContext
    // public static var current: AnyResolverContext? {
    //     return Thread.current.threadDictionary["Swinject.ResolverContext"] as? AnyResolverContext
    // }
    // /// 替换当前调用栈对应的ResolverContext
    // static func replaceCurrent(with context: AnyResolverContext?) -> AnyResolverContext? {
    //     let old = Thread.current.threadDictionary["Swinject.ResolverContext"]
    //     Thread.current.threadDictionary["Swinject.ResolverContext"] = context
    //     return old as? AnyResolverContext
    // }
}

/// Resolver期间的环境信息，方便信息共享和插件实现
public final class ResolverContext<Service, Arguments>: AnyResolverContext {
    public var arguments: (Resolver) -> Arguments

    // 内部创建结构，可以避免外部创建context和直接调用_resolve. _resolve是扩展实现的核心接口
    init(name: String?, resolver: Resolver, arguments: @escaping (Resolver) -> Arguments) {
        self.arguments = arguments
        super.init(key: ServiceKey(serviceType: Service.self, argumentsType: Arguments.self, name: name),
                   resolver: resolver)
    }

}

/// Resolver核心
/// 限制为AnyObject优化性能
public protocol Resolver: AnyObject {
    /// CoreAPI For Resolver
    ///
    /// - Parameters:
    ///   - name: the optional name for service variant
    ///   - context: the optional context value for plugins
    ///   - arguments: arguments for invoke the resolve
    /// - Returns: Service instance, nil when factory return nil
    /// - Throws: rethrow factory error or internal resolver error
    func _resolve<Service, Arguments>(context: ResolverContext<Service, Arguments>) throws -> Service // swiftlint:disable:this all
}
