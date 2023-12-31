//
//  CardViewConstant.swift
//  SKBitable
//
//  Created by zoujie on 2023/11/1.
//  

import Foundation

struct CardViewConstant {
    struct LayoutConfig {
        static let textTitleSingleLineHeight: CGFloat = 24 // 文本字段标题单行高度
        static let textTitleMutilLineHeight: CGFloat = 48 // 文本字段标题两行高度
        static let cardListViewPaddingTop: CGFloat = 16
        static let coverViewSingleCloSize: CGSize = CGSize(width: 104, height: 104) // 单列字段封面size
        static let cardCellInset: CGFloat = 4
        static let coverViewSize = coverViewSingleCloSize // 封面size
        static let fieldLineSpacing: CGFloat = 12 // 字段行间距
        static let fieldSingleCloLineSpacing: CGFloat = 2 // 单列字段行间距
        static let fieldInteritemSpacing: CGFloat = 8 // 字段列间距
        static let fieldHeightForRL: CGFloat = 24 //左右布局字段高度
        static let fieldHeightForTB: CGFloat = 42 // 上下布局字段高度
        static let groupHeaderHeight: CGFloat = 40 // 分组头的高度
        static let textTtileFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let footerHeightWithText: CGFloat = 156 // 列表底部footer高度
        static let groupHeightAdjustHeight: CGFloat = 8.0 // 分组头首尾的高度给到cell
        static let titleAndFieldSectionSpacingForSingleLine = 6.0 // 单列时，title和字段section间距
        static let titleAndFieldSectionSpacing: CGFloat = 8.0 // title和字段section间距
    }
    
    static let commonParams: [String: String] = ["building_type": "native"]
}
