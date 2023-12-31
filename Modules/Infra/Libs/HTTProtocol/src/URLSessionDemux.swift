//
//  URLSessionDemux.swift
//  HTTProtocol
//
//  Created by SolaWing on 2019/7/21.
//

import Foundation

/// Demux a URLSession delegate to multiple task based delegate
/// NOTE: the callback thread is not the same as the starting thread
final class URLSessionDemux: NSObject, URLSessionDataDelegate {
    private(set) var session: URLSession = .shared // `.shared` will be replaced after initialization
    private var delegateByIdentifier = [Int: URLSessionDataDelegate]()
    private var lock = DispatchSemaphore(value: 1)
    init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    /// NOTE: delegate will be a strong ref
    func dataTask(with request: URLRequest, delegate: URLSessionDataDelegate) -> URLSessionDataTask {
        let task = self.session.dataTask(with: request)
        lock.wait()
        delegateByIdentifier[task.taskIdentifier] = delegate
        lock.signal()
        return task
    }
    private func delegate(for task: URLSessionTask) -> URLSessionDataDelegate? {
        lock.wait(); defer { lock.signal() }
        return delegateByIdentifier[task.taskIdentifier]
    }
    // MARK: - URLSessionDelegate
    // swiftlint:disable line_length
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.wait()
        let taskDelegate = delegateByIdentifier.removeValue(forKey: task.taskIdentifier)
        lock.signal()
        guard let delegate = taskDelegate, let fn = delegate.urlSession(_:task:didCompleteWithError:) else {
            return
        }
        fn(session, task, error)
    }
    @available(iOS 10.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let delegate = delegate(for: task), let fn = delegate.urlSession(_:task:didFinishCollecting:) else {
            // TODO: check if the delegate exist? didCompleteWithError and this, which will be called first?
            return
        }
        fn(session, task, metrics)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard let delegate = delegate(for: task), let fn = delegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:) else {
            completionHandler(request) // default redirect, same as system
            return
        }
        fn(session, task, response, request, completionHandler)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let delegate = delegate(for: task), let fn = delegate.urlSession(_:task:didReceive:completionHandler:) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        fn(session, task, challenge, completionHandler)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let delegate = delegate(for: dataTask), let fn = delegate.urlSession(_:dataTask:didReceive:completionHandler:) else {
            completionHandler(.allow)
            return
        }
        fn(session, dataTask, response, completionHandler)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        guard let delegate = delegate(for: dataTask), let fn = delegate.urlSession(_:dataTask:didBecome:) as ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)? else {
            return
        }
        fn(session, dataTask, downloadTask)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        guard let delegate = delegate(for: dataTask), let fn = delegate.urlSession(_:dataTask:didBecome:) as ((URLSession, URLSessionDataTask, URLSessionStreamTask) -> Void)? else {
            return
        }
        fn(session, dataTask, streamTask)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let delegate = delegate(for: dataTask), let fn = delegate.urlSession(_:dataTask:didReceive:) else {
            return
        }
        fn(session, dataTask, data)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        guard let delegate = delegate(for: dataTask), let fn = delegate.urlSession(_:dataTask:willCacheResponse:completionHandler:) else {
            completionHandler(proposedResponse)
            return
        }
        fn(session, dataTask, proposedResponse, completionHandler)
    }
    // swiftlint:enable line_length
}
