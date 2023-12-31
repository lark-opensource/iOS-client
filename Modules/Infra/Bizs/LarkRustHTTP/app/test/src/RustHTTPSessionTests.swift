//
//  RustHTTPSessionTests.swift
//  LarkRustHTTPDevEEUnitTest
//
//  Created by SolaWing on 2023/4/23.
//

import XCTest
@testable import LarkRustHTTP
import Swifter

// swiftlint:disable line_length
// NOTE: large response with data completion: memory limit crash(in system)
// NOTE: delegate order: custom has willCache Call?
class RustHTTPSessionTests: URLProtocolTests {
    open override class func testSelectors() -> [String]? {
        return [
            // Basic
            NSStringFromSelector(#selector(testGetRequest)),
            NSStringFromSelector(#selector(testOptionsRequest)),
            NSStringFromSelector(#selector(testPostRequest)),
            NSStringFromSelector(#selector(testBodyStreamWithoutContentLengthShouldnotCrash)),
            NSStringFromSelector(#selector(testUploadTask)),
            NSStringFromSelector(#selector(testUploadFile)),
            NSStringFromSelector(#selector(testDownloadTask)),
            NSStringFromSelector(#selector(testHeaderRequest)),
            NSStringFromSelector(#selector(testPutPatchDeleteRequest)),
            NSStringFromSelector(#selector(testCancelRequest)),
            NSStringFromSelector(#selector(testBugs)),
            NSStringFromSelector(#selector(testMetrics)),
            NSStringFromSelector(#selector(test404Request)),
            // Redirect
            NSStringFromSelector(#selector(testRedirectCodeAndMethod)),
            NSStringFromSelector(#selector(testCanControlNoRedirect)),
            NSStringFromSelector(#selector(testRedirectCountShouldLimited)),
            // Cookie
            NSStringFromSelector(#selector(testCookieCanBeSaved)),
            NSStringFromSelector(#selector(testCookieSavePolicyCanbeControl)),
            NSStringFromSelector(#selector(testRequestWithCookie)),
            NSStringFromSelector(#selector(testRequestWithoutCookie)),
            // Other
            NSStringFromSelector(#selector(testCache)),
            NSStringFromSelector(#selector(testBasicAuth)),
            // Extension
            NSStringFromSelector(#selector(testRetryCount)),
            NSStringFromSelector(#selector(testSessionRetryCount))
        ]
    }
    override class var useRustNetwork: Bool { true }
    override class var registerProtocolClass: URLProtocol.Type? { nil }
    override class var sharedSession: BaseSession { RustHTTPSession.shared }
    override func makeSession(config: ((BaseSessionConfiguration) -> Void)? = nil, delegate: ((BaseSessionDelegate) -> Void)? = nil, delegateQueue: OperationQueue? = nil) -> BaseSession {
        let configuration = RustHTTPSessionConfig.default
        if let config { config(configuration) }
        let delegate = delegate.flatMap {
            let v = RustHTTPSessionTestDelegate()
            $0(v)
            return v
        }
        return makeSession(config: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    func makeSession(config: RustHTTPSessionConfig = .default, delegate: RustHTTPSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) -> RustHTTPSession {
        let session = RustHTTPSession(configuration: config, delegate: delegate, delegateQueue: delegateQueue)
        self.addTeardownBlock { session.invalidateAndCancel() }
        Self.sessions.append(.init(value: session))
        return session
    }
    static var sessions = [Weak<AnyObject>]()
    static func sessionCount() -> Int {
        sessions.removeAll { $0.value === nil }
        return sessions.count
    }

    class override func tearDown() {
        #if DEBUG
        precondition(RustHTTPSessionTask.resourceCounter.value == 0)
        precondition(runUntil(timeout: Date(timeIntervalSinceNow: 1), condition: sessionCount() == 0))
        #endif
        super.tearDown()
    }

    func testSessionRetryCount() {
        let responseText = "hello tester!"
        server["/retryCount"] = { req in
            let expect = req.headers["count"].flatMap { Int($0) } ?? 3
            let current = req.headers["cur"].flatMap { Int($0) } ?? 0
            if current < expect {
                return HttpResponse.internalServerError(nil)
            }
            return HttpResponse.ok(.text(responseText))
        }
        class Delegate: NSObject, RustHTTPSessionTaskDelegate {
            func rustHTTPSession(_ session: RustHTTPSession, shouldRetry task: RustHTTPSessionTask, with error: Error, completionHandler: @escaping (URLRequest?) -> Void) {
                if task.retryCount >= 3 {
                    completionHandler(nil)
                } else {
                    var req = task.originalRequest // originalTask不包含后续更改..
                    req.setValue(String(task.retryCount + 1), forHTTPHeaderField: "cur")
                    completionHandler(req)
                }
            }
            func rustHTTPSession(_ session: RustHTTPSession, validate task: RustHTTPSessionTask, body: RustHTTPBody?) -> Error? {
                guard let response = task.response else { return nil }
                if response.statusCode >= 500 {
                    struct ValidateError: Error {}
                    return ValidateError()
                }
                return nil
            }
        }
        let session = makeSession(delegate: Delegate())
        httpRequest(path: "/retryCount", in: session) { (data, response, error) in
            XCTAssertNil(error)
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertEqual(data, responseText.data(using: .utf8))
        }.resume()
        httpRequest(path: "/retryCount", headers: ["count": "4"], in: session) { (_, _, error) in
            XCTAssertNotNil(error, "excess max retry count should has error")
        }.resume()
        waitTasks()
    }
}
// 迁移TTNet后，复合连接能力好像没有了..
// class RustHTTPSessionComplexTests: RustHTTPSessionTests {
//     override var enableComplexConnect: Bool { true }
// }

extension RustHTTPSession: BaseSession {
    var baseConfiguration: BaseSessionConfiguration { self.configuration }
    func dataTask(with request: URLRequest) -> BaseSessionDataTask {
        return self.dataTask(with: request) as RustHTTPSessionDataTask
    }
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask {
        return self.dataTask(with: request, completionHandler: completionHandler) as RustHTTPSessionDataTask
    }
    func uploadTask(with request: URLRequest, from bodyData: Data, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask {
        return self.uploadTask(with: request, from: bodyData, completionHandler: completionHandler) as RustHTTPSessionDataTask
    }
    func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> BaseSessionDataTask {
        return self.uploadTask(with: request, fromFile: fileURL, completionHandler: completionHandler) as RustHTTPSessionDataTask
    }
    func downloadTask(with request: URLRequest, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> BaseSessionTask {
        return self.downloadTask(with: request, completionHandler: completionHandler) as RustHTTPSessionDownloadTask
    }
    func downloadTask(with request: URLRequest) -> BaseSessionTask {
        return self.downloadTask(with: request) as RustHTTPSessionDownloadTask
    }
}

extension RustHTTPSessionTask: BaseSessionTask {
    var rustMetrics: [LarkRustHTTP.RustHttpMetrics] {
        #if DEBUG || ALPHA
        return self._metrics.transactionMetrics
        #else
        return self.metrics.transactionMetrics
        #endif
    }
}

extension RustHTTPSessionDataTask: BaseSessionDataTask {}
extension RustHTTPSessionTaskMetrics: BaseSessionTaskMetrics {}

extension RustHTTPSessionConfig: BaseSessionConfiguration {
    func setHttpAdditionalHeaders(_ v: [String: String]?) {
        self.httpAdditionalHeaders = v
    }
}

class RustHTTPSessionTestDelegate: BaseSessionDelegate, RustHTTPSessionDataDelegate, RustHTTPSessionTaskDelegate, RustHTTPSessionDownloadDelegate {
    // swiftlint:disable line_length

    // var redirectionHandler: RedirectionHandler?
    // var authHandler: AuthHandler?
    // var receiveResponse: ReceiveResponse?
    // var finishCollecting: FinishCollecting?
    // var complete: Complete?

    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        log()
        if let handler = sendNotify {
            handler((session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend))
        }
    }
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        log()
        debug("\(dump(request: task.currentRequest)) --> \(dump(request: request))")
        if let handler = redirectionHandler {
            handler((session, task, response, request, completionHandler))
        } else {
            completionHandler(request) // default allow
        }
    }
    func rustHTTPSession(_ session: RustHTTPSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        log()
        if let authHandler = authHandler {
            authHandler((session, nil, challenge, completionHandler))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        log()
        if let authHandler = authHandler {
            authHandler((session, task, challenge, completionHandler))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didFinishCollecting metrics: RustHTTPSessionTaskMetrics) {
        log()
        if let v = finishCollecting { v((session, task, metrics)) }
    }
    func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (RustHTTPSession.ResponseDisposition) -> Void) {
        log()
        if let v = receiveResponse {
            v((session, dataTask, response, { completionHandler($0.toRustHTTPSessionResponseDisposition) }))
        } else {
            completionHandler(.allow)
        }
    }
    // func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, didBecome downloadTask: RustHTTPSessionDownloadTask) {
    //     // this allow task change to download task
    //     print("from dataTask \(ObjectIdentifier(dataTask)): \(dataTask.taskIdentifier), \(dataTask)\n to downloadTask \(ObjectIdentifier(downloadTask)): \(downloadTask.taskIdentifier)")
    // }
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, didCompleteWithError error: Error?) {
        log()
        if let v = complete { v((session, task, error)) }
    }
    func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, didReceive data: Data) {
        log()
        if let receiveData { receiveData((session, dataTask, data)) }
    }
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        log()
        completionHandler(nil)
    }
    func rustHTTPSession(_ session: RustHTTPSession, didBecomeInvalidWithError error: Error?) {
        log()
    }
    func rustHTTPSession(_ session: RustHTTPSession, dataTask: RustHTTPSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        log()
        completionHandler(proposedResponse)
    }
    func rustHTTPSession(_ session: RustHTTPSession, didCreateTask task: RustHTTPSessionTask) {
        log()
    }
    func rustHTTPSession(_ session: RustHTTPSession, task: RustHTTPSessionTask, willRequest request: RustHTTPRequest) {
        log()
    }
    func rustHTTPSession(_ session: RustHTTPSession, validate task: RustHTTPSessionTask, body: RustHTTPBody?) -> Error? {
        log()
        return nil
    }
    func rustHTTPSession(_ session: RustHTTPSession, shouldRetry task: RustHTTPSessionTask, with error: Error, completionHandler: @escaping (URLRequest?) -> Void) {
        log()
        completionHandler(nil)
    }
    func rustHTTPSession(_ session: RustHTTPSession, downloadTask: RustHTTPSessionDownloadTask, didFinishDownloadingTo location: URL) {
        log()
    }
    func rustHTTPSession(_ session: RustHTTPSession, downloadTask: RustHTTPSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        log()
    }
    // swiftlint:enable line_length
}

extension BaseSessionDelegate.ResponseDisposition {
    var toRustHTTPSessionResponseDisposition: RustHTTPSession.ResponseDisposition {
        switch self {
        case .allow: return .allow
        case .becomeDownload:
            // TODO: 支持task转换？感觉意义不大
            return .allow
        }
    }
}
