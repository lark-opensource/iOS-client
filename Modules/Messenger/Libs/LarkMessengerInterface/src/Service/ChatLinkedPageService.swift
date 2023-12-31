//
//  ChatLinkedPageService.swift
//  LarkMessengerInterface
//
//  Created by zhaojiachen on 2023/10/24.
//

import Foundation
import LarkQuickLaunchInterface
import LarkUIKit

public protocol ChatLinkedPageService {
    func createBarItems(for url: URL, on vc: UIViewController, with completion: @escaping (ChatLinkedPageBarItemsForWeb) -> Void)

    func destroyBarItems()
}

public struct ChatLinkedPageBarItemsForWeb {
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
