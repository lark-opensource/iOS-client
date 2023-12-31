//
//  ConstructTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class ConstructTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testConstruct() {
        let res = ConstructTests().construct { _ in
        }
        XCTAssertTrue(res.isKind(of: ConstructTests.self))
    }
}
