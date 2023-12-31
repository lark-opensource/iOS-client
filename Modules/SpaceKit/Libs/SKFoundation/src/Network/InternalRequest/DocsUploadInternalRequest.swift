//
//  DocsUploadInternalRequest.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/11.
//
// disable-lint: long parameters

import Foundation
import Alamofire
import LarkRustHTTP
import LarkContainer

//MARK: 上传成功返回给上层用于上报埋点相关数据
public struct DocsUploadInternalRequestMeta: DocsInternalBaseRequest {
    public var urlRequest: URLRequest?
    
    public var state: URLSessionTask.State?
    
    public var retryCount: UInt
    
    public var rustMetrics: [LarkRustHTTP.RustHttpMetrics]
    
    public var netMetrics: URLSessionTaskMetrics?
    
    public var netChannel: String
    
    init(urlRequest: URLRequest? = nil, state: URLSessionTask.State? = nil, retryCount: UInt = 0, rustMetrics: [LarkRustHTTP.RustHttpMetrics] = [], netMetrics: URLSessionTaskMetrics? = nil, netChannel: String) {
        self.urlRequest = urlRequest
        self.state = state
        self.retryCount = retryCount
        self.rustMetrics = rustMetrics
        self.netMetrics = netMetrics
        self.netChannel = netChannel
    }
}

//MARK: 对外网络请求上传文件协议
public protocol DocsUploadInternalRequest {
    func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64,
        to url: URLConvertible,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        timeout: TimeInterval?,
        rawResult: @escaping DRUploadRawResponse)
    
}

//MARK: Alamofire上传文件具体实现
class DocsUploadInternalAlamofireRequest: DocsUploadInternalRequest {
 
    var state: URLSessionTask.State?
    
    private let manager: SessionManager
    
    public var useRust: Bool
    
    public var netChannel: String {
        if useRust {
            return "rustChannel"
        } else {
            return "nativeUrlSession"
        }
    }
    
    public init(manager: SessionManager, useRust: Bool) {
        self.manager = manager
        self.useRust = useRust
    }
    
    public func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        timeout: TimeInterval? = nil,
        rawResult: @escaping DRUploadRawResponse) {
            self.manager.upload(multipartFormData: multipartFormData, usingThreshold: encodingMemoryThreshold, to: url, method: method, headers: headers, timeout: timeout) { [weak self] encodeResult in
                
                guard let self = self else {
                    return
                }
                
                //构建DocsUploadInternalRequestMeta
                var metaRequest = DocsUploadInternalRequestMeta(netChannel: self.netChannel)
                
                
                switch encodeResult {
                case let .failure(error):
                    rawResult(nil, nil, metaRequest, error)
                    DocsLogger.error("upload encode fail：\(error)")
                case let .success(request: uploadRequest, streamingFromDisk: _, streamFileURL: _):
                    
                    metaRequest.urlRequest = uploadRequest.request
                    metaRequest.state = uploadRequest.task?.state
                    metaRequest.rustMetrics = uploadRequest.task?.rustMetrics ?? []
                    metaRequest.retryCount = uploadRequest.retryCount
                
                    uploadRequest.response(completionHandler: { (response) in
                        
                        metaRequest.netMetrics = response.metrics
                        rawResult(nil, response, metaRequest ,response.error)
                    })
                @unknown default:
                    rawResult(nil, nil, metaRequest ,nil)
                    DocsLogger.error("upload encodeResult unkonwn")
                    fatalError("upload encodeResult unkonwn")
                }
            }
        }
}


//MARK: rust上传文件具体实现
class DocsUploadInternalRustRequest: DocsUploadInternalRequest {
    
    private let rustSession: RustHTTPSession
    
    let userResolver: UserResolver
    
    private let queue = DispatchQueue(label: "ccm.docsrequest.session-manager." + UUID().uuidString)
    
    public init(rustSession: RustHTTPSession, userResolver: UserResolver) {
        self.rustSession = rustSession
        self.userResolver = userResolver
    }
    
    public var netChannel: String {
        return "rustDirectChannel"
    }
    
    public var rustMetrics: [RustHttpMetrics] {
        return self.task?.rustMetrics ?? []
    }
    
    public var retryCount: UInt {
        return UInt(self.task?.retryCount ?? 0)
    }
    
    private let taskLock = NSLock()
    var task: RustHTTPSessionUploadTask? {
        set {
            taskLock.lock(); defer { taskLock.unlock() }
            _task = newValue
        }
        get {
            taskLock.lock(); defer { taskLock.unlock() }
            return _task
        }
    }
    
    private var _task: RustHTTPSessionUploadTask?
    
    public func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        timeout: TimeInterval? = nil,
        rawResult: @escaping DRUploadRawResponse) {
            
            let requestStartTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            
            do {
                var urlRequest = try URLRequest(url: url, method: method, headers: headers)
                if let timeout = timeout, timeout > 0 { urlRequest.timeoutInterval = timeout }
                
                //构建request结果相关数据
                
                
                //下面这段逻辑是参考Alamofire上传文件内部实现
                DispatchQueue.global(qos: .utility).async {
                    let formData = MultipartFormData()
                    multipartFormData(formData)
                    
                    var tempFilePath: SKFilePath?
                    
                    do {
                        var newUrlRequest = try urlRequest.asURLRequest()
                        newUrlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
                        
                        //小文件上传
                        if formData.contentLength < encodingMemoryThreshold {
                            let data = try formData.encode()
                            
                            let initialResponseTime = CFAbsoluteTimeGetCurrent()
                            let currentRequest = newUrlRequest
                            let task = self.queue.sync { [weak self] in
                                self?.rustSession.uploadTask(with: newUrlRequest, from: data) {[weak self] (data, response, error) in
                                    
                                    //构建responseData
                                    let dataResponse = DefaultDataResponse(
                                        request: currentRequest,
                                        response: response as? HTTPURLResponse,
                                        data: data,
                                        error: error,
                                        timeline: Timeline(requestStartTime: requestStartTime,
                                                           initialResponseTime: initialResponseTime,
                                                           requestCompletedTime: CFAbsoluteTimeGetCurrent(),
                                                           serializationCompletedTime:CFAbsoluteTimeGetCurrent()
                                                          )
                                    )
                                    
                                    //构建request相关信息，用于埋点记录
                                    let metaRequest = DocsUploadInternalRequestMeta(
                                        urlRequest: currentRequest,
                                        state: .completed,
                                        retryCount: self?.retryCount ?? 0,
                                        rustMetrics: self?.rustMetrics ?? [],
                                        netChannel: self?.netChannel ?? "")
                                    
                                    DispatchQueue.main.async { rawResult(nil , dataResponse, metaRequest, error)}
                                }
                            }
                            // check http header
                            if let currentRequest = task?.currentRequest, let request = try? DocsRequestAdapter(userResolver: self.userResolver).adapt(currentRequest) {
                                task?.updateStartRequest(request)
                            }
                            task?.resume()
                            
                        } else {
                            //大文件上传，先写到本地文件夹，再上传
                            let directoryPath = SKFilePath.globalSandboxWithTemporary
                                .appendingRelativePath("DocsRequset")
                                .appendingRelativePath("multipart.form.data")
                            // Create directory inside serial queue to ensure two threads don't do this in parallel
                            try directoryPath.createDirectory(withIntermediateDirectories: true)
                            
                            let fileName = UUID().uuidString
                            let filePath = directoryPath.appendingRelativePath(fileName)
                            
                            tempFilePath = filePath
                            
                            try formData.writeEncodedData(to: filePath.pathURL)
                            
                            let initialResponseTime = CFAbsoluteTimeGetCurrent()
                            let currentRequest = urlRequest
                            let currentTask = self.queue.sync { [weak self] in
                                self?.rustSession.uploadTask(with: newUrlRequest, fromFile: filePath.pathURL) { [weak self] (data, response, error) in
                                    
                                    let requestCompletedTime = CFAbsoluteTimeGetCurrent()
                                    try? filePath.removeItem()
                                     
                                    
                                    //构建耗时相关
                                    let tiemline = Timeline(requestStartTime: requestStartTime,
                                                            initialResponseTime: initialResponseTime,
                                                            requestCompletedTime: requestCompletedTime,
                                                            serializationCompletedTime: CFAbsoluteTimeGetCurrent()
                                    )
                                    
                                    //构建data
                                    let dataResponse = DefaultDataResponse(
                                        request: currentRequest,
                                        response: response as? HTTPURLResponse,
                                        data: data,
                                        error: error,
                                        timeline: tiemline
                                    )
                                    
                                    //构建request相关信息，用于埋点记录
                                    let metaRequest = DocsUploadInternalRequestMeta(
                                        urlRequest: currentRequest,
                                        state: .completed,
                                        retryCount: self?.retryCount ?? 0,
                                        rustMetrics: self?.rustMetrics ?? [],
                                        netChannel: self?.netChannel ?? "")
                                    
                                    DispatchQueue.main.async {
                                        rawResult(nil, dataResponse, metaRequest, error)
                                    }
                                }
                            }
                            // check http header
                            if let currentRequest = currentTask?.currentRequest, let request = try? DocsRequestAdapter(userResolver: self.userResolver).adapt(currentRequest) {
                                currentTask?.updateStartRequest(request)
                            }
                            currentTask?.resume()
                            self.task = currentTask
                        }
                    } catch {
                        // Cleanup the temp file in the event that the multipart form data encoding failed
                        if let tempFilePath = tempFilePath {
                            try? tempFilePath.removeItem()
                        }
                        spaceAssertionFailure("upload file error")
                        DocsLogger.error("upload file error：\(error)")
                        DispatchQueue.main.async {
                            rawResult(nil, nil, DocsUploadInternalRequestMeta(netChannel: self.netChannel), error)
                        }
                    }
                }
                
            } catch {
                spaceAssertionFailure("construct upload request error")
                DocsLogger.error("construct upload request error：\(error)")
                DispatchQueue.main.async {
                    rawResult(nil, nil, DocsUploadInternalRequestMeta(netChannel: self.netChannel), error)
                }
            }
        }
}
