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

public protocol Request {
    var requestID: String { get }
    var method: RequestMethod { get }
    var endpoint: String { get }
    var parameters: [String: Any] { get }
    var headers: [String: String] { get }
    var catchError: Bool { get }

    associatedtype ResponseType: MinutesResponseType
}

public extension Request {
    var method: RequestMethod { return .get }
    var headers: [String: String] { return [:] }
    var customHeaders: [String: String] {
        var headerParams = self.headers
        headerParams["reqeust-id"] = requestID
        return headerParams
    }
    var catchError: Bool {
        return false
    }
}

public protocol UploadRequest: Request {
    var objectToken: String { get }
    var segID: Int { get }
    var payload: Data { get }
}

public extension UploadRequest {
    var method: RequestMethod { return .post }
}
