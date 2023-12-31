//
//  SendHttpRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Basic_V1_SendHttpRequest
public struct SendHttpRequest {
    public static let command: NetworkCommand = .rust(.sendHTTP)
    public typealias Response = SendHttpResponse

    public init(url: String, method: Method, headers: [String: String] = [:], body: Data? = nil, timeout: Int32? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }

    /// If host_alias is set, the host of url will be replaced by rust.
    public var url: String

    public var method: Method

    public var headers: [String: String]

    /// request body
    public var body: Data?

    /// 如果为空，则默认使用 sdk 的超时机制。
    public var timeout: Int32?

    public enum Method: Int, Hashable {
        case get = 1
        case post // = 2
        case delete // = 3
        case put // = 4
        case patch // = 5
    }
}

/// Basic_V1_SendHttpResponse
public struct SendHttpResponse {

    public var status: Status

    public var headers: [String: String]

    public var httpStatusCode: Int32

    /// response body
    public var body: Data

    public enum Status: Int {
        /// 返回正常的 http status code
        case normal = 1
        case timeout // = 2
        case unknownError // = 3
    }
}

extension SendHttpRequest: RustRequestWithResponse {
    typealias ProtobufType = Basic_V1_SendHttpRequest

    func toProtobuf() throws -> Basic_V1_SendHttpRequest {
        var request = Basic_V1_SendHttpRequest()
        request.url = url
        if let m = Basic_V1_SendHttpRequest.Method(rawValue: method.rawValue) {
            request.method = m
        }
        request.headers = headers
        if let body = self.body {
            request.body = body
        }
        if let timeout = self.timeout {
            request.timeout = timeout
        }
        return request
    }
}

extension SendHttpResponse: RustResponse {
    typealias ProtobufType = Basic_V1_SendHttpResponse

    init(pb: Basic_V1_SendHttpResponse) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknownError
        self.headers = pb.headers
        self.httpStatusCode = pb.httpStatusCode
        self.body = pb.body
    }
}
