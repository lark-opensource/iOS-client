//
//  ShortcutService.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation
import EEAtomic
import LKCommonsLogging

public final class ShortcutService {
    private let userId: String

    @AtomicObject
    private var config: ShortcutConfig
    public init(userId: String, config: ShortcutConfig) {
        self.userId = userId
        self.config = config
        Logger.shortcut.info("init ShortcutService(\(userId)), config = \(config)")
    }

    deinit {
        Logger.shortcut.info("deinit ShortcutService(\(userId)), userId = \(self.userId)")
    }

    public func updateConfig(_ config: ShortcutConfig) {
        self.config = config
        Logger.shortcut.info("ShortcutService(\(userId)) updateConfig: \(config)")
    }

    public func getClient(_ token: ShortcutBizToken) -> ShortcutClient {
        ShortcutClient(token: token.token, service: self)
    }

    private let handlerLock = RWLock()
    private var handlers: [ShortcutAction.Identifier: [HandlerWrapper]] = [:]
    public func registerHandler(_ handler: ShortcutHandler, for id: ShortcutAction.Identifier, isWeakReference: Bool = false) {
        handlerLock.withWRLocking {
            var cache = handlers[id, default: []]
            cache.removeAll(where: { $0.ref == nil })
            cache.append(HandlerWrapper(handler, isWeakReference))
            handlers[id] = cache
        }
    }

    public func unregisterHandler(_ handler: ShortcutHandler, for id: ShortcutAction.Identifier) {
        handlerLock.withWRLocking {
            var cache = handlers[id, default: []]
            cache.removeAll(where: { $0.ref == nil || $0.ref === handler })
            handlers[id] = cache.isEmpty ? nil : cache
        }
    }

    private func findHandler(token: String, context: ShortcutActionContext) throws -> ShortcutHandler {
        let config = self.config
        let actionId = context.action.id
        if config.actionConfig.disabledActions.contains(actionId) {
            throw ShortcutError.noPermission
        }
        guard let bizConfig = config.bizConfigs[token], !bizConfig.isDisableAll, !bizConfig.disabledActions.contains(actionId) else {
            throw ShortcutError.noPermission
        }
        let handlers = handlerLock.withRDLocking(action: {
            self.handlers[actionId, default: []].compactMap({ $0.ref })
        })
        for handler in handlers {
            if handler.canHandleShortcutAction(context: context) {
                return handler
            }
        }
        throw ShortcutError.handlerNotFound
    }

    @AtomicObject
    private var tasks: [String: ShortcutTask] = [:]
    fileprivate func sendRequest(token: String, request: ShortcutRequest, completion: ((Result<ShortcutResponse, Error>) -> Void)?) {
        let logContext = ["contextID": request.requestId]
        if request.shortcut.actions.isEmpty {
            Logger.shortcut.info("ShortcutRequest(\(request.requestId)) success, action is empty", additionalData: logContext)
            completion?(.success(ShortcutResponse(request: request)))
            return
        }

        guard let bizConfig = config.bizConfigs[token], !bizConfig.isDisableAll else {
            Logger.shortcut.error("ShortcutRequest(\(request.requestId)) failed, \(token) noPermission", additionalData: logContext)
            completion?(.failure(ShortcutError.noPermission))
            return
        }

        let taskId = "\(request.requestId)-\(Util.uuid())"
        let task = ShortcutTask(taskId: taskId, request: request, token: token, handlerFactory: { [weak self] context in
            guard let self = self else {
                throw ShortcutError.handlerNotFound
            }
            return try self.findHandler(token: token, context: context)
        }, completion: { [weak self] response in
            completion?(response)
            self?.tasks.removeValue(forKey: taskId)
        })
        self.tasks[taskId] = task
        task.start()
    }
}

public final class ShortcutClient {
    private let token: String
    private let service: ShortcutService

    fileprivate init(token: String, service: ShortcutService) {
        self.token = token
        self.service = service
    }

    public func run(_ shortcut: Shortcut, completion: ((Result<ShortcutResponse, Error>) -> Void)? = nil) {
        sendRequest(ShortcutRequest(shortcut: shortcut), completion: completion)
    }

    public func run(_ action: ShortcutAction, completion: ((Result<Any, Error>) -> Void)? = nil) {
        sendRequest(ShortcutRequest(shortcut: Shortcut(name: "\(token).\(action.id)", actions: [action]))) { result in
            guard let completion = completion else { return }
            switch result {
            case .success(let response):
                if let ar = response.actionResults.first {
                    completion(ar.result)
                } else {
                    assertionFailure("actionResults isEmpty, taskId = \(response.request.requestId)")
                    completion(.failure(ShortcutError.unknown))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func sendRequest(_ request: ShortcutRequest, completion: ((Result<ShortcutResponse, Error>) -> Void)? = nil) {
        service.sendRequest(token: token, request: request, completion: completion)
    }
}

private struct HandlerWrapper {
    private let isWeak: Bool
    private var strongRef: ShortcutHandler?
    private weak var weakRef: ShortcutHandler?

    init(_ ref: ShortcutHandler, _ isWeak: Bool) {
        self.isWeak = isWeak
        if isWeak {
            self.weakRef = ref
        } else {
            self.strongRef = ref
        }
    }

    var ref: ShortcutHandler? {
        isWeak ? weakRef : strongRef
    }
}
