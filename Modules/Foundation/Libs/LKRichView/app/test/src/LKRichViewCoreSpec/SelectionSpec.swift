//
//  SelectionSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by 白言韬 on 2021/8/30.
//

import UIKit
import Foundation
import XCTest
@testable import LKRichView

// swiftlint:disable all
class SelectionSpec: XCTestCase {

    var core: LKRichViewCore!
    var styleSheet: CSSStyleSheet!
    let atPadding: CGFloat = 4

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: Tag.p), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 14))),
                StyleProperty.fontSize(.init(.point, 14)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.at), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.backgroundColor(.init(.value, UIColor.blue)),
                StyleProperty.color(.init(.value, UIColor.white)),
                StyleProperty.padding(.init(.value, Edges(.point(atPadding)))),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(1), height: .em(1)))))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "bold"), [
                StyleProperty.fontWeigth(.init(.value, .bold))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "italic"), [
                StyleProperty.fontStyle(.init(.value, .italic))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "italicBold"), [
                StyleProperty.fontWeigth(.init(.value, .bold)),
                StyleProperty.fontStyle(.init(.value, .italic))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "point"), [
                StyleProperty.verticalAlign(.init(.value, .top)),
                StyleProperty.width(.init(.point, 4)),
                StyleProperty.height(.init(.point, 4)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .point(2), height: .point(2)))))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "green"), [
                StyleProperty.backgroundColor(.init(.value, UIColor.green))
            ])
        ])
        core = LKRichViewCore(styleSheets: [styleSheet])
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // 先只提交一个测试
    func testNormal() {
        let element = LKBlockElement(tagName: Tag.p)
        let at1 = LKInlineBlockElement(tagName: Tag.at).addChild(LKTextElement(text: "普通的"))
        let point = LKInlineBlockElement(tagName: Tag.span, classNames: ["point", "green"])
        let atPoint = LKInlineBlockElement(tagName: Tag.span)
            .children([LKTextElement(text: "带圆点的名字"), point])
        let at2 = LKInlineBlockElement(tagName: Tag.at)
            .addChild(LKTextElement(text: "限制宽高的一"))
            .style(LKRichStyle().height(.point(60)).width(.point(55)))
        let splitText = LKTextElement(text: "这是一段很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字，需要被折行")
        let at3 = LKInlineBlockElement(tagName: Tag.at)
            .addChild(LKTextElement(text: "限制宽高的"))
            .style(LKRichStyle().height(.point(60)).width(.point(55)))
        element.children([at1, atPoint, at2, splitText, at3])

        guard let renderer = core.createRenderer(element) else {
            return
        }
        core.load(renderer: renderer)
        _ = core.layout(CGSize(width: 300, height: 200))

        if true {
            let rect = core.getSeletedRects(start: CGPoint(x: 6, y: 148), end: CGPoint(x: 274, y: 12))
            XCTAssertEqual(8, rect.rects.count)
        }
        if true {
            let at1Rect = renderer.children[0].boxRect
            let at3Rect = renderer.children[4].boxRect
            let rect = core.getSeletedRects(start: at1Rect.origin, end: at3Rect.origin)
            let expectRect: [CGRect] = [
                CGRect(x: 0, y: 95, width: 50, height: 63),
                CGRect(x: 50, y: 117, width: 90, height: 20),
                CGRect(x: 140, y: 95, width: 55, height: 62.8),
                CGRect(x: 195.5, y: 95, width: 100, height: 63),
                CGRect(x: 0, y: 77, width: 300, height: 20),
                CGRect(x: 0, y: 60, width: 300, height: 20),
                CGRect(x: 0, y: -1.4, width: 200, height: 63),
                CGRect(x: 200, y: -1.4, width: 1, height: 63)
            ]
            XCTAssertEqual(expectRect.count, rect.rects.count)
            for i in 0..<rect.rects.count {
                XCTAssertTrue(expectRect[i] ~= rect.rects[i])
            }
        }
    }

    func testInlineBlockWithPadding() {
        let text = LKTextElement(text: "有内边距的普通")
        let textSize = CGSize(width: 100, height: 16.7)
        assertConcreteSize(textSize, desc: "Text", element: text, styleSheets: [styleSheet])

        let at = LKInlineBlockElement(tagName: Tag.at).addChild(text)
        let atSize = CGSize(width: textSize.width + 2 * atPadding, height: textSize.height + 2 * atPadding)
        assertConcreteSize(atSize, desc: "AT", element: at, styleSheets: [styleSheet])

        let element = LKBlockElement(tagName: Tag.p)
            .children([at, text])
        let elementSize = CGSize(width: textSize.width + atSize.width, height: atSize.height)
        let elementRO = assertConcreteSize(elementSize, desc: "Container", element: element, styleSheets: [styleSheet])

        XCTAssertTrue(elementRO.children[0].boxRect.size ~= atSize)
        XCTAssertTrue(elementRO.children[0].children[0].boxRect.size ~= textSize)
        XCTAssertTrue(elementRO.children[1].boxRect.size ~= textSize)

        guard let renderer = core.createRenderer(element) else {
            return
        }
        core.load(renderer: renderer)
        _ = core.layout(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        let offset = renderer.renderStyle.lineHeight - renderer.renderStyle.fontSize
        let rect = core.getSeletedRects(start: CGPoint.zero, end: CGPoint(x: elementSize.width - 1, y: atPadding))
        let expectRext: [CGRect] = [
            CGRect(origin: CGPoint(x: 0, y: -offset / 2), size: CGSize(width: atSize.width, height: atSize.height + offset)),
            CGRect(origin: .init(x: atSize.width, y: -offset / 2), size: CGSize(width: textSize.width, height: atSize.height + offset))
        ]
        XCTAssertEqual(expectRext.count, rect.rects.count)
        for i in 0..<rect.rects.count {
            XCTAssertTrue(expectRext[i] ~= rect.rects[i])
        }
    }
}

extension SelectionSpec {
    enum Tag: Int8, LKRichElementTag {
        case p
        case h1
        case h2
        case h3
        case a
        case at
        case emotion
        case span

        var typeID: Int8 {
            return rawValue
        }
    }
}
