//
//  I18nUtilTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by CJ on 2022/4/6.
//

import XCTest
@testable import SKFoundation

class I18nUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAppleLanguage() {
        let appleLanguage = I18nUtil.appleLanguage
        let systemLanguage = I18nUtil.systemLanguage

        XCTAssertNotNil(appleLanguage)
        XCTAssertNotNil(systemLanguage)
    }

}
