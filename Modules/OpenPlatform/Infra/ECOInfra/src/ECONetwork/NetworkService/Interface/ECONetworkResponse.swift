//
//  ECONetworkResponse.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

public protocol ECONetworkResponseOrigin {
    var bodyData: Data? { get }
    var downloadFileLocation: URL? { get }
    var request: URLRequest { get }
    var response: HTTPURLResponse { get }
}

public struct ECONetworkResponse<ResultType>: ECONetworkResponseOrigin {
    public let statusCode: Int
    /// 请求接口中指定的最终数据结构
    public private(set) var result: ResultType?
    public let request: URLRequest
    public let response: HTTPURLResponse
    public var metrics: ECONetworkMetrics?
    
    /// 未经序列化的原始数据
    public let bodyData: Data?
    public let downloadFileLocation: URL?

    private let trace: OPTrace
    
    // ❗勿对模块外暴露初始化接口, 外部只允许更新操作
    init(
        statusCode: Int,
        request: URLRequest,
        response: HTTPURLResponse,
        trace: OPTrace,
        data: Data? = nil,
        downloadFileLocation: URL? = nil
    ) {
        self.statusCode = statusCode
        self.request = request
        self.response = response
        self.bodyData = data
        self.downloadFileLocation = downloadFileLocation
        self.trace = trace
    }
    
    public mutating func updateResult(result: ResultType) {
        self.result = result

        let log = """
        ECONetwork/request-id/\(trace.getRequestID() ?? ""),
        domain=\(request.url?.host ?? ""),
        path=\(request.url?.path ?? ""),
        info=parse data to \(ResultType.self)
        """
        trace.info(log, tag: ECONetworkLogKey.getResponseEdit)
    }
}
