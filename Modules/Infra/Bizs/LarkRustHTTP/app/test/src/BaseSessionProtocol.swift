//
//  BaseSessionProtocol.swift
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2023/4/24.
//

import Foundation
@testable import LarkRustHTTP

// swiftlint:disable line_length identifier_name
protocol BaseSession: AnyObject {
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask
    func dataTask(with request: URLRequest) -> BaseSessionDataTask
    func uploadTask(with request: URLRequest, from bodyData: Data, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask
    func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask
    func downloadTask(with request: URLRequest, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> BaseSessionTask
    func downloadTask(with request: URLRequest) -> BaseSessionTask
    func invalidateAndCancel()
    var baseConfiguration: BaseSessionConfiguration { get }
    var accessibilityHint: String? { get set }
}

protocol BaseSessionTask: AnyObject {
    func resume()
    func cancel()
    var rustMetrics: [RustHttpMetrics] { get }
}
protocol BaseSessionDataTask: BaseSessionTask {}

extension URLSessionTask: BaseSessionTask {}
extension URLSessionDataTask: BaseSessionDataTask {}

extension URLSession: BaseSession {
    var baseConfiguration: BaseSessionConfiguration { self.configuration  }
    func dataTask(with request: URLRequest) -> BaseSessionDataTask {
        return self.dataTask(with: request) as URLSessionDataTask
    }
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask {
        return self.dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }
    func uploadTask(with request: URLRequest, from bodyData: Data, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask {
        return self.uploadTask(with: request, from: bodyData, completionHandler: completionHandler) as URLSessionUploadTask
    }
    func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask {
        return self.uploadTask(with: request, fromFile: fileURL, completionHandler: completionHandler) as URLSessionUploadTask
    }
    func downloadTask(with request: URLRequest, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> BaseSessionTask {
        return self.downloadTask(with: request, completionHandler: completionHandler) as URLSessionDownloadTask
    }
    func downloadTask(with request: URLRequest) -> BaseSessionTask {
        return self.downloadTask(with: request) as URLSessionDownloadTask
    }
}

// MARK: BaseSessionBuilder
protocol BaseSessionConfiguration: AnyObject {
    func setHttpAdditionalHeaders(_ v: [String: String]?)
    var requestCachePolicy: URLRequest.CachePolicy { get set }
    var httpCookieStorage: HTTPCookieStorage? { get set }
    var httpShouldSetCookies: Bool { get set }
    var urlCache: URLCache? { get set }
}

protocol BaseSessionTaskMetrics: AnyObject {
}
extension URLSessionTaskMetrics: BaseSessionTaskMetrics {
}
class BaseSessionDelegate: NSObject {
    var enableLog = true
    var called: [String] = []
    func log(function: String = #function) {
        guard enableLog else { return }
        print("Delegate - \(function)")
        called.append(function)
    }

    enum ResponseDisposition {
        case allow // currently only this implement
        case becomeDownload
        var toURLSessionResponseDisposition: URLSession.ResponseDisposition {
            switch self {
            case .allow: return .allow
            case .becomeDownload: return .becomeDownload
            }
        }
    }

    typealias SendNotifiy = ((session: BaseSession, task: BaseSessionTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)) -> Void
    typealias RedirectionHandler = ((session: BaseSession, task: BaseSessionTask, response: HTTPURLResponse, newRequest: URLRequest, completionHandler: ((URLRequest?) -> Void))) -> Void
    typealias AuthHandler = ((session: BaseSession, task: BaseSessionTask?, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)) -> Void
    typealias ReceiveResponse = ((session: BaseSession, task: BaseSessionDataTask, response: URLResponse, completionHandler: (ResponseDisposition) -> Void)) -> Void
    typealias ReceiveData = ((session: BaseSession, task: BaseSessionDataTask, data: Data)) -> Void
    typealias Complete = ((session: BaseSession, task: BaseSessionTask, error: Error?)) -> Void
    typealias FinishCollecting = ((session: BaseSession, task: BaseSessionTask, metrics: BaseSessionTaskMetrics)) -> Void
    // storage
    var sendNotify: SendNotifiy?
    var redirectionHandler: RedirectionHandler?
    var authHandler: AuthHandler?
    var receiveResponse: ReceiveResponse?
    var receiveData: ReceiveData?
    var finishCollecting: FinishCollecting?
    var complete: Complete?

}
extension URLSessionConfiguration: BaseSessionConfiguration {
    func setHttpAdditionalHeaders(_ v: [String: String]?) {
        self.httpAdditionalHeaders = v
    }
}

class URLSessionTestDelegate: BaseSessionDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        log()
        if let handler = sendNotify {
            handler((session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend))
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        log()
        debug("\(dump(request: task.currentRequest)) --> \(dump(request: request))")
        if let handler = redirectionHandler {
            handler((session, task, response, request, completionHandler))
        } else {
            completionHandler(request) // default allow
        }
    }
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        log()
        if let authHandler = authHandler {
            authHandler((session, nil, challenge, completionHandler))
        } else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        log()
        if let authHandler = authHandler {
            authHandler((session, task, challenge, completionHandler))
        } else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        log()
        if let v = finishCollecting { v((session, task, metrics)) }
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        log()
        if let v = receiveResponse {
            v((session, dataTask, response, { completionHandler($0.toURLSessionResponseDisposition) }))
        } else {
            completionHandler(.allow)
        }
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        log()
        if let receiveData { receiveData((session, dataTask, data)) }
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        log()
        completionHandler(proposedResponse)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        log()
        // this allow task change to download task
        print("from dataTask \(ObjectIdentifier(dataTask)): \(dataTask.taskIdentifier), \(dataTask)\n to downloadTask \(ObjectIdentifier(downloadTask)): \(downloadTask.taskIdentifier)")
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        log()
        if let v = complete { v((session, task, error)) }
    }
    // MARK: Download
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        log()
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        log()
    }
}

class URLSessionTaskTestDelegate: URLSessionTestDelegate {
    override func log(function: String = #function) {
        print("Delegate(Task) - \(function)")
        called.append(function)
    }
}

// swiftlint:enable line_length identifier_name
