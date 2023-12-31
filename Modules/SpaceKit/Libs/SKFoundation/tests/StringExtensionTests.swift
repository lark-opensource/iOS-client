//
//  StringExtensionTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/9/16.
//  



import XCTest
@testable import SKFoundation

class StringExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNewRegularUrlRanges() {
        
        let checktextsMap = [
            "www.baidu.com": 1,
            "baidu.com": 1,
            "https//:www.baidu.com": 1,
            "http//:www.baidu.com": 1,
            "www.cn": 1,
            "前缀www.baidu.com": 1,
            "前缀 www.baidu.com": 1,
            "www.baidu.com后缀": 1,
            "www.baidu.com 后缀": 1,
            "前缀www.baidu.com后缀": 1,
            "www.baidu.com间隔www.baidu.com": 2,
            "abw.baidu.com": 1,
            "abw.bai du.com": 1,
            "www.baidu": 0,
            "https://baidu": 0
        ]
        checktextsMap.forEach { (text, linkNum) in
            let linkRange = text.docs.newRegularUrlRanges
            XCTAssertTrue(linkRange.count == linkNum)
        }
    }
}
