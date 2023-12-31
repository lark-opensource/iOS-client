//
//  Registry.swift
//  LarkStorage
//
//  Created by 7Up on 2023/6/28.
//

import Foundation
import LKLoadable
import LKCommonsLogging

public class CleanRegistry {
    private static let loadableKey = "LarkClean_CleanRegistry"

    public static let logger = Logger.log(CleanRegistry.self, category: "LarkClean.Registry")
}

// MARK: - Register Index

extension CleanRegistry {
    private static var _indexFactories = [String: [CleanIndex.Factory]]()

    internal static var indexFactories: [String: [CleanIndex.Factory]] {
        SwiftLoadable.startOnlyOnce(key: loadableKey)
        return _indexFactories
    }

    /// Registering CleanIndex
    ///
    /// - Parameters:
    ///   - group: group name, attaching to the factory to uniquely identify it in debugging tools and track reports.
    ///   - factory: index factory.
    public static func registerIndexes(forGroup group: String, factory: @escaping CleanIndex.Factory) {
        if _indexFactories[group] == nil {
            _indexFactories[group] = []
        }
        _indexFactories[group]?.append(factory)
    }

    /// Registering CleanIndex.Path
    ///
    /// - Parameters:
    ///   - group: group name, attaching to the factory to uniquely identify it in debugging tools and track reports.
    ///   - factory: path factory
    public static func registerPaths(forGroup group: String, factory: @escaping CleanIndex.PathFactory) {
        registerIndexes(forGroup: group) { ctx in
            return factory(ctx).map { .path($0) }
        }
    }

    /// Registering CleanIndex.Vkey
    ///
    /// - Parameters:
    ///   - group: group name, attaching to the factory to uniquely identify it in debugging tools and track reports.
    ///   - factory: path factory
    public static func registerVkeys(forGroup group: String, factory: @escaping CleanIndex.VkeyFactory) {
        registerIndexes(forGroup: group) { ctx in
            return factory(ctx).map { .vkey($0) }
        }
    }
}

// MARK: - Register Task

/// CleanTask 执行时间超过 30s 会被当做超时处理
public let kTaskTimeout: TimeInterval = 30.0

public enum CleanTaskCompletion {
    case finished
    case failure(Swift.Error)
}

public protocol CleanTaskSubscriber {
    func receive(completion: CleanTaskCompletion)
}

public typealias CleanTaskHandler = (_ context: CleanContext, _ subscriber: CleanTaskSubscriber) -> Void

extension CleanRegistry {

    private static var _taskHandlers = [String: CleanTaskHandler]()

    internal static var taskHandlers: [String: CleanTaskHandler] {
        SwiftLoadable.startOnlyOnce(key: loadableKey)
        return _taskHandlers
    }

    /// Registering CleanTask
    ///
    /// - Parameters:
    ///   - name: name attaching to the handler to uniquely identify it in debugging tools and track reports.
    ///   - handler: custom clean handler
    public static func registerTask(forName name: String, handler: @escaping CleanTaskHandler) {
        _taskHandlers[name] = handler
    }
}

internal extension CleanRegistry {
    /// 避免多次访问会频繁触发 factory
    private static var cachedIndexes: [String: [String: [CleanIndex]]] = [:]

    static func allIndexes(with context: CleanContext, cachedKey: String? = nil) -> [String: [CleanIndex]] {
        if let cachedKey, !cachedKey.isEmpty, let ret = cachedIndexes[cachedKey] {
            return ret
        }
        var ret = [String: [CleanIndex]]()
        for (group, facs) in CleanRegistry.indexFactories {
            if ret[group] == nil {
                ret[group] = []
            }
            let indexes = facs.flatMap { fac -> [CleanIndex] in
                return fac(context)
            }
            ret[group]?.append(contentsOf: indexes)
        }
        if let cachedKey, !cachedKey.isEmpty {
            cachedIndexes[cachedKey] = ret
        }
        return ret
    }
}
