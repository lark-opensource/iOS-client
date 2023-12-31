//
//  Request.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation

public enum RequestMethod {
    case get
    case post
    case put
    case delete
}

public protocol Request {
    associatedtype ResponseType: MeegoResponseType

    var method: RequestMethod { get }

    var endpoint: String { get }
    var headers: [String: String] { get }

    var needCommonParams: Bool { get }
    var catchError: Bool { get }

    var parameters: [String: Any] { get }
}

public extension Request {
    var method: RequestMethod { return .get }

    var headers: [String: String] { return [:] }
    var customHeaders: [String: String] {
        var headerParams = self.headers
        return headerParams
    }

    var needCommonParams: Bool {
        return false
    }

    var catchError: Bool {
        return false
    }
}
