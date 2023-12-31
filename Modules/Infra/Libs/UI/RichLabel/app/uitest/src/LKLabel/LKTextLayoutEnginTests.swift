//
//  LKTextLayoutEnginTests.swift
//  LarkUIKitDemoTests
//
//  Created by qihongye on 2018/4/26.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import RichLabel

infix operator ~==

func ~== (_ lhs: CGSize, _ rhs: CGSize) -> Bool {
    return abs(lhs.width - rhs.width) < 2
        && abs(lhs.height - rhs.height) < 2
}

func ~== (_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
    return abs(lhs - rhs) < 2
}

func ~== (_ lhs: [CGFloat], _ rhs: [CGFloat]) -> Bool {
    if lhs.count != rhs.count {
        return false
    }
    let count = lhs.count
    for i in 0..<count where !(lhs[i] ~== rhs[i]) {
        return false
    }
    return true
}

class LKTextLayoutEnginTests: XCTestCase {

    var layoutEngine: LKTextLayoutEngine?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        layoutEngine = LKTextLayoutEngineImpl()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        layoutEngine = nil
    }

    func genAttrString(string: String, textAlign: NSTextAlignment = .natural) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]
        let fontSize: CGFloat = 16

        let fontKey = NSAttributedString.Key.font
        attributes[fontKey] = UIFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlign
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = fontSize + 2

        let paragraphStyleKey = NSAttributedString.Key.paragraphStyle
        attributes[paragraphStyleKey] = paragraphStyle

        return NSAttributedString(string: string, attributes: attributes)
    }

    func testNormalEnglish() {
        let size = CGSize(width: 297, height: -1)
        let text = "Singletons and dependency injection\n"
            + "Just like the Singleton pattern, object declarations aren’t always ideal for use in large "
            + "software systems. They’re great for small pieces of code that have few or no dependencies, "
            + "but not for large components that interact with many other parts of the system. "
            + "The main reason is that you don’t have any control over the instantiation of "
            + "objects, and you can’t specify parameters for the constructors. "
            + "This means you can’t replace the implementations of the object itself, or other "
            + "classes the object depends on, in unit tests or in different configurations of the software"
            + "system. If you need that ability, you should use regular Kotlin classes together "
            + "with a dependency injection framework (such as Guice, https://github.com/google/"
            + "guice), just as in Java."
        self.layoutEngine!.attributedText = self.genAttrString(string: text)

        XCTAssert(self.layoutEngine!.ctframeSetter != nil, "已经生成ctframeSetter")
        XCTAssert(self.layoutEngine!.ctframe == nil, "还未生成ctframe")
        XCTAssert(self.layoutEngine!.numberOfLines == 0, "默认numberOfLines为0")

        self.measure {
            XCTAssert(self.layoutEngine!.layout(size: size).height ~== 401, "layout -> size正确")
            XCTAssert(self.layoutEngine!.ctframe != nil, "已经生成ctframe")
        }
    }

    func testNormalNumberOfLines() {
        let size = CGSize(width: 297, height: -1)
        let text = "Singletons and dependency injection\n"
            + "Just like the Singleton pattern, object declarations aren’t always ideal for use in large "
            + "software systems. They’re great for small pieces of code that have few or no dependencies, "
            + "but not for large components that interact with many other parts of the system. "
            + "The main reason is that you don’t have any control over the instantiation of "
            + "objects, and you can’t specify parameters for the constructors. "
            + "This means you can’t replace the implementations of the object itself, or other "
            + "classes the object depends on, in unit tests or in different configurations of the software"
            + "system. If you need that ability, you should use regular Kotlin classes together "
            + "with a dependency injection framework (such as Guice, https://github.com/google/"
            + "guice), just as in Java."
        layoutEngine!.attributedText = genAttrString(string: text)
        self.layoutEngine?.numberOfLines = 9

        self.measure {
            XCTAssert(self.layoutEngine!.layout(size: size).height ~== 172, "layout -> size正确")
            XCTAssert(self.layoutEngine!.lines.count == 9, "返回的lines.count 正确")
        }
    }

    func testFirstLineIsBreakLine() {
        let text = "\nabc"

        layoutEngine!.attributedText = genAttrString(string: text)
        let size = CGSize(width: -1, height: -1)
        let exceptSize = CGSize(width: 27, height: 39)
        self.measure {
            XCTAssert(self.layoutEngine!.layout(size: size) ~== exceptSize, "layout -> size正确")
        }
    }

    func testOutOfRangePointInRect() {
        let size = CGSize(width: 200, height: 0)
        let text = "Singletons"
        self.layoutEngine!.attributedText = genAttrString(string: text)
        self.layoutEngine?.numberOfLines = 1
        _ = self.layoutEngine!.layout(size: size).height

        self.measure {
//            XCTAssert(self.layoutEngine!.pointAt(CGPoint(x: size.width - 1, y: height / 2)) == nil, "out of range point 正确")
        }
    }

    func testShowMoreButton() {
        let text = "\nabc"
        let size = CGSize(width: 0, height: 20)
        self.layoutEngine!.attributedText = genAttrString(string: text)
        self.layoutEngine!.numberOfLines = 1
        let widthNormal = self.layoutEngine!.layout(size: size).width
        self.layoutEngine!.outOfRangeText = NSAttributedString(string: "ABC")
        let widthOutofRange = self.layoutEngine!.layout(size: size).width

        self.measure {
            XCTAssert(widthNormal < widthOutofRange, "show more button 正确")
        }
    }

    func testSpecialWord() {
        let text = "୧(๑•̀⌄•́๑)૭ "
        let size = CGSize.zero
        self.layoutEngine!.attributedText = genAttrString(string: text)

        self.measure {
            XCTAssert(self.layoutEngine!.layout(size: size).height <= 26, "୧(๑•̀⌄•́๑)૭高度计算不会失常")
        }
    }

    func testOneLineBadCase1() {
        let text = "∠( ᐛ 」∠)_看戏五个😚ヾડ🌚ડ⸂⸂⸜👊⸝⸃⸃୧😂୨ฅ😸ฅ😉┌✺◟😄◞✺"
        let label = LKLabel()
        let size = CGSize(width: 200, height: 18)
        label.attributedText = genAttrString(string: text)
        label.numberOfLines = 1
        label.outOfRangeText = NSAttributedString(string: "\u{2026}")

        self.measure {
            let layoutSize = label.sizeThatFits(size)
            XCTAssertEqual(layoutSize.height, 28)
            label.render.textSize = label.layout.textSize
            label.render.bounds = CGRect(.zero, size)
            XCTAssertTrue(label.render.textSize.height > size.height)
            XCTAssertEqual(label.render.textRect.y, (size.height - label.render.textSize.height) / 2)
        }
    }
}
