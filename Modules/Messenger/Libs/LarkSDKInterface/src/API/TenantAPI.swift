//
//  TenantAPI.swift
//  LarkSDKInterface
//
//  Created by shizhengyu on 2021/3/27.
//

import Foundation
import RxSwift
import ServerPB
import RustPB

public typealias CollaborationInviteInfo = ServerPB.ServerPB_Collaboration_PullCollaborationInviteQrCodeResponse

public protocol TenantAPI {
    func fetchCollaborationInviteQrCode(needRefresh: Bool, contactType: Int) -> Observable<CollaborationInviteInfo>

    func getTenantMessageConf(confTypes: [Im_V1_GetTenantMessageConfRequest.ConfType], forceServer: Bool) -> Observable<Im_V1_GetTenantMessageConfResponse>
}
