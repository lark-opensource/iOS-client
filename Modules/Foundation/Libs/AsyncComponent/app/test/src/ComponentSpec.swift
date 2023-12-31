//
//  ComponentSpec.swift
//  AsyncComponentDevEEUnitTest
//
//  Created by qihongye on 2019/1/26.
//

import Foundation
import XCTest
import EEFlexiable

@testable import AsyncComponent

class ComponentSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStyleClone() {
        let style = ASComponentStyle()
        style.backgroundColor = .black
        style.bottom = 10%
        style.aspectRatio = 0
        let clone = style.clone()
        XCTAssertEqual(clone.backgroundColor.hashValue, style.backgroundColor.hashValue)
        XCTAssertEqual(clone.bottom, style.bottom)
        XCTAssertEqual(clone.aspectRatio, style.aspectRatio)

        XCTAssertEqual(clone.boxSizing, style.boxSizing)
        clone.boxSizing = .borderBox
        XCTAssertNotEqual(clone.boxSizing, style.boxSizing)
        style.aspectRatio = 1
        XCTAssertNotEqual(clone.aspectRatio, style.aspectRatio)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
