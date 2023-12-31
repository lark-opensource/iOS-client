//
//  ToolBarTitleWidthCache.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/7.
//

import Foundation

private struct TitleItem: Hashable {
    let title: String
    let size: CGFloat
    let weight: UIFont.Weight
}

class ToolBarTitleWidthCache {
    private static var cache: [TitleItem: CGFloat] = [:]

    static func titleWidth(_ title: String, fontSize: CGFloat, fontWeight: UIFont.Weight) -> CGFloat {
        assertMain()
        let item = TitleItem(title: title, size: fontSize, weight: fontWeight)
        if let width = cache[item] {
            return width
        } else {
            let width = ToolBarItemLayout.textWidth(title, font: UIFont.systemFont(ofSize: fontSize, weight: fontWeight))
            cache[item] = width
            return width
        }
    }
}
