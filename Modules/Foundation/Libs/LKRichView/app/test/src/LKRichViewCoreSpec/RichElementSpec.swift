//
//  RichElementSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2021/11/10.
//

import Foundation
import XCTest

@testable import LKRichView

class RichElementSpec: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInlineBlock() throws {
        if true {
            let element = LKInlineBlockElement(tagName: TagName.p)
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().display(.block))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, false)
        }
        if true {
            let element = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().display(.inline))
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
    }

    func testInline() throws {
        if true {
            let element = LKInlineElement(tagName: TagName.p)
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKInlineElement(tagName: TagName.p, style: LKRichStyle().display(.block))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, false)
        }
        if true {
            let element = LKInlineElement(tagName: TagName.p, style: LKRichStyle().display(.inline))
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
    }

    func testBlock() throws {
        if true {
            let element = LKBlockElement(tagName: TagName.p)
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, false)
        }
        if true {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().display(.block))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, false)
        }
        if true {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().display(.inline))
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
    }

    func testImg() throws {
        if true {
            let element = LKImgElement()
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKImgElement(style: LKRichStyle().display(.block))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKImgElement(style: LKRichStyle().display(.inline))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKImgElement(style: LKRichStyle().display(.inlineBlock))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
    }

    func testText() throws {
        if true {
            let element = LKTextElement(text: "")
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKTextElement(style: LKRichStyle().display(.inline), text: "")
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKTextElement(style: LKRichStyle().display(.block), text: "")
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKTextElement(style: LKRichStyle().display(.inlineBlock), text: "")
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
    }

    func testAttachment() {
        if true {
            let element = LKAttachmentElement()
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKAttachmentElement(style: LKRichStyle().display(.inline))
            XCTAssertEqual(element.isBlock, false)
            XCTAssertEqual(element.isInline, true)
        }
        if true {
            let element = LKAttachmentElement(style: LKRichStyle().display(.block))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, false)
        }
        if true {
            let element = LKAttachmentElement(style: LKRichStyle().display(.inlineBlock))
            XCTAssertEqual(element.isBlock, true)
            XCTAssertEqual(element.isInline, true)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
