//
//  StylePropertyProtocols.swift
//  LKRichView
//
//  Created by qihongye on 2019/12/25.
//

import UIKit
import Foundation

public protocol StylePropertyProtocol {
    static func display(_ value: LKRichStyleValue<Display>) -> StyleProperty

    static func writingMode(_ value: WritingMode) -> StyleProperty

    static func lineHeight(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func fontSize(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func width(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func height(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func maxWidth(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func maxHeight(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func minWidth(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func minHeight(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty

    static func font(_ value: LKRichStyleValue<UIFont>) -> StyleProperty

    static func fontWeigth(_ value: LKRichStyleValue<FontWeight>) -> StyleProperty

    static func fontStyle(_ value: LKRichStyleValue<FontStyle>) -> StyleProperty

    static func backgroundColor(_ value: LKRichStyleValue<UIColor>) -> StyleProperty

    static func color(_ value: LKRichStyleValue<UIColor>) -> StyleProperty

    static func textAlign(_ value: LKRichStyleValue<TextAlign>) -> StyleProperty

    static func verticalAlign(_ value: LKRichStyleValue<VerticalAlign>) -> StyleProperty

    static func textDecoration(_ value: LKRichStyleValue<TextDecoration>) -> StyleProperty

    static func border(_ value: LKRichStyleValue<Border>) -> StyleProperty

    static func borderRadius(_ value: LKRichStyleValue<BorderRadius>) -> StyleProperty

    static func margin(_ value: LKRichStyleValue<Edges>) -> StyleProperty

    static func padding(_ value: LKRichStyleValue<Edges>) -> StyleProperty

    static func textOverflow(_ value: LKRichStyleValue<LKTextOverflow>) -> StyleProperty

    static func lineCamp(_ value: LKRichStyleValue<LineCamp>) -> StyleProperty
}
