//
//  Shortcut.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation

/// 快捷指令
public struct Shortcut {
    public var name: String
    public var actions: [ShortcutAction]

    public init(name: String, actions: [ShortcutAction]) {
        self.name = name
        self.actions = actions
    }
}

/// 操作
public struct ShortcutAction {
    /// 操作的唯一标识,用来选择Handler,比如"vc.startMeeting"
    public var id: Identifier
    /// 参数
    public var parameters: [String: Any]
    /// 操作选项，提供一些执行策略的参数
    public var options: Options
    /// 用来覆盖打印到日志的参数内容，nil则打印所有参数。
    public var descriptionForParameters: String?

    public init(id: Identifier, parameters: [String: Any] = [:], options: Options = .none, descriptionForParameters: String? = nil) {
        self.id = id
        self.parameters = parameters
        self.options = options
        self.descriptionForParameters = descriptionForParameters
    }

    public struct Identifier: Hashable, Codable, CustomStringConvertible {
        private let rawValue: String

        public init(from decoder: Decoder) throws {
            self.rawValue = try decoder.singleValueContainer().decode(String.self)
        }

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public var description: String {
            rawValue
        }
    }

    public struct Options {
        public var delay: TimeInterval = 0
        public var timeout: TimeInterval = 0 // <= 0: 不会超时
        public var nextOnError: Bool = false

        public static let none = Options()
    }
}

extension ShortcutAction: CustomStringConvertible {
    public var description: String {
        "ShortcutAction(id: \(id), parameters: \(descriptionForParameters ?? parameters.description)), options: \(options))"
    }
}

extension ShortcutAction.Options: CustomStringConvertible {
    public var description: String {
        var options: [String] = []
        if delay != 0 {
            options.append("delay: \(delay)")
        }
        if timeout != 0 {
            options.append("timeout: \(timeout)")
        }
        if nextOnError {
            options.append("nextOnError: \(nextOnError)")
        }
        return "[\(options.joined(separator: ", "))]"
    }
}
