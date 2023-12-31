//
//  RNNetWorkSession.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/5/9.
//  重构RNNetWorkHttpHandler，封装URLSession和RustHTTPSession

import Foundation
import LarkRustHTTP
import SKFoundation

public protocol RNNetWorkSession {
    func dataTaskAndResume(with request: URLRequest, delegate: RCTURLRequestDelegate) -> Any?
    func cancelRequest(_ requestToken: Any?)
    func invalidate()

}

// MARK: RN use URLSession
public class RNNetWorkURLSession: NSObject, RNNetWorkSession {
 
    
    private let lock: NSLock
    private var urlSession: URLSession?
    private var delegateDic: [URLSessionTask: RCTURLRequestDelegate] = [:]
    
    init(delegateQueue: OperationQueue?, lock: NSLock) {
        self.lock = lock
        super.init()
        let config = URLSessionConfiguration.default
        if DocsSDK.isEnableRustHttp {
            config.protocolClasses = [SKRustHTTPURLProtocol.self]
        }
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        config.httpCookieStorage = HTTPCookieStorage.shared
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
    }
    
    //注意这个方法不要加Lock，为了保持之前的代码不变，已经在RNNetWorkHttpHandler进行加锁操作，再调用当前方法
    public func dataTaskAndResume(with request: URLRequest, delegate: RCTURLRequestDelegate) -> Any? {
        let dataTask = self.urlSession?.dataTask(with: request)
        if let dataTask = dataTask {
            delegateDic.updateValue(delegate, forKey: dataTask)
        }
        dataTask?.resume()
        DocsLogger.info("rnNetHttp net create dataTask with URLSession", component: LogComponents.net)
        return dataTask
    }
    
    public func cancelRequest(_ requestToken: Any?) {
        guard let task = requestToken as? URLSessionDataTask else {
            return
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        delegateDic.removeValue(forKey: task)
        task.cancel()
    }
    
    public func invalidate() {
        lock.lock()
        defer {
            lock.unlock()
        }
        urlSession?.invalidateAndCancel()
        urlSession = nil
        delegateDic.removeAll()
    }

}

extension RNNetWorkURLSession: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        lock.lock()
        let deletate = delegateDic[task]
        lock.unlock()
        deletate?.urlRequest(task, didSendDataWithProgress: totalBytesSent)
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        lock.lock()
        let deletate = delegateDic[dataTask]
        lock.unlock()
        deletate?.urlRequest(dataTask, didReceive: response)
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        lock.lock()
        let deletate = delegateDic[dataTask]
        lock.unlock()
        deletate?.urlRequest(dataTask, didReceive: data)
    }

    public func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        lock.lock()
        let deletate = delegateDic[task]
        delegateDic.removeValue(forKey: task)
         lock.unlock()
        if let error = error {
            let errmsg: String = {
                let nsErr = error as NSError
                return "\(nsErr.code):\(nsErr.domain)"
            }()
            DocsLogger.info("rnNetHttp net URLSession error: \(errmsg)", extraInfo: nil, error: nil, component: LogComponents.net)
        }
        deletate?.urlRequest(task, didCompleteWithError: error)

    }

    public func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url {
            var nextRequest = request
            let cookies = HTTPCookieStorage.shared.cookies(for: url)
            nextRequest.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies ?? [])
            completionHandler(nextRequest)
        }
    }

}



// MARK: RN use RustHTTPSession
public class RNNetWorkRustSession: NSObject, RNNetWorkSession {
    
    private let lock: NSLock
    private var rustSession: RustHTTPSession?
    private var delegateRustDic: [RustHTTPSessionTask: RCTURLRequestDelegate] = [:]
    
    init(delegateQueue: OperationQueue?, lock: NSLock) {
        self.lock = lock
        super.init()
        let config = RustHTTPSessionConfig.default
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        rustSession = RustHTTPSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
    }
    
    //注意这个方法不要加Lock，为了保持之前的代码不变，已经在RNNetWorkHttpHandler进行加锁操作，再调用当前方法
    public func dataTaskAndResume(with request: URLRequest, delegate: RCTURLRequestDelegate) -> Any? {
        let dataTask = self.rustSession?.dataTask(with: request)
        if let dataTask = dataTask {
            delegateRustDic.updateValue(delegate, forKey: dataTask)
        }
        dataTask?.resume()
        DocsLogger.info("rnNetHttp net create dataTask with RustHTTPSession", component: LogComponents.net)
        return dataTask
    }
    
    public func cancelRequest(_ requestToken: Any?) {
        guard let task = requestToken as? RustHTTPSessionTask else {
            return
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        delegateRustDic.removeValue(forKey: task)
        task.cancel()
    }
    
    public func invalidate() {
        lock.lock()
        defer {
            lock.unlock()
        }
        rustSession?.invalidateAndCancel()
        rustSession = nil
        delegateRustDic.removeAll()
    }
}

extension RNNetWorkRustSession: RustHTTPSessionTaskDelegate, RustHTTPSessionDataDelegate {
    public func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64) {
        lock.lock()
        let deletate = delegateRustDic[task]
        lock.unlock()
        deletate?.urlRequest(task, didSendDataWithProgress: totalBytesSent)
    }
    
    public func rustHTTPSession(
        _ session: RustHTTPSession,
        dataTask: RustHTTPSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (RustHTTPSession.ResponseDisposition) -> Void) {
            lock.lock()
            let deletate = delegateRustDic[dataTask]
            lock.unlock()
            deletate?.urlRequest(dataTask, didReceive: response)
            completionHandler(.allow)
        }
    
    public func rustHTTPSession(
        _ session: RustHTTPSession,
        dataTask: RustHTTPSessionDataTask,
        didReceive data: Data) {
            lock.lock()
            let deletate = delegateRustDic[dataTask]
            lock.unlock()
            deletate?.urlRequest(dataTask, didReceive: data)
        }


    public func rustHTTPSession(
        _ session: RustHTTPSession,
        task: RustHTTPSessionTask,
        didCompleteWithError error: Error? ){
            lock.lock()
            let deletate = delegateRustDic[task]
            delegateRustDic.removeValue(forKey: task)
            lock.unlock()
            if let error = error {
                let errmsg: String = {
                    let nsErr = error as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                DocsLogger.info("rnNetHttp net RustHTTPSession error: \(errmsg)", extraInfo: nil, error: nil, component: LogComponents.net)
            }
            deletate?.urlRequest(task, didCompleteWithError: error)
        }

    public func rustHTTPSession(
       _ session: RustHTTPSession,
       task: RustHTTPSessionTask,
       willPerformHTTPRedirection response: HTTPURLResponse,
       newRequest request: URLRequest,
       completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
           if let url = request.url {
               var nextRequest = request
               let cookies = HTTPCookieStorage.shared.cookies(for: url)
               nextRequest.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies ?? [])
               completionHandler(nextRequest)
           }
       }
}


