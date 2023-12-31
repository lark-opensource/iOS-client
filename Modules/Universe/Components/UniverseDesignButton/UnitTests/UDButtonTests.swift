//
//  UDButtonTests.swift
//  UniverseDesignButton-Unit-UnitTests
//
//  Created by 姚启灏 on 2020/11/17.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignButton

class UDButtonTests: XCTestCase {
    let button = UDButton()

    func testShowLoading() {
        button.showLoading()

        XCTAssert(button.isLoading)
    }

    func testHiddenLoading() {
        button.hideLoading()
        XCTAssert(!button.isLoading)
    }

    func testUpdateConfig() {
        var config = button.config
        config.radiusStyle = .circle
        config.type = .big

        button.config = config

        button.layoutSubviews()

        XCTAssert(button.titleLabel?.font == UIFont.systemFont(ofSize: 17))
    }
}
