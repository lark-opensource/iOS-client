//
// Error.swift
//
//
// Created by kef on 2022/4/1.
//

import Foundation

internal struct WbError: Error {
    public let message: String

    static var getLast: WbError {
        let buffer = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: 1)
        wb_error_get_last(buffer)
        let message = String(cString: buffer.pointee!)
        wb_error_destroy(UnsafeMutablePointer(mutating: buffer.pointee!))

        return WbError(message: message)
    }
}

internal func wrap(closure: () -> C_WB_RESULT) {
    if closure() != C_WB_RESULT_OK {
        WbError.getLast.log()
    }
}

internal func wrap_throws(closure: () -> C_WB_RESULT) throws {
    guard closure() == C_WB_RESULT_OK else {
        throw WbError.getLast
    }
}
