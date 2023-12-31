//
//  OpenPlatformAPI+GetPlusMenuList.swift
//  LarkOpenPlatform
//
//  Created by  bytedance on 2020/9/11.
//

import LarkFoundation
import LarkAccountInterface
import LarkContainer

/// 加号菜单应用相关API
extension OpenPlatformAPI {

    /// 获取加号菜单「更多应用」接口
    public static func getPlusMenuListV1API(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getPlusMenuListV1, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.plusExplorer)
    }

    /// 获取加号菜单「外化展示」接口
    public static func getPlusMenuExternalItemsAPI(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getPlusMenuExternalItems, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.plusExplorer)
    }
}
