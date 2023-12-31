//
//  DocsRequest.swift
//  SpaceKit
//
//  Created by weidong fu on 5/3/2018.
//
//  Included OSS: Alamofire
//  Copyright (c) 2014-2022 Alamofire Software Foundation (http://alamofire.org/)
//  spdx license identifier: MIT
// swiftlint:disable file_length line_length

import Foundation
import Alamofire
import SwiftyJSON
import LarkRustHTTP
import RxSwift
import RxRelay
import LarkContainer

public typealias DRResult<T> = (_ object: T?, _ error: Error?) -> Void
public typealias DRRawResponse = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void
public typealias DRUploadRawResponse = (_ request : DocsInternalBaseRequest?, _ response: DefaultDataResponse?, _ metaRequest: DocsUploadInternalRequestMeta, _ error: Error?) -> Void
public typealias Params = [String: Any]
public typealias TransformData<T> = (_ json: JSON?) -> (T?, error: Error?)
public typealias RetryAction = (URLRequest?, UInt, Error) -> (Bool, TimeInterval)

// MARK: -
public protocol DocsRequestContext: AnyObject {
    var header: [String: String] { get }
    var session: NetworkSession { get }
    func authorizationRequired(_ session: String?)
    var host: String { get }
    var useRust: Bool { get }
}

public protocol DocsParamConvertible {
    var params: Params { get }
}
private let docsResponseQueue = DispatchQueue(label: "docsnetResponse-\(UUID())")

// MARK: - 定义及初始化
public class DocsRequest<ResponseData>: SKNetRequestServcie {
    public var context: DocsRequestContext
    /// 校验登陆态
    lazy var loginStateChecker: NetLoginStateChecker = {
        return  NetLoginStateChecker(context: context)
    }()
    /// 处理重试逻辑
    lazy var retryHander: RetryHandler = {
        let retryCount = userResolver.docs.netConfig?.retryCount ?? 2
        return RetryHandler(context: context, retryCount: retryCount)
    }()
    /// 处理网络上报
    private lazy var statisticReporter: NetStatisticsReporter = {
        let useRust = self.context.session.useRust
        return NetStatisticsReporter(identifier: "\(ObjectIdentifier(self))", useRust: useRust)
    }()
    private var transform: TransformData<ResponseData> = { (json: JSON?) in
        guard let json = json as? ResponseData else { return (nil, nil) }
        return (json, nil)
    }
    private var needVerifyData = true // 按照code+msg来校验，设置为false则需要调勇者自行verify response
    private var needFilterBOMChar = false
    // 用于让自己不被释放，外部不要使用
    private var selfRetainBlock: (() -> Void)?

    /// 发起请求时的配置信息, 每次都重新生成
    public var requestConfig: RequestConfig
    private var internalRequest: DocsInternalRequest?
    private var urlForLog: String = ""
    // 在内部的 Response handler 中会设这个属性的值，用来解决业务方很难拿到 logID 的问题
    // 后续待优化为请求时就生成
    private(set) public var responseLogID: String?
    
    public let userResolver: UserResolver
    
    public init(path: String, params: Params?, qos: NetConfigQos = .default, trafficType: NetConfigTrafficType = .default) {
        self.userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let netConfig = self.userResolver.docs.netConfig ?? NetConfig.shared
        context = netConfig.sessionFor(qos, trafficType: trafficType)
        let host = self.context.host
        spaceAssert(host.isEmpty == false, "host is empty")
        spaceAssert(path.hasPrefix("/"))
        requestConfig = RequestConfig(userResolver: self.userResolver)
        requestConfig.url = host + path
        requestConfig.params.merge(other: params)
    }

    public init(request: URLRequest, qos: NetConfigQos = .default, trafficType: NetConfigTrafficType = .default) {
        self.userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let netConfig = self.userResolver.docs.netConfig ?? NetConfig.shared
        context = netConfig.sessionFor(qos, trafficType: trafficType)
        requestConfig = RequestConfig(userResolver: self.userResolver)
        requestConfig.urlRequest = request
        requestConfig.url = request.url?.absoluteString ?? ""
        spaceAssert(requestConfig.url.isEmpty == false)
        userResolver.docs.netConfig?.setLanguageCookie(for: request.url)
    }

    required convenience public init(skRequest: URLRequest) {
        self.init(request: skRequest, qos: .default, trafficType: .docsFetch)
    }

    public init(url: String, params: Params?, qos: NetConfigQos = .default, trafficType: NetConfigTrafficType = .default) {
        self.userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let netConfig = self.userResolver.docs.netConfig ?? NetConfig.shared
        self.context = netConfig.sessionFor(qos, trafficType: trafficType)
        requestConfig = RequestConfig(userResolver: self.userResolver)
        requestConfig.params.merge(other: params)
        requestConfig.url = url
        userResolver.docs.netConfig?.setLanguageCookie(for: URL(string: url))
    }

    public var request: DocsInternalRequest? {
        return internalRequest
    }
    
    deinit {
        retryHander.removeRetryFor(self.internalRequest?.urlRequest)
    }

    func contructInternalRequest() {
        if var urlRequest = requestConfig.requestIdAddedRequest() {
            if statisticReporter.additionalStatisticInfos["docs_request_id"] == nil {
                statisticReporter.additionalStatisticInfos["docs_request_id"] = urlRequest.allHTTPHeaderFields?[DocsCustomHeader.requestID.rawValue]
            }
            if statisticReporter.additionalStatisticInfos[DocsCustomHeader.xttLogId.rawValue] == nil {
                statisticReporter.additionalStatisticInfos[DocsCustomHeader.xttLogId.rawValue] = urlRequest.allHTTPHeaderFields?[DocsCustomHeader.xttLogId.rawValue]
            }
            
            if requestConfig.forceComplexConnect {
                urlRequest.enableComplexConnect = true
            }
            self.internalRequest = context.session.manager.request(urlRequest)
        } else {
            let headersForRequest = requestConfig.headersWith(context.session.requestHeader)
            if statisticReporter.additionalStatisticInfos["docs_request_id"] == nil {
                statisticReporter.additionalStatisticInfos["docs_request_id"] = headersForRequest[DocsCustomHeader.requestID.rawValue]
            }
            if statisticReporter.additionalStatisticInfos[DocsCustomHeader.xttLogId.rawValue] == nil {
                statisticReporter.additionalStatisticInfos[DocsCustomHeader.xttLogId.rawValue] = headersForRequest[DocsCustomHeader.xttLogId.rawValue]
            }
            self.internalRequest = context.session.manager.request(requestConfig.url,
                                                                   method: requestConfig.method.toAlamofire,
                                                                   parameters: requestConfig.params,
                                                                   timeout: requestConfig.customTimeOut,
                                                                   encoding: requestConfig.encodeType.toAlamofire,
                                                                   forceComplexConnect: requestConfig.forceComplexConnect,
                                                                   headers: headersForRequest,
                                                                   cachePolicy: requestConfig.cachePolicy)
            
        }
        let reqId = (statisticReporter.additionalStatisticInfos["docs_request_id"] as? String) ?? ""
        let xttLogid = (statisticReporter.additionalStatisticInfos["DocsCustomHeader.xttLogId.rawValue"] as? String) ?? ""
        urlForLog = (self.internalRequest?.urlRequest?.url?.absoluteString.encryptToShort ?? "")
        DocsLogger.info("sknetinfo: docs_request_id=\(reqId), \(DocsCustomHeader.xttLogId.rawValue)=\(xttLogid), url=\(urlForLog)", component: LogComponents.net)
        retryHander.addRetryFor(self.internalRequest?.urlRequest) { [weak self] (_, _, error) in
            guard let self = self else { return }
            let request = self.internalRequest
            self.statisticReporter.doStatisticsFor(request: request, timeLine: request?.netMetrics,
                                                   error: error, response: nil, data: nil,
                                                   metrics: request?.netMetrics, requestEnd: false)
            self.statisticReporter.append(request?.netMetrics)
        }
    }

}

// MARK: - 构建请求等
extension DocsRequest {

    @discardableResult
    public func start(callbackQueue: DispatchQueue = .main,
                      result: @escaping DRResult<ResponseData>) -> DocsRequest<ResponseData> {
        contructInternalRequest()
        internalRequest?.docsResponseJSON(queue: docsResponseQueue, options: .mutableContainers, completionHandler: { [weak self] (response) in
            defer {
                self?.selfRetainBlock = nil
            }
            guard let strongSelf = self else { return }
            let reqId = (self?.statisticReporter.additionalStatisticInfos["docs_request_id"] as? String) ?? ""
            let xttlogId = (self?.statisticReporter.additionalStatisticInfos[DocsCustomHeader.xttLogId.rawValue] as? String) ?? ""
            strongSelf.printLogId(response: response.response, reqId: reqId)

            strongSelf.retryHander.removeRetryFor(self?.internalRequest?.urlRequest)
            guard strongSelf.loginStateChecker.isUserSessionValid() == true else { return }
            strongSelf.statisticReporter.doStatisticsFor(request: strongSelf.internalRequest, response: response)
            var error = self?.handleErrMessageIfNeed(response.error)
            let netError: Bool = (error != nil)
            if self?.needVerifyData == true, error == nil {
                error = Validator.verifyData(response.value)
            }

            guard strongSelf.loginStateChecker.isLoginRequired(error) == false else {
                callbackQueue.async {
                    result(nil, error)
                    strongSelf.loginStateChecker.authorizationRequired()
                }
                return
            }

            guard error == nil else {
                let errmsg: String = {
                    let nsErr = error! as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                DocsLogger.info("request error, url=\(self?.urlForLog ?? ""), errmsg=\(errmsg), isNetError=\(netError), docs_request_id=\(reqId), \(DocsCustomHeader.xttLogId.rawValue)=\(xttlogId)", component: LogComponents.net)
                if let json = response.result.value as? [String: Any], let (data, _) = self?.transform(JSON(json)) {
                    callbackQueue.async {
                        result(data, error)
                    }
                    return
                }
                callbackQueue.async {
                    result(nil, error)
                }
                return
            }

            guard let json = response.result.value as? [String: Any],
                let (data, parseError) = self?.transform(JSON(json)) else {
                    callbackQueue.async {
                        result(nil, DocsNetworkError.invalidData)
                    }
                    return
            }

            guard parseError == nil else {
                callbackQueue.async {
                    result(nil, parseError)
                }
                return
            }
            callbackQueue.async {
                result(data, error)
            }
        })
        return self
    }

    public func start(rawResult: @escaping DRRawResponse) {
        contructInternalRequest()
        internalRequest?.docsResponseData(queue: .main, completionHandler: { [weak self] (response) in
            defer {
                self?.selfRetainBlock = nil
            }
            guard let `self` = self else { return }
            self.retryHander.removeRetryFor(self.internalRequest?.urlRequest)
            let reqId = (self.statisticReporter.additionalStatisticInfos["docs_request_id"] as? String) ?? ""
            self.printLogId(response: response.response, reqId: reqId)
            guard self.loginStateChecker.isUserSessionValid() else { return }
            self.statisticReporter.doStatisticsFor(request: self.internalRequest, response: response)

            if let data = response.data, !data.isEmpty {
                let result = DataRequest.jsonResponseSerializer(options: .mutableContainers).serializeResponse(
                    self.internalRequest?.urlRequest,
                    response.response,
                    response.data,
                    response.error)

                // 处理登陆逻辑
                result.withValue { value in
                    guard let error = Validator.verifyData(value) else { return }
                    if self.loginStateChecker.isLoginRequired(error) {
                        self.loginStateChecker.authorizationRequired()
                    }
                }
            }
            let handleErr = self.handleErrMessageIfNeed(response.error)

            if self.needFilterBOMChar, SKFoundationConfig.shared.enableFilterBOMChar, var rspData = response.data {
                Data.filterBOMChar(&rspData)
                rawResult(rspData, response.response, handleErr)
            } else {
                rawResult(response.data, response.response, handleErr)
            }
        })
    }

    @discardableResult
    public func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        rawResult: @escaping DRRawResponse) -> DocsRequest<ResponseData> {
            guard let url = URL(string: requestConfig.url) else {
                spaceAssertionFailure()
                let extraInfo: [String: String] = ["method": requestConfig.method.rawValue]
                DocsLogger.error("upload param error", extraInfo: extraInfo, error: nil, component: nil)
                rawResult(nil, nil, NSError(domain: "upload param error", code: -1, userInfo: nil))
                return self
            }
            
            let finalHeaders = requestConfig.headersWith(context.session.header)
            
            context.session.manager.docsUpload(multipartFormData: { (formData) in
                multipartFormData(formData)
            }, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
                           to: url,
                       method: requestConfig.method.toAlamofire,
                      headers: finalHeaders,
                      timeout: requestConfig.customTimeOut) {[weak self] (request, response, metaRequest, error) in
                guard let strongSelf = self else { return }
                if let response = response {
                    strongSelf.statisticReporter.doUploadStatistisFor(request: metaRequest, response: response)
                }
                rawResult(response?.data, response?.response, error)
            }
        return self
    }

    public func cancel() {
        if let currentState = request?.state {
            if currentState != .canceling && currentState != .completed {
                NetUtil.shared.netDebugLog("\(selfIdentification) cancel, url is \(self.request?.urlRequest?.url?.debugDescription ?? "")")
                request?.cancel()
            }
        }
    }

    public func state() -> URLSessionTask.State? {
        return self.request?.state
    }

    public var requestID: String {
        return requestConfig.requestId
    }

    public var selfIdentification: String {
        return String(describing: ObjectIdentifier(self))
    }

    private func printLogId(response: URLResponse?, reqId: String) {
        guard let response = response as? HTTPURLResponse else { return }
        if let logId = response.allHeaderFields[DocsCustomHeader.xttLogId.rawValue] as? String {
            responseLogID = logId
            DocsLogger.info("request end, url=\(urlForLog), \(DocsCustomHeader.xttLogId.rawValue)=\(logId), docs_request_id=\(reqId), statusCode=\(response.statusCode)", component: LogComponents.net)
        }
    }

    private func handleErrMessageIfNeed(_ oriError: Error?) -> Error? {
        guard let error = oriError else {
            return oriError
        }
        let nsErr = error as NSError
        //userInfo可能会有敏感信息, 只加想知道的
        var userInfo: [String: Any] = [:]
        userInfo["request_id"] = statisticReporter.additionalStatisticInfos["docs_request_id"]
        if let description = reportRustErrorMsg(nsErr: nsErr) {
            userInfo[NSLocalizedDescriptionKey] = description
        }
        return NSError(domain: nsErr.domain, code: nsErr.code, userInfo: userInfo)
    }
    
    // drive 预览接口需要上报底层网络错误信息
    private func reportRustErrorMsg(nsErr: NSError) -> String? {
        let api = "file/info"
        if let description = nsErr.userInfo[NSLocalizedDescriptionKey] as? String,
           let url = nsErr.userInfo[NSURLErrorFailingURLStringErrorKey] as? String,
           url.contains(api) {
            let tokenPattern = SecurityInfoChecker.shared.assertPattern
            return description.replace(with: "******", for: tokenPattern)
        } else {
            return nil
        }
    }
}

// MARK: - 设置属性
extension DocsRequest {
    @discardableResult
    public func makeSelfReferenced() -> Self {
        self.selfRetainBlock = {
            spaceAssertionFailure("should not call \(self.selfRetainBlock.debugDescription)")
            DocsLogger.info("\(self.needVerifyData)")
        }
        return self
    }

    @discardableResult
    public func makeSelfUnReferfenced() -> Self {
        self.selfRetainBlock = nil
        return self
    }
    
    @discardableResult
    public func set(encodeType: ParamEncodingType) -> DocsRequest<ResponseData> {
        requestConfig.encodeType = encodeType
        return self
    }

    @discardableResult
    public func set(additionalStatistics: [String: Any]) -> Self {
        self.statisticReporter.additionalStatisticInfos = additionalStatistics
        return self
    }

    @discardableResult
    public func set(transform:
        @escaping TransformData<ResponseData>) -> DocsRequest<ResponseData> {
        self.transform = transform
        return self
    }

    @discardableResult
    public func set(method: DocsHTTPMethod) -> DocsRequest<ResponseData> {
        requestConfig.method = method
        return self
    }

    @discardableResult
    public func set(headers: [String: String]) -> DocsRequest<ResponseData> {
        requestConfig.headers = headers
        return self
    }

    @discardableResult
    public func set(needVerifyData: Bool) -> DocsRequest<ResponseData> {
        self.needVerifyData = needVerifyData
        return self
    }

    @discardableResult
    public func set(retryCount: UInt) -> Self {
        retryHander.retryCount = retryCount
        return self
    }

    @discardableResult
    public func set(timeout: Double) -> Self {
        guard timeout >= 0  else { return self }
        requestConfig.customTimeOut = timeout
        return self
    }

    @discardableResult
    public func set(forceComplexConnect: Bool) -> Self {
        requestConfig.forceComplexConnect = forceComplexConnect
        return self
    }

    @discardableResult
    public func set(cachePolicy: URLRequest.CachePolicy) -> Self {
        requestConfig.cachePolicy = cachePolicy
        return self
    }

    @discardableResult
    public func set(needFilterBOMChar: Bool) -> Self {
        self.needFilterBOMChar = needFilterBOMChar
        return self
    }
    
    @discardableResult
    public func set(retryAction: @escaping RetryAction) -> Self {
        self.retryHander.retryAction = retryAction
        return self
    }
}



extension DocsRequest {
    convenience public init(path: String, paramConvertible: DocsParamConvertible, qos: NetConfigQos = .default, trafficType: NetConfigTrafficType = .default) {
        self.init(path: path, params: paramConvertible.params, qos: qos, trafficType: trafficType)
    }
}
