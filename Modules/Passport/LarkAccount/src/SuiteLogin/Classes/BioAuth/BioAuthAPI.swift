//
//  BioAuthAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/3/12.
//

import Foundation
import RxSwift

class BioAuthAPI: APIV3 {

    func bioAuthType(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(pathPrefix: CommonConst.securityApiPath, pathSuffix: "bio_auth/type")
        let body = [
            CommonConst.sourceType: sourceType
        ]
        req.body = body
        req.required(.suiteSessionKey).required(.passportToken)
        return client.send(req)
            .trace(
                "bioAuthType",
                params: [
                    CommonConst.sourceType: String(describing: sourceType)
                ])
    }

    func bioAuthVerifyFace(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(pathPrefix: CommonConst.securityApiPath, pathSuffix: "bio_auth/verify")
        let body = [
            CommonConst.sourceType: sourceType
        ]
        req.body = body
        req.required(.suiteSessionKey).required(.passportToken)
        return client.send(req)
            .trace(
                "bioAuthVerify",
                params: [
                    CommonConst.sourceType: String(describing: sourceType)
                ])
    }

    func bioAuthVerify(
        serverInfo: ServerInfo,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(pathSuffix: CommonConst.bioVerifyPath)
        if let flowType = serverInfo.flowType {
            req.body = [CommonConst.flowType: flowType]
        }
        req.configDomain(serverInfo: serverInfo)
        req.required(.flowKey).required(.suiteSessionKey)
        return client.send(req)
    }

    func bioAuthGetTicket(
        serverInfo: ServerInfo,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(pathSuffix: CommonConst.bioGetTicketPath)
        if let flowType = serverInfo.flowType {
            req.body = [CommonConst.flowType: flowType]
        }
        req.configDomain(serverInfo: serverInfo)
        req.required(.flowKey).required(.suiteSessionKey).required(.checkLocalSecEnv)
        return client.send(req)
            .trace(
                "bioAuthGetTicket",
                params: [CommonConst.flowType: serverInfo.flowType ?? ""])
    }

    func bioAuthEnableLogin(
        enable: Bool,
        context: UniContextProtocol
    ) -> Observable<Void> {
        let enableKey = "enable_bio_auth_login"
        let req = LoginRequest<V3.SimpleResponse>(pathPrefix: CommonConst.securityApiPath, pathSuffix: "bio_auth/enable_login")
        let body = [
            enableKey: enable
        ]
        req.body = body
        req.required(.suiteSessionKey).required(.passportToken)
        return client.send(req).map { _ in () }
            .trace(
                "bioAuthEnableLogin",
                params: [
                    enableKey: String(describing: enable)
                ]
            )
    }
}
