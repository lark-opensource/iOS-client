//
//  TextRunBoxSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by Ping on 2023/1/10.
//

// swiftlint:disable overridden_super_call
import UIKit
import Foundation
import XCTest

@testable import LKRichView

class TextRunBoxSpec: XCTestCase {
    // https://meego.feishu.cn/larksuite/issue/detail/8643692
    // lineBreakMode = .byWorld时，折行会有问题
    func test_TextWorldWrap_split() {
        let attrString = NSAttributedString(
            string: "场景出现的吧。 出现版本从 5.21~5.24 ， 这个是已知问题么",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17)
            ]
        )
        let frameSetter = TextFrameSetter(attrString)
        let typeSetter = TextTypeSetter(frameSetter)
        let lines = frameSetter.getLines(length: attrString.length)
        XCTAssertTrue(lines.count == 1, "")
        let runBox = TextRunBox(
            style: RenderStyleOM(.init()),
            typeSetter: typeSetter,
            lineRange: lines.first!.range,
            renderContextLocation: 0
        )
        runBox.layout(context: nil)
        let res = runBox.split(mainAxisWidth: 291.79998779296875, first: true, context: nil)
        if case .success(let lhs, let rhs) = res {
            XCTAssertTrue(lhs.size.width == 216.57521875000003)
        } else {
            XCTExpectFailure("保留现场，@liyong.520查看原因")
        }
    }

    // lineBreakMode = .byWorld时，单词会被异常折断
    func test_TextWorldWrap_split_word1() {
        let core = LKRichViewCore()
        let rootElement = LKInlineElement(tagName: PrivateTags.attachment)
        rootElement.addChild(LKTextElement(text: "Long app names such as: "))
        rootElement.addChild(LKTextElement(text: "Announcement"))
        core.load(renderer: core.createRenderer(rootElement))
        core.setRendererDebugOptions(ConfigOptions([.fixSplitForTextRunBox(true)]))
        let size = core.layout(CGSize(width: 170, height: 1000))
        // 此时应该分割为两个LineBox
        XCTAssertTrue(size ~= CGSize(width: 167.651_367_187_5, height: 34.414_062_5))
        if case .normal(let runBox) = core.getRenderer({ $0.runBox }), let inlineRunBox = runBox as? InlineBlockContainerRunBox {
            XCTAssertTrue(inlineRunBox.lineBoxs.count == 2)
            // 第二个LineBox内容只有一个Announcement
            XCTAssertTrue(inlineRunBox.lineBoxs[1].runBoxs.count == 1)
            XCTAssertTrue((inlineRunBox.lineBoxs[1].runBoxs[0] as? TextRunBox)?.lineRange == CFRange(location: 0, length: 12))
            XCTAssertTrue((inlineRunBox.lineBoxs[1].runBoxs[0] as? TextRunBox)?.textLine.attributedString?.string == "Announcement")
        } else {
           XCTExpectFailure("保留现场，@liyong.520查看原因")
       }
    }
    func test_TextWorldWrap_split_word2() {
        let core = LKRichViewCore()
        let rootElement = LKInlineElement(tagName: PrivateTags.attachment)
        rootElement.addChild(LKTextElement(text: "Long app names such as: "))
        rootElement.addChild(LKTextElement(text: "this"))
        core.load(renderer: core.createRenderer(rootElement))
        core.setRendererDebugOptions(ConfigOptions([.fixSplitForTextRunBox(true)]))
        let size = core.layout(CGSize(width: 180, height: 1000))
        // 此时应该分割为两个LineBox
        XCTAssertTrue(size ~= CGSize(width: 167.651_367_187_5, height: 34.414_062_5))
        if case .normal(let runBox) = core.getRenderer({ $0.runBox }), let inlineRunBox = runBox as? InlineBlockContainerRunBox {
            XCTAssertTrue(inlineRunBox.lineBoxs.count == 2)
            // 第二个LineBox内容只有一个Announcement
            XCTAssertTrue(inlineRunBox.lineBoxs[1].runBoxs.count == 1)
            XCTAssertTrue((inlineRunBox.lineBoxs[1].runBoxs[0] as? TextRunBox)?.lineRange == CFRange(location: 0, length: 4))
            XCTAssertTrue((inlineRunBox.lineBoxs[1].runBoxs[0] as? TextRunBox)?.textLine.attributedString?.string == "this")
        } else {
           XCTExpectFailure("保留现场，@liyong.520查看原因")
       }
    }
}
