//
//  OpenPlatformAPI+getMsgActionList.swift
//  LarkOpenPlatform
//
//  Created by  bytedance on 2020/9/11.
//

import LarkFoundation
import LarkAccountInterface
import LarkContainer

/// 获取msgAction快捷操作列表的API
extension OpenPlatformAPI {

    /// 获取消息快捷操作「更多应用」接口
    public static func getMsgActionListV1API(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getMsgActionListV1, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.msgActionExplorer)
    }

    /// 获取消息快捷操作「外化展示」接口
    public static func getMsgActionExternalItemsAPI(resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getMsgActionExternalItems, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.msgActionExplorer)
    }

    /// 更新消息快捷操作|加号菜单 用户常用配置
    public static func updateUserCommonItemsAPI(bizScene: String, appIDs: [String], resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .updateUserCommonApps, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .scene, value: bizScene)
            .appendParam(key: .common_app_ids, value: appIDs)
            .appendCookie()
            .useLocale()
            .setScope(.msgActionExplorer)
    }
}
