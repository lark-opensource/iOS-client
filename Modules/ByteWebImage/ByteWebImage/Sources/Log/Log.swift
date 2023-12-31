//
//  Log.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/13.
//

import Foundation

extension WebImage {

    /// 日志输出类
    public enum Log {

        // https://cloud.tencent.com/developer/article/1692043
        /// 日志等级
        ///
        /// 由于图片请求通常非常频繁，一次``ImageRequest``的完整流程通常只会有最终回调结果，
        /// 不会有 ``WebImage/Log/Level-swift.enum/debug`` 以上级别的日志记录。
        /// ``WebImage/Log/Level-swift.enum/info`` 以上级别的日志只会用于图片库生命周期的信息。
        /// - Note: 推荐设置默认值为 ``WebImage/Log/Level-swift.enum/info``
        public enum Level: Int, Comparable {
            /// 关闭
            case off
            /// 严重错误
            case fatal
            /// 错误
            case error
            /// 警告
            case warning
            /// 信息
            case info
            /// 测试
            case debug
            /// 痕迹
            case trace
            /// 全部
            case all

            public static func < (lhs: WebImage.Log.Level, rhs: WebImage.Log.Level) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }

        /// 日志输出等级(等级越高，输出内容越少)
        public static var level: Level = .info

        public typealias Handler = (_ level: Level, _ desc: String, _ file: String, _ function: String, _ line: Int) -> Void

        /// 日志处理回调
        /// - Note: 默认操作是在 DEBUG 环境下打印 desc 到控制台。如果重写此值，不提供默认打印控制台功能
        public static var handler: Handler = { _, desc, file, function, line in
#if DEBUG
            print(desc, "file: \(file), func: \(function), line: \(line)")
#endif
        }
    }
}

typealias Log = WebImage.Log

extension Log {

    /// 仅用于图片库生命周期
    static func fatal(_ info: String, _ arguments: CVarArg..., file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, arguments, level: .fatal, file: file, function: function, line: line)
    }

    /// 仅用于图片库生命周期
    static func error(_ info: String, _ arguments: CVarArg..., file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, arguments, level: .error, file: file, function: function, line: line)
    }

    /// 仅用于图片库生命周期
    static func warning(_ info: String, _ arguments: CVarArg..., file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, arguments, level: .warning, file: file, function: function, line: line)
    }

    /// 仅用于图片库生命周期
    static func info(_ info: String, _ arguments: CVarArg..., file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, arguments, level: .info, file: file, function: function, line: line)
    }

    /// 可用于图片请求流程
    static func debug(_ info: String, _ arguments: CVarArg..., file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, arguments, level: .debug, file: file, function: function, line: line)
    }

    /// 可用于图片请求流程
    static func trace(_ info: String, _ arguments: CVarArg..., file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, arguments, level: .trace, file: file, function: function, line: line)
    }

    private static func log(_ info: String, _ arguments: CVarArg..., level: Level, file: String, function: String, line: Int) {
        guard level.rawValue <= self.level.rawValue else {
            return
        }
        var desc = String(format: info, arguments)
        desc = "[Image][" + "\(level)".capitalized + "] \(desc)"
        handler(level, desc, file, function, line)
    }
}

// Currently, `Variadic parameter cannot have a default value` in Swift
// So we provide functions without the arguments parameter to avoid the annoying `arguments:` completion
extension Log {

    /// 仅用于图片库生命周期
    static func fatal(_ info: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, level: .fatal, file: file, function: function, line: line)
    }

    /// 仅用于图片库生命周期
    static func error(_ info: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, level: .error, file: file, function: function, line: line)
    }

    /// 仅用于图片库生命周期
    static func warning(_ info: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, level: .warning, file: file, function: function, line: line)
    }

    /// 仅用于图片库生命周期
    static func info(_ info: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, level: .info, file: file, function: function, line: line)
    }

    /// 可用于图片请求流程
    static func debug(_ info: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, level: .debug, file: file, function: function, line: line)
    }

    /// 可用于图片请求流程
    static func trace(_ info: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(info, level: .trace, file: file, function: function, line: line)
    }
}
