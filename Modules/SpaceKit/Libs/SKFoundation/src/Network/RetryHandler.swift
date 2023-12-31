//
//  RetryHandler.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/24.
//

import Foundation
import Alamofire

/// 负责处理重试逻辑
class RetryHandler {
    let requestContext: DocsRequestContext
    var retryCount: UInt

    /// 原始的URLRequest
    var rawRequest: URLRequest?
    var onError: ((URLRequest?, UInt, Error) -> Void)?

    init(context: DocsRequestContext, retryCount: UInt) {
        requestContext = context
        self.retryCount = retryCount
    }

    lazy var retryAction: RetryAction? = {
        return { [weak self] (request: URLRequest?, currentRetryCount: UInt, error: Error) in
            guard let `self` = self, let urlError = error as? URLError  else {
                return (false, 0)
            }
            if currentRetryCount < self.retryCount && (urlError.code == URLError.timedOut || urlError.localizedDescription == "request timed out") {
                let extraInfo: [String: Any] = ["error": error.localizedDescription.toBase64(),
                                                "retryCount": currentRetryCount ]
                DocsLogger.info("networkretry", extraInfo: extraInfo, error: nil, component: nil)
                return (true, 1)
            } else {
                return (false, 0)
            }
        }
    }()

    func addRetryFor(_ request: URLRequest?, onError action: ((URLRequest?, UInt, Error) -> Void)? = nil) {
        guard let request = request else { return }
        guard rawRequest == nil else {
            spaceAssertionFailure("只能为一个request 添加重试逻辑")
            return
        }
        onError = action
        rawRequest = request
        requestContext.session.addSessionEventHandler(self)
    }

    func removeRetryFor(_ request: URLRequest?) {
        guard let request = request else { return }
        guard request == rawRequest else { return }
        requestContext.session.removeSessionEventHandler(request)
    }
}

extension RetryHandler: SessionEventHandler {
    func request() -> URLRequest? {
        return rawRequest
    }

    func should(_ manager: Alamofire.SessionManager?, retry request: URLRequest?, currentRetryCount: UInt, with error: Error, completion: @escaping Alamofire.RequestRetryCompletion) {
        onError?(request, currentRetryCount, error)

        guard let (shouldRetry, delay) = retryAction?(request!, currentRetryCount, error) else {
            completion(false, 0)
            return
        }
        completion(shouldRetry, delay)
    }
}
