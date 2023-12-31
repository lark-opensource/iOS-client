//
//  RetryHandler.swift
//  DocsSDK
//
//  Created by huahuahu on 2019/1/24.
//

import Foundation
import Alamofire

/// 负责处理重试逻辑
class RetryHandler {
    let requestContext: MailRequestContext
    var retryCount: UInt

    /// 原始的URLRequest
    var rawRequest: URLRequest?
    var onError: ((Request, Error) -> Void)?

    init(context: MailRequestContext, retryCount: UInt) {
        requestContext = context
        self.retryCount = retryCount
    }

    lazy var retryAction: RetryAction? = {
        return { [weak self] (request: Request, error: Error) in
            guard let `self` = self, let urlError = error as? URLError  else {
                return (false, 0)
            }
            if request.retryCount < self.retryCount && urlError.code == URLError.timedOut {
                let extraInfo: [String: Any] = ["url": request.request?.url?.absoluteString ?? "",
                                                "error": error.localizedDescription,
                                                "retryCount": request.retryCount ]
                return (true, 1)
            } else {
                return (false, 0)
            }
        }
    }()

    func addRetryFor(_ request: Request?, onError action: ((Request, Error) -> Void)? = nil) {
        guard let request = request else { return }
        guard rawRequest == nil else {
            return
        }
        onError = action
        rawRequest = request.request
        requestContext.session.addSessionEventHandler(self)
    }

    func removeRetryFor(_ request: Request?) {
        guard let request = request else { return }
        guard request.request == rawRequest else { return }
        requestContext.session.removeSessionEventHandler(self)
    }
}

extension RetryHandler: SessionEventHandler {
    func request() -> URLRequest? {
        return rawRequest
    }

    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        onError?(request, error)
        guard let (shouldRetry, delay) = retryAction?(request, error) else {
            completion(false, 0)
            return
        }
        completion(shouldRetry, delay)
    }
}
