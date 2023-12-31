//
//  RenderListSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2022/11/26.
//

import UIKit
import Foundation
import XCTest

@testable import LKRichView

final class RenderListSpec: XCTestCase {

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

    func testLayoutWithInlineBlock() throws {
        let text = LKTextElement(text: "测试文案测试文案测试文案测试文案测试文案测试文案").style(LKRichStyle().fontSize(.point(17)))
        let textSize = CGSize(width: 415.8, height: 20.3)
        assertConcreteSize(textSize, element: text, desc: "Text")

        let at = LKInlineBlockElement(tagName: TagName.at)
            .addChild(LKTextElement(text: "限制宽高的at2"))
            .style(LKRichStyle().height(.point(150)).width(.point(100)))
        let atSize = CGSize(width: 100, height: 150)
        assertConcreteSize(atSize, element: at, desc: "At")

        let ol1 = LKOrderedListElement(tagName: TagName.p, start: 3, olType: .lowercaseRoman).children([
            LKListItemElement(tagName: TagName.p).children([text]),
            LKListItemElement(tagName: TagName.p).children([text])
        ])
        let ol1Size = CGSize(width: 446.8, height: 2 * textSize.height)
        assertConcreteSize(ol1Size, element: ol1, desc: "OL1")

        let ol = LKOrderedListElement(tagName: TagName.p, start: 99, olType: .number).children([
            LKListItemElement(tagName: TagName.p).children([text]),
            ol1,
            LKListItemElement(tagName: TagName.p).children([text])
        ])
        let olSize = CGSize(width: 470.8, height: 4 * textSize.height)
        assertConcreteSize(olSize, element: ol, desc: "OL")

        let ul1 = LKUnOrderedListElement(tagName: TagName.p, ulType: .disc).children([LKListItemElement(tagName: TagName.p).children([text])])
        let ul1Size = CGSize(width: 438.4, height: textSize.height)
        assertConcreteSize(ul1Size, element: ul1, desc: "UL1")

        let ul = LKUnOrderedListElement(tagName: TagName.p, ulType: .circle).children([ul1])
        let ulSize = CGSize(width: 462.4, height: textSize.height)
        assertConcreteSize(ulSize, element: ul, desc: "UL")

        let container = LKBlockElement(tagName: TagName.p)
        container.children([
            at, ul, ol
        ])
        let containerSize = CGSize(
            width: max(atSize.width, olSize.width, ulSize.width),
            height: atSize.height + olSize.height + ulSize.height
        )
        let containerRenderObj = assertConcreteSize(containerSize, element: container, desc: "Container")

        assertEqual(containerRenderObj.boxRect, CGRect(origin: .zero, size: containerSize))
        // at
        assertEqual(containerRenderObj.children[0].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height), size: atSize))
        // ul
        assertEqual(containerRenderObj.children[1].boxRect, CGRect(origin: .init(x: 0, y: containerSize.height - atSize.height - ulSize.height), size: ulSize))
        // ol
        assertEqual(containerRenderObj.children[2].boxRect, CGRect(origin: .init(x: 0, y: 0), size: olSize))
        //
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    private func assertEqual(_ concrete: CGRect, _ expect: CGRect) {
        XCTAssertTrue(concrete ~= expect, "concrete{\(concrete)} is not equal to expect{\(expect)}")
    }

    @discardableResult
    private func assertConcreteSize(_ size: CGSize, element: LKRichElement, desc: String) -> RenderObject {
        let ro = element.createRenderer()
        let core = LKRichViewCore(ro, styleSheets: [styleSheet])
        let concreteResult = core.layout(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        XCTAssertNotNil(concreteResult)
        XCTAssertTrue(concreteResult! ~= size, "\(desc)(\(element.name)): \(concreteResult!) is not equal to \(size)")
        return ro
    }
}
