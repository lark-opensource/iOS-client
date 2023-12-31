//
//  PassportAPI.swift
//  LarkSDKInterface
//
//  Created by 李勇 on 2020/7/6.
//

import Foundation
import LarkModel
import RxSwift
import RustPB

public protocol PassportAPI {
    /// 获取Feed侧边栏远端下发的Sidebar
    func getMineSidebar(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<[RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]>
}
