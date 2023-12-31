//
//  BusinessPluginForWeb.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/9/21.
//

import Foundation
import LarkQuickLaunchInterface
import LarkUIKit

public protocol BusinessPluginForWebProtocol {
    // 网页容器在 URL 变化时 会调用此接口重新创建 items
    // vc 表示网页容器的视图控制器，方便业务方继续 push 或者 present 业务页面
    func createBarItems(for url: URL, on vc: UIViewController, with completion: @escaping (BusinessBarItemsForWeb) -> Void)
    // 网页容器在 URL 变化时、网页容器销毁时 都会调用此接口
    // 通知业务方销毁持有的 items，url 和 vc
    // 业务方应当 weak 持有以避免循环引用
    func destroyBarItems()
}

public protocol ImPluginForWebProtocol: BusinessPluginForWebProtocol {}

public protocol DocPluginForWebProtocol: BusinessPluginForWebProtocol {}

public struct BusinessBarItemsForWeb {
    // 将展示在网页顶部 NavigationBar，返回 nil 时不展示对应 button
    public var navigationBarItem: LKBarButtonItem?
    // 将展示在网页底部 QuickLaunchBar，返回 nil 时不展示对应 button
    public var launchBarItem: QuickLaunchBarItem?
    // 用于业务方传递埋点所需参数
    public var extraMap: [String: Any]?
    // 对应的 URL
    public var url: URL
    
    public init(url: URL,
         navigationBarItem: LKBarButtonItem? = nil,
         launchBarItem: QuickLaunchBarItem? = nil,
         extraMap: [String: Any]? = nil) {
        self.url = url
        self.navigationBarItem = navigationBarItem
        self.launchBarItem = launchBarItem
        self.extraMap = extraMap
    }
}
