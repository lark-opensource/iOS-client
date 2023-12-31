//
//  LKLabelTests.swift
//  LarkUIKitDemoTests
//
//  Created by qihongye on 2018/10/31.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import RichLabel

func == (_ lhs: CFRange?, _ rhs: CFRange) -> Bool {
    guard let lhs = lhs else {
        return false
    }
    return lhs.location == rhs.location && lhs.length == rhs.length
}

class LKLabelTests: XCTestCase {
    var label: LKLabel!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.label = LKLabel()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAttributedRangeAtPoint() {
        let labelFrame = CGRect(100, 100, 300, 100)
        label.frame = labelFrame
        label.attributedText = NSAttributedString(string: "\u{FFFC}\u{FFFC}1234567890ÅÒ")
        _ = label.sizeThatFits(label!.frame.size)

        label.render.bounds = label.bounds
        label.render.textSize = label.layout.textSize
        label.render.isOutOfRange = label.layout.isOutOfRange
        label.render.lines = label.layout.lines

        switch label.attributedIndex(at: CGPoint(x: 10, y: 50)) {
        case .inText(let idx):
            XCTAssertTrue(idx == 3, "attributedRangeAtPoint point: (10, 50) ok")
        default:
            XCTAssert(false)
        }

        switch label.attributedIndex(at: CGPoint(x: 20, y: 50)) {
        case .inText(let idx):
            XCTAssertTrue(idx == 5, "attributedRangeAtPoint point: (20, 50) ok")
        default:
            XCTAssert(false)
        }

        switch label.attributedIndex(at: CGPoint(x: 70, y: 50)) {
        case .inText(let idx):
            XCTAssertTrue(idx == 12, "attributedRangeAtPoint point: (70, 50) ok")
        default:
            XCTAssert(false)
        }

        switch label.attributedIndex(at: CGPoint(x: 90, y: 50)) {
        case .notInText:
            XCTAssertTrue(true, "attributedRangeAtPoint point: (90, 50) ok")
        default:
            XCTAssert(false)
        }
    }

    func testAttributedTappableRangeAtPoint() {
        let mutableAttrStr = NSMutableAttributedString(string: "1234567890ÅÒ")

        let labelFrame = CGRect(100, 100, 300, 100)
        label.frame = labelFrame
        label.attributedText = mutableAttrStr
        _ = label.sizeThatFits(label!.frame.size)

        label.render.bounds = label.bounds
        label.render.textSize = label.layout.textSize
        label.render.isOutOfRange = label.layout.isOutOfRange
        label.render.lines = label.layout.lines

        switch label.attributedIndex(at: CGPoint(x: 10, y: 50)) {
        case .inText(let idx):
            XCTAssertTrue(idx == 1, "attributedRangeAtPoint point: (10, 50) ok")
        default:
            XCTAssert(false)
        }

        switch label.attributedIndex(at: CGPoint(x: 20, y: 50)) {
        case .inText(let idx):
            XCTAssertTrue(idx == 3, "attributedRangeAtPoint point: (20, 50) ok")
        default:
            XCTAssert(false)
        }

        switch label.attributedIndex(at: CGPoint(x: 70, y: 50)) {
        case .inText(let idx):
            XCTAssertTrue(idx == 10, "attributedRangeAtPoint point: (70, 50) ok")
        default:
            XCTAssert(false)
        }
    }

    func testDetectLink() {
        let mutableAttrStr = NSMutableAttributedString(string: "12345 www.baidu.com 67890")
        let labelFrame = CGRect(100, 100, 80, 100)
        label.frame = labelFrame
        label.attributedText = mutableAttrStr
        _ = label.sizeThatFits(label!.frame.size)

        label.dataDetector = DataCheckDetector
        label.render.bounds = label.bounds
        label.render.textSize = label.layout.textSize
        label.render.isOutOfRange = label.layout.isOutOfRange
        label.render.lines = label.layout.lines

        label.detectLinks()

        let expectation =  self.expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error)

            switch self.label.attributedIndex(at: CGPoint(x: 10, y: 50)) {
            case .inText(let idx):
                XCTAssertTrue(idx == 7, "attributedRangeAtPoint point: (10, 50) ok")
            default:
                XCTAssert(false)
            }

            switch self.label.attributedIndex(at: CGPoint(x: 20, y: 50)) {
            case .inText(let idx):
                XCTAssertTrue(idx == 8, "attributedRangeAtPoint point: (20, 50) ok")
            default:
                XCTAssert(false)
            }

            switch self.label.attributedIndex(at: CGPoint(x: 70, y: 50)) {
            case .inText(let idx):
                XCTAssertTrue(idx == 17, "attributedRangeAtPoint point: (70, 50) ok")
            default:
                XCTAssert(false)
            }

            switch self.label.attributedIndex(at: CGPoint(x: 5, y: 40)) {
            case .inText(let idx):
                XCTAssertTrue(idx == 0, "attributedRangeAtPoint point: (5, 40) ok")
            default:
                XCTAssert(false)
            }
        }
    }

    func testRangeAtTapableText() {
        label.tapableRangeList = [NSRange(location: 0, length: 5)]

        XCTAssertTrue(label.indexAtTapableText(at: kCFNotFound) == -1, "kCFNotFound is ok")
        XCTAssertTrue(label.indexAtTapableText(at: -1) == -1, "-1 is ok")
        XCTAssertTrue(label.indexAtTapableText(at: 0) == 0, "0 is ok")
        XCTAssertTrue(label.indexAtTapableText(at: 4) == 0, "4 is ok")
        XCTAssertTrue(label.indexAtTapableText(at: 5) == -1, "3 is ok")
    }

    func testFirstLineAttachment() {
        // 当设置如下Paragraph属性的时候会导致CoreText计算的第一行的CTLine的ascent与实际自己包含的CTRun中的ascent不对等，下面单测测试并修复这种情况
        let paragraph = NSMutableParagraphStyle()
        paragraph.maximumLineHeight = 18
        paragraph.minimumLineHeight = 18

        let font = UIFont.systemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraph
        ]

        let mutableAttrStr = NSMutableAttributedString(string: "  \(LKLabelAttachmentPlaceHolderStr)\n\n\(LKLabelAttachmentPlaceHolderStr)\nHello ", attributes: attributes)
        let attachMent1 = LKAttachment(view: UIView(frame: CGRect(0, 0, 100, 100)))
        attachMent1.fontAscent = font.ascender
        attachMent1.fontDescent = font.descender
        attachMent1.margin = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)

        let attachMent2 = LKAttachment(view: UIView(frame: CGRect(0, 0, 100, 100)))
        attachMent2.fontAscent = font.ascender
        attachMent2.fontDescent = font.descender
        attachMent2.margin = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)

        mutableAttrStr.addAttributes([LKAttachmentAttributeName: attachMent1], range: NSRange(location: 2, length: 1))
        mutableAttrStr.addAttributes([LKAttachmentAttributeName: attachMent2], range: NSRange(location: 5, length: 1))

        label.attributedText = mutableAttrStr
        label.lineSpacing = 2
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.isUserInteractionEnabled = true
        let size = label.sizeThatFits(CGSize(width: 200, height: 300))
        XCTAssertTrue(size.height ~== 270, "LKLabelLayout is ok")
        XCTAssertTrue(label.layout.lines[0].ascent == label.layout.lines[0].runs[1].ascent, "LKTextLine.ascent is ok")
    }

    func testStringUnicodeScalarRanges1() {
        let str = "🌕🌖🌗🌘🌑🌒🌓🌔🌕"
        let ranges = StringUnicodeScalarRanges(string: str)
        let expect = [
            NSRange(location: 0, length: 2),
            NSRange(location: 2, length: 2),
            NSRange(location: 4, length: 2),
            NSRange(location: 6, length: 2),
            NSRange(location: 8, length: 2),
            NSRange(location: 10, length: 2),
            NSRange(location: 12, length: 2),
            NSRange(location: 14, length: 2),
            NSRange(location: 16, length: 2)
        ]
        XCTAssertTrue(ranges.count == expect.count)
        for i in 0..<ranges.count {
            XCTAssertEqual(ranges[i], expect[i])
        }
    }

    func testStringUnicodeScalarRanges2() {
        let str = "1🌕1⃣️2"
        let ranges = StringUnicodeScalarRanges(string: str)
        let expect = [
            NSRange(location: 0, length: 1),
            NSRange(location: 1, length: 2),
            NSRange(location: 3, length: 3),
            NSRange(location: 6, length: 1)
        ]
        XCTAssertTrue(ranges.count == expect.count)
        for i in 0..<ranges.count {
            XCTAssertEqual(ranges[i], expect[i])
        }
    }
}
