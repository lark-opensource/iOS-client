//
//  LKRichStyleSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2019/8/28.
//

import UIKit
import Foundation
import XCTest

@testable import LKRichView

// swiftlint:disable overridden_super_call
class LKRichStyleSpec: XCTestCase {

    var style: LKRichStyle!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        style = LKRichStyle()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDefaultValue() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        style.fontSize(nil)
            .font(nil)
            .fontStyle(nil)
            .fontWeight(nil)
            .color(nil)
            .backgroundColor(nil)
            .lineHeight(nil)
            .textDecoration(nil)
            .border()
            .borderRadius()
            .margin()
            .padding()

        XCTAssertEqual(style.fontSize, .point(SYSTEM_FONT_SIZE), "fontSize default value is .point(\(SYSTEM_FONT_SIZE))")
        XCTAssertEqual(style.storage.fontSize, LKRichStyleValue(.inherit, nil), "fontSize default is LKRichStyleValue(.inherit, nil)")

        XCTAssertEqual(style.font, nil, "fontFamily default is nil")
        XCTAssertEqual(style.storage.font, LKRichStyleValue(.inherit, nil), "fontFamily default is LKRichStyleValue(.value, SYSTEM_FONT_FAMILY))")

        XCTAssertEqual(style.fontStyle, .normal, "fontStyle default value is normal")
        XCTAssertEqual(style.storage.fontStyle, LKRichStyleValue(.value, .normal), "fontStyle default value is LKRichStyleValue(.value, .normal)")

        XCTAssertEqual(style.fontWeight, .normal, "fontWeight default is normal")
        XCTAssertEqual(style.storage.fontWeight, LKRichStyleValue(.value, .normal), "fontWeight default value is ")

        XCTAssertEqual(style.color, nil, "color default is nil")
        XCTAssertEqual(style.storage.color, LKRichStyleValue(.inherit, nil), "color default value is LKRichStyleValue(.inherit, nil)")

        XCTAssertEqual(style.backgroundColor, nil, "backgroundColor default is nil")
        XCTAssertEqual(style.storage.backgroundColor, LKRichStyleValue(.unset, nil), "backgroundColor default value is LKRichStyleValue(.unset, nil)")

        XCTAssertEqual(style.lineHeight, .em(1.2), "lineHeight default is nil")
        XCTAssertEqual(style.storage.lineHeight, LKRichStyleValue(.unset, nil), "lineHeight default value is LKRichStyleValue(.unset, nil)")

        XCTAssertEqual(style.border, nil, "border default is nil")
        XCTAssertEqual(style.storage.border, LKRichStyleValue(.unset, nil), "border default value is LKRichStyleValue(.unset, nil)")

        XCTAssertEqual(style.borderRadius, nil, "borderRadius default is nil")
        XCTAssertEqual(style.storage.borderRadius, LKRichStyleValue(.unset, nil), "borderRadius default value is LKRichStyleValue(.unset, nil)")

        XCTAssertEqual(style.margin, Edges(), "margin default is (0, 0, 0, 0)")
        XCTAssertEqual(style.margin!.top, .point(0))
        XCTAssertEqual(style.margin!.right, .point(0))
        XCTAssertEqual(style.margin!.bottom, .point(0))
        XCTAssertEqual(style.margin!.left, .point(0))
        XCTAssertEqual(style.storage.margin, LKRichStyleValue(.unset, Edges()), "margin default value is LKRichStyleValue(.unset, Edges())")

        XCTAssertEqual(style.padding, Edges(), "padding default is (0, 0, 0, 0)")
        XCTAssertEqual(style.padding!.top, .point(0))
        XCTAssertEqual(style.padding!.right, .point(0))
        XCTAssertEqual(style.padding!.bottom, .point(0))
        XCTAssertEqual(style.padding!.left, .point(0))
        XCTAssertEqual(style.storage.padding, LKRichStyleValue(.unset, Edges()), "padding default value is LKRichStyleValue(.unset, Edges())")

        XCTAssertEqual(style.width, nil, "width default is nil")
        XCTAssertEqual(style.storage.width, .init(.auto, nil), "width default is (auto, nil)")

        XCTAssertEqual(style.width, style.height, "width default is equal to height")
        XCTAssertEqual(style.storage.width, style.storage.height, "width default is equal to height")

        XCTAssertEqual(style.textOverflow, .none, "TextOverflow default is equal to `none`")
        XCTAssertEqual(style.storage.textOverflow, .init(.inherit, nil), "TextOverflow default is equal to LKRichStyleValue(.inherit, nil)")

        XCTAssertEqual(style.lineCamp, .none, "LineCamp default is equal to `none`")
        XCTAssertEqual(style.storage.lineCamp, .init(.unset, nil), "LineCamp default is equal to LKRichStyleValue(.inherit, nil)")
    }

    func testSetBorder() {
        let borderEdge = BorderEdge(style: .none, width: .point(1), color: UIColor.blue)
        style.border(top: borderEdge)

        XCTAssertEqual(style.border!.top, borderEdge)
        XCTAssertEqual(style.border!.right, borderEdge)
        XCTAssertEqual(style.border!.bottom, borderEdge)
        XCTAssertEqual(style.border!.left, borderEdge)

        style.border(right: borderEdge)
        XCTAssertEqual(style.border!.top, nil)
        XCTAssertEqual(style.border!.right, borderEdge)
        XCTAssertEqual(style.border!.bottom, nil)
        XCTAssertEqual(style.border!.left, borderEdge)

        let borderEdge1 = BorderEdge(style: .solid, width: .point(1), color: UIColor.blue)
        XCTAssertNotEqual(borderEdge, borderEdge1)
        style.border(top: borderEdge, bottom: borderEdge1)
        XCTAssertEqual(style.border!.top, borderEdge)
        XCTAssertEqual(style.border!.right, borderEdge)
        XCTAssertEqual(style.border!.bottom, borderEdge1)
        XCTAssertEqual(style.border!.left, borderEdge)

        style.border()
        XCTAssertEqual(style.border, nil)
    }

    func testSetBorderRadius() {
        let borderRadius: LengthSize = .point(10) / 11%
        style.borderRadius(topLeft: borderRadius)

        XCTAssertEqual(style.borderRadius!.topLeft, borderRadius)
        XCTAssertEqual(style.borderRadius!.topRight, borderRadius)
        XCTAssertEqual(style.borderRadius!.bottomRight, borderRadius)
        XCTAssertEqual(style.borderRadius!.bottomLeft, borderRadius)
    }

    func testMarginPadding() {
        style.margin().padding()

        XCTAssertEqual(style.margin, Edges())
        XCTAssertEqual(style.margin?.top, .point(0))
        XCTAssertEqual(style.margin?.right, .point(0))
        XCTAssertEqual(style.margin?.bottom, .point(0))
        XCTAssertEqual(style.margin?.left, .point(0))

        XCTAssertEqual(style.padding, Edges())
        XCTAssertEqual(style.padding?.top, .point(0))
        XCTAssertEqual(style.padding?.right, .point(0))
        XCTAssertEqual(style.padding?.bottom, .point(0))
        XCTAssertEqual(style.padding?.left, .point(0))

        style.margin(top: .point(10), right: nil, bottom: .point(5), left: nil)
            .padding(top: .point(10), right: nil, bottom: .point(5), left: nil)
        XCTAssertEqual(style.margin?.top, .point(10))
        XCTAssertEqual(style.margin?.right, .point(10))
        XCTAssertEqual(style.margin?.bottom, .point(5))
        XCTAssertEqual(style.margin?.left, .point(10))
        XCTAssertEqual(style.padding?.top, .point(10))
        XCTAssertEqual(style.padding?.right, .point(10))
        XCTAssertEqual(style.padding?.bottom, .point(5))
        XCTAssertEqual(style.padding?.left, .point(10))

        style.margin(top: nil, right: nil, bottom: .em(5), left: nil)
            .padding(top: nil, right: nil, bottom: .percent(5), left: nil)
        XCTAssertEqual(style.margin?.top, .point(0))
        XCTAssertEqual(style.margin?.right, .point(0))
        XCTAssertEqual(style.margin?.bottom, .em(5))
        XCTAssertEqual(style.margin?.left, .point(0))
        XCTAssertEqual(style.padding?.top, .point(0))
        XCTAssertEqual(style.padding?.right, .point(0))
        XCTAssertEqual(style.padding?.bottom, .percent(5))
        XCTAssertEqual(style.padding?.left, .point(0))
    }

    func testSetFont() {
        XCTAssertEqual(style.fontSize(.em(20)).fontSize, .em(20))
        XCTAssertEqual(style.font(UIFont.boldSystemFont(ofSize: 20)).font, UIFont.boldSystemFont(ofSize: 20))
        XCTAssertEqual(style.fontStyle(.italic).fontStyle, .italic)
        XCTAssertEqual(style.fontWeight(.bold).fontWeight, .bold)
        XCTAssertEqual(style.fontWeight(.numberic(100)).fontWeight, .numberic(100))
    }

    func testSetTextDecoration() {
        let textDecoration = style.textDecoration(TextDecoration(line: [.lineThrough, .underline], style: .solid)).textDecoration
        XCTAssert(textDecoration!.line.contains(.lineThrough))
        XCTAssert(textDecoration!.line.contains(.underline))
    }

    func testPercentage() {
        XCTAssertEqual(1%, .percent(1))
        XCTAssertEqual(0.2%, .percent(0.2))
        XCTAssertEqual(CGFloat.pi%, .percent(CGFloat.pi))
    }

    func testNumbericValue() {
        let value1: NumbericValue = .em(10)
        var value2 = LKRichStyleValue<CGFloat>(.percent, 10)
        XCTAssertNotEqual(value1, NumbericValue(value2), ".em(10) is not equal to .percent(10")

        value2 = LKRichStyleValue<CGFloat>(.unset, 10)
        XCTAssertNil(NumbericValue(value2), ".unset LKRichStyleValue<CGFloat> cannot init with NumbericValue")
        value2 = LKRichStyleValue<CGFloat>(.auto, 10)
        XCTAssertNil(NumbericValue(value2), ".auto LKRichStyleValue<CGFloat> cannot init with NumbericValue")
        value2 = LKRichStyleValue<CGFloat>(.inherit, 10)
        XCTAssertNil(NumbericValue(value2), ".inherit LKRichStyleValue<CGFloat> cannot init with NumbericValue")
        value2 = LKRichStyleValue<CGFloat>(.value, 10)
        XCTAssertNil(NumbericValue(value2), ".value LKRichStyleValue<CGFloat> cannot init with NumbericValue")
        value2 = LKRichStyleValue<CGFloat>(.em, nil)
        XCTAssertNil(NumbericValue(value2), ".em nil LKRichStyleValue<CGFloat> cannot init with NumbericValue")
        value2 = LKRichStyleValue<CGFloat>(.point, nil)
        XCTAssertNil(NumbericValue(value2), ".point nil LKRichStyleValue<CGFloat> cannot init with NumbericValue")
        value2 = LKRichStyleValue<CGFloat>(.percent, nil)
        XCTAssertNil(NumbericValue(value2), ".percent nil LKRichStyleValue<CGFloat> cannot init with NumbericValue")
    }

    func testLKRichStyleValue() {
        let expect: CGFloat = 10
        var value = LKRichStyleValue<CGFloat>(.auto, expect)
        XCTAssertTrue(value == expect)

        value.value = 0
        XCTAssertTrue(value != expect)
    }

    func testBorder() {
        let borderEdge1 = BorderEdge(style: .solid, width: .point(2), color: UIColor.black)
        let borderEdge2 = BorderEdge(style: .solid, width: .percent(2), color: UIColor.black)
        var border1 = Border(borderEdge1)
        var border2 = Border(borderEdge1, borderEdge1)
        let border3 = Border(borderEdge1, borderEdge1, borderEdge1)
        var border4 = Border(borderEdge1, borderEdge1, borderEdge1, borderEdge1)

        XCTAssertEqual(border1, border2)
        XCTAssertEqual(border2, border3)
        XCTAssertEqual(border3, border4)

        border1.bottom = borderEdge2
        XCTAssertNotEqual(border1, border2)

        border2.top = borderEdge2
        XCTAssertNotEqual(border2, border3)

        border2.top = borderEdge1
        border2.right = borderEdge2
        border4.left = borderEdge2
        border4.right = borderEdge2
        XCTAssertEqual(border4, border2)
    }

    func testEdges() {
        let value1: NumbericValue = .em(1)
        let value2: NumbericValue = .percent(1)
        let value3: NumbericValue = .point(1)
        let edge1 = Edges(value1)
        let edge2 = Edges(value1, value2)
        var edge3 = Edges(value1, value2, value3)
        var edge4 = Edges(value1, value1, value1, value1)

        XCTAssertNotEqual(edge1, edge2)
        XCTAssertNotEqual(edge1, edge3)
        XCTAssertNotEqual(edge1, edge3)
        XCTAssertEqual(edge1, edge4)

        edge3.top = value2
        edge3.right = value1
        edge4.top = value2
        edge4.bottom = value3
        edge4.left = value1
        edge4.right = value1
        XCTAssertEqual(edge3, edge4)
    }

    func testBorderRadius() {
        let value1 = LengthSize()
        let value2 = LengthSize(width: .point(10), height: .point(10))
        let value3 = LengthSize(width: .em(10), height: .em(10))

        var borderRadius = BorderRadius(value1, nil, nil, nil)
        XCTAssertEqual(borderRadius, BorderRadius(value1, value1, value1, value1), "1")
        borderRadius.topLeft = value2
        XCTAssertEqual(borderRadius, BorderRadius(value2, value2, value2, value2), "2")
        borderRadius.topRight = value1
        XCTAssertEqual(borderRadius, BorderRadius(value2, value1, value2, value1), "3")
        borderRadius.bottomRight = value3
        XCTAssertEqual(borderRadius, BorderRadius(value2, value1, value3, value1), "4")
        borderRadius.bottomLeft = value2
        XCTAssertEqual(borderRadius, BorderRadius(value2, value1, value3, value2), "5")
    }

    func testColor() {
        XCTAssertEqual(style.color(UIColor.white).storage.color, .init(.value, UIColor.white))
        XCTAssertEqual(style.color(nil).storage.color, .init(.inherit, nil))
    }

    func testBackgroundColor() {
        XCTAssertEqual(style.backgroundColor(UIColor.white).storage.backgroundColor, .init(.value, UIColor.white))
        XCTAssertEqual(style.backgroundColor(nil).storage.backgroundColor, .init(.unset, nil))
    }

    func testLineHeight() {
        XCTAssertEqual(style.lineHeight(.point(10)).storage.lineHeight, .init(.point, 10))
        XCTAssertEqual(style.lineHeight(nil).storage.lineHeight, .init(.unset, nil))
    }

    func testSize() {
        XCTAssertEqual(style.width(.percent(10)).storage.width, .init(.percent, 10))
        XCTAssertEqual(style.width(nil).storage.width, .init(.auto, nil))
        XCTAssertEqual(style.height(.percent(10)).storage.height, .init(.percent, 10))
        XCTAssertEqual(style.height(nil).storage.height, .init(.auto, nil))
    }

    func testFontWeigth() {
        XCTAssertEqual(FontWeight.normal.rawValue, UIFont.Weight.regular.rawValue)
        XCTAssertEqual(FontWeight.bold.rawValue, UIFont.Weight.bold.rawValue)
        XCTAssertEqual(FontWeight.numberic(500), FontWeight.normal)
        XCTAssertEqual(FontWeight.numberic(0).uiFontWeight, UIFont.Weight.ultraLight)
        XCTAssertEqual(FontWeight.bold.uiFontWeight, UIFont.Weight.bold)
        XCTAssertEqual(FontWeight.normal.uiFontWeight, UIFont.Weight.regular)
    }
}
