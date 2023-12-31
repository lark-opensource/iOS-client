//
//  JoinTeamAPIV3.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/2/25.
//

import Foundation
import LKCommonsLogging
import RxSwift

protocol JoinTeamAPIProtocol {

    func joinWithQRCode(
        _ body: TeamCodeReqBody,
        serverInfo: ServerInfo
    ) -> Observable<V3.Step>

    func create(
        _ body: UserCreateReqBody,
        serverInfo: ServerInfo
    ) -> Observable<V3.Step>

    func officialEmail(
        tenantId: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
}

class InvitationJoinRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
         self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)
     }

    convenience init(appId: APPID) {
        self.init(pathSuffix: appId.apiIdentify())
        self.appId = appId
    }
}

class JoinTeamAPIV3: APIV3, JoinTeamAPIProtocol {

    func joinWithQRCode(
        _ body: TeamCodeReqBody,
        serverInfo: ServerInfo
    ) -> Observable<V3.Step> {
        let req = InvitationJoinRequest<V3.Step>(appId: .v4JoinWithQRCode)
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.requiredHeader.insert(.flowKey)
        req.sceneInfo = body.sceneInfo
        return client.send(req)
    }

    func create(
        _ body: UserCreateReqBody,
        serverInfo: ServerInfo
    ) -> Observable<V3.Step> {
        let req = InvitationJoinRequest<V3.Step>(appId: .v3TenantPrepare)
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.sceneInfo = body.sceneInfo
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
    }

    func officialEmail(
        tenantId: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = InvitationJoinRequest<V3.Step>(pathSuffix: "official_email_join")
        req.body = ["tenant_id": tenantId]
        req.sceneInfo = sceneInfo
        return client.send(req)
    }
}
