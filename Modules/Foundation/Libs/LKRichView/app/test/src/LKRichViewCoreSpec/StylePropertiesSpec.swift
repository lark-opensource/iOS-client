//
//  StylePropertiesSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2019/11/14.
//

// swiftlint:disable overridden_super_call
import UIKit
import Foundation
import XCTest

@testable import LKRichView

class StylePropertiesSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStyleProperty() {
        if true {
            let color = LKRichStyleValue<UIColor>(.inherit, UIColor.black)
            let property = StyleProperty(name: .backgroundColor, value: color)
            XCTAssertTrue(property.colorRichStyleValue() == color)
        }
        if true {
            let width = LKRichStyleValue<CGFloat>(.auto, nil)
            let property = StyleProperty(name: .width, value: width)
            XCTAssertTrue(property.numbericRichStyleValue() == width)
        }
        if true {
            let edges = LKRichStyleValue<Edges>(.auto, Edges(.em(1), 10%, .point(20), 50%))
            let property = StyleProperty(name: .padding, value: edges)
            XCTAssertTrue(property.edgesRichStyleValue() == edges)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
