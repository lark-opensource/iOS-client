//
//  DocsDownloadInternalRequest.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/10.
//  抽取封装Alamofire 和 rusthttp download方法

import Foundation
import Alamofire
import LarkRustHTTP

//MARK: 对外下载协议
public protocol DocsDownloadInternalRequest {
    //如果queue为nil，默认用DispatchQueue.main
    @discardableResult
    func downloadProgress(queue: DispatchQueue? , closure: @escaping Alamofire.Request.ProgressHandler) -> Self
    
    @discardableResult
    func response(
        queue: DispatchQueue?,
        completionHandler: @escaping (DefaultDownloadResponse) -> Void)
        -> Self
  
}

//MARK: Alamofire下载具体实现
public class DocsDownloadInternalAlamofireRequest: DocsDownloadInternalRequest {
    
    private var alamofireDownloadRequest: DownloadRequest
    
    public init(alamofireDownloadRequest: DownloadRequest) {
        self.alamofireDownloadRequest = alamofireDownloadRequest
    }

    @discardableResult
    public func downloadProgress(queue: DispatchQueue? , closure: @escaping Alamofire.Request.ProgressHandler) -> Self {
        alamofireDownloadRequest.downloadProgress(queue: queue ?? DispatchQueue.main, closure: closure)
        return self
    }
    
    @discardableResult
    public func response(queue: DispatchQueue?, completionHandler: @escaping (Alamofire.DefaultDownloadResponse) -> Void) -> Self {
        self.alamofireDownloadRequest.response(queue: queue, completionHandler: completionHandler)
        return self
    }
}

//MARK: rust下载具体实现，目前暂时没有用下载的方法，都走drive下载相关，这里先预留接口，后续有需要进行实现
public class DocsDownloadInternalRustRequest: DocsDownloadInternalRequest {

    private var rustSession: RustHTTPSession
    private var alamofireRequest: DownloadRequest
    
    public init(alamofireRequest: DownloadRequest, rustSession: RustHTTPSession) {
        self.alamofireRequest = alamofireRequest
        self.rustSession = rustSession
    }
    
    @discardableResult
    public func downloadProgress(queue: DispatchQueue?, closure: @escaping Alamofire.Request.ProgressHandler) -> Self {
        assertionFailure("Do not implement related methods, please do it yourself")
        return self
    }
    
    @discardableResult
    public func response(queue: DispatchQueue?, completionHandler: @escaping (Alamofire.DefaultDownloadResponse) -> Void) -> Self {
        assertionFailure("Do not implement related methods, please do it yourself")
        return self
    }
    
}
