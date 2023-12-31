//
//  WebBrowser+FromSceneReport.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/12/1.
//

import Foundation

// https://bytedance.larkoffice.com/wiki/WQmUwkABaixr6nkFqd6cauvWnie

public enum WebBrowserFromSceneReport: RawRepresentable {
    /// normal
    case normal
    /// 群聊/单聊 通用兜底
    case chat
    /// 个人签名
    case profile
    /// 工作台
    case workplace
    // 大搜
    case search
    // 网页window.open
    case web
    // 小程序 openschema
    case gadget
    // 嵌入主导航的网页从固定区打开
    case mainTab
    // 嵌入主导航的网页从更多区打开
    case convenientTab
    // web工作台 workplacePortal
    case workplacePortal
    // feed 场景
    case feed
    // 应用商店点击打开应用
    case appStore
    // launcher_more：main； iPad/iPhone 上从主导航的固定区域打开
    case launcherFromMain
    // launcher_more：quick； iPad/iPhone 上从主导航的“更多”里打开
    case launcherFromQuick
    // launcher_more：temporary； iPad 上从主导航的临时区域打开
    case launcherFromTemporary
    // launcher_more: suspend; iPhone 上从浮窗打开
    case floatingWindow
    // 单聊中消息打开
    case p2p_message
    // 群聊中消息打开
    case group_message
    // 话题群中消息打开
    case thread_topic
    // 单聊会话pin
    case single_pin
    // 群聊会话pin
    case multi_pin
    // 单聊会话菜单
    case single_menu
    // 群聊会话菜单
    case multi_menu
    // 单聊中消息卡片打开
    case singleChatMessageCard
    // 群聊中消息卡片打开
    case multiChatMessageCard
    // 从单聊的加号菜单中打开
    case singleChatPlusMenu
    // 从群聊的加号菜单中打开
    case multiChatPlusMenu
    // 从消息的快捷操作打开
    case chatMessageShortcut
    // 扫码-摄像头扫描
    case camera_qrcode
    // 扫码-长按图片识别
    case press_image_qrcode
    // 扫码-相册识别
    case album_qrcode
    // 从其他app跳转打开(包括“从桌面快捷方式打开“)
    case app
    
    // 上游来源信息适配
    public static func build(context: [String: Any]?) -> WebBrowserFromSceneReport {
        guard let context else {
            return .normal
        }
        if let lkWebFrom = context["lk_web_from"] as? String, lkWebFrom == "webbrowser" {
            return .web
        } else if let fromSceneReport = context["from_scene_report"] as? String, fromSceneReport == "appStore" {
            return .appStore
        } else if let launcherFrom = context["launcher_from"] as? String, !launcherFrom.isEmpty {
            var launcherFromDetail = "normal"
            switch launcherFrom {
            case "main":
                launcherFromDetail = "launcherFromMain"
            case "quick":
                launcherFromDetail = "launcherFromQuick"
            case "temporary":
                launcherFromDetail = "launcherFromTemporary"
            case "suspend":
                launcherFromDetail = "floatingWindow"
            default:
                break
            }
            return WebBrowserFromSceneReport.init(rawValue: launcherFromDetail)
        } else if let fromDetail = context["from"] as? String {
            if fromDetail == "message" {
                // message 类型要识别成更具体的单聊/群聊
                guard let chatType = context["chat_type"] as? String else {
                    return .chat
                }
                if chatType == "group" {
                    return .group_message
                } else if chatType == "single" {
                    return .p2p_message
                } else if chatType == "topicGroup" {
                    return .thread_topic
                }
            }
            return WebBrowserFromSceneReport.init(rawValue: fromDetail)
        } else {
            return .normal
        }
    }
    
    public var rawValue: String {
        switch self {
        case .normal:
            return "normal"
        case .chat:
            return "chat"
        case .profile:
            return "profile"
        case .workplace:
            return "workplace"
        case .search:
            return "search"
        case .web:
            return "web"
        case .gadget:
            return "gadget"
        case .mainTab:
            return "mainTab"
        case .convenientTab:
            return "convenientTab"
        case .workplacePortal:
            return "workplacePortal"
        case .feed:
            return "feed"
        case .appStore:
            return "appStore"
        case .launcherFromMain:
            return "pinnedAreaNavBar"
        case .launcherFromQuick:
            return "moreNavBar"
        case .launcherFromTemporary:
            return "temporaryAreaNavBar"
        case .floatingWindow:
            return "floatingWindow"
        case .p2p_message:
            return "p2p_message"
        case .group_message:
            return "group_message"
        case .thread_topic:
            return "thread_topic"
        case .single_pin:
            return "single_pin"
        case .multi_pin:
            return "multi_pin"
        case .single_menu:
            return "single_menu"
        case .multi_menu:
            return "multi_menu"
        case .singleChatMessageCard:
            return "singleChatMessageCard"
        case .multiChatMessageCard:
            return "multiChatMessageCard"
        case .singleChatPlusMenu:
            return "singleChatPlusMenu"
        case .multiChatPlusMenu:
            return "multiChatPlusMenu"
        case .chatMessageShortcut:
            return "chat.messageShortcut"
        case .camera_qrcode:
            return "camera_qrcode"
        case .album_qrcode:
            return "album_qrcode"
        case .press_image_qrcode:
            return "press_image_qrcode"
        case .app:
            return "app"
        }
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case "normal":
            self = .normal
        case "chat", "message":
            self = .chat
        case "single_pin":
            self = .single_pin
        case "multi_pin":
            self = .multi_pin
        case "single_menu":
            self = .single_menu
        case "multi_menu":
            self = .multi_menu
        case "single_cardlink", "single_innerlink":
            self = .singleChatMessageCard
        case "multi_cardlink", "topic_cardlink", "multi_innerlink", "topic_innerlink":
            self = .multiChatMessageCard
        case "profile", "self_signature":
            self = .profile
        case "workplace":
            self = .workplace
        case "appcenter":
            self = .workplace
        case "search", "global_search":
            self = .search
        case "webbrowser", "web_url":
            // webbrowser 网页window.open ，web_url 统一路由网页openschema
            self = .web
        case "gadget", "micro_app":
            // 小程序openschema
            self = .gadget
        case "mainTab":
            self = .mainTab
        case "convenientTab":
            self = .convenientTab
        case "workplacePortal":
            self = .workplacePortal
        case "feed":
            self = .feed
        case "appStore":
            self = .appStore
        case "launcherFromMain":
            self = .launcherFromMain
        case "launcherFromQuick":
            self = .launcherFromQuick
        case "launcherFromTemporary":
            self = .launcherFromTemporary
        case "floatingWindow":
            self = .floatingWindow
        case "single_appplus":
            self = .singleChatPlusMenu
        case "multi_appplus":
            self = .multiChatPlusMenu
        case "message_action":
            self = .chatMessageShortcut
        case "camera_qrcode":
            self = .camera_qrcode
        case "press_image_qrcode":
            self = .press_image_qrcode
        case "album_qrcode":
            self = .album_qrcode
        case "app":
            self = .app
        default:
            self = .normal
        }
    }
    
    public func sceneCode() -> Int {
        /// 获取场景值
        switch self {
        case .normal:
            return 1000
        case .chat:
            return 2306
        case .profile:
            return 1024
        case .workplace:
            return 1001
        case .search:
            return 1005
        case .web:
            return 2307
        case .gadget:
            return 2308
        case .mainTab:
            return 1506
        case .convenientTab:
            return 1507
        case .workplacePortal:
            return 2309
        case .feed:
            return 1002
        case .appStore:
            return 2301
        case .launcherFromMain:
            return 1519
        case .launcherFromQuick:
            return 1520
        case .launcherFromTemporary:
            return 1522
        case .floatingWindow:
            return 1187
        case .p2p_message:
            return 1009
        case .group_message:
            return 1010
        case .thread_topic:
            return 1010
        case .single_pin:
            return 2302
        case .multi_pin:
            return 2303
        case .single_menu:
            return 2304
        case .multi_menu:
            return 2305
        case .singleChatMessageCard:
            return 1007
        case .multiChatMessageCard:
            return 1008
        case .singleChatPlusMenu:
            return 1509
        case .multiChatPlusMenu:
            return 1510
        case .chatMessageShortcut:
            return 1516
        case .camera_qrcode:
            return 1011
        case .album_qrcode:
            return 1013
        case .press_image_qrcode:
            return 1012
        case .app:
            return 1517
        }

    }
}
