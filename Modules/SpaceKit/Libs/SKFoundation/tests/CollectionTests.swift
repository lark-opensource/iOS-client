//
//  CollectionTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class CollectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testCollectionAt() {
        let array = [0, 1, 2, 3, 4]
        var res = array[at: 1]
        XCTAssertEqual(res, 1)

        res = array[at: 4]
        XCTAssertEqual(res, 4)
    }
}
