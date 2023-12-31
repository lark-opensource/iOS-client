//
//  RenderTextSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2019/9/4.
//

// swiftlint:disable
import UIKit
import Foundation
import XCTest

@testable import LKRichView

// swiftlint:disable all

class Attachment: LKRichAttachment {
    var verticalAlign: VerticalAlign = .middle

    var padding: Edges?

    let size: CGSize

    init(size: CGSize) {
        self.size = size
    }

    func getAscent(_ mode: WritingMode) -> CGFloat {
        switch mode {
        case .horizontalTB:
            return 0
        case .verticalLR, .verticalRL:
            return 0
        }
    }

    func createView() -> UIView {
        let imgView = UIImageView(frame: CGRect(origin: .zero, size: size))
        imgView.image = UIImage(named: "AppIcon")
        imgView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(onTap)))
        return imgView
    }

    @objc
    private func onTap(_ target: Any) {
        print(target)
    }
}

func ~= (_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
    return abs(lhs - rhs) <= 2
}

func ~= (_ lhs: Double, _ rhs: Double) -> Bool {
    return abs(lhs - rhs) <= 2
}

func ~= (_ lhs: CGSize, _ rhs: CGSize) -> Bool {
    return lhs.width ~= rhs.width && lhs.height ~= rhs.height
}

func ~= (_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
    return lhs.x ~= rhs.x && lhs.y ~= rhs.y
}

func ~= (_ lhs: CGRect, _ rhs: CGRect) -> Bool {
    return lhs.origin ~= rhs.origin && lhs.size ~= rhs.size
}

class RenderTextSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateMatrixWithFontStyle() {
        XCTAssertEqual(RenderText.createMatrixWith(fontStyle: .normal), nil)
        XCTAssertEqual(RenderText.createMatrixWith(fontStyle: .italic), CGAffineTransform(a: 1, b: 0, c: CGFloat(tanf(Float.pi / 180 * 15)), d: 1, tx: 0, ty: 0))
    }

    func testCreateCTFont() {
        let fontSize: CGFloat = 15
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        let ctfont = RenderText.createCTFontWith(font: font, size: fontSize, style: .normal, weight: .bold)
        XCTAssertEqual(CTFontGetSize(ctfont), fontSize)
        XCTAssertEqual(CTFontGetMatrix(ctfont), CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0))
        XCTAssertEqual(CTFontCopyFamilyName(ctfont), font.familyName as CFString)
    }

    func testCreateCTFontEqualToSystemNormalFont() {
        let fontSize: CGFloat = 20
        let font = UIFont.systemFont(ofSize: fontSize)
        let ctfont = RenderText.createCTFontWith(font: font, size: fontSize, style: .normal, weight: .normal)
        let font1 = CTFontCreateWithFontDescriptor(CTFontCopyFontDescriptor(font), fontSize, nil)
        let font2 = UIFont.boldSystemFont(ofSize: fontSize)
        XCTAssertEqual(font1.hashValue, font.hashValue)
        if UIAccessibility.isBoldTextEnabled {
            XCTAssertEqual(ctfont.hashValue, font2.hashValue)
        } else {
            XCTAssertEqual(ctfont.hashValue, font.hashValue)
        }
    }

    func testCreateCTFontWithFontWeight() {
        let fontSize: CGFloat = 30
        let boldSystem = UIFont.boldSystemFont(ofSize: fontSize)
        let system = UIFont.systemFont(ofSize: fontSize)
        let boldSystemWithWeight = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let ctfont = RenderText.createCTFontWith(font: system, size: fontSize, style: .normal, weight: .semibold)
        let boldTextBoldSystem = UIFont.systemFont(ofSize: fontSize, weight: .black)

        XCTAssertEqual(boldSystem.fontName, boldSystemWithWeight.fontName)
        XCTAssertNotEqual(boldSystem.fontName, system.fontName)
        XCTAssertEqual(boldSystem.familyName as CFString, CTFontCopyName(ctfont, kCTFontFamilyNameKey))
        if UIAccessibility.isBoldTextEnabled {
            XCTAssertEqual(boldTextBoldSystem.fontName as CFString, CTFontCopyName(ctfont, kCTFontPostScriptNameKey))
        } else {
            XCTAssertEqual(boldSystem.fontName as CFString, CTFontCopyName(ctfont, kCTFontPostScriptNameKey))
        }
    }

    func test_Framesetter_getLineShouldClusterFalse() {
        if true {
            let attrStr = NSAttributedString(string: "CR有一个重要的功能是它可以教会开发者一些语言、框架、通用软件设计原则相关的新东西。留下帮助开发者学习新东西的评论总是好的。分享知识是持续的提高系统代码质量的一部分。请记住，如果你的评论只是单纯教育性质的，不是那些能在这篇文章中找到的规范，那么请在前面加一个“Nit:”或者注明作者不需要解决它。", attributes: [.font: UIFont.systemFont(ofSize: 12)])

            let frameSetter = TextFrameSetter(attrStr)
            let setter = TextTypeSetter(frameSetter)
            let line = setter.getLine(range: setter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude, shouldCluster: false))
            if #available(iOS 13.0, *) {
                XCTAssert(CGSize(width: 1764.0, height: 14.68) ~= line.size)
            } else {
                XCTAssert(CGSize(width: 1649.0, height: 15.465) ~= line.size)
            }
        }

        if true {
            let attrStr = NSAttributedString(string: """
Code review can have an important function of teaching developers something new about a language, a framework, or general software design principles. It's always fine to leave comments that help a developer learn something new. Sharing knowledge is part of improving the code health of a system over time. Just keep in mind that if your comment is purely educational, but not critical to meeting the standards described in this document, prefix it with "Nit: " or otherwise indicate that it's not mandatory for the author to resolve it in this CL.
""", attributes: [.font: UIFont(name: "PingFangSC-Regular", size: 20)!])
            let frameSetter = TextFrameSetter(attrStr)
            let setter = TextTypeSetter(frameSetter)
            let line = setter.getLine(range: setter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude, shouldCluster: false))
            XCTAssert(CGSize(width: 5094, height: 28) ~= line.size)
        }

        if true {
            let attrStr = NSAttributedString(string: 藏文, attributes: [.font: UIFont.systemFont(ofSize: 20)])
            let frameSetter = TextFrameSetter(attrStr)
            let setter = TextTypeSetter(frameSetter)
            let line = setter.getLine(range: setter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude, shouldCluster: false))
            if #available(iOS 14.0, *) {
                // pipeline测试无法通过，环境的原因，不是代码的问题
                // XCTAssert(line.size ~= CGSize(width: 1643.0, height: 29))
            } else if #available(iOS 13.0, *) {
                XCTAssert(line.size ~= CGSize(width: 1622.0, height: 29))
            } else {
                XCTAssert(line.size ~= CGSize(width: 1622.0, height: 30))
            }
        }
    }

    func test_Framesetter_getLineShouldClusterTrue() {
        if true {
            let attrStr = NSAttributedString(string: "CR有一个重要的功能是它可以教会开发者一些语言、框架、通用软件设计原则相关的新东西。留下帮助开发者学习新东西的评论总是好的。分享知识是持续的提高系统代码质量的一部分。请记住，如果你的评论只是单纯教育性质的，不是那些能在这篇文章中找到的规范，那么请在前面加一个“Nit:”或者注明作者不需要解决它。", attributes: [.font: UIFont.systemFont(ofSize: 12)])

            let frameSetter = TextFrameSetter(attrStr)
            let setter = TextTypeSetter(frameSetter)
            let line = setter.getLine(range: setter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude, shouldCluster: true))
            if #available(iOS 13.0, *) {
                XCTAssert(CGSize(width: 1764.0, height: 14.68) ~= line.size)
            } else {
                XCTAssert(CGSize(width: 1649.0, height: 15.465) ~= line.size)
            }
        }

        if true {
            let attrStr = NSAttributedString(string: """
Code review can have an important function of teaching developers something new about a language, a framework, or general software design principles. It's always fine to leave comments that help a developer learn something new. Sharing knowledge is part of improving the code health of a system over time. Just keep in mind that if your comment is purely educational, but not critical to meeting the standards described in this document, prefix it with "Nit: " or otherwise indicate that it's not mandatory for the author to resolve it in this CL.
""", attributes: [.font: UIFont(name: "PingFangSC-Regular", size: 20)!])
            let frameSetter = TextFrameSetter(attrStr)
            let setter = TextTypeSetter(frameSetter)
            let line = setter.getLine(range: setter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude, shouldCluster: true))
            XCTAssert(CGSize(width: 5094, height: 28) ~= line.size)
        }

        if true {
            let attrStr = NSAttributedString(string: 藏文, attributes: [.font: UIFont.systemFont(ofSize: 20)])
            let frameSetter = TextFrameSetter(attrStr)
            let setter = TextTypeSetter(frameSetter)
            let line = setter.getLine(range: setter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude, shouldCluster: true))
            if #available(iOS 14.0, *) {
                // pipeline测试无法通过，环境的原因，不是代码的问题
                // XCTAssert(line.size ~= CGSize(width: 1643.0, height: 29))
            } else if #available(iOS 13.0, *) {
                XCTAssert(line.size ~= CGSize(width: 1622.0, height: 29))
            } else {
                XCTAssert(line.size ~= CGSize(width: 1622.0, height: 30))
            }
        }
    }

    func test_TextFrame_Normal中文() {
//        let attrStr = NSAttributedString(string: "CR有一个重要的功能是它可以教会开发者一些语言、框架、通用软件设计原则相关的新东西。留下帮助开发者学习新东西的评论总是好的。分享知识是持续的提高系统代码质量的一部分。请记住，如果你的评论只是单纯教育性质的，不是那些能在这篇文章中找到的规范，那么请在前面加一个“Nit:”或者注明作者不需要解决它。")
//        let setter = TextFrameSetter(attrStr)
//        let frame = TextFrame(setter, path: CGPath(rect: CGRect(origin: .zero, size: CGSize(width: 500, height: 10000)), transform: nil), attributes: nil)
//        let lines = frame.getLines(0)
//        XCTAssertEqual(lines.count, 4)
//        if true {
//            let line = lines[0]
//            XCTAssertEqual(line.ascent, 12.72)
//            XCTAssertEqual(line.descent, 4.08)
//            XCTAssertEqual(line.leading, 6.0)
//            XCTAssertEqual(line.range, CFRange(location: 0, length: 42))
//            XCTAssertEqual(line.rect, CGRect(origin: .zero, size: CGSize(width: 498, height: 22.8)))
//        }
//        if true {
//            let line = lines[1]
//            XCTAssertEqual(line.ascent, 12.72)
//            XCTAssertEqual(line.descent, 4.08)
//            XCTAssertEqual(line.leading, 6)
//            XCTAssertEqual(line.range, CFRange(location: 42, length: 41))
//            XCTAssertEqual(line.rect, CGRect(origin: .zero, size: CGSize(width: 492, height: 22.8)))
//        }
//        if true {
//            let line = lines[2]
//            XCTAssertEqual(line.ascent, 12.72)
//            XCTAssertEqual(line.descent, 4.08)
//            XCTAssertEqual(line.leading, 6)
//            XCTAssertEqual(line.range, CFRange(location: 83, length: 41))
//            XCTAssertEqual(line.rect, CGRect(origin: .zero, size: CGSize(width: 492, height: 22.8)))
//        }
//        if true {
//            let line = lines[3]
//            XCTAssertEqual(line.ascent, 10.56)
//            XCTAssert(line.descent ~= 2.8)
//            XCTAssertEqual(line.leading, 6)
//            XCTAssertEqual(line.range, CFRange(location: 124, length: 24))
//            XCTAssert(line.rect ~= CGRect(origin: .zero, size: CGSize(width: 242, height: 19.37)))
//            XCTAssertEqual(line.range.location + line.range.length, attrStr.length)
//        }
    }

    // https://lark-oncall.bytedance.net/mobile/tickets/ticket_16526892441940443?from=plus-btn
    func test_InlineBlockSplit() {
        let documentElement = LKBlockElement(tagName: SelectionSpec.Tag.p)
        let icon = LKAttachmentElement(attachment: Attachment(size: CGSize(width: 16, height: 16)))
        let text = LKTextElement(text: "「CB-HR Focus」2022年3-4双月进展同步\n（会议材料）")
        text.style.fontSize(.point(17))
        let container = LKInlineElement(tagName: SelectionSpec.Tag.a).children([icon, text])
        documentElement.children([container])
        let core = LKRichViewCore()
        let renderer = core.createRenderer(documentElement)
        core.load(renderer: renderer)
        let size = core.layout(CGSize(width: 380, height: 10_000)) ?? .zero

        XCTAssert(size.height ~= 45) // CGSize(width: 349, height: 45)
    }

    func testPerformance_SuggestSize() {
        // This is an example of a performance test case.
        let attrStr = NSAttributedString(string: 藏文, attributes: [.font: UIFont.systemFont(ofSize: 20)])
        let frameSetter = TextFrameSetter(attrStr)
        let typeSetter = TextTypeSetter(frameSetter)
        self.measure {
            // Put the code you want to measure the time of here.
            _ = CTTypesetterSuggestLineBreak(
                typeSetter.ctTypeSetter,
                0,
                Double.greatestFiniteMagnitude
            )
        }
    }

    func testPerformance_FrameGetLine() {
        // This is an example of a performance test case.
        let attrStr = NSAttributedString(string: "fsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklfjklsdafajklfsdklafjsdlkfklasdjklfjasdklasdklasdklas", attributes: [.font: UIFont.systemFont(ofSize: 17)])
        let frameSetter = TextFrameSetter(attrStr)
        let typeSetter = TextTypeSetter(frameSetter)
        self.measure {
            // Put the code you want to measure the time of here.
            let width = 274
            var startIndex = 0
            let length = attrStr.length
            var lineCount = 0
            while startIndex < length {
                lineCount += 1
                print("startIndex: \(startIndex)")
                let range = typeSetter.getLineRange(startIndex: startIndex, width: Double(width), shouldCluster: false)
                if range.location < startIndex { break }
                startIndex += range.length
                _ = typeSetter.getLine(range: range)
            }
            print("length: \(length) lineCount: \(lineCount)")
//            var abc = 546
//            var start = 0
//            while abc > 0 {
//                abc -= 1
//                start += 38
//                print("startIndex: \(start)")
//                let range = typeSetter.getLineRange(startIndex: start, width: Double.greatestFiniteMagnitude)
//                _ = typeSetter.getLine(range: range)
//            }
//            _ = typeSetter.getLine(range: typeSetter.getLineRange(startIndex: 0, width: Double.greatestFiniteMagnitude))
        }

    }
}
