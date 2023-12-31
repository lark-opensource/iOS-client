//
//  Log+Event.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/3/31.
//

import Foundation

extension Logger {
    /// 日志事件结构体，无法被使用方初始化，仅可在模块内部初始化
    ///
    /// 标注：一般而言，在使用方调用info等日志输出方法时，会构造一个事件对象，参见：@Logger
    struct Event {
        /// 日志标识
        public let label: String
        /// 日志记录的时间，1970年1月1日以来的秒数。浮点类型，小数部分可以精确到ms。
        public let time: TimeInterval
        /// 日志的记录级别，参考 @LogLevel
        public let level: Logger.Level
        /// 日志 Tags 标记
        public let tags: [String]
        /// 日志详细内容
        public let message: Logger.Message
        /// 记录日志发生的线程
        public let thread: String
        /// 记录日志的文件名
        public let file: String
        /// 记录日志的函数名
        public let function: String
        /// 记录日志的所在行号
        public let line: Int
        /// 额外添加的错误，默认为空
        public let error: Error?
        /// 额外添加的附加信息，键值对数据，默认为空
        public let additionalData: [String: String]?
    }
}

extension Logger.Event: CustomStringConvertible {
    public var description: String {
        let file = self.file.components(separatedBy: CharacterSet(charactersIn: "\\/")).last ?? self.file
        let date = Date()
        let formatString = "yyyy-MM-dd HH:mm:ss.SSS +0000"
        let utcTimeZone = TimeZone(abbreviation: "UTC")
        let format = DateFormatter()
        format.dateFormat = formatString
        format.timeZone = utcTimeZone
        let logTime = format.string(from: date)

        var logMessage: String = "\(logTime) \(self.level.levelString) "
            + "[\(file):\(self.line)][\(self.label)]"
            + "[\(self.thread)]"
            + " - \(self.message)\n"

        if let data = self.additionalData {
            logMessage += "    with additional data: \(data)\n"
        }

        if let error = self.error {
            logMessage += "    with error:\(error)\n"
        }

        return logMessage
    }
}
