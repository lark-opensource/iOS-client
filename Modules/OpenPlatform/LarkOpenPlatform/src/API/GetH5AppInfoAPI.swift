//
//  GetH5AppInfoAPI.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/20.
//

import UIKit
import LarkContainer

extension OpenPlatformAPI {
    public static func GetH5AppInfoAPI(larkVer: String,
                                       appId: String,
                                       downgrade: Bool = false, resolver: UserResolver) -> OpenPlatformAPI {
        let path: APIUrlPath = downgrade ? .appLinkH5AppInfo : .appLinkH5AppInfoWithOffline
        let scope: Scope = downgrade ? .appplus : .shareApp
        return OpenPlatformAPI(path: path, resolver: resolver)
            .setMethod(.post)
            .useLocale()
            .appendParam(key: .larkVersion, value: larkVer)
            .appendParam(key: .appIdH5, value: appId)
            .setScope(scope)
            .useSession()
            .useSessionKey(sessionKey: .Session)
    }
}
