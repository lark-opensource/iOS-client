//
//  MapperTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/11.
//

import XCTest

class MapperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testArrayToJSONString() {
        let array = [0, 1, 2, 3, 4]
        let res = array.toJSONString()
        let expect = "[0,1,2,3,4]"
        XCTAssertEqual(res, expect)
    }

    func testDictionaryToJSONString() {
        let dict = ["0": "h",
                    "1": "e",
                    "2": "l",
                    "3": "l",
                    "4": "o"]
        let res = dict.toJSONString()
        XCTAssertNotNil(res)
        XCTAssertTrue((res?.count ?? 0) > 0)
    }

    func testStringToDictionary() {
        let str = "{\"3\":\"l\",\"1\":\"e\",\"2\":\"l\",\"0\":\"h\",\"4\":\"o\"}"
        let res = str.toDictionary() as? [String: String]
        let expect = ["0": "h",
                    "1": "e",
                    "2": "l",
                    "3": "l",
                    "4": "o"]
        XCTAssertEqual(res, expect)
    }
}
