//
//  FontBarItem.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/7.
//

import UIKit

public enum FontBarStyle {
    case `static`
    // fontbar能动态显隐
    case dynamic
}

public struct FontToolBarStatusItem: Equatable {
    public var style: FontBarStyle?
    public var isBold: Bool = false
    public var isItalic: Bool = false
    public var isStrikethrough: Bool = false
    public var isUnderline: Bool = false

    public init(style: FontBarStyle? = nil,
                isBold: Bool = false,
                isItalic: Bool = false,
                isStrikethrough: Bool = false,
                isUnderline: Bool = false) {
        self.style = style
        self.isBold = isBold
        self.isItalic = isItalic
        self.isStrikethrough = isStrikethrough
        self.isUnderline = isUnderline
    }

    public static func == (lhs: FontToolBarStatusItem, rhs: FontToolBarStatusItem) -> Bool {
        return lhs.isBold == rhs.isBold
            && lhs.isItalic == rhs.isItalic
            && lhs.isStrikethrough == rhs.isStrikethrough
            && lhs.isUnderline == rhs.isUnderline
    }
}
