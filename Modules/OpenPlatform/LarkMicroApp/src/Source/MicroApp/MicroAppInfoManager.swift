//
//  MicroAppInfoManager.swift
//  LarkMicroApp
//
//  Created by yinyuan on 2019/10/9.
//

import Foundation
import EEMicroAppSDK
import LarkAppLinkSDK
import RustPB
import LarkTab
import LarkNavigation


public final class MicroAppInfo {
    var appID: String
    var scene: FromScene = .undefined
    public var hide: Bool = true

    public var feedAppID: String?  // 从 feed 打开的小程序带有 feedAppID
    public var feedSeqID: String?  // 从 feed 打开的小程序带有 feedSeqID
    public var feedType: Basic_V1_FeedCard.EntityType?  // 从 feed 打开的小程序带有 feedType

    var sslocal: SSLocalModel?

    init(appID: String) {
        self.appID = appID
    }
}

public final class MicroAppInfoManager {

    public static var shared = MicroAppInfoManager()

    fileprivate var infos: [String: MicroAppInfo] = [:]

    func setAppInfo(_ info: MicroAppInfo) {
        infos[info.appID] = info
    }

    public func getAppInfo(appID: String) -> MicroAppInfo? {
        return infos[appID]
    }

    public func removeAppInfo(appID: String) {
        infos[appID] = nil
    }
}

@available(*, deprecated, message: "Use OPScenc instead")
extension FromScene {
    @available(*, deprecated, message: "Use OPScenc instead")
    public func sceneCode() -> Int {
        switch self {
        case .undefined, .message:
            return 1000         // 其他暂时未定义的场景值目前统一设置成1000，非卡片消息聊天也归为1000，后续有定义再修改
        case .appcenter:
            return 1001         // "发现栏小程序主入口，「最近使用」列表，小程序包更新时重启小程序。"
        case .feed:
            return 1002
        case .global_search:
            return 1005
        case .appcenter_search:
            return 1006
        case .single_cardlink:
            return 1007         // 消息卡片-单人聊天-cardlink
        case .multi_cardlink:
            return 1008         // 消息卡片-多人聊天-cardlink
        case .topic_cardlink:
            return 1514         // 消息卡片-话题群或详情页-cardlink
        case .single_innerlink:
            return 1009         // 消息卡片-单人聊天-内部link
        case .multi_innerlink:
            return 1010         // 消息卡片-多人聊天-内部link
        case .topic_innerlink:
            return 1514         // 消息卡片-话题群或详情页-内部link
        case .camera_qrcode:
            return 1011         // 扫码-摄像头扫描
        case .press_image_qrcode:
            return 1012         // 扫码-长按图片识别
        case .album_qrcode:
            return 1013         // 扫码-相册识别
        case .micro_app, .mini_program:
            return 1037         // 小程序打开小程序
        case .app:
            return 1069         // 外部应用打开小程序
        case .bot:
            return 1504         // bot中打开
        case .single_appplus:
            return 1509         // 在单聊的加号菜单中打开
        case .multi_appplus:
            return 1510         // 在群聊的加号菜单中打开
        case .app_flag_cardlink:
            return 1511         // 消息卡片底部小程序链接
        case .web_url:
            return 1513         // web链接跳转小程序
        case .doc:
            return 1515         // 云文档进入小程序
        case .p2p_message:
            return 1009         // 消息-单人聊天-内部link
        case .group_message:
            return 1010         // 消息-多人聊天-内部link
        case .thread_topic:
            return 1514         // 消息-话题群或详情页-内部link
        case .message_action:
            return 1516
        case .desktop_shortcut:
            return 1517
        case .multi_task:
            return 1187         // 多任务浮窗启动
        case .im_open_biz:
            return 1518         // 群开放，如在群内通过开放配置打开小程序，目前来源目前为IM打开半屏小程序
        case .launcher_tab:
            return 1519         // launcher固定区
        case .launcher_more:
            return 1520         // launcher更多区
        case .launcher_recent:
            return 1521         // launcher最近区
        case .temporary:
            return 1522         // iPad临时区
        case .chat_bot_profile: fallthrough
        @unknown default:
            // 其他暂时未定义的场景值目前统一设置成1000，非卡片消息聊天也归为1000，后续有定义再修改
            return 1000
        }
    }
    
    //是否允许在 iPad 特定场景下，不切换Tab到应用中心的情况下打开小程序
    public func enableOpenInCurrentVC() -> Bool {
        switch self {
        //以下场景，绝对不允许在辅窗口打开
        //遵循原有应用中心打开小程序逻辑
        case .camera_qrcode, .album_qrcode:
            return false
        case .message,
        .global_search, .appcenter_search,
        .press_image_qrcode,
        .single_cardlink,// 消息卡片-单人聊天-cardlink
        .multi_cardlink,// 消息卡片-多人聊天-cardlink
        .topic_cardlink,// 消息卡片-话题群或详情页-cardlink
        .single_innerlink,// 消息卡片-单人聊天-内部link
        .multi_innerlink,// 消息卡片-多人聊天-内部link
        .topic_innerlink,// 消息卡片-话题群或详情页-内部link
//        case .bot:
//            return 1504         // bot中打开
        .app_flag_cardlink, // 消息卡片底部小程序链接
        .p2p_message,// 消息-单人聊天-内部link
        .group_message, // 消息-多人聊天-内部link
        .thread_topic, // 消息-话题群或详情页-内部link
        .message_action, // message action
        .single_appplus, // 在单聊的+号中打开
        .chat_bot_profile, //在聊天bot的profile页中打开
        .multi_appplus:  // 在群聊的+号中打开
            return true
        default:
            //其余场景，只要Tab在conversation，默认允许当前navigator打开小程序
                if let currentTab = RootNavigationController.shared.viewControllers.first?.animatedTabBarController?.currentTab,
                   currentTab == Tab.feed {
                    return true
                }
                return false
            return false
        }
    }
}
