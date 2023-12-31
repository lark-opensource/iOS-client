//
//  LineBoxTruncatedSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by 李勇 on 2023/2/28.
//

import UIKit
import XCTest
import Foundation
@testable import LKRichView

/// LineBox-truncatedIfNeeded新增单测
class LineBoxTruncatedSpec: XCTestCase {
    /// 不需要移除任何RunBox
    func testFunc1() {
        // 构造TextRunBox
        let frameSetter = TextFrameSetter(NSAttributedString(string: "test"))
        let typeSetter = TextTypeSetter(frameSetter)
        let lines = frameSetter.getLines(length: 4)
        let textRunBox = TextRunBox(style: RenderStyleOM(LKRenderRichStyle()), typeSetter: typeSetter, lineRange: lines.first!.range, renderContextLocation: 0)
        textRunBox.layout(context: nil)
        let oldMainAxisWidth = textRunBox.mainAxisWidth
        // 构造LineBox
        let lineBox = LineBox(style: RenderStyleOM(LKRenderRichStyle()))
        lineBox.append(runBox: textRunBox)
        // 测试裁减
        var remainedMainAxisWidth: CGFloat = 40
        lineBox.truncatedIfNeeded(context: LayoutContext(lineCamp: LineCamp(maxLine: 1, blockTextOverflow: "...")), remainedMainAxisWidth: &remainedMainAxisWidth)

        XCTAssertEqual(remainedMainAxisWidth, 40)
        XCTAssertEqual(oldMainAxisWidth, textRunBox.mainAxisWidth)
        XCTAssertEqual(lineBox.runBoxs.count, 2)
        XCTAssertTrue(lineBox.runBoxs[0] === textRunBox)
    }

    /// 需要移除最后一个AttachmentRunBox
    func testFunc2() {
        // 构造AttachmentRunBox
        let attachment = LKRichAttachmentImp(view: UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 20)))
        let attachmentRunBox = AttachmentRunBox(style: RenderStyleOM(LKRenderRichStyle()), attachment: attachment, avaliableMainAxisWidth: 100, avaliableCrossAxisWidth: 100, renderContextLocation: 0)
        attachmentRunBox.layout(context: nil)
        // 构造LineBox
        let lineBox = LineBox(style: RenderStyleOM(LKRenderRichStyle()))
        lineBox.append(runBox: attachmentRunBox)
        // 测试裁减
        var remainedMainAxisWidth: CGFloat = 10
        lineBox.truncatedIfNeeded(context: LayoutContext(lineCamp: LineCamp(maxLine: 1, blockTextOverflow: "...")), remainedMainAxisWidth: &remainedMainAxisWidth)

        XCTAssertEqual(remainedMainAxisWidth, 110)
        XCTAssertEqual(lineBox.runBoxs.count, 1)
    }

    /// 需要裁减最后一个TextRunBox
    func testFunc3() {
        // 构造TextRunBox
        let frameSetter = TextFrameSetter(NSAttributedString(string: "qwertyuiopasdfghjklzxcvbnm"))
        let typeSetter = TextTypeSetter(frameSetter)
        let lines = frameSetter.getLines(length: 4)
        let textRunBox = TextRunBox(style: RenderStyleOM(LKRenderRichStyle()), typeSetter: typeSetter, lineRange: lines.first!.range, renderContextLocation: 0)
        textRunBox.layout(context: nil)
        let oldMainAxisWidth = textRunBox.mainAxisWidth
        // 构造LineBox
        let lineBox = LineBox(style: RenderStyleOM(LKRenderRichStyle()))
        lineBox.append(runBox: textRunBox)
        // 测试裁减
        var remainedMainAxisWidth: CGFloat = 10
        lineBox.truncatedIfNeeded(context: LayoutContext(lineCamp: LineCamp(maxLine: 1, blockTextOverflow: "...")), remainedMainAxisWidth: &remainedMainAxisWidth)

        XCTAssertEqual(remainedMainAxisWidth, 13.996_093_75)
        XCTAssertEqual(oldMainAxisWidth, 26.009_765_625)
        XCTAssertEqual(textRunBox.mainAxisWidth, 22.013_671_875)
        XCTAssertEqual(lineBox.runBoxs.count, 2)
        XCTAssertTrue(lineBox.runBoxs[0] === textRunBox)
    }

    /// 需要裁减最后一个TextRunBox，斜体
    func testFunc4() {
        // 构造TextRunBox
        let frameSetter = TextFrameSetter(NSAttributedString(string: "qwertyuiopasdfghjklzxcvbnm"))
        let typeSetter = TextTypeSetter(frameSetter)
        let lines = frameSetter.getLines(length: 4)
        var style = LKRenderRichStyle(); style.fontStyle = .init(.value, .italic)
        let textRunBox = TextRunBox(style: RenderStyleOM(style), typeSetter: typeSetter, lineRange: lines.first!.range, renderContextLocation: 0)
        textRunBox.layout(context: nil)
        let oldMainAxisWidth = textRunBox.mainAxisWidth
        // 构造LineBox
        let lineBox = LineBox(style: RenderStyleOM(LKRenderRichStyle()))
        lineBox.append(runBox: textRunBox)
        // 测试裁减
        var remainedMainAxisWidth: CGFloat = 10
        lineBox.truncatedIfNeeded(context: LayoutContext(lineCamp: LineCamp(maxLine: 1, blockTextOverflow: "...")), remainedMainAxisWidth: &remainedMainAxisWidth)

        XCTAssertEqual(remainedMainAxisWidth, 13.996_093_75)
        XCTAssertEqual(oldMainAxisWidth, 29.761_054_337_024_69)
        XCTAssertEqual(textRunBox.mainAxisWidth, 25.764_960_587_024_69)
        XCTAssertEqual(lineBox.runBoxs.count, 2)
        XCTAssertTrue(lineBox.runBoxs[0] === textRunBox)
    }

    /// 需要裁减最后一个InlineBlockContainerRunBox，嵌套情况
    func testFunc5() {
        // 构造TextRunBox
        let frameSetter = TextFrameSetter(NSAttributedString(string: "qwertyuiopasdfghjklzxcvbnm"))
        let typeSetter = TextTypeSetter(frameSetter)
        let lines = frameSetter.getLines(length: 4)
        let textRunBox = TextRunBox(style: RenderStyleOM(LKRenderRichStyle()), typeSetter: typeSetter, lineRange: lines.first!.range, renderContextLocation: 0)
        textRunBox.layout(context: nil)
        let oldTextRunBoxMainAxisWidth = textRunBox.mainAxisWidth
        // 构造InlineBlockContainerRunBox
        let inlineBlockContainerRunBox = InlineBlockContainerRunBox(style: RenderStyleOM(LKRenderRichStyle()), avaliableMainAxisWidth: 100, avaliableCrossAxisWidth: 20, renderContextLocation: 0)
        inlineBlockContainerRunBox.children = [textRunBox]
        inlineBlockContainerRunBox.layout(context: nil)
        let oldInlineBlockRunBoxMainAxisWidth = inlineBlockContainerRunBox.mainAxisWidth
        // 构造LineBox
        let lineBox = LineBox(style: RenderStyleOM(LKRenderRichStyle()))
        lineBox.append(runBox: inlineBlockContainerRunBox)
        // 测试裁减
        var remainedMainAxisWidth: CGFloat = 10
        lineBox.truncatedIfNeeded(context: LayoutContext(lineCamp: LineCamp(maxLine: 1, blockTextOverflow: "...")), remainedMainAxisWidth: &remainedMainAxisWidth)

        XCTAssertEqual(remainedMainAxisWidth, 13.996_093_75)
        XCTAssertEqual(oldTextRunBoxMainAxisWidth, 26.009_765_625)
        XCTAssertEqual(oldInlineBlockRunBoxMainAxisWidth, 26.009_765_625)
        XCTAssertEqual(textRunBox.mainAxisWidth, 22.013_671_875)
        XCTAssertEqual(inlineBlockContainerRunBox.mainAxisWidth, 22.013_671_875)
        XCTAssertEqual(lineBox.runBoxs.count, 2)
        XCTAssertTrue(lineBox.runBoxs[0] === inlineBlockContainerRunBox)
        XCTAssertTrue(inlineBlockContainerRunBox.lineBoxs.count == 1)
        XCTAssertTrue(inlineBlockContainerRunBox.lineBoxs[0].runBoxs.count == 1)
        XCTAssertTrue(inlineBlockContainerRunBox.lineBoxs[0].runBoxs[0] === textRunBox)
    }

    /// 需要裁减最后一个BlockContainerRunBox，嵌套情况
    func testFunc6() {
        // BlockContainerRunBox的layout是读取的ownerRenderObject.childs，所以需要构造一个RenderBlock
        let renderAttachment = RenderAttachment(nodeType: .canvas,
                                                renderStyle: LKRenderRichStyle(),
                                                ownerElement: nil,
                                                attachment: LKRichAttachmentImp(view: UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 20))))
        _ = renderAttachment.layout(CGSize(width: 300, height: 20), context: nil)
        let renderBlock = RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
        renderBlock.appendChild(renderAttachment)
        // 构造BlockContainerRunBox
        let blockContainerRunBox = BlockContainerRunBox(style: RenderStyleOM(LKRenderRichStyle()), avaliableMainAxisWidth: 300, avaliableCrossAxisWidth: 20, renderContextLocation: 0)
        blockContainerRunBox.ownerRenderObject = renderBlock
        blockContainerRunBox.layout(context: nil)
        let oldBlockRunBoxMainAxisWidth = blockContainerRunBox.mainAxisWidth
        // 构造LineBox
        let lineBox = LineBox(style: RenderStyleOM(LKRenderRichStyle()))
        lineBox.append(runBox: blockContainerRunBox)
        // 测试裁减
        var remainedMainAxisWidth: CGFloat = 10
        lineBox.truncatedIfNeeded(context: LayoutContext(lineCamp: LineCamp(maxLine: 1, blockTextOverflow: "...")), remainedMainAxisWidth: &remainedMainAxisWidth)

        XCTAssertEqual(remainedMainAxisWidth, 110)
        XCTAssertEqual(oldBlockRunBoxMainAxisWidth, 100)
        XCTAssertEqual(blockContainerRunBox.mainAxisWidth, 100)
        XCTAssertEqual(lineBox.runBoxs.count, 1)
        XCTAssertTrue(lineBox.runBoxs[0] !== blockContainerRunBox)
    }
}
