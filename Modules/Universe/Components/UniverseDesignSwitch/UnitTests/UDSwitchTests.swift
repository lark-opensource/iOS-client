//
//  UDSwitchTests.swift
//  UniverseDesignSwitchTests
//
//  Created by CJ on 2020/11/19.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignSwitch
import UniverseDesignColor

class UDSwitchTests: XCTestCase {

    let udSwitch: UDSwitch = UDSwitch()

    override class func setUp() {
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

    /// Test Switch isEnabled
    func testSetEnabled() {
        self.udSwitch.isEnabled = false
        XCTAssertEqual(udSwitch.contentView.backgroundColor, UIColor.ud.B200)
        XCTAssertEqual(udSwitch.circleView.backgroundColor, UIColor.ud.N00)
        XCTAssertEqual(udSwitch.indicator.backgroundColor, UIColor.ud.N00)
    }

    /// Test Switch behaviourType
    func testSetBehaviourType() {
        self.udSwitch.behaviourType = .waitCallback
    }

    /// Test Switch uiConfig
    func testSetUIConfig() {
        let customUIConfig1 = UDSwitchUIConfig(onNormalTheme:
                                                UDSwitchUIConfig.ThemeColor(tintColor: UIColor.green,
                                                                            thumbColor: UIColor.white))
        self.udSwitch.uiConfig = customUIConfig1
        XCTAssertEqual(udSwitch.contentView.backgroundColor, UIColor.green)
        XCTAssertEqual(udSwitch.circleView.backgroundColor, UIColor.white)
        XCTAssertEqual(udSwitch.indicator.backgroundColor, UIColor.ud.N300)
    }
}
