//
//  MsgCardRichViewExtension.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/6/21.
//

import Foundation
import LKRichView

let RichViewConfig = ConfigOptions([
    .debug(false),
    .visualConfig(VisualConfig(
        selectionColor: UIColor.ud.colorfulBlue.withAlphaComponent(0.16),
        cursorColor: UIColor.ud.colorfulBlue,
        cursorHitTestInsets: UIEdgeInsets(
            top: -14, left: -25, bottom: -14, right: -25
        )
    ))
])
let CursorSize = SelectionCursor(type: .start).pointRadius * -2.0

public enum Tag: Int8, LKRichElementTag {
    case container = 0
    case p = 1
    case a = 2
    case at = 3
    case more = 4
    case person = 5
    case emotion = 6
    case textTagContainer = 7
    case ul = 8
    case ol = 9
    case li = 10

    public var typeID: Int8 {
        return rawValue
    }
}

public struct ClassName {
    static let atMe = "atMe"
    static let atAll = "atAll"
    static let atInnerGroup = "atInnerGroup"
    static let atOuterGroup = "atOuterGroup"
    static let bold = "bold"
    static let italic = "italic"
    static let underline = "underline"
    static let lineThrough = "lineThrough"
    static let emotion = "emotion"
    static let plaintText = "plaintText"
    static let br = "br"
}

public func createStyleSheets() -> [CSSStyleSheet] {
    let styleSheet = CSSStyleSheet(rules: [
        // MARK: li
        CSSStyleRule.create(CSSSelector(value: Tag.li), [
            StyleProperty.padding(.init(.value, Edges(.point(1), .point(0), .point(3), .point(0)))),
            StyleProperty.verticalAlign(.init(.value, .baseline))
        ]),
        // MARK: TextTag
        CSSStyleRule.create(CSSSelector(value: Tag.textTagContainer), [
            StyleProperty.display(.init(.value, .inlineBlock))
        ]),
        // MARK: ANCHOR
        CSSStyleRule.create(CSSSelector(value: Tag.a), [
            StyleProperty.color(.init(.value, UIColor.ud.textLinkNormal)),
            StyleProperty.textDecoration(.init(.value, .none))
        ]),
        // MARK: AT
        CSSStyleRule.create(CSSSelector(value: Tag.at), [
            StyleProperty.display(.init(.value, .inline))
        ]),
        // AT ME
        CSSStyleRule.create([CSSSelector(value: ElementTag.at), CSSSelector(match: .className, value: ClassName.atMe)], [
            StyleProperty.display(.init(.value, .inlineBlock)),
            StyleProperty.backgroundColor(.init(.value, UIColor.ud.functionInfoContentDefault)),
            StyleProperty.color(.init(.value, UIColor.ud.primaryOnPrimaryFill)),
            StyleProperty.padding(.init(.value, Edges(.point(1), .point(4)))),
            StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
        ]),
        CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atMe)], [
            StyleProperty.display(.init(.value, .inlineBlock)),
            StyleProperty.backgroundColor(.init(.value, UIColor.ud.functionInfoContentDefault)),
            StyleProperty.color(.init(.value, UIColor.ud.primaryOnPrimaryFill)),
            StyleProperty.padding(.init(.value, Edges(.point(1), .point(4)))),
            StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
        ]),
        /// AT ALL
        CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atAll)], [
            StyleProperty.color(.init(.value, UIColor.ud.textLinkNormal)),
            StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
        ]),
        /// AT INNERGROUP
        CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atInnerGroup)], [
            StyleProperty.color(.init(.value, UIColor.ud.textLinkNormal)),
            StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
        ]),
        /// AT OUTERGROUP
        CSSStyleRule.create([CSSSelector(value: Tag.at), CSSSelector(match: .className, value: ClassName.atOuterGroup)], [
            StyleProperty.color(.init(.value, UIColor.ud.textCaption)),
            StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8)))))
        ]),
        // MARK: TEXT
        CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.bold), [
            StyleProperty.fontWeigth(.init(.value, .bold))
        ]),
        CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.italic), [
            StyleProperty.fontStyle(.init(.value, .italic))
        ]),
        CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.underline), [
            StyleProperty.textDecoration(
                .init(.value, TextDecoration(line: .underline, style: .solid, thickness: 1))
            )
        ]),
        CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.lineThrough), [
            StyleProperty.textDecoration(
                .init(.value, TextDecoration(line: .lineThrough, style: .solid, thickness: 1))
            )
        ]),
        // MARK: EMOTION
        CSSStyleRule.create(CSSSelector(match: .className, value: ClassName.emotion), [
            StyleProperty.height(.init(.em, 1.2)),
            StyleProperty.padding(.init(.value, .init(.point(0), .point(1), .point(0), .point(1)))),
            StyleProperty.verticalAlign(.init(.value, .baseline))
        ]),
    ])
    return [styleSheet]
}
