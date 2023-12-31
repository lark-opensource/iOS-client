//
//  WAResourceInterceptor.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/10/23.
//

import SKFoundation
import LarkWebViewContainer
import LarkExtensions
import ThreadSafeDataStructure
import LKCommonsLogging

class WAResourceInterceptor: NSObject, WKResourceInterceptProtocol {
    static let logger = Logger.log(WAWebView.self, category: WALogger.TAG)
    
    var dataSessionList = SafeDictionary<String, WADataSession>()
    weak var dataDelegate: WADataSessionDelegate?
    let sessionHanlder = WADataSessionHandler()
    
    deinit {
        Self.logger.info("WebAppResourceInterceptor deinit, dataSessionList: \(dataSessionList.count)", tag: LogTag.net.rawValue)
        dataSessionList.forEach { _, val in
            val.invalidateAndCancel()
        }
        dataSessionList.removeAll()
    }
    
    func shouldInterceptRequest(webView: WKWebView, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>?) -> Void) {
        guard let url = request.url else {
            completionHandler(.failure(NSError(domain: "WebAppResourceIntercept", code: WebAppDataSessionErrorCode.invalidParam.rawValue)))
            return
        }
        let urlForLog = url.urlForLog
        Self.logger.info("intercept start url:\(urlForLog)", tag: LogTag.net.rawValue)
        
        let session = WADataSession(request: request, sessionHanlder: sessionHanlder, delegate: self.dataDelegate)
        dataSessionList.updateValue(session, forKey: session.key)
        
        session.start { [weak self, weak session] data, response, error in
            defer {
                if let session = session {
                    session.finishTasksAndInvalidate()
                    self?.dataSessionList.removeValue(forKey: session.key)
                }
            }
            if let error = error {
                Self.logger.error(" intercept,rsp error \(error), url: \(urlForLog)", tag: LogTag.net.rawValue)
                completionHandler(.failure(error))
            } else {
                if let response = response, let data = data {
                    if response.statusCode == DocsNetworkError.HTTPStatusCode.MovedTemporarily.rawValue, let redirectStr = response.allHeaderFields["location"] as? String,
                       let redirectUrl = URL(string: redirectStr) {
                        Self.logger.warn(" intercept, rsp 302, url: \(urlForLog), new location: \(redirectUrl)", tag: LogTag.net.rawValue)
                    } else if response.statusCode >= DocsNetworkError.HTTPStatusCode.BadRequest.rawValue {
                        Self.logger.error(" intercept, rsp error code:\(response.statusCode), url: \(urlForLog)", tag: LogTag.net.rawValue)
                    } else {
                        Self.logger.info(" intercept, rsp code:\(response.statusCode), url: \(urlForLog)", tag: LogTag.net.rawValue)
                    }
                    completionHandler(.success((response, data)))
                } else {
                    Self.logger.error(" intercept, rsp invalid , url: \(urlForLog)", tag: LogTag.net.rawValue)
                    completionHandler(.failure(NSError(domain: "WebAppResourceIntercept", code: WebAppDataSessionErrorCode.invalidParam.rawValue)))
                }
            }
        }
        
    }
    
    var jssdk: String = ""
}

