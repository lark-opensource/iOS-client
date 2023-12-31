//
//  AppBadgeListenerService.swift
//  LarkOPInterface
//
//  Created by Meng on 2022/11/16.
//

import Foundation

/// 应用 Badge 监听服务，仅用于 API。
/// tt.onServerBadgePush
/// tt.offServerBadgePush
public protocol AppBadgeListenerService {
    /// 监听 badge
    /// - Parameters:
    ///   - appId: 应用 id
    ///   - subAppIds: 监听其他应用 id，能力受白名单控制，使用场景如工作台官方组件「应用列表」
    ///   - callback: 监听回调
    func observeBadge(appId: String, subAppIds: [String], callback: @escaping (AppBadgeNode) -> Void)

    /// 移除监听 badge
    /// - Parameters:
    ///   - appId: 应用 id
    ///   - subAppIds: 监听其他应用 id，能力受白名单控制，使用场景如工作台官方组件「应用列表」
    ///   - callback: 监听回调
    func removeObserver(appId: String, subAppIds: [String])
}
