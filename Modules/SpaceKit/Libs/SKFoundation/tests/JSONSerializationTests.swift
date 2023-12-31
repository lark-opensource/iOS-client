//
//  JSONSerializationTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class JSONSerializationTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testModelToJson() {
        let model = JSONTestModel(content: "测试mode转json")
        let res = JSONSerialization.modelToJson(model) as? [String: Any]
        let expect = ["content": "测试mode转json"]
        XCTAssertNotNil(res)
        XCTAssertEqual((res as? [String: String]), expect)
    }
}

public struct JSONTestModel: Codable {
    var content: String
    public init(content: String) {
        self.content = content
    }
}
