//
//  WPGuideKey.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2023/10/26.
//

import Foundation

/// Lark Guide Key
enum WPGuideKey: String {
    /// 「应用排序和角标展示」引导
    /// 权值：100
    /// maxCount: 1
    /// 可视区域：AppCenter
    /// 接入端：all
    /// 需上线环境：boe，cn online，va online，sg online，jp online
    /// 上线版本：7.6
    case sortBadgeGuide = "workplace_sort_badge_guide"
}
