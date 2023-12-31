//
//  DataAssignerTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by CJ on 2022/4/6.
//

import XCTest
@testable import SKFoundation

class DataAssignerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAssignIfPresent() {
        let resTitle = "dataTitle"
        let resContent = "dataContent"
        let resDetail = "datadetail"

        let data: [String: String] = ["title": resTitle,
                                      "content": resContent,
                                      "detail": resDetail]
        let target = DataAssignerTestModel(title: "title1", content: "content1")
        let assigner = DataAssigner(target: target, data: data)
        assigner.assignIfPresent(key: "title", keyPath: \.title)
        assigner.assignIfPresent(key: "content", keyPath: \.content)
        assigner.assignIfPresent(key: "detail", keyPath: \.detail)

        XCTAssertEqual(target.title, resTitle)
        XCTAssertEqual(target.content, resContent)
        XCTAssertEqual(target.detail, resDetail)
    }
}

class DataAssignerTestModel {
    var title: String
    var content: String
    var detail: String?
    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }
}
