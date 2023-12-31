//
//  Looger+Message.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/4/1.
//

import Foundation

extension Logger {
    /// `Logger.Message` 表示一段Log输出的文本。
    ///
    /// 可以用字符串或者字符串插值初始化`Logger.Message`，例如:
    ///
    ///     let world: String = "world"
    ///     let myLogMessage: Logger.Message = "Hello \(world)"
    ///
    /// 一般来说, `Logger.Message`是作为info等方法的参数使用，例如:
    ///
    ///     logger.info("Hello \(world)")
    ///
    public struct Message: ExpressibleByStringLiteral, CustomStringConvertible, ExpressibleByStringInterpolation {
        private var value: String

        public init(stringLiteral value: String) {
            self.value = value
        }

        public var description: String {
            return self.value
        }

        public static func + (left: Message, right: Message) -> Message {
            return .init(stringLiteral: left.value + right.value)
        }
    }
}
