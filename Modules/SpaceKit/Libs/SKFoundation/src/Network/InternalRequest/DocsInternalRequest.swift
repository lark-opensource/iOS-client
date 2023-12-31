//
//  DocsInternalRequest.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/8.
//  抽取封装Alamofire 和 rusthttp 基础网络请求方法


import Foundation
import Alamofire
import SwiftyJSON
import LarkRustHTTP
import LarkContainer

//MARK: 对外网络请求基础base协议，用来获取网络请求相关参数
public protocol DocsInternalBaseRequest {
    // 当前请求URLRequest
    var urlRequest: URLRequest? { get }
    // 当前task状态
    var state: URLSessionTask.State? { get }
    // 当前请求重试了多少次
    var retryCount: UInt { get }
    // rust请求相关信息
    var rustMetrics: [RustHttpMetrics] { get }
    // URLSessionTask原生相关信息，如果是直连rust请求，该值为空
    var netMetrics: URLSessionTaskMetrics? { get }
    // 当前网络通道：在原来"rustChannel" ， "nativeUrlSession"，加上"rustDirectChannel"
    var netChannel: String { get }
}

//MARK: 对外网络基础请求协议
public protocol DocsInternalRequest: DocsInternalBaseRequest {
    //发起请求，返回的是JSON
    func docsResponseJSON(
        queue: DispatchQueue?,
        options: JSONSerialization.ReadingOptions,
        completionHandler: @escaping (DataResponse<Any>) -> Void)

    //发起请求，返回的是Data
    func docsResponseData(
        queue: DispatchQueue?,
        completionHandler: @escaping (DataResponse<Data>) -> Void)
    
    //取消请求
    func cancel()

}

//MARK: Alamofire网络请求具体实现
public class DocsInternalAlamofireRequest: DocsInternalRequest {
    
    
    private var alamofireRequest: DataRequest
    
    public var netMetrics: URLSessionTaskMetrics? {
        return self.alamofireRequest.delegate.netMetrics
    }
    
    public var retryCount: UInt  {
        return self.alamofireRequest.retryCount
    }
    
    public var rustMetrics: [LarkRustHTTP.RustHttpMetrics] {
        return self.alamofireRequest.task?.rustMetrics ?? []
    }

    public var urlRequest: URLRequest? {
        return self.alamofireRequest.request
    }
    
    public var state: URLSessionTask.State? {
        return self.alamofireRequest.task?.state
    }
    
    public var useRust: Bool
    
    public var netChannel: String {
        if useRust {
            return "rustChannel"
        } else {
            return "nativeUrlSession"
        }
    }
    
    public init(alamofireRequest: DataRequest, useRust: Bool) {
        self.useRust = useRust
        self.alamofireRequest = alamofireRequest
    }
    
    public func docsResponseJSON(queue: DispatchQueue?, options: JSONSerialization.ReadingOptions, completionHandler: @escaping (Alamofire.DataResponse<Any>) -> Void) {
        self.alamofireRequest.responseJSON(queue: queue, completionHandler: completionHandler)
    }
    
    public func docsResponseData(queue: DispatchQueue?, completionHandler: @escaping (Alamofire.DataResponse<Data>) -> Void) {
        self.alamofireRequest.responseData(queue: queue, completionHandler: completionHandler)
    }
    
    public func cancel() {
        self.alamofireRequest.cancel()
    }
    
}

//MARK: 直连rust网络请求具体实现
public class DocsInternalRustRequest: DocsInternalRequest {
    
    private let rustManager: DocsRustSessionManager
        
    public var urlRequest: URLRequest?
    
    let userResolver: UserResolver
    
    private let taskLock = NSLock()
    private var task: RustHTTPSessionDataTask? {
        set {
            taskLock.lock(); defer { taskLock.unlock() }
            _task = newValue
        }
        get {
            taskLock.lock(); defer { taskLock.unlock() }
            return _task
        }
    }
    
    private var _task: RustHTTPSessionDataTask?
    
    public var netChannel: String {
        return "rustDirectChannel"
    }
    
    public var netMetrics: URLSessionTaskMetrics? {
        return nil
    }
    
    public var retryCount: UInt {
        return UInt(self.task?.retryCount ?? 0)
    }
    
    public var rustMetrics: [LarkRustHTTP.RustHttpMetrics] {
        return self.task?.rustMetrics ?? []
    }
    
    //为了兼容对外都是使用URLSessionTask.State，对RustHTTPSessionTask.state 做了一层转化
    public var state: URLSessionTask.State? {
        guard let taskState = self.task?.state else {
            return nil
        }
        switch taskState {
        case .running:
            return URLSessionTask.State.running
        case .suspended:
            return URLSessionTask.State.suspended
        case .canceling:
            return URLSessionTask.State.canceling
        case .completed:
            return URLSessionTask.State.completed
        @unknown default:
            return nil
        }
    }
    
    //MARK: Method
    public init(urlRequest: URLRequest?, rustManager: DocsRustSessionManager, userResolver: UserResolver) {
        self.rustManager = rustManager
        self.urlRequest = urlRequest
        self.userResolver = userResolver
    }
    
    public func docsResponseJSON(queue: DispatchQueue?, options: JSONSerialization.ReadingOptions, completionHandler: @escaping (Alamofire.DataResponse<Any>) -> Void) {
        
        guard let request = self.urlRequest else {
            DocsLogger.info("request is nil", component: LogComponents.net)
            (queue ?? DispatchQueue.main).async {
                completionHandler(DataResponse(request: nil, response: nil, data: nil,
                                 result: .failure(DocsNetworkError.parse)))
             }
            return
        }
    
        let currentTask = self.rustManager.rustSession.dataTask(with: request) { (data, response, error) in

            let result = Request.serializeResponseJSON(options: options,
                                                       response: response as? HTTPURLResponse,
                                                       data: data,
                                                       error: error)
            let dataResponse = DataResponse<Any>(
                request: request,
                response: response as? HTTPURLResponse,
                data: data,
                result: result,
                timeline: Timeline()
            )
            (queue ?? DispatchQueue.main).async { completionHandler(dataResponse) }

        }
        
        // check http header
        if let currentRequest = currentTask.currentRequest, let request = try? DocsRequestAdapter(userResolver: userResolver).adapt(currentRequest) {
            currentTask.updateStartRequest(request)
        }

        currentTask.resume()
        self.task = currentTask
    }
    
    public func docsResponseData(queue: DispatchQueue?, completionHandler: @escaping (Alamofire.DataResponse<Data>) -> Void) {
        
        guard let request = self.urlRequest else {
            DocsLogger.info("request is nil", component: LogComponents.net)
            (queue ?? DispatchQueue.main).async {
                completionHandler(DataResponse(request: nil, response: nil, data: nil,
                                               result: .failure(DocsNetworkError.parse)))
            }
            return
        }
        
        let currentTask = self.rustManager.rustSession.dataTask(with: request) { (data, response, error) in
            let result = Request.serializeResponseData(response: response as? HTTPURLResponse,
                                                       data: data,
                                                       error: error)
            
            let dataResponse = DataResponse<Data>(
                request: request,
                response: response as? HTTPURLResponse,
                data: data,
                result: result,
                timeline: Timeline()
            )
            (queue ?? DispatchQueue.main).async {
                completionHandler(dataResponse)
            }
        }
        
        // check http header
        if let currentRequest = currentTask.currentRequest, let request = try? DocsRequestAdapter(userResolver: userResolver).adapt(currentRequest) {
            currentTask.updateStartRequest(request)
        }
        currentTask.resume()
        self.task = currentTask
    }
    
    public func cancel() {
        guard let task = self.task else { return }
        task.cancel()
    }
}
