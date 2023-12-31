//
//  LineCampSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2022/11/23.
//

import UIKit
import Foundation
import XCTest

@testable import LKRichView

final class LineCampSpec: XCTestCase {

    lazy var styleSheet: CSSStyleSheet = {
        let styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: TagName.p), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 16))),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: TagName.at), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.backgroundColor(.init(.value, UIColor.blue)),
                StyleProperty.color(.init(.value, UIColor.white)),
                StyleProperty.padding(.init(.value, Edges(.point(10), .point(20), .point(20)))),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(1), height: .em(1)))))
            ])
        ])
        return styleSheet
    }()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCalcRunBoxMaxLine() throws {
        if true {
            var rstyle = LKRenderRichStyle()
            rstyle.lineCamp = .init(.value, LineCamp(maxLine: 2))
            let style = RenderStyleOM(rstyle)
            XCTAssertEqual(calcMaxLine(style: style, context: nil), 2)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 3))), 2)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 1))), 2)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 0))), 2)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: -1))), 2)
        }
        if true {
            var rstyle = LKRenderRichStyle()
            rstyle.lineCamp = .init(.value, LineCamp(maxLine: 0))
            let style = RenderStyleOM(rstyle)
            XCTAssertEqual(calcMaxLine(style: style, context: nil), -1)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 3))), 3)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 1))), 1)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 0))), 0)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: -1))), -1)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: -2))), -1)
        }
        if true {
            var rstyle = LKRenderRichStyle()
            rstyle.lineCamp = .init(.value, LineCamp(maxLine: -2))
            let style = RenderStyleOM(rstyle)
            XCTAssertEqual(calcMaxLine(style: style, context: nil), -1)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 3))), 3)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 1))), 1)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: 0))), 0)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: -1))), -1)
            XCTAssertEqual(calcMaxLine(style: style, context: LayoutContext(lineCamp: LineCamp(maxLine: -2))), -1)
        }
    }

    func testLayoutLineCampWithList() {
        let text = LKTextElement(text: "测试文案测试文案测试文案测试文案测试文案测试文案").style(LKRichStyle().fontSize(.point(17)))
        let textSize = CGSize(width: 415.8, height: 20.3)
        assertConcreteSize(textSize, desc: "Text", element: text, styleSheets: [styleSheet])

        let at = LKInlineBlockElement(tagName: TagName.at)
            .addChild(LKTextElement(text: "限制宽高的at2"))
            .style(LKRichStyle().height(.point(150)).width(.point(100)))
        let atSize = CGSize(width: 100, height: 150)
        assertConcreteSize(atSize, desc: "At", element: at, styleSheets: [styleSheet])

        let ol1 = LKOrderedListElement(tagName: TagName.p, start: 3, olType: .lowercaseRoman).children([
            LKListItemElement(tagName: TagName.p).children([text]),
            LKListItemElement(tagName: TagName.p).children([text])
        ])
        let ol1Size = CGSize(width: 446.8, height: 2 * textSize.height)
        assertConcreteSize(ol1Size, desc: "OL1", element: ol1, styleSheets: [styleSheet])

        let ol = LKOrderedListElement(tagName: TagName.p, start: 99, olType: .number).children([
            LKListItemElement(tagName: TagName.p).children([text]),
            ol1,
            LKListItemElement(tagName: TagName.p).children([text])
        ])
        let olSize = CGSize(width: 470.8, height: 4 * textSize.height)
        assertConcreteSize(olSize, desc: "OL", element: ol, styleSheets: [styleSheet])

        let ul1 = LKUnOrderedListElement(tagName: TagName.p, ulType: .disc).children([LKListItemElement(tagName: TagName.p).children([text])])
        let ul1Size = CGSize(width: 438.4, height: textSize.height)
        assertConcreteSize(ul1Size, desc: "UL1", element: ul1, styleSheets: [styleSheet])

        let ul = LKUnOrderedListElement(tagName: TagName.p, ulType: .circle).children([ul1])
        let ulSize = CGSize(width: 462.4, height: textSize.height)
        assertConcreteSize(ulSize, desc: "UL", element: ul, styleSheets: [styleSheet])

        // maxline 7
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 7))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: max(atSize.width, olSize.width, ulSize.width),
                height: atSize.height + olSize.height + ulSize.height
            )
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: olSize))
        }
        // maxline 6
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 6))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: max(atSize.width, olSize.width, ulSize.width),
                height: atSize.height + olSize.height + ulSize.height
            )
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: olSize))
        }
        // maxline 5
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 5))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: max(atSize.width, olSize.width, ulSize.width),
                height: atSize.height + olSize.height + ulSize.height - textSize.height
            )
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: .init(width: olSize.width, height: olSize.height - textSize.height)))
        }
        // maxline 3
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 3))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: max(atSize.width, ulSize.width),
                height: atSize.height + ulSize.height + textSize.height
            )
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container maxline3", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: .init(width: 454.4, height: textSize.height)))
        }
        // maxline 2
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 2))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: max(atSize.width, ulSize.width),
                height: atSize.height + ulSize.height)
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            XCTAssertEqual(containerRenderObj.children.count, 3)
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: .zero))
        }
        // maxline 1
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 1))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: atSize.width,
                height: atSize.height
            )
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            XCTAssertEqual(containerRenderObj.children.count, 3)
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .zero, size: .zero))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .zero, size: .zero))
        }
        // maxline 0
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.style.lineCamp(LineCamp(maxLine: 0))
            container.children([
                at, ul, ol
            ])
            let containerSize = CGSize(
                width: max(atSize.width, olSize.width, ulSize.width),
                height: atSize.height + olSize.height + ulSize.height
            )
            let containerRenderObj = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [styleSheet])

            assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
            // at
            assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
            // ul
            assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
            // ol
            assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: olSize))
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
