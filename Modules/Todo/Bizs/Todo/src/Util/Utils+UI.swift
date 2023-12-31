//
//  Utils+UI.swift
//  Todo
//
//  Created by 张威 on 2020/11/13.
//

import LarkUIKit
import LarkTimeFormatUtils

extension Utils {
    // swiftlint:disable type_name
    struct UI { }
    // swiftlint:enable type_name
}

extension Utils.UI {
    /// Lark 定义的导航栏的高度
    static var naviBarHeight: CGFloat { LarkNaviBarConsts.naviHeight }
}

extension Utils.UI {

    /// 计算展示一段文字需要的行数
    /// - Parameters:
    ///   - text: 文本
    ///   - width: 文本控件的宽度
    ///   - font: 文本字体
    /// - Returns: 行数
    static func needLines(from text: String, width: CGFloat, font: UIFont) -> Int {
        var label = UILabel()
        label.font = font
        let splitText = text.components(separatedBy: "\n")
        var lines: Float = 0
        for sText in splitText {
            label.text = sText
            let textSize = label.systemLayoutSizeFitting(.zero)
            var sLines = ceilf(Float(textSize.width / width))
            sLines = sLines == 0 ? 1 : sLines
            lines += sLines
        }
        return Int(lines)
    }
}
