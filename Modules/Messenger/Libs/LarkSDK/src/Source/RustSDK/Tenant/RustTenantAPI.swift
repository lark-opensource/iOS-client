//
//  RustTenantAPI.swift
//  LarkSDK
//
//  Created by shizhengyu on 2021/3/27.
//

import Foundation
import LarkSDKInterface
import RxSwift
import ServerPB
import RustPB

final class RustTenantAPI: LarkAPI, TenantAPI {
    func fetchCollaborationInviteQrCode(needRefresh: Bool, contactType: Int) -> Observable<CollaborationInviteInfo> {
        var request = ServerPB.ServerPB_Collaboration_PullCollaborationInviteQrCodeRequest()
        request.reset = needRefresh
        // 默认为外部
        request.collaborationQrType = ServerPB_Collaboration_ConnectType(rawValue: contactType) ?? ServerPB_Collaboration_ConnectType()
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullCollaborationInviteQrcode)
    }

    func getTenantMessageConf(confTypes: [Im_V1_GetTenantMessageConfRequest.ConfType], forceServer: Bool) -> Observable<Im_V1_GetTenantMessageConfResponse> {
        var request = Im_V1_GetTenantMessageConfRequest()
        request.confTypes = confTypes
        request.syncDataStrategy = forceServer ? .forceServer : .tryLocal
        return client.sendAsyncRequest(request)
    }
}
