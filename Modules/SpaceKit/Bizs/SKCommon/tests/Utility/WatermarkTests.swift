//
//  WatermarkTests.swift
//  SpaceDemoTests
//
//  Created by lijuyou on 2022/3/7.
//  Copyright © 2022 Bytedance.All rights reserved.


import XCTest
@testable import SKCommon
import OHHTTPStubs
import SKFoundation
import SpaceInterface
import SKInfra

class WatermarkTests: XCTestCase {

    private var requestExpectation: XCTestExpectation!
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        WatermarkManager.shared.addListener(self)
    }
    
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        WatermarkManager.shared.removeListener(self)
        AssertionConfigForTest.reset()
    }
        
    func testRequestWatermarkInfo() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.API.getDocsConfig)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("WatermarkInfo.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        
        requestExpectation = expectation(description: "Request WatermarkInfo")
        
        let key = WatermarkKey(objToken: "doxcnVEZ3D6QU2Urp3q4uRJ2vIf", type: DocsType.docX.rawValue)
        
        var isShow = WatermarkManager.shared.shouldShowWatermarkFor(key)
        // TODO: lijuyou 单测失败看看
        XCTAssertTrue(isShow)
        
        WatermarkManager.shared.requestWatermarkInfo(key)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        
        isShow = WatermarkManager.shared.shouldShowWatermarkFor(key)
        XCTAssertTrue(isShow == false)
    }
}

extension WatermarkTests: WatermarkUpdateListener {
    func didUpdateWatermarkEnable() {
        print("xxxx -- after assert fulfill")
        requestExpectation.fulfill()
    }
}
