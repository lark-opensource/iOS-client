//
//  MaxMinLayoutSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2022/7/12.
//

import UIKit
import Foundation
import XCTest
@testable import LKRichView

// swiftlint:disable all

func layout(_ element: LKRichElement, config: ConfigOptions?, size: CGSize) -> LKRichViewCore {
    let core = LKRichViewCore()
    guard let renderer = core.createRenderer(element) else {
        return core
    }
    core.load(renderer: renderer)
    core.setRendererDebugOptions(config)
    _ = core.layout(size)
    return core
}

class MaxMinLayoutSpec: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMaxHeightForSingleLine() throws {
        let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(50)))
        let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(100)).width(.point(100)))
        let text = LKTextElement(text: "Im a single text.")
        element.children([img, text])

        let core = layout(element, config: nil, size: CGSize(width: 375, height: 10000))
        XCTAssertTrue(core.size ~= CGSize(width: 201, height: 50))
        XCTAssertTrue(core.isContentScroll)
        if let children = core.getRenderer({ $0.children }) {
            XCTAssertTrue(children[0].isRenderBlock)
            XCTAssertTrue(children[0].isRenderInline)
            XCTAssertFalse(children[1].isRenderBlock)
            XCTAssertTrue(children[1].isRenderInline)
            XCTAssertTrue(children[0].boxRect ~= CGRect(x: 0, y: -50, width: 100, height: 100))
            XCTAssertTrue(children[1].boxRect ~= CGRect(x: 100, y: -53, width: 101, height: 17))
        }
    }

    func testMinHeightForSingleLine() throws {
        let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().minHeight(.point(200)))
        let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(100)).width(.point(100)))
        let text = LKTextElement(text: "Im a single text.")
        element.children([img, text])

        let core = layout(element, config: nil, size: CGSize(width: 375, height: 10000))
        XCTAssertTrue(core.size ~= CGSize(width: 201, height: 200))
        XCTAssertFalse(core.isContentScroll)
        if let children = core.getRenderer({ $0.children }) {
            XCTAssertTrue(children[0].isRenderBlock)
            XCTAssertTrue(children[0].isRenderInline)
            XCTAssertFalse(children[1].isRenderBlock)
            XCTAssertTrue(children[1].isRenderInline)
            XCTAssertTrue(children[0].boxRect ~= CGRect(x: 0, y: 100, width: 100, height: 100))
            XCTAssertTrue(children[1].boxRect ~= CGRect(x: 100, y: 97, width: 101, height: 17))
        }
    }

    func testMaxHeightForMultiLine() throws {
        let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(150)))
        let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(100)).width(.point(100)))
        let text = LKTextElement(text: "Im a single text.")
        element.children([img, text, text, img, text])

        let core = layout(element, config: nil, size: CGSize(width: 375, height: 10_000))
        XCTAssertTrue(core.size ~= CGSize(width: 302, height: 103))
        XCTAssertTrue(core.isContentScroll)

        let expectRects = [
            CGRect(x: 0, y: 3.37, width: 100, height: 100),
            CGRect(x: 100, y: 0, width: 101, height: 16.7),
            CGRect(x: 201, y: 0, width: 101, height: 16.7),
            CGRect(x: 0, y: -101, width: 100, height: 100),
            CGRect(x: 100, y: -104, width: 101, height: 16.7)
        ]
        if let children = core.getRenderer({ $0.children }) {
            XCTAssertEqual(children.count, expectRects.count)
            for i in 0..<children.count {
                XCTAssertTrue(children[i].boxRect ~= expectRects[i])
            }
        }
    }

    func testMaxHeightForMultiLineWithMaxHeightBuffer() throws {
        let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(150)))
        let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(100)).width(.point(100)).backgroundColor(.red))
        let text = LKTextElement(text: "Im a single text.")
        element.children([img, text, text, img, text])

        let core = layout(element, config: ConfigOptions([.maxHeightBuffer(100)]), size: CGSize(width: 375, height: 10_000))
        XCTAssertTrue(core.size ~= CGSize(width: 302, height: 207))
        XCTAssertFalse(core.isContentScroll)
        let expectRects = [
            CGRect(x: 0, y: 108, width: 100, height: 100),
            CGRect(x: 100, y: 104, width: 101, height: 17),
            CGRect(x: 201, y: 104, width: 101, height: 17),
            CGRect(x: 0, y: 3, width: 100, height: 100),
            CGRect(x: 100, y: 0, width: 101, height: 17)
        ]
        if let children = core.getRenderer({ $0.children }) {
            XCTAssertEqual(children.count, expectRects.count)
            for i in 0..<children.count {
                XCTAssertTrue(children[i].boxRect ~= expectRects[i])
            }
        }
    }

    /// 下面的三个case来自于https://bytedance.feishu.cn/docx/AGUvd9zbao4QSsxZvg1cU34inAQ
    /// crossAxisWidth <= maxCrossAxisWidth < maxCrossAxisWidthWithBuffer
    func testMaxCrossAxisWidthWithBuffer1() {
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            element.children([img])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 100))
            // 所有内容都能排下
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertFalse(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(20)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 100))
            // 只能排第一行，所有内容没超出max+buffer，不需要调整
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertTrue(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(80)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 100))
            // 只能排第一行，所有内容没超出max+buffer，需要调整，但90<max，结果依然是90
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertTrue(core.isContentScroll)
        }
    }

    /// maxCrossAxisWidth < crossAxisWidth < maxCrossAxisWidthWithBuffer
    func testMaxCrossAxisWidthWithBuffer2() {
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            element.children([img])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 120))
            // 所有内容都能排下
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertFalse(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(110)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(20)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 120))
            // 只能排下第一行，所有内容不超过max+buffer，不需要调整
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 110))
            XCTAssertTrue(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(80)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 120))
            // 只能排下第一行，所有内容超过max+buffer，但90<max，结果依然是90
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertTrue(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(110)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(80)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 120))
            // 只能排下第一行，所有内容超过max+buffer，需要调整
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 100))
            XCTAssertTrue(core.isContentScroll)
        }
    }

    /// maxCrossAxisWidth < maxCrossAxisWidthWithBuffer <= crossAxisWidth
    func testMaxCrossAxisWidthWithBuffer3() {
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            element.children([img])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 1000))
            // 所有内容都能排下
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertFalse(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(90)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(80)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 1000))
            // 只能排下第一行，所有内容超过max+buffer，但90<max，结果依然是90
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 90))
            XCTAssertTrue(core.isContentScroll)
        }
        do {
            let element = LKBlockElement(tagName: TagName.p, style: LKRichStyle().maxHeight(.point(100)))
            let img = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(110)).width(.point(100)))
            let text = LKInlineBlockElement(tagName: TagName.p, style: LKRichStyle().height(.point(80)).width(.point(100)))
            element.children([img, text])
            let core = layout(element, config: ConfigOptions([.maxHeightBuffer(50)]), size: CGSize(width: 100, height: 1000))
            // 只能排下第一行，所有内容超过max+buffer，需要调整
            XCTAssertTrue(core.size ~= CGSize(width: 100, height: 100))
            XCTAssertTrue(core.isContentScroll)
        }
    }
}
