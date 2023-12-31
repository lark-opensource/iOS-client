//
//  OpenPlatformAPI+MenuPanel.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/9/17.
//

import LarkFoundation
import LarkAccountInterface
import LarkContainer

/// 更多菜单相关网络请求
extension OpenPlatformAPI {
    
    /// 获得Web Bot的信息
    public static func getWebBotInfoAPI(appID: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getWebBotInfo, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .cli_id, value: appID)
            .appendParam(key: .need_chatable, value: true)
            .appendParam(key: .need_meta_info, value: true)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.menuPanel)
    }
    
}

class OPWebBotInfoResponse: APIResponse {
    var chatType: Int? {
        return json["data"]["chat_type"].int
    }

    var botID: String? {
        return json["data"]["bot_id"].string
    }
    
    var avatarKey: String? {
        return json["data"]["avatar_key"].string
    }

    var avatarUrl: String? {
        return json["data"]["avatar_url"].string
    }
}
