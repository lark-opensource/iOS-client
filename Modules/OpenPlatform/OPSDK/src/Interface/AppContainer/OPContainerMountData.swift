//
//  OPContainerMountData.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/18.
//

import Foundation

/// 开放平台统一定义的场景值，各应用形态都要保持一致
/// 完整定义详见 https://bytedance.feishu.cn/sheets/shtcnK6GyZ1zpV45eOorIq9BKeb
@objc public enum OPAppScene: Int {
    case undefined = 1000                   // 其他暂时未定义的场景值目前统一设置成1000，非卡片消息聊天也归为1000，后续有定义再修改(message)
    case appcenter = 1001                   // "发现栏小程序主入口，「最近使用」列表，小程序包更新时重启小程序。"(multi_task)
    case feed = 1002
    case global_search = 1005
    case appcenter_search = 1006
    case single_cardlink = 1007             // 消息卡片-单人聊天-cardlink
    case multi_cardlink = 1008              // 消息卡片-多人聊天-cardlink
    case topic_cardlink = 1514              // 消息卡片-话题群或详情页-cardlink
    case single_innerlink = 1009            // 消息卡片-单人聊天-内部link
    case multi_innerlink = 1010             // 消息卡片-多人聊天-内部link
    case camera_qrcode = 1011               // 扫码-摄像头扫描
    case press_image_qrcode = 1012          // 扫码-长按图片识别
    case album_qrcode = 1013                // 扫码-相册识别
    case device_debug = 1014                // 真机调试
    case performance_profile = 1015         // 性能调试
    case micro_app = 1037                   // 小程序打开小程序
    case app = 1069                         // 外部应用打开小程序
    case bot = 1504                         // bot中打开
    case single_appplus = 1509              // 在单聊的加号菜单中打开
    case multi_appplus = 1510               // 在群聊的加号菜单中打开
    case mainTab = 1506                     //  主导航
    case convenientTab = 1507               //  快捷导航
    case app_flag_cardlink = 1511           // 消息卡片底部小程序链接
    case web_url = 1513                     // web链接跳转小程序
    case doc = 1515                         // 云空间打开小程序
    case message_action = 1516              // Message Action 导索页面
    case desktop_shortcut = 1517              // 桌面快捷方式打开小程序
    case multi_task = 1187                  // 多任务浮窗启动
    case im_open_biz = 1518          // 群开放，如在群内通过开放配置打开小程序，目前来源目前为IM打开小程序(预期内是以半屏小程序为主)
    case launcher_tab = 1519                // launcher固定区打开
    case launcher_more = 1520               // launcher 更多区打开
    case launcher_recent = 1521             // launcher 最近使用区打开
    case temporary = 1522                   // iPad 临时区打开
}



public func OPAppSceneFromInt(sceneInt: Int) -> OPAppScene {
    return OPAppScene(rawValue: sceneInt) ?? .undefined
}

public func OPAppSceneFromString(sceneString: String?) -> OPAppScene {
    guard let sceneString = sceneString, let sceneInt = Int(sceneString) else {
        return .undefined
    }
    return OPAppSceneFromInt(sceneInt: sceneInt)
}

public enum OPStartChannel: String {
    case undefined = "undefined"
    case applink = "mini_app_applink"
    case sslocal = "mini_app_sslocal"
}

@objc public protocol OPContainerMountDataProtocol {
    
    var scene: OPAppScene { get }
    
    var launcherFrom: String? { get }
}
