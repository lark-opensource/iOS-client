//
//  RustPassportAPI.swift
//  LarkSDK
//
//  Created by 李勇 on 2020/7/6.
//

import Foundation
import LarkSDKInterface
import LarkModel
import RustPB
import RxSwift

final class RustPassportAPI: LarkAPI, PassportAPI {
    /// 获取Feed侧边栏远端下发的Sidebar
    func getMineSidebar(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<[RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]> {
        var request = RustPB.Passport_V1_GetUserSidebarRequest()
        request.syncDataStrategy = strategy

        return client.sendAsyncRequest(request) { (response: RustPB.Passport_V1_GetUserSidebarResponse) in
            response.sidebarInfos
        }.subscribeOn(scheduler)
    }
}
