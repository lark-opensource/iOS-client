//
//  CodeTheme.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/11/6.
//

import UIKit
import RustPB
import Foundation
import UniverseDesignColor

/// copy from RichTextStyleKey
public enum TextStyleKey: String {
    case fontWeight = "fontWeight"
    case fontStyle = "fontStyle"
    case textDecoration = "-lark-textDecoration"
}

/// copy from RichTextStyleValue
public enum TextStyleValue: String {
    case bold
    case italic
    case underline
    case lineThrough
}

/// CodeBlock主题配置，需要考虑暗黑模式
public struct CodeTheme {
    /// 默认主题，一期的主题配置写死一份在端上
    public static let `default` = CodeTheme()
    /// 每个ContentType对应的样式
    public struct Style {
        /// contentStyles中获取不到的，则使用默认样式
        public static let `default` = Style()
        /// 使用考虑深浅色适配
        public let color: UIColor
        /// 和富文本的key-value保持一致
        public let style: [TextStyleKey: TextStyleValue]
        /// dark不传则和light保持一致，提供String的初始化方法减少代码量
        init(_ light: String = "#2b2f36", _ dark: String? = nil, style: [TextStyleKey: TextStyleValue] = [:]) {
            if let dark = dark { self.color = UIColor.ud.rgb(light) & UIColor.ud.rgb(dark) } else { self.color = UIColor.ud.rgb(light) }
            self.style = style
        }
    }
    /// 为了节省代码量，使用默认样式的不存储
    public let styles: [Basic_V1_RichTextElement.CodeBlockV2Property.ContentType: Style] = [
        .text: Style("#2b2f36", "#e8e8e8"), .operator: Style("#2b2f36", "#e8e8e8"), .punctuation: Style("#2b2f36", "#e8e8e8"),
        .property: Style("#2b2f36", "#e8e8e8"), .charEscape: Style("#2b2f36", "#e8e8e8"), .class: Style("#2b2f36", "#e8e8e8"),
        .function: Style("#2b2f36", "#e8e8e8"), .variableLanguage: Style("#986801"), .variableConstant: Style("#986801"),
        .titleClassInherited: Style("#4078f2"), .titleFunction: Style("#4078f2"), .titleFunctionInvoke: Style("#4078f2"),
        .params: Style("#2b2f36", "#e8e8e8"), .metaPrompt: Style("#4078f2"), .metaKeyword: Style("#4078f2"),
        .tag: Style("#2b2f36", "#e8e8e8"), .code: Style("#2b2f36", "#e8e8e8"),
        .emphasis: Style("#2b2f36", "#e8e8e8", style: [.fontStyle: .italic]), .templateTag: Style("#2b2f36", "#e8e8e8"),
        .keyword: Style("#a626a4"), .builtIn: Style("#c18401"), .type: Style("#986801"), .literal: Style("#0184bb"),
        .number: Style("#986801"), .regexp: Style("#50a14f"), .string: Style("#50a14f"), .subst: Style("#e45649"),
        .symbol: Style("#4078f2"), .variable: Style("#986801"), .title: Style("#4078f2"), .titleClass: Style("#4078f2"),
        .comment: Style("#a0a1a7", style: [.fontStyle: .italic]), .doctag: Style("#a626a4"), .meta: Style("#4078f2"),
        .metaString: Style("#50a14f"), .section: Style("#e45649"), .name: Style("#e45649"), .attr: Style("#986801"),
        .attribute: Style("#50a14f"), .bullet: Style("#4078f2"), .formula: Style("#a626a4"),
        .link: Style("#4078f2", style: [.textDecoration: .underline]), .quote: Style("#a0a1a7", style: [.fontStyle: .italic]), .selectorTag: Style("#e45649"),
        .selectorID: Style("#4078f2"), .selectorClass: Style("#986801"), .selectorAttr: Style("#986801"), .selectorPseudo: Style("#986801"),
        .templateVariable: Style("#986801"), .addition: Style("#50a14f"), .deletion: Style("#e45649")
    ]
}
