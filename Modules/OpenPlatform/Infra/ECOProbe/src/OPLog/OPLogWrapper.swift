//
//  OPTraceLogWrapper.swift
//  ECOProbe
//
//  Created by qsc on 2021/3/30.
//

import UIKit
import LKCommonsLogging


@objc(OPLog)
@objcMembers
final class OPLogWrapper: NSObject {
    private static let shared = OPLogWrapper()

    private let logger = Logger.oplog(self, category: "OPLogWrpper")

    override init() {
        super.init()
    }

    // MARK: - Log internal API

    private func _log( level: LogLevel,
                          _ message: String,
                          tag: String = "",
                          additionalData params: [String: String]? = nil,
                          error: Error? = nil,
                          file: String = #fileID,
                          function: String = #function,
                          line: Int = #line) {
        logger.log(
            level: level,
            message,
            tag: tag,
            additionalData: params,
            error: error,
            file: file,
            function: function,
            line: line)
    }

    // MARK: - Log public API
    public class func debug(_ message: String, file: String, function: String, line: Int) {
        OPLogWrapper.shared._log(level: .debug, message, file: file, function: function, line: line)
    }

    public class func info(_ message: String, file: String, function: String, line: Int) {
        OPLogWrapper.shared._log(level: .info, message, file: file, function: function, line: line)
    }

    public class func warn(_ message: String, file: String, function: String, line: Int) {
        OPLogWrapper.shared._log(level: .warn, message, file: file, function: function, line: line)
    }

    public class func error(_ message: String, file: String, function: String, line: Int) {
        OPLogWrapper.shared._log(level: .error, message, file: file, function: function, line: line)
    }

    public class func fatal(_ message: String, file: String, function: String, line: Int) {
        OPLogWrapper.shared._log(level: .fatal, message, file: file, function: function, line: line)
    }
}
