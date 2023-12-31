//
//  ShortcutActionBody.swift
//  LarkShortcut
//
//  Created by kiri on 2023/12/8.
//

import Foundation
import SuiteCodable

/// body support
public protocol ShortcutActionBody {
    static var actionId: ShortcutAction.Identifier { get }
}

public extension ShortcutActionBody {
    func toAction(options: ShortcutAction.Options = .none) -> ShortcutAction {
        ShortcutAction(id: Self.actionId, body: self, options: options)
    }
}

public extension ShortcutAction {
    init(id: Identifier, body: Any, options: Options = .none) {
        var params: [String: Any] = [:]
        if let obj = body as? Encodable, let dict = try? DictionaryEncoder().encode(obj) {
            params = dict
        }
        params[ShortcutAction.bodyParamName] = body
        self.init(id: id, parameters: params, options: options, descriptionForParameters: "\(body)")
    }

    /// 使用类型做入参时的便利方法
    var body: Any? {
        parameters[ShortcutAction.bodyParamName]
    }

    fileprivate static let bodyParamName = "__body"
}

public extension Shortcut {
    init(name: String, actions: [ShortcutActionBody]) {
        self.init(name: name, actions: actions.map({ $0.toAction() }))
    }
}

public extension Array where Element == ShortcutAction {
    mutating func append(_ body: ShortcutActionBody, options: ShortcutAction.Options = .none) {
        self.append(body.toAction(options: options))
    }

    mutating func insert(_ body: ShortcutActionBody, at i: Int, options: ShortcutAction.Options = .none) {
        self.insert(body.toAction(options: options), at: i)
    }
}

public extension ShortcutClient {
    func run(_ body: ShortcutActionBody, options: ShortcutAction.Options = .none, completion: ((Result<Any, Error>) -> Void)? = nil) {
        run(body.toAction(options: options), completion: completion)
    }
}
