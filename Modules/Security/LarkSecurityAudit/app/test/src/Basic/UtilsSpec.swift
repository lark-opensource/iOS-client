//
//  UtilsSpec.swift
//  LarkSecurityAuditDevEEUnitTest
//
//  Created by Yiming Qu on 2020/11/24.
//

import XCTest
@testable import LarkSecurityAudit

class UtilsSpec: XCTestCase {

    func testExample() throws {
        let result1 = "path1/".appendPath("path2")
        let result2 = "path1".appendPath("path2")
        let result3 = "path1".appendPath("/path2")
        let result4 = "path1/".appendPath("/path2")
        let result5 = "path1/".appendPath("/path2/")
        let result6 = "path1/".appendPath("/path2/", addLastSlant: true)
        let result7 = "path1/".appendPath("/path2/", addLastSlant: true)
        XCTAssertEqual(result1, "path1/path2")
        XCTAssertEqual(result1, "path1/path2")
        XCTAssertEqual(result2, "path1/path2")
        XCTAssertEqual(result3, "path1/path2")
        XCTAssertEqual(result4, "path1/path2")
        XCTAssertEqual(result5, "path1/path2/")
        XCTAssertEqual(result6, "path1/path2/")
        XCTAssertEqual(result7, "path1/path2/")
    }
//
//    func testUrlAppend() throws {
//        let result1 = "https://path1/".urlAppendPath("path2")
//        let result2 = "https://path1".urlAppendPath("path2")
//        let result3 = "https://path1".urlAppendPath("/path2")
//        let result4 = "https://path1/".urlAppendPath("/path2")
//        let result5 = "https://path1/".urlAppendPath("/path2/")
//        let result6 = "https://path1/".urlAppendPath("/path2/", addLastSlant: true)
//        let result7 = "https://path1/".urlAppendPath("/path2/", addLastSlant: true)
//        XCTAssertEqual(result1, "https://path1/path2")
//        XCTAssertEqual(result1, "https://path1/path2")
//        XCTAssertEqual(result2, "https://path1/path2")
//        XCTAssertEqual(result3, "https://path1/path2")
//        XCTAssertEqual(result4, "https://path1/path2")
//        XCTAssertEqual(result5, "https://path1/path2/")
//        XCTAssertEqual(result6, "https://path1/path2/")
//        XCTAssertEqual(result7, "https://path1/path2/")
//    }
}
