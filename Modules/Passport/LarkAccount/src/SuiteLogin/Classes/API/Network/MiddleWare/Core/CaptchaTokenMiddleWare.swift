//
//  CaptchaTokenMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation

private extension PassportRequest {
    enum CapatcheMethodResult {
        case ok(String)
        case error(V3LoginError)
    }
    func getCaptchaMethod() -> CapatcheMethodResult {
        var captchaMethod = "/\(path)"
        switch method {
        // TODO: 目前只有suite/passport/devices 使用PATCH
        // 并且在url的query中添加参数，所以先加在query上，实际上要支持queryParams 和 bodyParams
        case .get, .patch:
            let apiURL = SuiteLoginUtil.queryURL(urlString: url, params: getCombinedParams())
            guard let url = apiURL else {
                self.logger.error("construct get url fail apiInfo: \(self.url)")
                return .error(.badServerData)
            }
            if let query = url.query {
                captchaMethod = "\(captchaMethod)?\(query)"
            }
            return .ok(captchaMethod)
        case .post, .delete:
            return .ok(captchaMethod)
        }
    }

    func getCaptchaBody() -> String {
        switch method {
        case .get, .patch:
            return ""
        case .post, .delete:
            return getCombinedParams().jsonString()
        }
    }
}

class CaptchaTokenMiddleWare: HTTPMiddlewareProtocol {

    let helper: V3APIHelper

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .request: .low
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {

        switch request.getCaptchaMethod() {
        case .ok(let captchaMethod):
            helper.captchaToken(
            method: captchaMethod,
            body: request.getCaptchaBody(),
            result: { (res) in
                switch res {
                case .success(let token):
                    request.context.extraHeaders[CommonConst.captchaToken] = token
                    request.context.token = token
                    complete()
                case .failure(let err):
                    request.context.error = err
                    complete()
                }
            })
        case .error(let err):
            request.context.error = err
            complete()
        }
    }
}
