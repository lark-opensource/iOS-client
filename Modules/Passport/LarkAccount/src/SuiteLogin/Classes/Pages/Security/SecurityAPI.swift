//
//  SecurityAPI.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/9/4.
//

import Foundation
import RxSwift

enum SecurityError: String {
    case userCancel = "User canceled, security verification failed."
    case incorrectPwd = "Incorrect password,security verification failed."
    case incorrectPwdRestrict = "Incorrect password is entered too many times,security verification failed."
}

typealias OnStepSuccess = (_ step: V3.Step) -> Void

class SecurityAPI: APIV3 {
    
    func checkSecurityPasswordStatus(completion: @escaping (Bool, V3LoginError?) -> Void) {
        _ = checkSecurityPasswordStatus { step in
            if let isOpen = step.stepData.stepInfo["is_open"] as? Bool {
                completion(isOpen, nil)
            } else {
                completion(false, .badServerData)
            }
        } failure: { error in
            completion(false, error)
        }
    }
    
    func checkSecurityPasswordStatus(success: @escaping OnStepSuccess, failure: @escaping OnFailureV3) -> AfterLoginRequest<V3.Step> {
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.accountSecurityApiPath, pathSuffix: APPID.checkSecPwd.apiIdentify())
        req.method = .post
        req.domain = .passportAccounts()
        client.send(req) { response, header in
            success(response)
        } failure: { error in
            failure(error)
        }

        return req
    }
    
    func setSecurityPassword(serverInfo: ServerInfo, password: String, success: @escaping OnStepSuccessV3, failure: @escaping OnFailureV3) -> AfterLoginRequest<V3.Step> {
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.accountAuthApiPath, pathSuffix: "sec_pwd/set")
        req.configDomain(serverInfo: serverInfo)
        req.method = .post
        let params: [String: Any] = [
            "sec_pwd": password,
            CommonConst.flowType: serverInfo.flowType ?? "",
        ]
        req.body = params
        client.send(req, success: success, failure: failure)
        return req
    }
    
    func verifySecurityPassword(serverInfo: ServerInfo, appID: String, password: String, success: @escaping OnStepSuccessV3, failure: @escaping OnFailureV3) -> AfterLoginRequest<V3.Step> {
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.accountAuthApiPath, pathSuffix: "sec_pwd/verify")
        req.configDomain(serverInfo: serverInfo)
        req.method = .post
        let params: [String: Any] = [
            "sec_pwd": password,
            CommonConst.flowType: serverInfo.flowType ?? "",
            "app_id": appID,
        ]
        req.body = params
        client.send(req, success: success, failure: failure)
        return req
    }

}
