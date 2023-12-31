//
//  RuntimeHelperTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class RuntimeHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testExample() {}
    
    func testExistSelector() {
        let selector = #selector(testExample)
        var res = existSelector(selector: selector, cls: RuntimeHelperTests.self)
        XCTAssertTrue(res)
        
        res = existSelector(selector: selector, cls: AESUtil.self)
        XCTAssertFalse(res)
    }

    func testSelector() {
        let res = selector(uid: "uid", classes: [RuntimeHelperTests.self], block: nil)
        XCTAssertEqual(res, Selector(("uid")))
    }
}
