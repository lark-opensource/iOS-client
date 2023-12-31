//
//  UserCenterAPI.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/24.
//

import Foundation
import LKCommonsLogging
import RxSwift

class UserCenterAPI: APIV3 {
    // 在 user/list 接口调用前，需要保证 suiteSessionKey(当前前台用户)和 sessionKeys(CP 下所有登录用户)已被设置好
    func fetchUserList() -> Observable<V3.CommonArrayResponse<[V4UserInfo]>> {
        let req = AfterLoginRequest<V3.CommonArrayResponse<[V4UserInfo]>>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.v4UserList.apiIdentify())
        req.required(.sessionKeys)
        req.required(.suiteSessionKey)
        req.method = .post
        req.domain = .passportAccounts()
        return client.send(req)
    }

    func fetchUserCenter() -> Observable<V3.Step> {
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.v4UserCenter.apiIdentify())
        req.required(.sessionKeys)
        req.required(.suiteSessionKey)
        req.method = .post
        // user center 接口显式指定包域名
        req.domain = .passportAccounts(usingPackageDomain: true)
        return client.send(req)
    }
    
    func fetchPhoneNumberRegionList() -> Observable<V3.CredentialListResponse> {
        let req = AfterLoginRequest<V3.CredentialListResponse>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.credentialList.apiIdentify())
        req.domain = .passportAccounts()
        req.required(.suiteSessionKey)
        req.method = .get
        req.body = ["scene" : "member_add"]
        return client.send(req)
    }

    func fetchCredentialList() -> Observable<[Credential]> {
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

    func initOfficialEmail(
        serverInfo: ServerInfo,
        tenantId: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.tenantId: tenantId
        ]
        if let fType = serverInfo.flowType {
            params[CommonConst.flowType] = fType
        }
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.v4InitOfficialEmail.apiIdentify())
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
    }
    
    func upgradeLogin() -> Observable<V3.UpgradeLoginResponse> {
        // 由于升级 session 的重试逻辑会重新订阅信号，如果使用 client 生成的 observable 会将重复发送相同的 request
        // 而如果第一个 request 失败，request.context.error 将会被赋值，后面重试时 executeRequestMiddleWare 会直接跳过请求
        // 因此这里手动创建 observable，每次都重新创建 request
        return Observable.create { [weak self] (ob) -> Disposable in
            guard let self = self else {
                ob.onError(V3LoginError.clientError("Self can not be nil"))
                return Disposables.create()
            }
            
            let request = AfterLoginRequest<V3.UpgradeLoginResponse>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.upgradeLogin.apiIdentify())
            request.domain = .passportAccounts()
            request.required(.fetchDeviceId)
            request.requiredHeader.remove(.sessionKeys)
            
            self.client.send(request, success: { (resp, _) in
                ob.onNext(resp)
                ob.onCompleted()
            }, failure: { error in
                ob.onError(error)
            })
            return Disposables.create()
        }
    }
}
