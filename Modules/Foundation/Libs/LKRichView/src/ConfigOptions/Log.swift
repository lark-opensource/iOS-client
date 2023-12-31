//
//  Log.swift
//  LKRichView
//
//  Created by qihongye on 2021/8/31.
//

import Foundation

public protocol Log {
    func debug(id: String?, message: String, params: [String: Any]?)
    func info(id: String?, message: String, params: [String: Any]?)
    func warn(id: String?, message: String, params: [String: Any]?)
    func error(id: String?, message: String, params: [String: Any]?)
}

struct Logger: Log {
    func debug(id: String?, message: String, params: [String: Any]?) {
        log(level: "debug", id: id, message: message, params: params)
    }

    func info(id: String?, message: String, params: [String: Any]?) {
        log(level: "info", id: id, message: message, params: params)
    }

    func warn(id: String?, message: String, params: [String: Any]?) {
        log(level: "warn", id: id, message: message, params: params)
    }

    func error(id: String?, message: String, params: [String: Any]?) {
        log(level: "error", id: id, message: message, params: params)
    }

    private func log(level: String, id: String?, message: String, params: [String: Any]?) {
        var idStr = ""
        if let id = id {
            idStr = " \(id)"
        }
        print("[\(level)\(idStr)] message: \(message), params: \(params ?? [:])")
    }
}
