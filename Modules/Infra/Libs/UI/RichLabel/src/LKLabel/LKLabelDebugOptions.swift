//
//  LKLabelDebugOptions.swift
//  RichLabel
//
//  Created by qihongye on 2019/2/19.
//

import Foundation

public protocol LKLabelLogger {
    func debug(_ message: String, error: Error?, file: String, method: String, line: Int)
    func info(_ message: String, error: Error?, file: String, method: String, line: Int)
    func error(_ message: String, error: Error?, file: String, method: String, line: Int)
}

extension LKLabelLogger {
    func debug(_ message: String, error: Error? = nil, file: String = #fileID, method: String = #function, line: Int = #line) {
        self.debug(message, error: error, file: file, method: method, line: line)
    }

    func info(_ message: String, error: Error? = nil, file: String = #fileID, method: String = #function, line: Int = #line) {
        self.info(message, error: error, file: file, method: method, line: line)
    }

    func error(_ message: String, error: Error? = nil, file: String = #fileID, method: String = #function, line: Int = #line) {
        self.error(message, error: error, file: file, method: method, line: line)
    }
}

public enum LKLabelDebugOptions {
    case logger(LKLabelLogger)

    public var key: Int {
        switch self {
        case .logger:
            return 0
        }
    }
}

extension Array where Iterator.Element == LKLabelDebugOptions {
    func lastMatch(_ targetKey: Int) -> Iterator.Element? {
        if isEmpty {
            return nil
        }
        return self.last(where: { $0.key == targetKey })
    }
}

public extension Array where Iterator.Element == LKLabelDebugOptions {
    var logger: LKLabelLogger? {
        guard let item = lastMatch(0),
            case .logger(let logger) = item else {
                return nil
        }
        return logger
    }
}

struct LKLabelLoggerImpl: LKLabelLogger {
    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }

    private func formatDetailInfo(file: String, method: String, line: Int) -> String {
        return "[\(sourceFileName(filePath: file))]:\(line) \(method)"
    }

    func debug(_ message: String, error: Error?, file: String, method: String, line: Int) {
        var errorMsg = ""
        if let error = error {
            errorMsg = "| With error: \(error)"
        }
        print("[debug] \(formatDetailInfo(file: file, method: method, line: line)) ==> ", message, errorMsg)
    }

    func info(_ message: String, error: Error?, file: String, method: String, line: Int) {
        var errorMsg = ""
        if let error = error {
            errorMsg = "| With error: \(error)"
        }
        print("[info] \(formatDetailInfo(file: file, method: method, line: line)) ==> ", message, errorMsg, formatDetailInfo(file: file, method: method, line: line))
    }

    func error(_ message: String, error: Error?, file: String, method: String, line: Int) {
        var errorMsg = ""
        if let error = error {
            errorMsg = "| With error: \(error)"
        }
        print("[error] \(formatDetailInfo(file: file, method: method, line: line)) ==> ", message, errorMsg)
    }
}
