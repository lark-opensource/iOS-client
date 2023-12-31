/**
 * Copyright (c) 2022 ByteDance Inc. All rights reserved.
 */
import Foundation

import XCTest
@testable import LarkCore
import LarkBaseKeyboard

class LarkCoreUnitTestExample: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInputUtilRandomId() {
        let id = InputUtil.randomId()
        XCTAssert(id < 100_000_000)
    }

}
