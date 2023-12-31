//
//  AppLinkService.swift
//  LarkInterface
//
//  Created by yinyuan on 2019/8/21.
//

import Foundation
import EENavigator

// swiftlint:disable identifier_name
public enum AppLinkFrom: String {
    case unknown
    case app
    case scan
    case qrcode
    case card
    case chat
    case message
    case mini_program
    case webview
    /// 云文档
    case doc
    case multi_task             // 多任务浮窗启动
    case launcher_tab           // launcher固定区
    case launcher_more          // launcher更多区
    case launcher_recent        // launcher最近区
    case temporary              //iPad临时区
}

public struct AppLink {
    public var url: URL
    public let from: AppLinkFrom
    public var traceId: String?
    public let timestamp: TimeInterval = Date().timeIntervalSince1970
    public let openType: OpenType
    // 其他一些扩展信息
    public var context: [String: Any]?
    // 打开Applink的页面来源，用于页面路由
    public var fromControler: UIViewController? {
        return (self.context?[ContextKeys.from] as? EENavigator.NavigatorFrom)?.fromViewController
    }

    public init(url: URL, from: AppLinkFrom, fromControler: UIViewController? = nil, openType: OpenType = .push) {
        self.url = url
        self.from = from
        self.openType = openType
        if let fromControler = fromControler {
            self.context = [ContextKeys.from: NavigatorFromWrapper(fromControler)]
        }
    }
}

public typealias AppLinkHandler = (AppLink) -> Void
public typealias AppLinkOpenCallback = (Bool) -> Void

public protocol AppLinkService {
    
    @available(*, deprecated, message: "此接口由于适配 UIScene 原因已废弃, 请选择有 fromControler 的API")
    func open(url: URL, from: AppLinkFrom, callback: @escaping AppLinkOpenCallback)
    
    func open(url: URL, from: AppLinkFrom, fromControler: UIViewController?, callback: @escaping AppLinkOpenCallback)
    func open(appLink: AppLink, callback: @escaping AppLinkOpenCallback)
    func isAppLink(_ url: URL) -> Bool
}
// swiftlint:enable identifier_name
