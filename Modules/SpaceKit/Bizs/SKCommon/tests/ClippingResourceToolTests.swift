//
//  ClippingResourceToolTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/7/13.
//  

import UIKit
import WebBrowser
@testable import SKCommon
import SKResource
import XCTest

class ClippingResourceToolTests: XCTestCase {

    
    
    func testExtract() {
        let tool = try? ClippingResourceTool()
        let expect = expectation(description: "test resouce tool")
        tool?.fetchJSResource { [weak self] jsStr, _ in
            expect.fulfill()
            XCTAssertNotNil(jsStr)
            XCTAssertNotNil(tool?.jsExtractedFile)
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
    
    func testOldResourceClear() {
        let tool = try? ClippingResourceTool()
        tool?.clearOldResource()
        let basePath = tool?.basePath
        guard let subPaths = try? basePath?.contentsOfDirectory() else {
            XCTAssertTrue(true)
            return
        }
        let resource = ClippingDocResource()
        for path in subPaths {
            XCTAssertTrue(path.contains(resource.version))
        }
    }
}
