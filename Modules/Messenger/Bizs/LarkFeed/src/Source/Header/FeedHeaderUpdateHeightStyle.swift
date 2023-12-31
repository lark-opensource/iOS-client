//
//  FeedHeaderUpdateHeightStyle.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/7.
//

import Foundation
enum HeaderUpdateHeightStyle {
    case normal // 正常更新高度
    case expandByScrollForShortcut // 通过下拉对shortcut进行展开导致的高度更新
    case collapseByScrollForShortcut // 通过上滑对shortcut进行收起导致的高度更新
    case expandCollapseByClickForShortcut // 通过点击对shortcut进行展开/收起导致的高度更新
}
