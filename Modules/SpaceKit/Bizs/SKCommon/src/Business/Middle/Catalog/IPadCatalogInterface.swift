//
//  DocsCatalogInterface.swift
//  SKDoc
//
//  Created by lizechuang on 2021/3/31.
//

import Foundation

public enum IpadCatalogStatus: Int {
    case loading // 加载状态（目录数据暂未拉取）
    case normal // 显示状态（有数据）
    case empty // 显示状态（无数据）
}

public enum IPadCatalogMode: Int {
    case embedded     // 嵌入式
    case covered      // 覆盖式
}

public protocol IPadCatalogSideViewDelegate: AnyObject {
    func didClickItem(_ item: CatalogItemDetail, mode: IPadCatalogMode)
}

public struct IPadCatalogConst {
    static let lineOffsetX: CGFloat = 16.0
    static let lindHeight: CGFloat = 36.0
    static let contentInsetY: CGFloat = 12.0
    static let emptyLabelOffsetY: CGFloat = 16.0
    static let caculateEmptyLabelHeight: CGFloat = 44.0
    static let emptyCentetOffsetY: CGFloat = 12.0
    static let emptyIconWidth: CGFloat = 104
    // 显示样式相关
    public static let embeddedMinimumContainerWidth: CGFloat = 900 // https://bytedance.feishu.cn/docs/doccnDERI84ENjLwi3p8tOldkzh
    // 显示样式相关，嵌入式
    public static let catalogDisplayMinWidth: CGFloat = 172
    public static let catalogDisplayNormalPercentage: CGFloat = 0.2 // 目录显示宽度，根据容器宽度的百分比计算，正常情况下都是20%
    public static let catalogDisplayLargePercentage: CGFloat = 0.2361 // 目录显示宽度，根据容器宽度的百分比计算，大屏情况下都是23.61%
    public static let maxContentWidth: CGFloat = 1240
    // 显示样式相关，覆盖式
    public static let catalogDisplayCoveredWidth: CGFloat = 272 // 固定值
}
