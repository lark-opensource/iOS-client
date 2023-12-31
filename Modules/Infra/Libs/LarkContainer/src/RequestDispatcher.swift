//
//  RequestDispatcher.swift
//  LarkContainer
//
//  Created by liuwanlin on 2018/4/20.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation

// swiftlint:disable missing_docs

public protocol Request {
    associatedtype Response
}

public struct EmptyResponse {
    public init() {}
}

open class BaseHandler: NSObject {
    public override init() {}
}

open class RequestHandler<T: Request>: BaseHandler {
    open func handle(_ request: T) -> T.Response? {
        fatalError("Must Override")
    }
}

open class PreHook {
    public init() {}

    public func handle<T: Request>(request: T) -> Bool {
        return true
    }
}

public typealias HandlerLoader = () -> BaseHandler

protocol HandlerStorage {
    var instance: BaseHandler? { get set }
}

final class TransientStorage: HandlerStorage {
    var instance: BaseHandler? {
        get { return nil }
        set {}
    }
}

final class PermanentStorage: HandlerStorage {
    var instance: BaseHandler?
}

final class HandlerEntry {
    var storage: HandlerStorage
    var loader: HandlerLoader

    init(storage: HandlerStorage, loader: @escaping HandlerLoader) {
        self.storage = storage
        self.loader = loader
    }
}

open class RequestDispatcher {

    var entries: [String: HandlerEntry] = [:]

    // 请求前的钩子，返回false终止后续流程
    public var preHooks: [PreHook] = []

    private let label: String
    public let userResolver: UserResolver

    public init(userResolver: UserResolver, label: String) {
        self.label = label
        self.userResolver = userResolver
    }

    public func reset() {
        self.entries.forEach { (_, entry) in
            entry.storage.instance = nil
        }
    }

    @discardableResult
    public func register<T: Request>(
        _ type: T.Type,
        loader: @escaping HandlerLoader,
        cacheHandler: Bool = false
    ) -> Bool {
        let key = self.key(for: type)

        if entries[key] != nil {
            assertionFailure("Duplicate loader for [\(key)]")
            return false
        }

        entries[key] = cacheHandler ?
            HandlerEntry(storage: PermanentStorage(), loader: loader) :
            HandlerEntry(storage: TransientStorage(), loader: loader)

        return true
    }

    @discardableResult
    public func send<T: Request>(_ request: T) -> T.Response? {
        let key = self.key(for: T.self)

        guard let handler = getHandler(key) as? RequestHandler<T> else {
            return nil
        }

        for preHook in preHooks {
            if !preHook.handle(request: request) {
                return nil
            }
        }

        return handler.handle(request)
    }

    private func getHandler(_ key: String) -> BaseHandler? {
        guard let entry = entries[key] else {
            return nil
        }

        if let handler = entry.storage.instance {
            return handler
        }

        let handler = entry.loader()
        entry.storage.instance = handler
        return handler
    }

    private func key<T: Request>(for type: T.Type) -> String {
        let key = label + "." + String(describing: type)
        return key
    }
}
