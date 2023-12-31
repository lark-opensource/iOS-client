//
//  SessionManager+Docs.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/10.
//
// disable-lint: long parameters

import Foundation
import Alamofire

extension SessionManager {
    //构建URLRequest，给Rust初始化URLRequest使用，如果改这个方法，记得同步修改下面Almofire构建URLRequest的方法，后续fg去掉，则可以忽略
    public static func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeout: TimeInterval? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        forceComplexConnect: Bool = false,
        headers: HTTPHeaders? = nil,
        cachePolicy: URLRequest.CachePolicy)
    -> URLRequest? {
        do {
            var originalRequest = try URLRequest(url: url, method: method, headers: headers)
            originalRequest.cachePolicy = cachePolicy
            originalRequest.enableComplexConnect = forceComplexConnect
            if let timeout = timeout, timeout > 0 { originalRequest.timeoutInterval = timeout }
            let encodedURLRequest = try encoding.encode(originalRequest, with: parameters)
            return encodedURLRequest
        } catch {
            spaceAssertionFailure("construct request error")
            return nil
        }
    }
}

//MARK: 从DocsRequst.swift 文件迁移出来
extension SessionManager {
    @discardableResult
    public func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeout: TimeInterval? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        forceComplexConnect: Bool = false,
        headers: HTTPHeaders? = nil,
        cachePolicy: URLRequest.CachePolicy)
        -> DataRequest {
        do {
            var originalRequest = try URLRequest(url: url, method: method, headers: headers)
            originalRequest.cachePolicy = cachePolicy
            originalRequest.enableComplexConnect = forceComplexConnect
            if let timeout = timeout, timeout > 0 { originalRequest.timeoutInterval = timeout }
            let encodedURLRequest = try encoding.encode(originalRequest, with: parameters)
            let dataRequest = request(encodedURLRequest)
            checkFixRequest(dataRequest)
            return dataRequest
        } catch {
            spaceAssertionFailure("construct request error")
            let dataRequest = request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            checkFixRequest(dataRequest)
            return dataRequest
        }
    }

    public func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        timeout: TimeInterval? = nil,
        encodingCompletion: ((MultipartFormDataEncodingResult) -> Void)?) {
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            if let timeout = timeout, timeout > 0 { urlRequest.timeoutInterval = timeout }

            return upload(
                multipartFormData: multipartFormData,
                usingThreshold: encodingMemoryThreshold,
                with: urlRequest,
                encodingCompletion: encodingCompletion
            )
        } catch {
            spaceAssertionFailure("construct upload request error")
            DispatchQueue.main.async { encodingCompletion?(.failure(error)) }
        }
    }
    
    /// 检测 request 是否合格，如果不合格就进入断言
    private func checkFixRequest(_ request: DataRequest) {
        #if DEBUG
        //1. 检测 httpMethod 与参数位置是否一致。
        func isBodyEmpty(_ req: DataRequest) -> Bool {
            return req.request?.httpBody == nil && req.request?.httpBodyStream == nil
        }
        if request.request?.httpMethod == "GET", !isBodyEmpty(request) {
            assertionFailure("GET method should not has httpBody")
        }
        /// 如果有使用 Post 方法，但是 httpBody 为空的情况，那就需要跟后台讨论下用 post 的用意了。
        if request.request?.httpMethod == "POST", isBodyEmpty(request) {
            assertionFailure("POST method should has httpBody")
        }
        #endif
    }
}
