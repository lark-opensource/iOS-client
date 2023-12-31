//
//  BootDependency.swift
//  BootManager
//
//  Created by KT on 2020/7/3.
//

import UIKit
import Foundation
import NotificationUserInfo
import LarkTab

/**
 业务类型
 根据启动场景，Push入口，动态选择首屏之前需要执行的Task
 */
public struct BizScope: OptionSet, Hashable, CustomStringConvertible {
    /// Messenger业务
    public static let messenger = BizScope(rawValue: 1 << 0)
    /// 日历业务
    public static let calendar = BizScope(rawValue: 1 << 1)
    /// 小程序、应用中心
    public static let openplatform = BizScope(rawValue: 1 << 2)
    /// CCM
    public static let docs = BizScope(rawValue: 1 << 3)
    /// 邮件
    public static let mail = BizScope(rawValue: 1 << 4)
    /// 音视频
    public static let vc = BizScope(rawValue: 1 << 5)
    /// Todo
    public static let todo = BizScope(rawValue: 1 << 6)
    /**
    LaunchOption不为空，且不匹配上面的业务类型
    如3DTouch、universalLink启动等场景
    */
    public static let specialLaunch = BizScope(rawValue: 1 << 7)

    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public var description: String {
        switch self {
        case .messenger: return "messenger"
        case .calendar: return "calendar"
        case .openplatform: return "openplatform"
        case .docs: return "docs"
        case .mail: return "mail"
        case .vc: return "vc"
        case .todo: return "todo"
        case .specialLaunch: return "specialLaunch"
        default: fatalError("Unknown type of BizScope")
        }
    }
}

/**
 判断业务的依赖
 BootManager底层库
 不依赖Tab、Notification等业务库
 */
public protocol BootDependency {
    /// Tab -> BizScope
    func tabStringToBizScope(_ tabString: String) -> BizScope?

    /// launchOptions -> BizSope
    func launchOptionToBizScope(
        _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BizScope?

    /// Task / Stage 执行回调
//    var eventObserver: EventMonitorProtocol? { get }
}

final class BootManagerDependency: BootDependency {
    func tabStringToBizScope(_ tabString: String) -> BizScope? {
        // 小程序、H5没有固定url，判断prefix
        if tabString.hasPrefix(Tab.gadgetPrefix) || tabString.hasPrefix(Tab.webAppPrefix) {
            return .openplatform
        }

        switch tabString {
        case Tab.feed.urlString,
             Tab.contact.urlString:
            return .messenger
        case Tab.calendar.urlString:
            return .calendar
        case Tab.mail.urlString:
            return .mail
        case Tab.appCenter.urlString:
            return .openplatform
        case Tab.byteview.urlString:
            return .vc
        case Tab.doc.urlString, Tab.wiki.urlString, Tab.base.urlString:
            return .docs
        case Tab.todo.urlString:
            return .todo
        default:
//            assertionFailure("unknow Tab -> BizScope")
            return nil
        }
    }

    func launchOptionToBizScope(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BizScope? {
        /// 通知进入
        if let notificationDic = (launchOptions?[.remoteNotification] as? [AnyHashable: Any])
            ?? (launchOptions?[.localNotification] as? UILocalNotification)?.userInfo,
            let dic = notificationDic as? [String: Any],
            let userInfo = UserInfo(dict: dic) {
            switch userInfo.extra?.type {
            case .openAppChat, .openMicroApp, .chatApplication: return .openplatform
            case .docs: return .docs
            case .mail: return .mail
            case .calendar: return .calendar
            case .todo: return .todo
            case .call, .video: return .vc
            case .unknow,
                 .none,
                 .message,
                 .badge,
                 .reaction,
                 .active,
                 .chatApply,
                 .urgent,
                 .urgentAck,
                 .openApp:
                return .messenger
            @unknown default: assertionFailure("unknow type")
            }
        }
        return .specialLaunch
    }
}
