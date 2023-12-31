//
//  FeedRenderType.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/8.
//

/// Feed刷新策略
import UIKit
import Foundation
enum FeedRenderType: Equatable {
    // 直接reloadData
    case reload

    // 通过Diff局部更新且带动画(insert/delete/reload/move)
    case animate(UITableView.RowAnimation)

    // 通过Diff局部更新但不带动画(insert/delete/reload/move)
    // 注意即使RowAnimation = none，更新row时也是有动画的
    case none

    // 只更新数据源，不刷新UI，也不更新UI数据
    case ignore

    static func == (lhs: FeedRenderType, rhs: FeedRenderType) -> Bool {
        switch (lhs, rhs) {
        case (.reload, .reload): return true
        case (.animate(let l), .animate(let r)): return l == r
        case (.none, .none): return true
        case (.ignore, .ignore): return true
        default: return false
        }
    }
}
