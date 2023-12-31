//
//  JSServiceUtilTests.swift
//  SKBrowser-Unit-Tests
//
//  Created by ByteDance on 2023/12/5.
//

import XCTest
@testable import SKBrowser

final class JSServiceUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testFixCharacters() {
        JSServiceUtil.fixUnicodeCtrlCharacters("xxxx", function: "unittest")
    }
}
