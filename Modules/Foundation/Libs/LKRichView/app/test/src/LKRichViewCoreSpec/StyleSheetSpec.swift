//
//  StyleSheetSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2019/12/25.
//
// swiftlint:disable overridden_super_call

import UIKit
import Foundation
import XCTest

@testable import LKRichView

class StyleSheetSpec: XCTestCase {
    enum TagName: LKRichElementTag {
        case p
        case span
        case a

        var typeID: Int8 {
            switch self {
            case .p:
                return 0
            case .span:
                return 1
            case .a:
                return 2
            }
        }
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStyleSheetCreate() {
        let font = UIFont(name: "PingFangSC-Reqular", size: 14)
        let styleRule = CSSStyleRule.create(CSSSelector(value: TagName.p), [
            StyleProperty.font(.init(.value, font)),
            StyleProperty.display(.init(.value, .block))
        ])
        XCTAssertEqual(
            (styleRule.properties.storage[LKRenderRichStyle.Key.font.rawValue] as? LKRichStyleValue<UIFont>)?.value,
            font
        )

        let styleSheet = CSSStyleSheet(rules: [styleRule])
        XCTAssertEqual(
            (styleSheet.rules[0].properties.storage[LKRenderRichStyle.Key.font.rawValue] as? LKRichStyleValue<UIFont>)?.value,
            font
        )
    }

    func testStyleRuleMatch() {
        /**
         * #id1.class1.class2 p { dispaly: inline-block; color: white; backgroundColor: red; }
         * #id2.class1 > class2 { display: block; color: inherit; backgroundColor: green; }
         * p#id1.class1.class2
         *  p
         *   p
         *   p#id2.class1
         *    p.class2
         *     p.class2
         */
        let rule1 = CSSStyleRule(
            selectors: CSSSelector(match: .id, value: "id1")
                <& CSSSelector(match: .className, value: "class1")
                <& CSSSelector(match: .className, value: "class2")
                <| CSSSelector(match: .tag, value: Int(TagName.p.typeID)),
            properties: StyleProperties([
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.color(.init(.value, UIColor.white)),
                StyleProperty.backgroundColor(.init(.value, UIColor.red))
            ])
        )
        let rule2 = CSSStyleRule(
            selectors: CSSSelector(match: .id, value: "id2")
                <& .init(match: .className, value: "class1")
                <> .init(match: .className, value: "class2"),
            properties: StyleProperties([
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.color(.init(.inherit, nil)),
                StyleProperty.backgroundColor(.init(.value, UIColor.green))
            ])
        )

        let root = LKBlockElement(id: "id1", tagName: TagName.p, classNames: ["class1", "class2"])
            .children([
                LKInlineBlockElement(tagName: TagName.p)
                    .children([
                        LKBlockElement(tagName: TagName.p),
                        LKBlockElement(id: "id2", tagName: TagName.p, classNames: ["class1"])
                            .children([
                                LKBlockElement(tagName: TagName.p, classNames: ["class2"])
                                    .children([
                                        LKBlockElement(tagName: TagName.p, classNames: ["class2"])
                                    ])
                            ])
                    ])
            ])

        XCTAssertFalse(rule1.match(node: root))
        XCTAssertFalse(rule2.match(node: root))
        // p#id1 > p
        XCTAssertTrue(rule1.match(node: root.subElements[0]))
        XCTAssertFalse(rule2.match(node: root.subElements[0]))
        // p#id1 > p > p
        XCTAssertTrue(rule1.match(node: root.subElements[0].subElements[0]))
        XCTAssertFalse(rule2.match(node: root.subElements[0].subElements[0]))
        XCTAssertTrue(rule1.match(node: root.subElements[0].subElements[1]))
        XCTAssertFalse(rule2.match(node: root.subElements[0].subElements[1]))
        // p#id1 > p > p > p
        XCTAssertTrue(rule1.match(node: root.subElements[0].subElements[1].subElements[0]))
        XCTAssertTrue(rule2.match(node: root.subElements[0].subElements[1].subElements[0]))
        // p#id1 > p > p > p > p
        XCTAssertTrue(rule1.match(node: root.subElements[0].subElements[1].subElements[0].subElements[0]))
        XCTAssertFalse(rule2.match(node: root.subElements[0].subElements[1].subElements[0].subElements[0]))
    }

    func testChild() {
        /**
         * #id1.class1.class2 p { dispaly: inlneBlock; color: inherit; backgroundColor: red; }
         * #id2.class1 > class2 { display: block; color: inherit; backgroundColor: green; }
         * span { display: block; }
         * a { text-decoration: none; }
         * p#id1.class1.class2
         *  p
         *   p
         *    span.class2
         *   p#id2.class1
         *    p.class2
         *     p.class2
         */
        let sheet = CSSStyleSheet(rules: [
            CSSStyleRule(
                selectors: CSSSelector(match: .id, value: "id1")
                    <& CSSSelector(match: .className, value: "class1")
                    <& CSSSelector(match: .className, value: "class2")
                    <| CSSSelector(match: .tag, value: Int(TagName.p.typeID)),
                properties: StyleProperties([
                    StyleProperty.display(.init(.value, .inlineBlock)),
                    StyleProperty.color(.init(.value, UIColor.white)),
                    StyleProperty.backgroundColor(.init(.value, UIColor.red))
                ])
            ),
            CSSStyleRule(
                selectors: CSSSelector(match: .id, value: "id2")
                    <& .init(match: .className, value: "class1")
                    <> .init(match: .className, value: "class2"),
                properties: StyleProperties([
                    StyleProperty.display(.init(.value, .block)),
                    StyleProperty.color(.init(.inherit, nil)),
                    StyleProperty.backgroundColor(.init(.value, UIColor.green))
                ])
            ),
            CSSStyleRule(
                selectors: [CSSSelector(value: TagName.a)],
                properties: StyleProperties([
                    StyleProperty.textDecoration(.init(.value, nil))
                ])
            ),
            CSSStyleRule(
                selectors: [CSSSelector(value: TagName.span)],
                properties: StyleProperties([
                    StyleProperty.display(.init(.value, .block))
                ])
            )
        ])
        let anchor = LKAnchorElement(tagName: TagName.a, text: "")
        let root = LKBlockElement(id: "id1", tagName: TagName.p, classNames: ["class1", "class2"])
            .children([
                LKInlineBlockElement(tagName: TagName.p)
                    .children([
                        LKBlockElement(tagName: TagName.p).children([
                            LKInlineElement(tagName: TagName.span, classNames: ["class2"])
                        ]),
                        LKBlockElement(id: "id2", tagName: TagName.p, classNames: ["class1"])
                            .children([
                                LKBlockElement(tagName: TagName.p, classNames: ["class2"])
                                    .children([
                                        LKBlockElement(tagName: TagName.p, classNames: ["class2"])
                                            .children([
                                                LKAnchorElement(tagName: TagName.a, text: ""),
                                                anchor
                                            ])
                                    ])
                            ])
                    ])
            ])

        let textDecoration = TextDecoration(line: .lineThrough + .underline, style: .dashed, thickness: 1, color: UIColor.black)
        anchor.style.textDecoration(textDecoration)

        let engine = CSSStyleEngine([sheet])
        let renderer = root.createRenderer(cssEngine: engine)

        if true {
            // p#id1.class1.class2
            XCTAssertEqual(renderer.renderStyle.backgroundColor, nil)
            XCTAssertEqual(renderer.renderStyle.color, UIColor.black)
            XCTAssertEqual(renderer.renderStyle.display, .block)
        }
        if true {
            // p
            let renderer = renderer.children[0]
            XCTAssertEqual(renderer.renderStyle.backgroundColor, UIColor.red)
            XCTAssertEqual(renderer.renderStyle.color, UIColor.white)
            XCTAssertEqual(renderer.renderStyle.display, .inlineBlock)
        }
        if true {
            // p p
            let renderer = renderer.children[0].children[0]
            XCTAssertEqual(renderer.renderStyle.backgroundColor, UIColor.red)
            XCTAssertEqual(renderer.renderStyle.color, UIColor.white)
            XCTAssertEqual(renderer.renderStyle.display, .inlineBlock)
        }
        if true {
            // p p span
            let renderer = renderer.children[0].children[0].children[0]
            XCTAssertEqual(renderer.renderStyle.display, .block)
        }
        if true {
            // p p#id2.class1
            let renderer = renderer.children[0].children[1]
            XCTAssertEqual(renderer.renderStyle.backgroundColor, UIColor.red)
            XCTAssertEqual(renderer.renderStyle.color, UIColor.white)
            XCTAssertEqual(renderer.renderStyle.display, .inlineBlock)
        }
        if true {
            // p p#id2.class1 p.class2
            let renderer = renderer.children[0].children[1].children[0]
            XCTAssertEqual(renderer.renderStyle.backgroundColor, UIColor.green)
            XCTAssertEqual(renderer.renderStyle.color, UIColor.white)
            XCTAssertEqual(renderer.renderStyle.display, .block)
        }
        if true {
            // p p#id2.class1
            let renderer = renderer.children[0].children[1].children[0].children[0]
            XCTAssertEqual(renderer.renderStyle.backgroundColor, UIColor.red)
            XCTAssertEqual(renderer.renderStyle.color, UIColor.white)
            XCTAssertEqual(renderer.renderStyle.display, .inlineBlock)
        }
        if true {
            // p > a
            let renderer = renderer.children[0].children[1].children[0].children[0].children[0]
            XCTAssertEqual(renderer.renderStyle.textDirection?.lineThrough, nil)
            XCTAssertEqual(renderer.renderStyle.textDirection?.underline, nil)
        }
        if true {
            // p > a
            let renderer = renderer.children[0].children[1].children[0].children[0].children[1]
            XCTAssertEqual(renderer.renderStyle.textDirection?.lineThrough, textDecoration)
            XCTAssertEqual(renderer.renderStyle.textDirection?.underline, textDecoration)
        }
    }

    func testCreateRenderStyle() {
        /// order: tag < className < id < style
        let sheet = CSSStyleSheet(rules: [
            CSSStyleRule(
                selectors: [CSSSelector(value: TagName.span)],
                properties: StyleProperties([
                    StyleProperty.textDecoration(
                        .init(.value, .none)
                    )
                ])
            ),
            CSSStyleRule(
                selectors: [CSSSelector(match: .className, value: "span")],
                properties: StyleProperties([
                    StyleProperty.color(.init(.value, .red)),
                    StyleProperty.backgroundColor(.init(.value, .red))
                ])
            ),
            CSSStyleRule(
                selectors: [CSSSelector(match: .id, value: "span")],
                properties: StyleProperties([
                    StyleProperty.color(.init(.value, .yellow)),
                    StyleProperty.backgroundColor(.init(.value, .yellow))
                ])
            )
        ])
        let engine = CSSStyleEngine([sheet])
        let span = LKInlineElement(id: "span", tagName: TagName.span, classNames: ["span"])
        let textDecoration = TextDecoration(line: .lineThrough + .underline, style: .solid, thickness: 1, color: .red)
        span.style.textDecoration(textDecoration)
        span.style.backgroundColor(UIColor.black)

        XCTAssertEqual(engine.createRenderStyle(node: span).textDecoration.value, textDecoration)
        XCTAssertEqual(engine.createRenderStyle(node: span).color.value, .yellow)
        XCTAssertEqual(engine.createRenderStyle(node: span).backgroundColor.value, .black)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
