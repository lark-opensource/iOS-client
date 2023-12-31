//
//  FlexNodeSpec.swift
//  EEFlexiableDevEEUnitTest
//
//  Created by qihongye on 2018/11/25.
//

import UIKit
import Foundation
import XCTest
@testable import EEFlexiable

class FlexNodeSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFlexNodeSyncToYogaNode() {
        let fnode = FlexNode()
        fnode.alignContent = .center
        fnode.alignItems = .auto

        XCTAssertEqual(YGNodeStyleGetAlignContent(fnode.node).rawValue, fnode.alignContent.rawValue)
        XCTAssertEqual(YGNodeStyleGetAlignItems(fnode.node).rawValue, fnode.alignItems.rawValue)
    }

    func testFlexNodeDefaultValue() {
        let fnode = FlexNode()

        XCTAssertEqual(fnode.alignItems, .stretch)
        XCTAssertEqual(fnode.alignContent, .flexStart)
        XCTAssertEqual(fnode.alignSelf, .auto)
        XCTAssertEqual(fnode.aspectRatio, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderBottomWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderEndWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderLeftWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderRightWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderStartWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderTopWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.borderWidth, CGFloat.CSSUndefined)
        XCTAssertEqual(fnode.bottom, CSSValueUndefined)
        XCTAssertEqual(fnode.direction, .inherit)
        XCTAssertEqual(fnode.display, .flex)
//        XCTAssertEqual(fnode.flexDirection, .column)
        XCTAssertEqual(fnode.flexGrow, 0)
//        XCTAssertEqual(fnode.flexShrink, 0)
        XCTAssertEqual(fnode.flexWrap, .noWrap)
        XCTAssertEqual(fnode.flexBasis, CSSValueAuto)
        XCTAssertEqual(fnode.justifyContent, .flexStart)
        XCTAssertEqual(fnode.width, CSSValueAuto)
        XCTAssertEqual(fnode.height, CSSValueAuto)
        XCTAssertEqual(fnode.maxWidth, CSSValueUndefined)
        XCTAssertEqual(fnode.maxHeight, CSSValueUndefined)
        XCTAssertEqual(fnode.minWidth, CSSValueUndefined)
        XCTAssertEqual(fnode.minHeight, CSSValueUndefined)
        XCTAssertEqual(fnode.aspectRatio, CGFloat(CSSValueUndefined.value))
    }

    ///  _________________________
    /// |      |                  |
    /// |------|                  |
    /// |______|__________________|
    func testFlexNodeLayout() {
        let root = FlexNode()
        let left = FlexNode()
        let right = FlexNode()
        let left1 = FlexNode()
        let left2 = FlexNode()

        if (true) {
            root.width = 500
            root.flexDirection = .row
            root.addSubFlexNode(left)
            root.addSubFlexNode(right)
        }
        if (true) {
            left.flexDirection = .column
            left.flexShrink = 1
            left.addSubFlexNode(left1)
            left.addSubFlexNode(left2)
        }
        if (true) {
            left1.setMeasureFunc { (width, height) -> CGSize in
                var w = width
                var h = height
                if (w > 250) {
                    w = 250
                    h = w
                } else {
                    h = 300
                }
                return CGSize(width: w, height: h)
            }
            left2.flexShrink = 1
            left2.setMeasureFunc { (width, height) -> CGSize in
                let seq: CGFloat = 5000
                if (width > height) {
                    return CGSize(width: width, height: seq / width)
                }
                return CGSize(width: seq / height, height: height)
            }
        }
        if (true) {
            right.flexGrow = 1
            right.setMeasureFunc { (_, _) -> CGSize in
                return CGSize(width: 100, height: 100)
            }
        }

        let rootSize = root.calculateLayout(with: CGSize(width: 500, height: 500))
        XCTAssertEqual(rootSize, root.frame.size)
        XCTAssertEqual(root.frame, CGRect(x: 0, y: 0, width: 500, height: 500))
//        XCTAssertEqual(left.frame, CGRect(x: 0, y: 0, width: 400, height: 500))
//        XCTAssertEqual(left1.frame, CGRect(x: 0, y: 0, width: 400, height: 250))
//        XCTAssertEqual(left2.frame, CGRect(x: 0, y: 250, width: 400, height: 250))
//        XCTAssertEqual(right.frame, CGRect(x: 400, y: 0, width: 100, height: 500))
    }

    func testDisplayNone() {
        let root = FlexNode()
        let left = FlexNode()
        let right = FlexNode()
        let left1 = FlexNode()
        let left2 = FlexNode()

        if (true) {
            root.width = 500
            root.flexDirection = .row
            root.setSubFlexNodes([left, right])
        }
        if (true) {
            left.flexDirection = .column
            left.flexShrink = 1
            left.setSubFlexNodes([left1, left2])
        }
        if (true) {
            left1.setMeasureFunc { (width, height) -> CGSize in
                var w = width
                var h = height
                if (w > 250) {
                    w = 250
                    h = w
                } else {
                    h = 300
                }
                return CGSize(width: w, height: h)
            }
            left2.display = .none
            left2.flexShrink = 1
            left2.setMeasureFunc { (width, height) -> CGSize in
                let seq: CGFloat = 5000
                if (width > height) {
                    return CGSize(width: width, height: seq / width)
                }
                return CGSize(width: seq / height, height: height)
            }
        }
        if (true) {
            right.flexGrow = 1
            right.setMeasureFunc { (_, _) -> CGSize in
                return CGSize(width: 100, height: 100)
            }
        }

        let rootSize = root.calculateLayout(with: CGSize(width: 500, height: 500))
        XCTAssertEqual(rootSize, root.frame.size)
        XCTAssertEqual(root.frame, CGRect(x: 0, y: 0, width: 500, height: 500))
        XCTAssertEqual(left.frame, CGRect(x: 0, y: 0, width: 250, height: 500))
        XCTAssertEqual(left1.frame, CGRect(x: 0, y: 0, width: 250, height: 250))
        XCTAssertEqual(left2.frame, CGRect(x: 0, y: 0, width: 0, height: 0))
        XCTAssertEqual(right.frame, CGRect(x: 250, y: 0, width: 250, height: 500))
    }

    func testClone() {
        let root = FlexNode()
        let left = FlexNode()
        let right = FlexNode()
        let left1 = FlexNode()
        let left2 = FlexNode()

        if (true) {
            root.width = 500
            root.flexDirection = .row
            root.addSubFlexNode(left)
            root.addSubFlexNode(right)
        }
        if (true) {
            left.flexDirection = .column
            left.flexShrink = 1
            left.addSubFlexNode(left1)
            left.addSubFlexNode(left2)
        }
        if (true) {
            left1.setMeasureFunc { (width, height) -> CGSize in
                var w = width
                var h = height
                if (w > 250) {
                    w = 250
                    h = w
                } else {
                    h = 300
                }
                return CGSize(width: w, height: h)
            }
            left2.flexShrink = 1
            left2.setMeasureFunc { (width, height) -> CGSize in
                let seq: CGFloat = 5000
                if (width > height) {
                    return CGSize(width: width, height: seq / width)
                }
                return CGSize(width: seq / height, height: height)
            }
        }
        if (true) {
            right.flexGrow = 1
            right.setMeasureFunc { (_, _) -> CGSize in
                return CGSize(width: 100, height: 100)
            }
        }

        let rootSize = root.calculateLayout(with: CGSize(width: 500, height: 500))
        let newRoot = root.clone()
        let newLeft = left.clone()
        let newLeft1 = left1.clone()
        let newLeft2 = left2.clone()
        let newRight = right.clone()
        XCTAssertEqual(root.frame.size, rootSize)
        XCTAssertEqual(newRoot.frame, root.frame)
        XCTAssertEqual(newLeft.frame, left.frame)
        XCTAssertEqual(newRight.frame, right.frame)
        XCTAssertEqual(newLeft1.frame, left1.frame)
        XCTAssertEqual(newLeft2.frame, left2.frame)
        let rootSize2 = root.calculateLayout(with: CGSize(width: 500, height: 300))
        XCTAssertEqual(root.frame.size, rootSize2)
        XCTAssertNotEqual(newRoot.frame, root.frame)
        XCTAssertNotEqual(newLeft.frame, left.frame)
        XCTAssertNotEqual(newRight.frame, right.frame)
//        XCTAssertEqual(newLeft1.frame, left1.frame)
        XCTAssertNotEqual(newLeft2.frame, left2.frame)
    }

    /// https://bytedance.feishu.cn/wiki/wikcnjS9uVfFopQObxLkB0LwIoe#
    func testYGRoundValueToPixelGrid() {
        // range = (0.9999/scale, 1/scale)(1.9999/scale, 2/scale)(2.9999/scale, 3/scale)
        // left in range
        if true {
            let scale: Float = 3
            let widthAddition: Float = 2 / scale
            let d = 0.000001 / Float.pi
            for i in 1..<4 {
                let i = Float(i)
                let target = i/scale
                var value: Float = (i+0.9999) / scale
                var width: Float = 0
                var expectWidth: Float = width
                while value < target {
                    width = ceilf(Float.random(in: 1..<1000) * Float.pi * scale) / scale
                    expectWidth = YGRoundValueToPixelGrid(value + width  + widthAddition, scale, false, true)
                        - YGRoundValueToPixelGrid(value, scale, false, true)
                    XCTAssertTrue(width <= expectWidth, "width: \(width) expect: \(expectWidth)")
                    value += d
                }
            }
        }
        // left in whole range
        if true {
            for i in 1..<9 {
                let scale = Float(i)
                let widthAddition: Float = 2 / scale
                let d = 0.000001 / Float.pi
                let target = scale
                var value: Float = 0
                var width: Float = 0
                var expectWidth: Float = width
                while value < target {
                    width = ceilf(Float.random(in: 1..<1000) * Float.pi * scale) / scale
                    expectWidth = YGRoundValueToPixelGrid(value + width  + widthAddition, scale, false, true) - YGRoundValueToPixelGrid(value, scale, false, true)
                    XCTAssertTrue(width <= expectWidth, "width: \(width) expect: \(expectWidth)")
                    value += d
                }
            }
        }
    }

    func testMultiThreadFree() {

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
