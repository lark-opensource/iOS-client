//
//  WADataSessionHandler.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/26.
//

import Foundation
import LarkRustHTTP
import LKCommonsLogging

/// 兼容URLSession和RustHTTPSession的代理，方便切换测试
/// 系统URLSessionTaskDelegate会存在释放不及时的Bug, 每个容器使用一个实例来代理
class WADataSessionHandler: NSObject {
    static let logger = Logger.log(WADataSessionHandler.self, category: WALogger.TAG)
    
    func handleWillPerformHTTPRedirection(response: HTTPURLResponse,
                                          newRequest request: URLRequest,
                                          completionHandler: @escaping (URLRequest?) -> Void) {
        Self.logger.info("http 302, will redirection, from:\(response.url?.absoluteString ?? "") to: \(request.url?.absoluteString ?? "")", tag: LogTag.net.rawValue)
        if let url = request.url {
            var nextRequest = request
            if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
                //302后的req可能丢失cookie，需要手动设置
                //这里使用HTTPCookieStorage或WKCookie都可以，一般来说主进程的会同步较及时，不存在拿不到的情况
                nextRequest.setwk(cookies: cookies)
            }
            
            DispatchQueue.main.async {
                Self.logger.info("http 302, plant cookie start, from:\(response.url?.absoluteString ?? "")", tag: LogTag.net.rawValue)
                //302后的response cookie要及时种回到WK  syncCookiesToWK
                response.syncCookiesToWKHTTPCookieStore {
                    Self.logger.info("http 302, plant cookie end", tag: LogTag.net.rawValue)
                    completionHandler(nextRequest)
                }
            }
        } else {
            Self.logger.info("http 302, but invalid url", tag: LogTag.net.rawValue)
            completionHandler(request)
        }
    }
}

extension WADataSessionHandler: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        self.handleWillPerformHTTPRedirection(response: response,
                                              newRequest: request,
                                              completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Self.logger.info("urlsession didCompleteWithError, err:\(String(describing: error))", tag: LogTag.net.rawValue)
        session.finishTasksAndInvalidate()
    }
}

extension WADataSessionHandler: RustHTTPSessionTaskDelegate {
    func rustHTTPSession(_ session: RustHTTPSession,
                                task: RustHTTPSessionTask,
                                willPerformHTTPRedirection response: HTTPURLResponse,
                                newRequest request: URLRequest,
                                completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        
        self.handleWillPerformHTTPRedirection(response: response,
                                              newRequest: request,
                                              completionHandler: completionHandler)
    }
}
