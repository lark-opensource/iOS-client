//
//  ColorTest.swift
//  CalendarTests
//
//  Created by linlin on 2018/1/19.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import XCTest
@testable import Calendar

class ColorTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    typealias RGBComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    func testColorToARGB() {
        let color = UIColor.green
        var c1: RGBComponents = (0, 0, 0, 0)

        if color.getRed(&c1.red, green: &c1.green, blue: &c1.blue, alpha: &c1.alpha) {
            XCTAssertEqual(c1.alpha, 1)
        }

    }

}
