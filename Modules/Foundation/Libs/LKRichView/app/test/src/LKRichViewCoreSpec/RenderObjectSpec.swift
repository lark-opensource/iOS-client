//
//  RenderObjectSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2022/11/27.
//

import Foundation
import XCTest

@testable import LKRichView

final class RenderObjectSpec: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsChildrenRenderBlock() throws {
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertTrue(renderObject.isChildrenInline)
        }
        // When first subElement is display none.
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p).style(LKRichStyle().display(Display.none)),
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p).style(LKRichStyle().display(Display.none)),
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertFalse(renderObject.isChildrenInline)
        }
    }

    func testIsChildrenRenderInline() throws {
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p),
                LKInlineBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenBlock)
            XCTAssertTrue(renderObject.isChildrenInline)
        }
        // When first subElement is display none.
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKBlockElement(tagName: TagName.p).style(LKRichStyle().display(Display.none)),
                LKInlineElement(tagName: TagName.p),
                LKBlockElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
        if true {
            let container = LKBlockElement(tagName: TagName.p)
            container.children([
                LKInlineElement(tagName: TagName.p).style(LKRichStyle().display(Display.none)),
                LKInlineElement(tagName: TagName.p),
                LKInlineElement(tagName: TagName.p)
            ])
            let renderObject = container.createRenderer()
            XCTAssertTrue(renderObject.isChildrenInline)
            XCTAssertFalse(renderObject.isChildrenBlock)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
