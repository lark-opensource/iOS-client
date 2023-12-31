//
//  ShortcutHandler.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation
import SuiteCodable

public protocol ShortcutHandler: AnyObject {
    /// 默认实现返回true/
    func canHandleShortcutAction(context: ShortcutActionContext) -> Bool
    func handleShortcutAction(context: ShortcutActionContext, completion: @escaping (Result<Any, Error>) -> Void)
}

public extension ShortcutHandler {
    func canHandleShortcutAction(context: ShortcutActionContext) -> Bool {
        true
    }
}

public final class ShortcutActionContext {
    public let action: ShortcutAction
    private weak var task: ShortcutTask?

    init(action: ShortcutAction, task: ShortcutTask) {
        self.action = action
        self.task = task
    }
}

public extension ShortcutActionContext {
    /// 方便ShortcutHandler使用
    func parameter(_ key: String) -> Any? {
        if let value = self.action.parameters[key] {
            return value
        }
        return self.task?.userInfo[key]
    }

    func bool(_ key: String, defaultValue: Bool = false) -> Bool {
        if let value = self.parameter(key) as? Bool {
            return value
        }
        return defaultValue
    }

    func int(_ key: String, defaultValue: Int = 0) -> Int {
        if let value = self.parameter(key) as? Int {
            return value
        }
        return defaultValue
    }

    func string(_ key: String) -> String? {
        parameter(key) as? String
    }

    func updateContext(_ value: Any?, forKey key: String) {
        self.task?.userInfo[key] = value
    }

    var previousActionResults: [ShortcutResponse.ActionResult] {
        self.task?.actionResults ?? []
    }

    var fromSource: String {
        self.task?.token ?? ""
    }

    subscript(key: String) -> Any? {
        get { parameter(key) }
        set { updateContext(newValue, forKey: key) }
    }

    func decodeParameters<T: Decodable>(to type: T.Type) throws -> T {
        var params = action.parameters
        if let userInfo = self.task?.userInfo {
            params.merge(userInfo, uniquingKeysWith: { old, _ in old })
        }
        let decoder = DictionaryDecoder()
        decoder.decodeTypeStrategy = .loose
        return try decoder.decode(T.self, from: params)
    }
}
