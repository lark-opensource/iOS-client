//
//  LarkMinutesAPI.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation
import LarkRustHTTP
import LKCommonsLogging
import LarkAppConfig
import MinutesFoundation
import MinutesNetwork
import TTNetworkManager
import Minutes
import LarkEnv
import LarkSetting
import LarkContainer

extension RequestMethod {
    var httpMethod: String {
        switch self {
        case .post:
            return "POST"
        case .get:
            return "GET"
        }
    }
}

extension Env {
    func meetingDomain(_ defaultDomain: String?) -> String {
        if let defaultDomain = defaultDomain {
            MinutesAPI.logger.info("meetingDomain is \(defaultDomain)")
            return defaultDomain
        } else {
            let prefix = "meetings"
            let core = EnvManager.env.isChinaMainlandGeo ? "feishu" : "larksuite"
            let subfix = EnvManager.env.isChinaMainlandGeo ? "cn" : "com"
            let coreEnv: String = {
                switch (type, unit) {
                case (.preRelease, _):
                    return "-pre"
                case (.staging, "boecn"):
                    return "-boe"
                case (.staging, "boeva"):
                    return "-boe"
                case (.staging, _):
                    return "-staging"
                default:
                    return ""
                }
            }()
            let domain = "\(prefix).\(core)\(coreEnv).\(subfix)"
            MinutesAPI.logger.info("meetingDomain is \(domain)")
            return domain
        }
    }
}


final class MinutesNetworkRequestJsonSerializer: TTDefaultHTTPRequestSerializer {

    override func urlRequest(withURL URL: String!,
                             headerField headField: [AnyHashable: Any]!,
                             params: Any!, method: String!,
                             constructingBodyBlock bodyBlock: TTConstructingBodyBlock!,
                             commonParams commonParam: [AnyHashable: Any]!) -> TTHttpRequest! {
        let request: TTHttpRequest = super.urlRequest(withURL: URL,
                                                      headerField: headField,
                                                      params: params,
                                                      method: method,
                                                      constructingBodyBlock: bodyBlock,
                                                      commonParams: commonParam)
        if let params = params as? [AnyHashable: Any], !params.isEmpty {
            let postData: Data? = try? JSONSerialization.data(withJSONObject: params as Any,
                                                              options: JSONSerialization.WritingOptions.fragmentsAllowed)
            request.httpBody = postData
            return request
        }
        return request
    }
}


public final class LarkMinutesAPI: MinutesAPI {
    let userResolver: UserResolver
    let larkMinutesConfig: MinutesConfig

    static let slardarTracker: SlardarTracker = SlardarTracker()
    static let teaTracker: BusinessTracker = BusinessTracker()

    public override var config: MinutesConfig {
        return larkMinutesConfig
    }

    static var defaultURL: URL {
        let defaultDomain = ConfigurationManager.shared.settings[.vcMm]?.first
        let domain = EnvManager.env.meetingDomain(defaultDomain)
        let urlString = "https://\(domain)"
        return URL(string: urlString)!
    }

    public init(_ baseURL: URL?, config: MinutesConfig, resolver: UserResolver) {
        self.userResolver = resolver
        self.larkMinutesConfig = config
        let url = baseURL ?? LarkMinutesAPI.defaultURL
        super.init(url)
    }

    public override func sendRequest<T: MinutesNetwork.Request>(_ request: T, completionHandler: @escaping (Swift.Result<T.ResponseType, Error>) -> Void) {
        let url = URL(string: request.endpoint, relativeTo: baseURL)!
        
        let urlString = url.absoluteString
        let requestDebugString = "\(type(of: request))[\(request.requestID)]"

        var headers = config.commonHeaders().merging(request.customHeaders) { $1 }
        // hack for referer

        var requestSerializer: TTHTTPRequestSerializerProtocol.Type? = nil
        if request.endpoint.contains("lingo") {
            headers["Content-Type"] = "application/json;charset=utf-8"

            requestSerializer = {
                MinutesNetworkRequestJsonSerializer.self
            }()
        }

        headers["Referer"] = baseURL.absoluteString
        let host = baseURL.host ?? ""

        MinutesAPI.logger.info("baseURL: \(requestDebugString) ===> \(host) ...")

        removeLatestErrorMsgIfNeeded(key: request.endpoint)

        let requestStart = CFAbsoluteTimeGetCurrent()
        TTNetworkManager.shareInstance().requestForBinary(withResponse: urlString, params: request.parameters, method: request.method.httpMethod, needCommonParams: true, headerField: headers, enableHttpCache: false, autoResume: true, isCustomizedCookie: true, requestSerializer: requestSerializer, responseSerializer: nil, progress: nil, callback: { [weak self] error, jsonData, response in
            let requestEnd = CFAbsoluteTimeGetCurrent()
            let logId: String = response?.allHeaderFields?["x-tt-logid"] as? String ?? ""
            let statusCode = response?.statusCode
            if let statusCode = statusCode,
               let error = ResponseError(rawValue: statusCode) {
                MinutesAPI.logger.warn("\(requestDebugString) <=== with error: \(error), logId: \(logId)")
                DispatchQueue.main.async {
                    let targetView = self?.userResolver.navigator.mainSceneWindow?.fromViewController?.view
                    self?.commonErrorMsgDealer(statusCode: statusCode, jsonData: jsonData, requestInterface: request.endpoint, catchError: request.catchError, targetView: targetView)
                }

                self?.tracker(statusCode: statusCode, logId: logId, description: error.localizedDescription, path: request.endpoint)

                completionHandler(.failure(error))
                return
            }

            guard let data = jsonData as? Data else {
                MinutesAPI.logger.warn("\(requestDebugString) <=== with error: invalidData, logId: \(logId)")
                self?.tracker(statusCode: statusCode ?? Int.max, logId: logId, description: "invalidData", path: request.endpoint)

                completionHandler(.failure(ResponseError.invalidData))
                return
            }

            if let error = error {
                MinutesAPI.logger.warn("\(requestDebugString) <=== with error: \(error), logId: \(logId)")
                self?.tracker(statusCode: statusCode ?? Int.max, logId: logId, description: error.localizedDescription, path: request.endpoint)

                completionHandler(.failure(error))
            } else {
                let parseStart = CFAbsoluteTimeGetCurrent()
                let result = T.ResponseType.build(from: data)
                let parseEnd = CFAbsoluteTimeGetCurrent()
                NetPerformance.setNetPerformance(apiDesc: request.endpoint, requestStart: requestStart, requestEnd: requestEnd, parseStart: parseStart, parseEnd: parseEnd)
                switch result {
                case .success:
                    MinutesAPI.logger.info("\(requestDebugString) <=== success.")
                case .failure(let error):
                    MinutesAPI.logger.warn("\(requestDebugString) <=== with error: \(error), logId: \(logId)")
                    self?.tracker(statusCode: statusCode ?? Int.max, logId: logId, description: error.localizedDescription, path: request.endpoint)
                }
                completionHandler(result)
            }
        }, callbackInMainThread: false)
    }

    public override func upload<T: MinutesNetwork.UploadRequest>(_ request: T, completionHandler: @escaping (Swift.Result<T.ResponseType, Error>) -> Void) {
        let url = URL(string: request.endpoint, relativeTo: baseURL)!
        let urlString = url.absoluteString
        let requestDebugString = "Upload Task \(type(of: request))[\(request.requestID)]"
        var headers = config.commonHeaders().merging(request.customHeaders) { $1 }
        headers["Referer"] = baseURL.absoluteString
        MinutesAPI.logger.info("\(requestDebugString) ===> \(baseURL.host) ...")
        removeLatestErrorMsgIfNeeded(key: request.endpoint)
        do {
            var queryItems: [URLQueryItem] = []
            for (key, value) in request.parameters {
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
            var urlComponents = URLComponents(string: urlString)
            urlComponents?.queryItems = queryItems
            // ttnet实现原因，url外部得拼好，传参进去无效
            guard let urlString = urlComponents?.url?.absoluteString else {
                throw ResponseError.invalidURL
            }

            let workQueue = Self.workQueue
            let task = TTNetworkManager.shareInstance().upload(withResponse: urlString, parameters: [:], headerField: headers, constructingBodyWith: { (formData) in
                formData.appendPart(withFileData: request.payload, name: "payload", fileName: "\(request.objectToken)_\(request.segID).pcm", mimeType: "application/octet-stream")
            }, progress: nil, needcommonParams: true, requestSerializer: nil, responseSerializer: nil, autoResume: false, callback: { [weak self] (error, data, response) in
                workQueue.async {
                    let logId: String = response?.allHeaderFields?["x-tt-logid"] as? String ?? ""
                    // 先判断status code，再判断biz code
                    let statusCode = response?.statusCode
                    if let statusCode = statusCode,
                        let error = ResponseError(rawValue: statusCode) {
                        MinutesAPI.logger.warn("\(requestDebugString)[encounter response error] <=== with error: \(error), logId: \(logId)")

                        if let value = data as? Data {
                            let result = T.ResponseType.build(from: value)
                            switch result {
                            case .success:
                                break
                            case .failure(let error):
                                MinutesAPI.logger.warn("\(requestDebugString) <=== with error: invalidJSONObject, \(error), logId: \(logId)")
                                completionHandler(.failure(UploadResponseError.error(with: error, data: nil, statusCode: statusCode, logId: logId)))
                                return
                            }
                            completionHandler(.failure(UploadResponseError.error(with: error, data: result, statusCode: statusCode ?? Int.max, logId: logId)))
                        } else {
                            MinutesAPI.logger.warn("\(requestDebugString) <=== with error: invalidData, logId: \(logId)")
                            completionHandler(.failure(UploadResponseError.error(with: error, data: nil, statusCode: statusCode ?? Int.max, logId: logId)))
                        }

                        DispatchQueue.main.async {
                            let targetView = self?.userResolver.navigator.mainSceneWindow?.fromViewController?.view
                            self?.commonErrorMsgDealer(statusCode: statusCode, jsonData: data, requestInterface: request.endpoint, catchError: request.catchError, targetView: targetView)
                        }
                        return
                    }

                    if let error = error {
                        MinutesAPI.logger.warn("\(requestDebugString)[encounter error] <=== with error: \(error), logId: \(logId)")
                        completionHandler(.failure(UploadResponseError.error(with: error, data: nil, statusCode: statusCode ?? Int.max, logId: logId)))
                    } else {
                        do {
                            guard let value = data as? Data else {
                                throw ResponseError.invalidData
                            }
                            let result = T.ResponseType.build(from: value)

                            switch result {
                            case .success:
                                MinutesAPI.logger.info("\(requestDebugString) <=== success.")
                            case .failure(let error):
                                MinutesAPI.logger.warn("\(requestDebugString)[encounter parse error] <=== with error: \(error), logId: \(logId)")
                            }

                            completionHandler(result)
                        } catch let error {
                            MinutesAPI.logger.warn("\(requestDebugString)[encounter data error] <=== with error: \(error), logId: \(logId)")
                            completionHandler(.failure(UploadResponseError.error(with: error, data: nil, statusCode: statusCode ?? Int.max, logId: logId)))
                        }
                    }
                }
            }, timeout: 10)
            task?.enableCustomizedCookie = true
            task?.resume()
        } catch {
            MinutesAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
            completionHandler(.failure(error))
        }
    }

    public override func clone(_ baseURL: URL? = nil, config: MinutesConfig? = nil) -> MinutesAPI {
        let base = baseURL
        let finalConfig = config ?? self.config
        return LarkMinutesAPI(base, config: finalConfig, resolver: self.userResolver)
    }
}

/// Common Error

extension LarkMinutesAPI {
    func commonErrorMsgDealer(statusCode: Int, jsonData: Any?, requestInterface: String, catchError: Bool, targetView: UIView?) {
        MinutesCommonErrorToastManger.internetCheck(requestInterface: requestInterface, targetView: targetView)
        guard let data = jsonData as? Data else {
            return
        }
        let result = ErrorResponse.build(from: data)
        if MinutesCommonErrorToastManger.shouldToastCheck(requestInterface: requestInterface) {
            MinutesCommonErrorToastManger.errorMsgManger(result: result, targetView: targetView)
        }
        if let msg = try? result.get(), let isShow = msg.newMsg?.isShow, isShow == false {
            MinutesCommonErrorToastManger.saveMessage(msg, forKey: requestInterface)
        }
        if requestInterface == MinutesAPIPath.upload, let msg = try? result.get() {
            MinutesCommonErrorToastManger.saveMessage(msg, forKey: requestInterface)
        }
        if requestInterface == MinutesAPIPath.create, let msg = try? result.get() {
            MinutesCommonErrorToastManger.saveMessage(msg, forKey: requestInterface)
        }
    }

    func removeLatestErrorMsgIfNeeded(key: String) {
        MinutesCommonErrorToastManger.removeMessage(forKey: key)
    }
}

extension LarkMinutesAPI {
    public func tracker(statusCode: Int, logId: String, description: String, path: String) {
        // metrics需要，确保logID不为空
        var logID = logId.isEmpty == false ? logId : "unknown"
        let params: [String : Any] = ["status_code": statusCode, "mm_log_id": logID, "description": description, "path": path, "biz_code": "unknown"]
        Self.slardarTracker.tracker(service: BusinessTrackerName.requestError.rawValue, metric: params, category: ["type": "result"])
        Self.teaTracker.tracker(name: .requestError, params: params)
    }
}

