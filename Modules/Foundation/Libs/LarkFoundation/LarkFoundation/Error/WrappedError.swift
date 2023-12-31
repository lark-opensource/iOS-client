//
//  WrappedError.swift
//  Lark
//
//  Created by Sylar on 2017/12/11.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

import Foundation

/// Responsible for wrapped two error, and one as the other's meta error.
public final class WrappedError: Error {
    /// Wrapped error
    fileprivate var error: Error

    /// Error Stack
    fileprivate var errStack: [Error] = []

    public init(error: Error) {
        self.error = error
        self.errStack.append(error)
    }

    public init(error: Error, metaError: Error) {
        self.error = error
        self.errStack.append(error)
        if let metaErr = metaError as? WrappedError {
            self.errStack.append(contentsOf: metaErr.errStack)
        } else {
            self.errStack.append(metaError)
        }
    }

    /// Create a new WrappedError by mapping `Error` using `transform`.
    ///
    /// - parameter transform: A function used to create new `Error` using `underlyingError`
    ///
    /// - returns: A new WrappedError
    public func map(_ transform: (_ underlyingError: Error) -> Error) -> WrappedError {
        return WrappedError(error: transform(self.underlyingError), metaError: self)
    }

    /// Push a error into current wrapped error, and push the underlying error into error stack
    ///
    /// - parameter error: Error to push and wrap
    ///
    /// - returns: WrappedError with new underlying error and error stack
    public func push(error: Error) -> WrappedError {
        if let wrappedErr = error as? WrappedError {
            self.error = wrappedErr.underlyingError
            self.errStack.insert(contentsOf: wrappedErr.errStack, at: 0)
        } else {
            self.error = error
            self.errStack.insert(error, at: 0)
        }
        return self
    }

    /// Push a error into current wrapped error, and push the underlying error into error stack
    ///
    /// - parameter error: Error to push and wrap
    /// - parameter transform: A function used to create new `Error` using `underlyingError`
    ///
    /// - returns: WrappedError with new underlying error and error stack
    public func push(_ transform: (_ underlyingError: Error) -> Error) -> WrappedError {
        return self.push(error: transform(self.error))
    }
}

// MARK: - Adapt Error

public extension Error {
    var underlyingError: Error { return (self as? WrappedError)?.error ?? self }
    var metaErrorStack: [Error] { return (self as? WrappedError)?.errStack ?? [] }

    /// Wrap the Error to a new WrappedError
    ///
    /// - parameter transform: A function used to create new `Error` using `underlyingError`
    ///
    /// - returns: A new WrappedError
    func wrapped(_ transform: (_ underlyingError: Error) -> Error) -> WrappedError {
        return WrappedError(error: transform(self.underlyingError), metaError: self)
    }

    func asWrappedError() -> WrappedError {
        if let err = self as? WrappedError {
            return err
        } else {
            return WrappedError(error: self)
        }
    }
}

// MARK: - LocalizedError

extension WrappedError: LocalizedError {
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        return self.description
    }

    /// A localized message describing the reason for the failure.
    //    public var failureReason: String? { get }

    /// A localized message describing how one might recover from the failure.
    //    public var recoverySuggestion: String? { get }

    /// A localized message providing "help" text if the user requests help.
    //    public var helpAnchor: String? { get }
}

// MARK: - CustomStringConvertible

/* Description Print Example:
 [Error| APIError: 未知的业务错误类型(RustSDk)
 Error Stack:
    0.APIError -> 未知的业务错误类型(RustSDk)
    1.RCError -> 业务错误，ErrorCode: 0, DebugMessage: validate code failed: err_code= Normal(BadRequest), DisplayMessage: 验证码错误，请重新输入]
 */
extension WrappedError: CustomStringConvertible {
    public var description: String {
        var errs: [String] = []
        for (idx, err) in self.errStack.enumerated() {
            errs.append("    \(idx).\(type(of: err)) -> \(err)")
        }
        let error = self.underlyingError
        return " \(type(of: error)): \(error)\n Error Stack:\n\(errs.joined(separator: "\n"))"
    }
}

// MARK: - CustomDebugStringConvertible

extension WrappedError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}
