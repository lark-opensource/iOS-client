//
//  NetworkClientProtocol.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/14.
//

import Foundation


@objc public enum ECONetworkTaskState: Int {
    case running = 0
    case suspended = 1
    case canceling = 2
    case completed = 3
    
    static let descriptionMap = [
        Self.running: "running",
        Self.suspended: "pausing",
        Self.canceling: "canceling",
        Self.completed: "completed"
    ]
    
    func description() -> String {
        return Self.descriptionMap[self] ?? String(rawValue)
    }
}

@objc public protocol ECONetworkTaskProtocol {

    var taskIdentifier: Int { get }
    var originalRequest: URLRequest? { get }
    var currentRequest: URLRequest? { get }
    var state: ECONetworkTaskState { get }
    var response: URLResponse? { get }
    var error: Error? { get }
    var metrics: ECONetworkMetrics? { get }

    func resume()
    func suspend()
    func cancel()
}

@objc public protocol ECONetworkContextProtocol {
    /// 上一个环境中的 Context, ECONetwork 内部不使用,  在所有回调给外界的口中会带上作为参数
    var previousContext: AnyObject? { get }
    var trace: OPTrace { get }
    var source: String? { get }
}

@objc public protocol ECONetworkMetricsProtocol { }

/// NetworkClient
/// 替代 URLSession 提供给上层实现网络请求的 Client 协议
/// 目的是对外隐藏真正实现网络请求的对象, 让网络都能被管控
@objc public protocol ECONetworkClientProtocol  {
    weak var delegate: ECONetworkClientEventDelegate? { get }

    /// 创建一个 dataTask, 使用方式与 URLSession dataTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func dataTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkTaskProtocol
    
    /// 创建一个 downloadTask, 使用方式与 URLSession downloadTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func downloadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        cleanTempFile: Bool,
        completionHandler: ((AnyObject?, URL?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkTaskProtocol
    
    /// 创建一个 downloadTask, 使用方式与 URLSession downloadTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func uploadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        fromFile fileURL: URL,
        completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkTaskProtocol
    
    /// 创建一个 uploadTask, 使用方式与 URLSession uploadTask 一致
    /// - Parameters:
    ///   - context: ECONetwork 需要的上下文, 由外部提供
    ///   - completionHandler: 第一个参数是 外部Context:  ECONetworkContext 中带着的上一个 context
    func uploadTask(
        with context: ECONetworkContextProtocol,
        request: URLRequest,
        from bodyData: Data,
        completionHandler: ((AnyObject?, Data?, URLResponse?, Error?) -> Void)?
    ) -> ECONetworkTaskProtocol
    
    
    /// 完成所有任务, 并使 Client 无效
    func finishTasksAndInvalidate()
    
    /// 直接将 Client 无效
    func invalidateAndCancel()
}


/// NetworkClient 的生命周期
/// context
@objc public protocol ECONetworkClientEventDelegate {
    
    /// willPerformHTTPRedirection
    /// - Parameters:
    ///   - context: 生成 networkcontext 的上一个 context
    ///   - client: 触发 delegate 的 Client
    @objc optional func willPerformHTTPRedirection(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        response: URLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    )
    
    /// didFinishCollecting
    /// - Parameters:
    ///   - context: 生成 networkcontext 的上一个 context
    ///   - client: 触发 delegate 的 Client
    @objc optional func didFinishCollecting(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        metrics: ECONetworkMetrics
    )
    
    /// 发送了 httpBody
    /// - Parameters:
    ///   - context: 生成 networkcontext 的上一个 context
    ///   - client: 触发 delegate 的 Client
    @objc optional func didSendBodyData(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    )
    
    /// 收到服务端数据, 并写入 Data
    /// - Parameters:
    ///   - context: 生成 networkcontext 的上一个 context
    ///   - client: 触发 delegate 的 Client
    @objc optional func didReceive(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        data: Data
    )
    
    /// 收到服务端数据并写入磁盘, 下载任务的回调
    /// - Parameters:
    ///   - context: 生成 networkcontext 的上一个 context
    ///   - client: 触发 delegate 的 Client
    @objc optional func didWriteData(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    )
}

