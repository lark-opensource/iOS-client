//
//  RealnameVerifyAPIIMP.swift
//  LarkAccount
//
//  Created by zhaojingxin on 2022/1/18.
//

import Foundation
import RxSwift

class RealnameVerifyAPIIMP: APIV3, RealnameVerifyAPI {

    func startVerificationFromQRCode(params: [String: Any]) -> Observable<V3.Step> {
        let request = LoginRequest<V3.Step>(pathPrefix: "accounts/general_qr", pathSuffix: "scan")
        request.domain = .passportAccounts()
        request.required(.flowKey)
        request.method = .post
        request.body = params
        return client.send(request)
    }

    func cancelQRCodeVerification(serverInfo: ServerInfo) {
        let request = LoginRequest<V3.Step>(pathPrefix: "accounts/general_qr", pathSuffix: "cancel")
        request.configDomain(serverInfo: serverInfo)
        request.required(.flowKey)
        request.method = .post
        if let flowType = serverInfo.flowType {
            request.body = [CommonConst.flowType: flowType]
        }
        client.send(request).subscribe(onNext: { _ in })
    }
}


