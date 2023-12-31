//
//  DKFeedModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by tanyunpeng on 2022/10/9.
//  


import XCTest
import SKFoundation
@testable import SKDrive

class DKFeedModuleTests: XCTestCase {
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }
    
    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    var hostModule: DKHostModuleType!

    var feedModule: DKFeedModule!
    
    func testShowFeedVC() {
        let expect = expectation(description: "did present")
        let hostModuleVC = MockDKHostSubModule()
        hostModuleVC.complete = {
            expect.fulfill()
        }
        hostModule = MockHostModule(hostController: hostModuleVC)
        feedModule = DKFeedModule(hostModule: hostModule)
        _ = feedModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showFeed)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(hostModuleVC.didPresent)
    }

}
