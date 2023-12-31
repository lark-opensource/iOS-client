//
//  DocsRequest.swift
//  DocsSDK
//
//  Created by weidong fu on 5/3/2018.
//

import Foundation
import Alamofire
import SwiftyJSON
import LarkFoundation

typealias ProgressHandler = DataRequest.ProgressHandler
typealias DRResult<T> = (_ object: T?, _ error: Error?) -> Void
typealias DRRawResponse = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void
typealias Params = [String: Any]
typealias TransformData<T> = (_ json: JSON?) -> (T?, error: Error?)
typealias RetryAction = (Request, Error) -> (Bool, TimeInterval)

// MARK: - MailRequestContext
protocol MailRequestContext: AnyObject {
    var header: [String: String] { get }
    var session: NetworkSession { get }
    var host: String { get }
    var useRust: Bool { get }
    func authorizationRequired(_ session: String?)
}

protocol MailParamConvertible {
    var params: Params { get }
}

// MARK: - MailRequest 定义及初始化
class MailRequest<ResponseData> {
    var context: MailRequestContext

    /// 校验登陆态
    lazy var loginStateChecker: MailNetLoginStateChecker = {
        return  MailNetLoginStateChecker(context: context)
    }()
    /// 处理重试逻辑
    lazy var retryHander: RetryHandler = {
        return RetryHandler(context: context, retryCount: MailNetConfig.retryCount)
    }()
    private var transform: TransformData<ResponseData> = { (json: JSON?) in
        guard let json = json as? ResponseData else { return (nil, nil) }
        return (json, nil)
    }
    /// 按照code+msg来校验，设置为false则需要调勇者自行verify response
    private var needVerifyData = true
    /// 用于让自己不被释放，外部不要使用
    private var selfRetainBlock: (() -> Void)?

    /// 发起请求时的配置信息
    var requestConfig: RequestConfig = .default
    private var internalRequest: DataRequest?

    init(path: String, params: Params?, qos: MailNetConfig.Qos = .default, trafficType: MailNetConfig.TrafficType = .default) {
        context = MailNetConfig.sessionFor(qos, trafficType: trafficType)
        let host = self.context.host
        requestConfig.url = host + path
        requestConfig.params.merge(other: params)
    }

    init(request: URLRequest, qos: MailNetConfig.Qos = .default, trafficType: MailNetConfig.TrafficType = .default) {
        context = MailNetConfig.sessionFor(qos, trafficType: trafficType)
        requestConfig.urlRequest = request
        requestConfig.url = request.url?.absoluteString ?? ""
    }

    required convenience init(skRequest: URLRequest) {
        self.init(request: skRequest, qos: .default, trafficType: .mailFetch)
    }

    init(url: String, params: Params?, qos: MailNetConfig.Qos = .default, trafficType: MailNetConfig.TrafficType = .default) {
        self.context = MailNetConfig.sessionFor(qos, trafficType: trafficType)
        requestConfig.params.merge(other: params)
        requestConfig.url = url
    }

    var request: Request? {
        return internalRequest
    }
}

// MARK: - 构建请求等
extension MailRequest {
    private func contructInternalRequest() {
        if let urlRequest = requestConfig.requestIdAddedRequest() {
            internalRequest = context.session.manager.request(urlRequest)
        } else {
            let headersForRequest = requestConfig.heandersWith(context.session.requestHeader)
            internalRequest = context.session.manager.request(requestConfig.url,
                                                                   method: requestConfig.method.toAlamofire,
                                                                   parameters: requestConfig.params,
                                                                   timeout: requestConfig.customTimeOut,
                                                                   encoding: requestConfig.encodeType.toAlamofire,
                                                                   headers: headersForRequest)
        }
        retryHander.addRetryFor(self.internalRequest)
    }

    func start(progressHandler: DataRequest.ProgressHandler? = nil, rawResult: @escaping DRRawResponse) {
        contructInternalRequest()
        internalRequest?.validate().downloadProgress(closure: { (progress) in
            progressHandler?(progress)
        }).responseData(completionHandler: { [weak self] (response) in
            defer {
                self?.selfRetainBlock = nil
            }
            guard let `self` = self else { return }
            self.retryHander.removeRetryFor(self.internalRequest)
            guard self.loginStateChecker.isUserSessionValid() else { mailAssertionFailure("fail to valid session in mail request"); return }

            if let data = response.data, !data.isEmpty {
                let result = DataRequest.jsonResponseSerializer(options: .mutableContainers).serializeResponse(
                    self.internalRequest?.request,
                    self.internalRequest?.response,
                    self.internalRequest?.delegate.data,
                    self.internalRequest?.delegate.error)

                // 处理登陆逻辑
                result.withValue { value in
                    guard let error = Validator.verifyData(value) else { return }
                    MailLogger.info("error in mail request result valus \(error)")
                    if self.loginStateChecker.isLoginRequired(error) {
                        self.loginStateChecker.authorizationRequired()
                    }
                }
            }
            rawResult(response.data, response.response, response.error)
        })
    }

    func cancel() {
        if let currentState = request?.task?.state {
            if currentState != .canceling && currentState != .completed {
                request?.cancel()
            }
        }
    }

    var requestID: String {
        return requestConfig.requestId
    }

    var selfIdentification: String {
        return String(describing: ObjectIdentifier(self))
    }
}

extension SessionManager {
    @discardableResult
    func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeout: TimeInterval? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> DataRequest {
        var originalRequest: URLRequest?

        do {
            originalRequest = try URLRequest(url: url, method: method, headers: headers)
            if let timeout = timeout, timeout > 0 { originalRequest?.timeoutInterval = timeout }
            let encodedURLRequest = try encoding.encode(originalRequest!, with: parameters)
            return request(encodedURLRequest)
        } catch {
            return request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        }
    }
}

extension MailRequest {
    convenience init(path: String, paramConvertible: MailParamConvertible, qos: MailNetConfig.Qos = .default, trafficType: MailNetConfig.TrafficType = .default) {
        self.init(path: path, params: paramConvertible.params, qos: qos, trafficType: trafficType)
    }
}
