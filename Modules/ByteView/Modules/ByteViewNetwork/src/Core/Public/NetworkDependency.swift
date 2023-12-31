//
//  NetworkDependency.swift
//  ByteViewNetwork
//
//  Created by kiri on 2022/12/13.
//

import Foundation

public protocol NetworkDependency {
    func sendRequest(request: RawRequest, completion: @escaping (RawResponse) -> Void)
}

public struct RawRequest {
    public let userId: String
    public let contextId: String
    public let command: NetworkCommand
    public let data: Data
    /// 是否保序，会保证同一个Command的请求异步发送的顺序
    public let keepOrder: Bool
    public let contextIdCallback: ((String) -> Void)?

    public init(userId: String, contextId: String, command: NetworkCommand, data: Data,
                keepOrder: Bool, contextIdCallback: ((String) -> Void)?) {
        self.userId = userId
        self.contextId = contextId
        self.command = command
        self.data = data
        self.keepOrder = keepOrder
        self.contextIdCallback = contextIdCallback
    }
}

public struct RawResponse {
    public let contextId: String
    public let result: Result<Data, Error>

    public init(contextId: String, result: Result<Data, Error>) {
        self.contextId = contextId
        self.result = result
    }
}
