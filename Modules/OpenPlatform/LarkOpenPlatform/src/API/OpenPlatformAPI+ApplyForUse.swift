//
//  OpenPlatformAPI+ApplyForUse.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/9/17.
//

import Foundation
import LarkAccountInterface
import LarkContainer

extension OpenPlatformAPI {
    
    //更新通知
    public static func updateNotifacation(appID: String, notificationType: Int, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .updateNotification, resolver: resolver)
            .setMethod(.post)
            .appendParam(key: .cli_id, value: appID)
            .appendParam(key: .notification_type, value: notificationType)
            .useSession()
            .appendCookie()
            .useLocale()
            .setScope(.appSetting)
    }

}


