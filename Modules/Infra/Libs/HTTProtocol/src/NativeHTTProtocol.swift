//
//  NativeHTTProtocol.swift
//  HTTProtocol
//
//  Created by SolaWing on 2019/7/21.
//

import Foundation

/// http protocol use native's implementation.
/// this is mainly for provide a native implementation for WKHTTPHandler, which need a implementation when try to redirect
/// so this can make implement function like local cache easily.
open class NativeHTTProtocol: BaseHTTProtocol, HTTProtocolHandler, URLSessionDataDelegate {
    public override class func canInit(with task: URLSessionTask) -> Bool {
        /// not support task, only support request.
        /// this may prevent get a task with nil current request?
        /// NOTE: in iOS 13, return false will cause protocol be skip, and will not check canInit(with request)
        return false
    }

    static let demuxSession = URLSessionDemux()
    override public var handler: HTTProtocolHandler { return self }
    public var dataTask: URLSessionTask? // use on start thread
    typealias AuthCompletionHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    var authCompletionHandler: AuthCompletionHandler?

    // TODO: currently only support shared cache, and basic request. not support URLSession dataTask
    public func startLoading(request: BaseHTTProtocol) {
        let task = NativeHTTProtocol.demuxSession.dataTask(with: self.request, delegate: self)
        self.dataTask = task
        task.resume()
    }

    public func stopLoading(request: BaseHTTProtocol) {
        if let dataTask = self.dataTask {
            dataTask.cancel()
            self.dataTask = nil
        }
        self.authCompletionHandler = nil
    }

    // MARK: - URLSessionDataDelegate
    // swiftlint:disable line_length
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        workQueue?.async { [weak self] in
            guard let self = self else { return }
            self.dataTask = nil
            if let error = error {
                self.response(event: .error(error))
            } else {
                self.response(event: .finish)
            }
        }
    }
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // 进入URLProtocol时，request只提供bodyStream, 但如果原来是body的，每次访问bodyStream都会得到一个新stream.
        // 但是URLSesssion给的request, body stream是已经用光了的。
        // 进一步即使这里用新stream替换了重定向的stream, 如果再次重定向，就没机会得到新的stream了.
        // 所以需要用原request copy后修改赋值
        let newRequest: URLRequest
        if request.httpBodyStream != nil {
            var v = self.request
            v.url = request.url
            v.mainDocumentURL = request.mainDocumentURL
            v.httpMethod = request.httpMethod
            newRequest = v
        } else {
            newRequest = request
        }
        self.response(event: .redirect(newRequest: newRequest, response: response))
        completionHandler(nil) // disable redirect to allow caller do redirect
    }
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        workQueue?.async { [weak self] in
            guard let `self` = self else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            // original challenge sender will crash app by unknown selector
            // FIXME: if challenge multiple times, still have memory leak
            let copy = URLAuthenticationChallenge(authenticationChallenge: challenge, sender: self)
            self.authCompletionHandler = completionHandler
            self.response(event: .challenge(copy))
        }
    }
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // FIXME: use default shared cache. caller not need to save it.
        self.response(event: .receive(response: response, policy: .notAllowed))
        completionHandler(.allow)
    }
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.response(event: .data(data))
    }
    // swiftlint:enable line_length
}

// URLSession provide URLAuthenticationChallenge's sender not implement all method, and cause doesn't found method crash. specifically, `performDefaultHandlingForAuthenticationChallenge` not implement
// official doc say not use sender in URLSessionAPI, always use completion Handler.
// @see `https://stackoverflow.com/questions/27604052/nsurlsessiontask-authentication-challenge-completionhandler-and-nsurlauthenticat?rq=1`
extension NativeHTTProtocol: URLAuthenticationChallengeSender {
    public func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        authCompletionHandler?(.useCredential, credential)
    }

    public func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        authCompletionHandler?(.useCredential, nil)
    }

    public func cancel(_ challenge: URLAuthenticationChallenge) {
        authCompletionHandler?(.cancelAuthenticationChallenge, nil)
    }

    public func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        authCompletionHandler?(.performDefaultHandling, nil)
    }

    public func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
        authCompletionHandler?(.rejectProtectionSpace, nil)
    }
}
