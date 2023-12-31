//
//  FromScene.swift
//  LarkInterface
//
//  Created by tujinqiu on 2019/9/4.
//

import Foundation

public struct FromSceneKey {
    public static var key = "from"
}

// swiftlint:disable identifier_name
public enum FromScene: String {
    case undefined
    case appcenter
    case multi_task             // 多任务浮窗启动
    case feed
    case global_search
    case appcenter_search
    case camera_qrcode
    case press_image_qrcode
    case album_qrcode
    case message                // 消息（上游变动导致未能识别的情况）
    case p2p_message            // 消息-单人聊天-内部link
    case group_message          // 消息-多人聊天-内部link
    case thread_topic           // 消息-话题群或详情页-内部link
    case single_cardlink
    case multi_cardlink
    case single_innerlink
    case multi_innerlink
    case topic_cardlink         // 消息卡片-话题群或详情页-cardlink
    case topic_innerlink        // 消息卡片-话题群或详情页-内部link
    case micro_app
    case mini_program
    case app
    case single_appplus
    case multi_appplus
    case bot
    case app_flag_cardlink
    case web_url
    /// 云文档
    case doc
    // message action 场景值
    case message_action
    //在聊天bot的profile页中打开
    case chat_bot_profile
    /// 通过桌面快捷方式打开
    case desktop_shortcut
    // 群开放，如在群内通过开放配置打开小程序，目前来源目前为IM打开半屏小程序
    case im_open_biz
    // super app launcher 固定区打开
    case launcher_tab
    // super app launcher 更多区打开
    case launcher_more
    // super app launcher 最近使用区打开
    case launcher_recent
    // iPad 临时区
    case temporary

    
    // 上游来源信息适配
    public static func build(context: [String: Any]?) -> FromScene {
        // iPad临时区因为CCM等业务占用了from字段，所以单独新增了字段launcher_from
        if let context = context, let launcherFrom = context["launcher_from"] as? String {
            if launcherFrom == "temporary" {
                return .temporary
            } else if launcherFrom == "main" {
                return .launcher_tab
            } else if launcherFrom == "quick" {
                return .launcher_more
            }
        }
        
        guard let context = context, let from = context[FromSceneKey.key] as? String else {
            return .undefined
        }
        guard let scene = FromScene.init(rawValue: from) else {
            return .undefined
        }
        
        if scene == .message {
            // message 类型要识别成更具体的情况
            guard let chatType = context["chat_type"] as? String else {
                return scene
            }
            if chatType == "group" {
                return .group_message
            } else if chatType == "single" {
                return .p2p_message
            } else if chatType == "topicGroup" {
                return .thread_topic
            }
        }
        
        return scene
    }
}
// swiftlint:enable identifier_name

public enum StartChannel: String {
    case undefined = "undefined"
    case applink = "mini_app_applink"
    case sharelink = "app_share_applink"
    case sslocal = "mini_app_sslocal"
}
