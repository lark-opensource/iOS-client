//
//  PassportDidUpgradeAPI.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/9.
//

import Foundation
import RxSwift

class PassportDIDUpgradeAPI: APIV3 {
    
    func upgradeSessions() -> Observable<V4EnterAppInfo>{
        
        let req = PassportDIDUpgradeRequest<V3.CommonResponse<V4EnterAppInfo>>(pathSuffix: APPID.upgradeSessionDid.apiIdentify())
        req.method = .post
        req.required(.sessionKeys)
        req.required(.suiteSessionKey)
        req.required(.fetchUniDeviceId)
        req.domain = .passportAccounts()
        
        return Observable.create { (ob)->Disposable in
            self.client.send(req) { resp, _ in
                guard var data = resp.dataInfo else {
                    ob.onError(V3LoginError.badServerData)
                    return
                }
                ob.onNext(data)
                ob.onCompleted()
            } failure: { error in
                ob.onError(error)
            }
            return Disposables.create()
        }
    }
    
}

class PassportDIDUpgradeRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: "did/upgrade/login")
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .toastMessage,
            .saveToken
        ]
        self.requiredHeader = [.suiteSessionKey, .sessionKeys, .flowKey, .proxyUnit]
     }
}

