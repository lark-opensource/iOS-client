//
//  RouterError.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/11.
//

import Foundation

public final class RouterError: Error {
    /// Error message
    public let message: String
    /// Error code
    public let code: Int

    public private(set) var openType: OpenType = .none

    public private(set) var url: String?

    public private(set) var fromViewController: String?

    /// Error stack, contains all the error
    public private(set) var stack: [Error] = []
    /// Top most error of error stack
    public var current: Error {
        return stack.last ?? self
    }

    public init(code: Int, message: String = "") {
        self.code = code
        self.message = message
    }

    /// Append error to the error stack
    ///
    /// - Parameter error: error
    public func append(_ error: Error) {
        self.stack.append(error)
    }
}

extension RouterError: CustomStringConvertible {
    public var description: String {
        return "Router Error, error code: \(code), messge: \(message), url: \(url?.base64 ?? ""), openType: \(openType), fromViewController: \(String(describing: fromViewController))"
    }
}

extension RouterError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self)"
    }
}

extension RouterError {
    /// Empty error to hold other errors
    public static var empty: RouterError {
        return RouterError(code: 10_000, message: "empty")
    }
    /// The request isn't handled by any routes or middlewares
    public static var notHandled: RouterError {
        return RouterError(code: 10_001, message: "not handled, no middleware or route can match the request")
    }
    /// The request redirects too many times
    public static var tooManyRedirects: RouterError {
        return RouterError(code: 10_002, message: "too many redirects, redirects over maximum")
    }
    /// Some parameters are invalid
    public static func invalidParameters(_ key: String) -> RouterError {
        return RouterError(code: 10_003, message: "parameter [\(key)] is invalid")
    }
}

extension RouterError {
    public func patchExtraInfo(with url: String? = nil, from: NavigatorFrom? = nil, naviParams: NaviParams? = nil) -> RouterError {
        self.fromViewController = String(describing: from?.fromViewController)
        self.openType = naviParams?.openType ?? .none
        self.url = url
        return self
    }
}
