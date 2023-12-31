//
//  SetupLarkBadgeTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LarkBadge

// Debug下设置LarkBadge的依赖

final class SetupLarkBadgeTask: FlowBootTask, Identifiable {
    static var identify = "SetupLarkBadgeTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // Badge 服务本地依赖
        BadgeManager.setDependancy(with: BadgeImpl.default)
    }
}

struct BadgeImpl: BadgeDependancy {

    // 路径节点白名单
    var whiteLists: [NodeName]

    // 路径节点前缀白名单
    var prefixWhiteLists: [NodeName]

    static let `default` = BadgeImpl(whiteLists: whiteLists + chat + webContent + gadgetContent,
                                     prefixWhiteLists: prefix)

    static let prefix = ["chat_id", "web_url", "app_id"]

    static let whiteLists: [NodeName] = []

    // Chat相关Badge
    static let chat = [
        "announcement", "pin", "search",
        "setting", "event", "meetingSummary",
        "chat_more", "group_setting",
        "approve", "freeBusyInChat", "todo"
    ]

    // web 容器相关
    static let webContent = [
        "web_more", "share", "refresh",
        "copyLink", "openInSafari",
        "bot", "botNoRespond", "about", "translate", "commonApp", // added by liuyang.apple
        "webFloating",   //  多任务浮窗的菜单插件支持红点 https://bytedance.feishu.cn/docs/doccnXBUpcw7EtchpYyYnZKkHUd
        "shareToWeChat", "shareToWeChatMoments", // 微信分享
        "webTextSize"
    ]

    // 小程序相关
    static let gadgetContent = [
        "app_more",
        "custom",
        "goHome",
        "share",
        "setting",
        "feedback",
        "about",
        "debug",
        "larkDebug",
        "bot",
        "commonApp",
        "unknown",
        "gadgetFloating"    // 小程序多任务浮动窗口
    ]
}
