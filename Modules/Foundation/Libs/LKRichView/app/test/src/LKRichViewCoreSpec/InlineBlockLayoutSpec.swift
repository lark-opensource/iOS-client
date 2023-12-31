//
//  InlineBlockLayoutSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2022/12/6.
//

import UIKit
import Foundation
import XCTest
@testable import LKRichView

final class InlineBlockLayoutSpec: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTextAlignLeftWithPadding() throws {
        let paddingTop: CGFloat = 1
        let paddingRight: CGFloat = 4

        let container = LKInlineBlockElement(tagName: TagName.p)
        container.style.padding(top: .point(paddingTop), right: .point(paddingRight)).fontSize(.init(.point(20)))
            .textAlign(.left)
        let text = LKTextElement(text: "1234")
        text.style.fontSize(.point(20))
        container.addChild(text)

        let textSize = CGSize(width: 44.3, height: 23.9)
        let containerSize = CGSize(width: textSize.width + 2 * paddingRight, height: textSize.height + 2 * paddingTop)

        assertConcreteSize(textSize, desc: "Text", element: text, styleSheets: [])

        let renderContainer = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [])
        assertEqual(renderContainer.children[0].boxRect, .init(origin: .init(x: 4, y: 1), size: textSize))
    }

    func testTextAlignCenterWithPadding() throws {
        let paddingTop: CGFloat = 1
        let paddingRight: CGFloat = 4

        let container = LKInlineBlockElement(tagName: TagName.p)
        container.style.padding(top: .point(paddingTop), right: .point(paddingRight))
            .fontSize(.init(.point(20)))
            .textAlign(.center)
        let text = LKTextElement(text: "1234")
        text.style.fontSize(.point(20))
        container.addChild(text)

        let textSize = CGSize(width: 44.3, height: 23.9)
        let containerSize = CGSize(width: textSize.width + 2 * paddingRight, height: textSize.height + 2 * paddingTop)

        assertConcreteSize(textSize, desc: "Text", element: text, styleSheets: [])

        let renderContainer = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [])
        assertEqual(renderContainer.children[0].boxRect, .init(origin: .init(x: 4, y: 1), size: textSize))
    }

    func testTextAlignRightWithPadding() throws {
        let paddingTop: CGFloat = 1
        let paddingRight: CGFloat = 4

        let container = LKInlineBlockElement(tagName: TagName.p)
        container.style.padding(top: .point(paddingTop), right: .point(paddingRight))
            .fontSize(.init(.point(20)))
            .textAlign(.right)
        let text = LKTextElement(text: "1234")
        text.style.fontSize(.point(20))
        container.addChild(text)

        let textSize = CGSize(width: 44.3, height: 23.9)
        let containerSize = CGSize(width: textSize.width + 2 * paddingRight, height: textSize.height + 2 * paddingTop)

        assertConcreteSize(textSize, desc: "Text", element: text, styleSheets: [])

        let renderContainer = assertConcreteSize(containerSize, desc: "Container", element: container, styleSheets: [])
        assertEqual(renderContainer.children[0].boxRect, .init(origin: .init(x: 4, y: 1), size: textSize))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
