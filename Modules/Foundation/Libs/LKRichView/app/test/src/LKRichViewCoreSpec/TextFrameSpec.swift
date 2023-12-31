//
//  TextFrameSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2019/9/25.
//

// swiftlint:disable overridden_super_call
import UIKit
import Foundation
import XCTest

@testable import LKRichView

class TextFrameSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_TextFrame() {
        let attrString = NSAttributedString(string: """
// This is an example of a functional test case.
// Use XCTAssert and related functions to verify your tests produce the correct results.
""")
        let frameSetter = TextFrameSetter(attrString)
        let setter = TextTypeSetter(frameSetter)
        if true {
            let inputLocation = 100
            let line = setter.getLine(range: setter.getLineRange(startIndex: inputLocation, width: 100, shouldCluster: false))
            XCTAssertTrue(line.size ~= CGSize(width: 90, height: 12), "")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
