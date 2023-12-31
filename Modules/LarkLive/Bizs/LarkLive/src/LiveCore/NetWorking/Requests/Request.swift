//
//  Request.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public enum RequestMethod {
    case get
    case post
}

public protocol LarkLiveRequest {
    var requestID: String { get }
    var method: RequestMethod { get }
    var endpoint: String { get }
    var parameters: [String: Any] { get }
    var headers: [String: String] { get }

    associatedtype ResponseType: LiveResponseType
}

public extension LarkLiveRequest {
    var method: RequestMethod { return .get }
    var headers: [String: String] { return [:] }
    var customHeaders: [String: String] {
        var headerParams = self.headers
        headerParams["reqeust-id"] = requestID
        return headerParams
    }
}

public protocol VerifyRequest: LarkLiveRequest {
    var requestID: String { get }
    var method: RequestMethod { get }
    var endpoint: String { get }
    var parameters: [String: Any] { get }
    var headers: [String: String] { get }
    associatedtype ResponseType: LiveResponseType
}

public extension VerifyRequest {
    var method: RequestMethod { return .get }
}
