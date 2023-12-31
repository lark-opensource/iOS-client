//
//  RustCaptchaAPI.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/5.
//

import Foundation
import RustPB
import LarkRustClient
import LarkFoundation
import RxSwift
import RxCocoa
import LarkContainer
import LKCommonsLogging

typealias GetCaptchaEncryptedTokenRequest = Tool_V1_GetCaptchaEncryptedTokenRequest
typealias GetCaptchaEncryptedTokenResponse = Tool_V1_GetCaptchaEncryptedTokenResponse

class RustCaptchaAPI: CaptchaAPI {
    static let logger = Logger.plog(RustCaptchaAPI.self, category: "SuiteLogin.RustCaptchaAPI")

    @Provider var service: GlobalRustService

    private let disposeBag = DisposeBag()

    func captchaToken(method: String, body: String, result: @escaping (Result<String, V3LoginError>) -> Void) {
        var request = GetCaptchaEncryptedTokenRequest()
        request.method = method
        request.requestBody = body
        request.appVersion = Utils.appVersion
        request.devicePlatform = "ios"
        service.sendAsyncRequest(request)
            .map({ (response) -> GetCaptchaEncryptedTokenResponse in
                return response.response
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { resp in
                result(.success(resp.token))
            }, onError: { error in
                Self.logger.error("GetCaptchaEncryptedTokenRequest method:\(method) appVersion:\(request.appVersion) error:\(error.localizedDescription)")
                result(.failure(.server(error)))
            })
            .disposed(by: disposeBag)
    }
}
