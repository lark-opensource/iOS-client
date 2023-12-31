//
//  RenderImgSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2020/2/3.
//

// swiftlint:disable overridden_super_call
import Foundation
import XCTest

@testable import LKRichView

class RenderImgSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRenderImgNormal() {
        let renderer = RenderImg(nodeType: .element, renderStyle: LKRenderRichStyle(), ownerElement: nil)
        XCTAssertEqual(renderer.isRenderBlock, true)
        XCTAssertEqual(renderer.isRenderInline, true)
        XCTAssertEqual(renderer.isRenderFloat, false)
        XCTAssertEqual(renderer.isChildrenBlock, false)
        XCTAssertEqual(renderer.isChildrenInline, false)

        renderer.appendChild(RenderObject(nodeType: .element, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        XCTAssertEqual(renderer.children.count, 0)
        renderer.removeChild(idx: 0)
        XCTAssertEqual(renderer.children.count, 0)
        XCTAssertEqual(renderer.layout(.zero, context: nil), .zero)
        XCTAssertNotNil(renderer.createRunBox())
    }
}
