//
//  LarkLiveAPI.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation
import LKCommonsLogging
import LarkAppConfig
import TTNetworkManager
import LarkLive
import LarkAccountInterface
import LarkEnv
import LarkRustClient
import Alamofire

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
    var isPrerelease: Bool {
        return type == .preRelease
    }

    func meetingDomain(_ defaultDomain: String?) -> String {
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
        if isPrerelease {
            return domain
        } else {
            return defaultDomain ?? domain
        }
    }
}

public final class LarkLiveAPI: LiveAPI {

    let larkLiveConfig: LiveConfig
    let rustService: RustService

    public override var config: LiveConfig {
        return larkLiveConfig
    }

    static var defaultURL: URL {
        let defaultDomain = ConfigurationManager.shared.settings[.vcMm]?.first
        let domain = EnvManager.env.meetingDomain(defaultDomain)
        let urlString = "https://\(domain)"
        return URL(string: urlString)!
    }

    public init(_ baseURL: URL?, config: LiveConfig, rustService: RustService) {
        self.larkLiveConfig = config
        self.rustService = rustService
        let url = baseURL ?? LarkLiveAPI.defaultURL
        super.init(url)
    }

    private func setCookie(url: URL?) {
        if let domain = url?.host {
            let session = AccountServiceAdapter.shared.currentAccessToken
            if let cookie = HTTPCookie(properties: [
                .domain: domain,
                .path: "/",
                .name: "session",
                .value: session,
                .secure: "FALSE",
                .discard: "TRUE"
            ]) {
                HTTPCookieStorage.shared.setCookie(cookie)
                print("Cookie inserted: \(cookie)")
            }
        }
    }

    public override func sendRequest(_ urlString: String, method: RequestMethod, params: [String: Any], headers: [String: String], useTTNet: Bool = true, completionHandler: @escaping ((Data) -> Void), failureHandler: @escaping ((Error) -> Void)) {
        guard let url = URL(string: urlString) else {
            let error: ResponseError = .invalidURL
            failureHandler(error)
            return
        }
        self.setCookie(url: url)
        let urlString = url.absoluteString
        
        if useTTNet {
            TTNetworkManager.shareInstance().requestForBinary(withResponse: urlString, params: params, method: method.httpMethod, needCommonParams: true, headerField: headers, enableHttpCache: false, autoResume: true, isCustomizedCookie: true, requestSerializer: TTPostDataHttpRequestSerializer.self, responseSerializer: nil, progress: nil, callback: { [weak self] error, jsonData, response in
                guard let data = jsonData as? Data else {
                    let error: ResponseError = .invalidData
                    failureHandler(error)
                    return
                }

                if let error = error {
                    failureHandler(error)
                } else {
                    completionHandler(data)
                }
            }, callbackInMainThread: false)
        } else {
            var afMethod: Alamofire.HTTPMethod = .get
            if method == .get {
                afMethod = .get
            } else {
                afMethod = .post
            }
            let encoding: ParameterEncoding = method == .get ? URLEncoding.default : JSONEncoding.default
            
            Alamofire.request(url,
                              method: afMethod,
                              parameters: params,
                              encoding: encoding,
                              headers: headers)
                .response(completionHandler: { [weak self] (res) in
                    guard let self = self else { return }

                    let error = res.error
                    let jsonData = res.data
                    let response = res.response
                    
                    guard let data = jsonData as? Data else {
                        let error: ResponseError = .invalidData
                        failureHandler(error)
                        return
                    }

                    if let error = error {
                        failureHandler(error)
                    } else {
                        completionHandler(data)
                    }
            })
        }
    }
    
    
    public override func sendRequest<T: LarkLiveRequest>(_ request: T, useTTNet: Bool = true, completionHandler: @escaping (Swift.Result<T.ResponseType, Error>) -> Void) {
        guard let url = URL(string: request.endpoint, relativeTo: baseURL) else {
            let error: ResponseError = .invalidURL
            completionHandler(.failure(error))
            return
        }
        self.setCookie(url: url)
        let urlString = url.absoluteString
        var requestDebugString = "\(type(of: request))[\(request.requestID)]"

        var headers = config.commonHeaders().merging(request.customHeaders) { $1 }
        // hack for referer
        headers["Referer"] = baseURL.absoluteString
        LiveAPI.logger.info("\(requestDebugString) ===> \(baseURL.host) ...")
        
        if useTTNet {
            TTNetworkManager.shareInstance()
                .requestForBinary(withResponse: urlString,
                                  params: request.parameters,
                                  method: request.method.httpMethod,
                                  needCommonParams: true,
                                  headerField: headers,
                                  enableHttpCache: false,
                                  autoResume: true,
                                  isCustomizedCookie: true,
                                  requestSerializer: TTPostDataHttpRequestSerializer.self,
                                  responseSerializer: nil,
                                  progress: nil,
                                  callback: { [weak self] error, jsonData, response in
                    if let logID = response?.allHeaderFields?["x-tt-logid"] {
                        requestDebugString += "[\(logID)]"
                    }
                    if let statusCode = response?.statusCode,
                        let error = ResponseError(rawValue: statusCode) {
                        LiveAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
                        completionHandler(.failure(error))
                        return
                    }
                    
                    self?.handleResponse(request, error: error, jsonData: jsonData, completionHandler: completionHandler)
            }, callbackInMainThread: false)
        } else {
            var method: Alamofire.HTTPMethod = .get
            if request.method == .get {
                method = .get
            } else {
                method = .post
            }
            let encoding: ParameterEncoding = method == .get ? URLEncoding.default : JSONEncoding.default
            
            Alamofire.request(url,
                              method: method,
                              parameters: request.parameters,
                              encoding: encoding,
                              headers: headers)
                .response(completionHandler: { [weak self] (res) in
                    guard let self = self else { return }

                    let error = res.error
                    let jsonData = res.data
                    let response = res.response
                    
                    if let logID = response?.allHeaderFields["x-tt-logid"] {
                        requestDebugString += "[\(logID)]"
                    }
                    if let statusCode = response?.statusCode,
                        let error = ResponseError(rawValue: statusCode) {
                        LiveAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
                        completionHandler(.failure(error))
                        return
                    }
                    
                    self.handleResponse(request, error: error, jsonData: jsonData, completionHandler: completionHandler)
            })
        }
    }
    
    private func handleResponse<T: LarkLiveRequest>(_ request: T, error: Error?, jsonData: Any?, completionHandler: @escaping (Swift.Result<T.ResponseType, Error>) -> Void) {
        let requestDebugString = "\(type(of: request))[\(request.requestID)]"

        guard let data = jsonData as? Data else {
            let error: ResponseError = .invalidData
            LiveAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
            completionHandler(.failure(error))
            return
        }

        if let error = error {
            LiveAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
            completionHandler(.failure(error))
        } else {
            do {
                let result = T.ResponseType.build(from: data)
                switch result {
                case .success:
                    LiveAPI.logger.info("\(requestDebugString) <=== success.")
                case .failure(let error):
                    LiveAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
                }
                completionHandler(result)
            } catch let error {
                LiveAPI.logger.warn("\(requestDebugString) <=== with error: \(error)")
                completionHandler(.failure(error))
            }
        }
    }
}
