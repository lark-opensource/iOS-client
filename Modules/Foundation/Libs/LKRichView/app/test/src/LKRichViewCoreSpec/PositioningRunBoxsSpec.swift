//
//  PositioningRunBoxsSpec.swift
//  LKRichViewDev
//
//  Created by qihongye on 2019/10/30.
//

// swiftlint:disable overridden_super_call
import UIKit
import Foundation
import XCTest

@testable import LKRichView

class MockRunBox: RunBox {
    var _renderContextLocation: Int = 0
    var isSplit: Bool
    var isLineBreak: Bool = false

    var contentSize: CGSize = .zero
    var ascent: CGFloat = 0
    var baselineOrigin: CGPoint = .zero
    var crossAxisAlign: VerticalAlign = .baseline
    var crossAxisWidth: CGFloat {
        return contentCrossAxisWidth + edges.top + edges.bottom
    }
    var contentMainAxisWidth: CGFloat = 1
    var contentCrossAxisWidth: CGFloat {
        return ascent + descent + leading
    }
    var edges: UIEdgeInsets
    var debugOptions: ConfigOptions?
    var descent: CGFloat = 0
    var globalBaselineOrigin: CGPoint = .zero
    var globalOrigin: CGPoint = .zero
    var leading: CGFloat = 0
    var mainAxisWidth: CGFloat {
        return contentMainAxisWidth + edges.left + edges.right
    }
    var origin: CGPoint = .zero
    var ownerLineBox: LineBox?
    var ownerRenderObject: RenderObject?
    var renderContextLength: Int = 0
    var renderContextLocation: Int = 0
    var renderContextRange: CFRange = CFRangeMake(0, 0)
    var size: CGSize = .zero
    var writingMode: WritingMode = .horizontalTB

    init(ascent: CGFloat, descent: CGFloat, leading: CGFloat, crossAxisAlign: VerticalAlign, edges: UIEdgeInsets = .zero) {
        self.ascent = ascent
        self.descent = descent
        self.leading = leading
        self.edges = edges
        self.crossAxisAlign = crossAxisAlign
        self.isSplit = false
    }

    func layout(context: LayoutContext?) {
    }
    func layoutIfNeeded(context: LayoutContext?) {
    }
    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult {
        return .disable(lhs: self, rhs: nil)
    }
    func draw(_ paintInfo: PaintInfo) {
    }
}

extension LineLayoutInfo: Equatable {
    public static func == (_ lhs: LineLayoutInfo, _ rhs: LineLayoutInfo) -> Bool {
        return lhs.ascent == rhs.ascent && lhs.descent == rhs.descent && lhs.leading == rhs.leading
            && lhs.mainAxisWidth == rhs.mainAxisWidth && lhs.crossAxisWidth == rhs.crossAxisWidth
            && lhs.edges == rhs.edges
    }
}

class PositioningRunBoxsSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_CalculateLineInfoHorizon1() {
        let runBoxs = [
            MockRunBox(ascent: 10, descent: 5, leading: 0, crossAxisAlign: .baseline),
            MockRunBox(ascent: 5, descent: 2, leading: 1, crossAxisAlign: .baseline),
            MockRunBox(ascent: 10, descent: 5, leading: 5, crossAxisAlign: .baseline),
            MockRunBox(ascent: 20, descent: 0, leading: 0, crossAxisAlign: .baseline),
            MockRunBox(ascent: 0, descent: 1, leading: 9, crossAxisAlign: .baseline),
            MockRunBox(ascent: 0, descent: 10, leading: 0, crossAxisAlign: .baseline)
        ]
        let expectLineInfo = LineLayoutInfo(mainAxisWidth: 6, ascent: 20, descent: 10, leading: 0)

        XCTAssertEqual(calculateLineInfoHorizon(runBoxs: runBoxs), expectLineInfo)
    }

    func test_CalculateLineInfoHorizon2() {
        let runBoxs = [
            MockRunBox(ascent: 10, descent: 5, leading: 0, crossAxisAlign: .top),
            MockRunBox(ascent: 5, descent: 2, leading: 1, crossAxisAlign: .top),
            MockRunBox(ascent: 10, descent: 5, leading: 5, crossAxisAlign: .top),
            MockRunBox(ascent: 20, descent: 0, leading: 0, crossAxisAlign: .top),
            MockRunBox(ascent: 0, descent: 1, leading: 9, crossAxisAlign: .top),
            MockRunBox(ascent: 0, descent: 10, leading: 0, crossAxisAlign: .top)
        ]
        let expectLineInfo = LineLayoutInfo(mainAxisWidth: 6, ascent: 0, descent: 0, leading: 20)

        XCTAssertEqual(calculateLineInfoHorizon(runBoxs: runBoxs), expectLineInfo)
    }

    func test_CalculateLineInfoHorizon3() {
        let runBoxs = [
            MockRunBox(ascent: 10, descent: 5, leading: 0, crossAxisAlign: .bottom),
            MockRunBox(ascent: 5, descent: 2, leading: 1, crossAxisAlign: .bottom),
            MockRunBox(ascent: 10, descent: 5, leading: 5, crossAxisAlign: .bottom),
            MockRunBox(ascent: 20, descent: 0, leading: 0, crossAxisAlign: .bottom),
            MockRunBox(ascent: 0, descent: 1, leading: 9, crossAxisAlign: .bottom),
            MockRunBox(ascent: 0, descent: 10, leading: 0, crossAxisAlign: .bottom)
        ]
        let expectLineInfo = LineLayoutInfo(mainAxisWidth: 6, ascent: 20, descent: 0, leading: 0)

        XCTAssertEqual(calculateLineInfoHorizon(runBoxs: runBoxs), expectLineInfo)
    }

    func test_CalculateLineInfoHorizon4() {
        let runBoxs = [
            MockRunBox(ascent: 10, descent: 5, leading: 0, crossAxisAlign: .middle),
            MockRunBox(ascent: 5, descent: 2, leading: 1, crossAxisAlign: .middle),
            MockRunBox(ascent: 10, descent: 5, leading: 5, crossAxisAlign: .middle),
            MockRunBox(ascent: 20, descent: 0, leading: 0, crossAxisAlign: .middle),
            MockRunBox(ascent: 0, descent: 1, leading: 9, crossAxisAlign: .middle),
            MockRunBox(ascent: 0, descent: 10, leading: 0, crossAxisAlign: .middle)
        ]
        let expectLineInfo = LineLayoutInfo(mainAxisWidth: 6, ascent: 10, descent: 0, leading: 10)

        XCTAssertEqual(calculateLineInfoHorizon(runBoxs: runBoxs), expectLineInfo)
    }

    func test_CalculateLineInfoHorizon() {
        let runBoxs = [
            MockRunBox(ascent: 10, descent: 5, leading: 0, crossAxisAlign: .baseline),
            MockRunBox(ascent: 5, descent: 2, leading: 1, crossAxisAlign: .baseline),
            MockRunBox(ascent: 10, descent: 5, leading: 5, crossAxisAlign: .top),
            MockRunBox(ascent: 20, descent: 0, leading: 0, crossAxisAlign: .bottom),
            MockRunBox(ascent: 0, descent: 10, leading: 11, crossAxisAlign: .middle),
            MockRunBox(ascent: 0, descent: 10, leading: 1, crossAxisAlign: .baseline)
        ]
        let expectLineInfo = LineLayoutInfo(mainAxisWidth: 6, ascent: 10.5, descent: 10, leading: 1)

        XCTAssertEqual(calculateLineInfoHorizon(runBoxs: runBoxs), expectLineInfo)
    }

    func test_CalculateLineInfoHorizonEdges() {
        let runBoxs = [
            MockRunBox(ascent: 10, descent: 5, leading: 0, crossAxisAlign: .baseline, edges: UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 1)),
            MockRunBox(ascent: 5, descent: 2, leading: 1, crossAxisAlign: .baseline, edges: UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 1)),
            MockRunBox(ascent: 10, descent: 5, leading: 5, crossAxisAlign: .top, edges: UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 1)),
            MockRunBox(ascent: 20, descent: 0, leading: 0, crossAxisAlign: .bottom, edges: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 1)),
            MockRunBox(ascent: 0, descent: 10, leading: 11, crossAxisAlign: .middle, edges: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 1)),
            MockRunBox(ascent: 0, descent: 10, leading: 1, crossAxisAlign: .baseline, edges: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 1))
        ]
        let expectLineInfo = LineLayoutInfo(mainAxisWidth: 12, ascent: 10.5, descent: 10, leading: 1, edges: UIEdgeInsets(top: 10, left: 0, bottom: 9.5, right: 0))

        XCTAssertEqual(calculateLineInfoHorizon(runBoxs: runBoxs), expectLineInfo)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
