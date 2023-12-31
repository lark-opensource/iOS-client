//
//  LayoutSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by 白言韬 on 2021/11/25.
//

import UIKit
import Foundation
import XCTest
@testable import LKRichView

// swiftlint:disable all
class LayoutSpec: XCTestCase {

    // 测试 inline split 时，对 padding 的处理，目前实现还有问题，仅供参考
    func test1() {
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "一二三四五六七八九十一二三四五六七八九十一二三四"),
            LKInlineElement(tagName: Tag.span).children([
                LKInlineBlockElement(tagName: Tag.span).children([LKTextElement(text: "🐶")])
            ]).style(LKRichStyle().padding(top: .point(0), right: .point(5)))
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 17, width: 342, height: 17))

        XCTAssert(lineBoxs[1].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 0, width: 30, height: 16))
        XCTAssert(lineBoxs[1].runBoxs[1] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[1].runBoxs[1].globalRect ~= CGRect(x: 30, y: 3, width: 10, height: 0))
    }

    // 和 test1 的区别在于 inline 在 split 时，自己的 children 也是一个 inline，目前实现还有问题，仅供参考
    func test2() {
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "一二三四五六七八九十一二三四五六七八九十一二三四"),
            LKInlineElement(tagName: Tag.span).children([
                // 区别在这里
                LKInlineElement(tagName: Tag.span).children([LKTextElement(text: "🐶")])
            ]).style(LKRichStyle().padding(top: .point(0), right: .point(5)))
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 13, width: 342, height: 17))
        XCTAssert(lineBoxs[0].runBoxs[1] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[0].runBoxs[1].globalRect ~= CGRect(x: 342, y: 13, width: 30, height: 16))

        XCTAssert(lineBoxs[1].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 0, width: 10, height: 0))
    }

    // 测试 TextRunbox 在 split 时，给了一个很小的宽度的 badcase
    func test3() {
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "一二三四五六七八九十一二三四五六七八九十一二三四五"),
            LKTextElement(text: "🐶")
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 17, width: 356, height: 17))

        XCTAssert(lineBoxs[1].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 0, width: 20, height: 16))
    }

    // 基于 test3 扩散出的更边界的 case，即关键字后面带了一个空格的情况
    func test3_1() {
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "1一二三四五六七八九十一二三四五六七八九十一二三四五"),
            LKTextElement(text: "国 国")
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        if #available(iOS 16.0, *) {
            XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 17, width: 365, height: 17))
        } else {
            XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 17, width: 363, height: 17))
        }

        XCTAssert(lineBoxs[1].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 0, width: 32, height: 17))
    }

    // 测试 inline 反复嵌套，且有换行符的情况
    func test4() {
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "普通文字\n"),
            LKInlineElement(tagName: Tag.span).children([
                LKTextElement(text: "一二三四五六七八九十\n一二三四五六七八九十一二三四五六七八九十一二三四五六七八九十"),
                LKInlineElement(tagName: Tag.span).children([LKTextElement(text: "一二三四五六七八九十\n一二三四五六七八九十一二三四五六七八九十一二三四五六七八九十\n")])
            ]),
            LKTextElement(text: "普通文字")
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 108, width: 57, height: 17))

        XCTAssert(lineBoxs[1].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 90, width: 142, height: 17))

        XCTAssert(lineBoxs[2].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[2].runBoxs[0].globalRect ~= CGRect(x: 0, y: 72, width: 357, height: 17))

        XCTAssert(lineBoxs[3].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[3].runBoxs[0].globalRect ~= CGRect(x: 0, y: 54, width: 214, height: 17))

        XCTAssert(lineBoxs[4].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[4].runBoxs[0].globalRect ~= CGRect(x: 0, y: 36, width: 357, height: 17))

        XCTAssert(lineBoxs[5].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[5].runBoxs[0].globalRect ~= CGRect(x: 0, y: 18, width: 71, height: 17))

        XCTAssert(lineBoxs[6].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[6].runBoxs[0].globalRect ~= CGRect(x: 0, y: 3, width: 0, height: 0))

        XCTAssert(lineBoxs[6].runBoxs[1] is TextRunBox)
        XCTAssert(lineBoxs[6].runBoxs[1].globalRect ~= CGRect(x: 0, y: 0, width: 57, height: 17))
    }

    // 测试斜体被切割的问题
    func test5() {
        let container = LKBlockElement(tagName: Tag.p).style(LKRichStyle().fontSize(.point(11)))
        container.children([
            LKTextElement(text: "国国国国国国国国国国国国国国国国国国国国国国国国国国国国国国国国国").style(LKRichStyle().fontStyle(.italic)),
            LKTextElement(text: "国国国国国国国国国国国国国国")
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 14, width: 362, height: 13))

        XCTAssert(lineBoxs[1].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 1, width: 14, height: 13))

        XCTAssert(lineBoxs[1].runBoxs[1] is TextRunBox)
        XCTAssert(lineBoxs[1].runBoxs[1].globalRect ~= CGRect(x: 14, y: 1, width: 157, height: 13))
    }

    // 测试纯英文下，lineBreak by word
    func test6() {
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.").style(LKRichStyle().fontSize(.point(14)))
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 53, width: 360, height: 16.7))

        XCTAssert(lineBoxs[1].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 35, width: 305, height: 16.7))

        XCTAssert(lineBoxs[2].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[2].runBoxs[0].globalRect ~= CGRect(x: 0, y: 17, width: 348, height: 16.7))

        XCTAssert(lineBoxs[3].runBoxs[0] is TextRunBox)
        XCTAssert(lineBoxs[3].runBoxs[0].globalRect ~= CGRect(x: 0, y: 0, width: 309.2, height: 16.7))
    }

    // 测试 AT 其他人在 split 的时候，丢失了 rhs 的处理的 case
    func test7() {
        let atContainer = LKInlineElement(tagName: Tag.span).children([
            LKTextElement(text: "一个名"),
            LKInlineBlockElement(tagName: Tag.span).children([
                LKTextElement(text: "字"),
                LKInlineElement(tagName: Tag.span, classNames: ["point", "green"])
            ])
        ])
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            LKTextElement(text: "一二三四五六七八九十一二三四五六七八九十一二三四五1"),
            atContainer
        ])
        let lineBoxs = getLineBoxs(container)
        XCTAssert(lineBoxs[0].runBoxs[0] is TextRunBox)
        if #available(iOS 16.0, *) {
            XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 17, width: 365, height: 17))
        } else {
            XCTAssert(lineBoxs[0].runBoxs[0].globalRect ~= CGRect(x: 0, y: 18, width: 363, height: 17))
        }

        XCTAssert(lineBoxs[1].runBoxs[0] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[1].runBoxs[0].globalRect ~= CGRect(x: 0, y: 0, width: 42, height: 17))

        XCTAssert(lineBoxs[1].runBoxs[1] is InlineBlockContainerRunBox)
        XCTAssert(lineBoxs[1].runBoxs[1].globalRect ~= CGRect(x: 42, y: 0, width: 18, height: 17))
    }

    private func getLineBoxs(_ element: LKRichElement) -> [LineBox] {
        let core = LKRichViewCore()
        core.load(styleSheets: [styleSheet])
        guard let renderer = core.createRenderer(element) else {
            return []
        }
        core.load(renderer: renderer)
        _ = core.layout(CGSize(width: 370, height: CGFloat.greatestFiniteMagnitude))
        guard case .normal(let box) = renderer.runBox, let inline = box as? InlineBlockContainerRunBox else {
            return []
        }
        return inline.lineBoxs
    }

    private lazy var styleSheet: CSSStyleSheet = {
        let styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: Tag.p), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 16))),
                StyleProperty.display(.init(.value, .block))
//                StyleProperty.maxHeight(.init(.point, 250))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h1), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 24))),
                StyleProperty.fontSize(.init(.point, 24)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h2), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 20))),
                StyleProperty.fontSize(.init(.point, 20)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h3), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 18))),
                StyleProperty.fontSize(.init(.point, 18)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.at), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.backgroundColor(.init(.value, UIColor.blue)),
                StyleProperty.color(.init(.value, UIColor.white)),
                StyleProperty.padding(.init(.value, Edges(.point(10), .point(20), .point(20)))),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(1), height: .em(1)))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.a), [
                StyleProperty.display(.init(.value, .inline)),
                StyleProperty.lineHeight(.init(.value, 14)),
                StyleProperty.textDecoration(.init(.value, .none))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.quote), [
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.color(.init(.value, UIColor.gray)),
                StyleProperty.padding(.init(.value, Edges(.point(20), .point(5), .point(5), .point(17)))),
                StyleProperty.margin(.init(.value, Edges(.point(20), .point(0)))),
                StyleProperty.border(.init(.value, Border(nil, nil, nil, BorderEdge(style: .solid, width: .point(3), color: UIColor.blue))))
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
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.verticalAlign(.init(.value, .top)),
                StyleProperty.width(.init(.point, 4)),
                StyleProperty.height(.init(.point, 4)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .point(2), height: .point(2)))))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "green"), [
                StyleProperty.backgroundColor(.init(.value, UIColor.green))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "underline"), [
                StyleProperty.textDecoration(.init(.value, .init(line: .underline, style: .solid, thickness: 1)))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "lineThrough"), [
                StyleProperty.textDecoration(.init(.value, .init(line: .lineThrough, style: .solid, thickness: 1)))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.abbr), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.verticalAlign(.init(.value, .baseline)),
                StyleProperty.border(.init(.value, Border(nil, nil, BorderEdge(style: .dashed, width: .point(1), color: UIColor.red), nil))),
                StyleProperty.padding(LKRichStyleValue(.value, Edges(nil, nil, .point(2.5))))
            ])
        ])
        return styleSheet
    }()
}

fileprivate enum Tag: Int8, LKRichElementTag {
    case p
    case h1
    case h2
    case h3
    case a
    case at
    case emotion
    case span
    case quote
    case abbr

    public var typeID: Int8 {
        return rawValue
    }
}
