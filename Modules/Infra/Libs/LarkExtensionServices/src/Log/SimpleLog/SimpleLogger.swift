//
//  SimpleLogger.swift
//  LarkExtensionServices
//
//  Created by Yaoguoguo on 2023/2/15.
//

import Foundation
import RustSimpleLogSDK

/// 自己封装.a成为xcframework，需要自己手动更新
class SimpleLog {
    private var lock = NSLock()
    private var simplelogPtr: SimpleLoggerPtr?

    init(path: String, name: String, version: String) {
        var fileName = name
        if fileName.data(using: .utf8)?.count ?? 0 > 16 {
            assertionFailure("超过name限制16字节")
            fileName = "extension"
        }

        let ptr = UnsafeMutablePointer<SimpleLoggerPtr?>.allocate(capacity: 1)
        let result = lark_simplelog_new(path, fileName, version, ptr)
        if result.rawValue == 0 {
            simplelogPtr = ptr.pointee
        }
    }

    deinit {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard simplelogPtr != nil else {
            return
        }
        lark_simplelog_close(simplelogPtr)
    }

    func write(msg: String) {
        guard simplelogPtr != nil else {
            return
        }
        let data = Date().timeIntervalSince1970
        let infoMsg = msg
        lock.lock()
        defer {
            lock.unlock()
        }
        infoMsg.withCString { ptr in
            lark_simplelog_desensitize_str(UnsafeMutablePointer(mutating: ptr), infoMsg.data(using: .utf8)?.count ?? 0)
            lark_simplelog_write2(simplelogPtr, Int64(data), infoMsg, infoMsg.data(using: .utf8)?.count ?? 0)
        }
    }

    func flush() {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard simplelogPtr != nil else {
            return
        }
        lark_simplelog_flush(simplelogPtr)
    }
}
