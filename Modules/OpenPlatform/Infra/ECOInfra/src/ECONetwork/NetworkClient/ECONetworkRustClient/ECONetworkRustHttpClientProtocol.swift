//
//  ECONetworkRustHttpClientProtocol.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation


@objc public protocol ECONetworkRustHttpClientProtocol  {

    /// 创建一个 dataTask, 使用方式与 RustHTTPSession dataTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func dataTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkRustTaskProtocol
    
    /// 创建一个 downloadTask, 使用方式与 RustHTTPSession downloadTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func downloadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        cleanTempFile: Bool,
        completionHandler: ((URL?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkRustTaskProtocol
    
    /// 创建一个 downloadTask, 使用方式与 RustHTTPSession downloadTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func uploadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        fromFile fileURL: URL,
        completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkRustTaskProtocol
    
    /// 创建一个 uploadTask, 使用方式与 RustHTTPSession uploadTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func uploadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        from bodyData: Data,
        completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkRustTaskProtocol
    
    /// 完成所有任务, 并使 Client 无效
    func finishTasksAndInvalidate()
    
    /// 直接将 Client 无效
    func invalidateAndCancel()
    
}


