//
//  VCError+Rust.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/9/16.
//

import Foundation
import ByteViewNetwork

extension Error {
    func toErrorCode() -> Int? {
        if let error = self as? RustBizError {
            return error.code
        }
        if let error = self as? VCError {
            return error.code
        }
        return nil
    }

    func toVCError() -> VCError {
        VCError(error: self)
    }

    func toRustError() -> RustBizError? {
        if let error = self as? RustBizError {
            return error
        }
        if let error = self as? VCError, let e = error.rustError {
            return e
        }
        return nil
    }
}
