//
//  ShortcutExpandCollapseType.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/6.
//

// 展开收起的类型
enum ShortcutExpandCollapseType {
    case none
    case expandByClick // 通过点击按钮进行展开操作
    case collapseByClick // 通过点击按钮进行收起操作
    case expandByScroll // 通过滑动进行展开操作（下拉）
    case collapseByScroll // 通过滑动进行收起操作（上滑）
}
