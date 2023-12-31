//
//  UnregisterService.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/5/14.
//

import Foundation
import LarkContainer
import RxSwift

final class UnregisterService {

    private var unregisterAPI: UnregisterAPI

    init(resolver: UserResolver?) throws {
        if let r = resolver {
            unregisterAPI = try r.resolve(assert: UnregisterAPI.self)
        } else {
            unregisterAPI = try Container.shared.resolve(assert: UnregisterAPI.self) // user:checked (global-resolve)
        }
    }

    func checkUnRegisterStatus(scope: Int?, success: @escaping OnStepSuccessV3, error: @escaping OnFailureV3) {
        unregisterAPI.checkUnRegisterStatus(scope: scope, success: success, failure: error)
    }
}

class V3UnregisterRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
         self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)
     }
}

final class UnregisterAPI: APIV3 {

    func checkUnRegisterStatus(scope: Int?, success: @escaping OnStepSuccessV3, failure: @escaping OnFailureV3) {
        var params: [String: Any] = [:]
        if let scope = scope {
            params["scene"] = scope
        }
        params["source"] = 1 //代表 native 请求的接口
        let req = V3UnregisterRequest<V3.Step>(pathSuffix: APPID.deprovisionCheck.apiIdentify())
        req.body = params
        req.method = .get
        req.domain = .passportAccounts()
        client.send(req, success: { (resp, _) in
            success(resp.stepData.nextStep, resp.stepData.stepInfo)
        }, failure: failure)
    }
}
