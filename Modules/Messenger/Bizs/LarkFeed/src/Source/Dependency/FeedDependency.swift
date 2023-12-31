//
//  FeedDependency.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/28.
//

import Foundation
import RxSwift
import LarkInteraction
import LarkContainer

public typealias FeedDependencyProvider = () -> FeedDependency

/// Feed对外部的依赖
public protocol FeedDependency: UserResolverWrapper {
    // MARK: LarkCore
    /// chat 支持的 item 类型
    var supportTypes: [DropItemType] { get }
    /// 展示草稿
    func getDraftFromLarkCoreModel(content: String) -> String
    /// 设置临时的 DropItems
    func setDropItemsFromLarkCoreModel(chatID: String, items: [DropItemValue])

    // MARK: LarkMinimumMode
    /// 展示切换至基本功能模式提示(内部会去判断是否需要执行展示逻辑) show：具体的展示逻辑
    func showMinimumModeChangeTip(show: () -> Void)
}
