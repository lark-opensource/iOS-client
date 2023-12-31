//
//  RichTextStyle.swift
//  LarkRichTextCore
//
//  Created by wangwanxin on 2023/4/4.
//

import Foundation

public enum RichTextStyleKey: String {
    case fontWeight = "fontWeight"
    case fontStyle = "fontStyle"
    case textDecoration = "-lark-textDecoration"
}

public enum RichTextStyleValue: String {
    case bold
    case italic
    case underline
    case lineThrough
}
