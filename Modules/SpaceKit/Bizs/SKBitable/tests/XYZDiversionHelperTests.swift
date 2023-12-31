//
//  XYZDiversionHelperTests.swift
//  SKBitable-Unit-Tests
//
//  Created by 刘焱龙 on 2023/12/19.
//

import XCTest
@testable import SKBitable
@testable import SKFoundation
import SKCommon

class XYZDiversionHelperTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDoXYZDiversionSuccess() {
        let expect = expectation(description: "testDoXYZDiversionSuccess")
        XYZDiversionHelper.doXYZDiversion { event, loadForm in
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }
}
