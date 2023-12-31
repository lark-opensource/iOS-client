//
//  UDDatePickerTests.swift
//  UDDatePickerTests
//
//  Created by 姚启灏 on 2020/12/10.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignDatePicker
import UniverseDesignDatePicker
import LarkTimeFormatUtils

class UDDatePickerTests: XCTestCase {
    let config = UDWheelsStyleConfig(maxDisplayRows: 5, centerWheels: false,
                                   is12Hour: false, textColor: UIColor.ud.N900,
                                   textFont: UIFont.systemFont(ofSize: 18),
                                   mode: .dayHourMinute())
    let defaultConfig = UDWheelsStyleConfig()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Test  custom config
    func testConfig() {
        XCTAssertEqual(config.maxDisplayRows, 5)
        XCTAssertEqual(config.centerWheels, false)
        XCTAssertEqual(config.is12Hour, false)
        XCTAssertEqual(config.textColor, UIColor.ud.N900)
        XCTAssertEqual(config.textFont, UIFont.systemFont(ofSize: 18))
        XCTAssertEqual(config.mode, .dayHourMinute())
    }

    /// Test default config
    func testDefaultConfig() {
        XCTAssertEqual(defaultConfig.maxDisplayRows, 3)
        XCTAssertEqual(defaultConfig.centerWheels, true)
        XCTAssertEqual(defaultConfig.is12Hour, true)
        XCTAssertEqual(defaultConfig.textColor, UIColor.ud.N900)
        XCTAssertEqual(defaultConfig.textFont, UIFont.systemFont(ofSize: 18))
        XCTAssertEqual(defaultConfig.mode, .yearMonthDay)
    }

}
