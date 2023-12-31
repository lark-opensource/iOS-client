//
//  CredentialAPI.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/5/12.
//

import Foundation
import RxSwift
import LarkContainer

class CredentialRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)
    }
}

class CredentialModifyRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
         self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)
        self.middlewareTypes = [
            .requestCommonHeader,
            .saveToken
        ]
     }
}

enum SendCodeCMD {
    case modifySendOld
    case modifySendNew
    case deleteCPSend
    case addNewSend
}

enum VerifyNewCodeCMD {
    case addNewVerify
    case modifyVerifyNew
}

// MARK: CP 增删改
protocol CredentialAPIProtocol {
    // MARK: V3

    func addNewIdpCredential(
        channel: LoginCredentialIdpChannel?,
        domain: String?,
        sceneInfo: [String: String]?
    ) -> Observable<V3.Step>

    func deleteIdpCredential(
        channel: LoginCredentialIdpChannel,
        cpId: String,
        tenantId: String,
        isTenantCp: Bool,
        success: @escaping OnStepSuccessV3,
        failure: @escaping OnFailureV3
    )

    func modifyCredential(
        contact: String
    ) -> Observable<V3.Step>

    func recoverType(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    // MARK: V2

    func getCredentialList() -> Observable<[Credential]>

    func sendVerifyCode(
        contact: String,
        cmd: SendCodeCMD,
        token: String
    ) -> Observable<String?>

    func verifyNewCode(
        code: String,
        cmd: VerifyNewCodeCMD,
        token: String
    ) -> Observable<V3.Step>

}

class CredentialAPI: APIV3, CredentialAPIProtocol {

    @Provider private var loginAPI: LoginAPI

    func addNewIdpCredential(
        channel: LoginCredentialIdpChannel?,
        domain: String?,
        sceneInfo: [String: String]?
    ) -> Observable<V3.Step> {
        var params: [String: Any]  = [:]
        if let channel = channel {
            params[CommonConst.authenticationChannel] = channel.rawValue
        }
        if let tenantDomain = domain {
            params[CommonConst.tenantDomain] = tenantDomain
        }
        let req = CredentialRequest<V3.Step>(pathSuffix: "add/idp/apply")
        req.body = params
        req.sceneInfo = sceneInfo
        return client.send(req)
    }

    func deleteIdpCredential(
        channel: LoginCredentialIdpChannel,
        cpId: String,
        tenantId: String,
        isTenantCp: Bool,
        success: @escaping OnStepSuccessV3,
        failure: @escaping OnFailureV3) {
        let params: [String: Any] = [
            CommonConst.authenticationChannel: channel.rawValue,
            CommonConst.cpId: cpId,
            CommonConst.tenantId: tenantId,
            CommonConst.isTenantCp: isTenantCp
        ]
        let req = CredentialRequest<V3.Step>(pathSuffix: "delete/idp/apply")
        req.body = params
        client.send(req, success: success, failure: failure)
    }

    func modifyCredential(
        contact: String
    ) -> Observable<V3.Step> {

        let params: [String: Any] = [
            "contact": contact
        ]
        let req = CredentialModifyRequest<V3.Step>(pathSuffix: "recover/check")
        req.body = params
        return client.send(req)
    }

    func getCredentialList() -> Observable<[Credential]> {
        let req = AfterLoginRequest<V3.SimpleResponse>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.credentialList.apiIdentify())
        req.domain = .passportAccounts()
        req.method = .get
        return client.send(req).map { (resp) -> [Credential] in
            let cps: [Credential]
            if let data = resp.rawData?["data"] as? [String: Any],
               let cp = data["credentials"] as? [[String: Any]] {
                cps = cp.map({ (cpDic) -> Credential in
                    return Credential(dic: cpDic)
                })
            } else {
                cps = []
            }
            return cps
        }
    }

    func sendVerifyCode(
        contact: String,
        cmd: SendCodeCMD,
        token: String
    ) -> Observable<String?> {
        let suffix: String
        switch cmd {
        case .modifySendOld:
            suffix = "modify/apply_old"
        case .modifySendNew:
            suffix = "modify/apply_new"
        case .deleteCPSend:
            suffix = "delete/apply"
        case .addNewSend:
            suffix = "add/apply"
        }
        var params: [String: Any] = ["contact": contact]
        if !token.isEmpty {
            params["cp_token"] = token
        }
        let req = CredentialRequest<V3.SimpleResponse>(pathSuffix: suffix)
        req.body = params
        return client.send(req).map { (resp) -> String? in
            return resp.rawData?["cp_token"] as? String
        }
    }

    func verifyNewCode(
        code: String,
        cmd: VerifyNewCodeCMD,
        token: String
    ) -> Observable<V3.Step> {
        let suffix: String
        switch cmd {
        case .modifyVerifyNew:
            suffix = "modify/verify_new"
        case .addNewVerify:
            suffix = "add/verify"
        }

        let params = [
            "code": code,
            "cp_token": token
        ]
        let req = CredentialRequest<V3.Step>(pathSuffix: suffix)
        req.body = params
        return client.send(req)
    }

    func recoverType(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        return loginAPI.recoverType(sourceType: sourceType, context: context)
    }

}
