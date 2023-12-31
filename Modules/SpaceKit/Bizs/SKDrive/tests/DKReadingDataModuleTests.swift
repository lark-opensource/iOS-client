//
//  DKReadingDataModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by tanyunpeng on 2022/10/10.
//  


import XCTest
import SKFoundation
import SKCommon
@testable import SKDrive

class DKReadingDataModuleTests: XCTestCase {
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }
    
    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    var hostModule: DKHostModuleType!
    var uiDependency: MockDependency!
    var readingDataModuleVC: DKReadingDataModule!
    
    func testShowPresentReadingDataVC() {
        let expect = expectation(description: "did present  ")
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        let status = MockNetworkStatusMonitor()
        readingDataModuleVC = DKReadingDataModule(hostModule: hostModule, networkStauts: status, navigator: navigator)
        _ = readingDataModuleVC.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.openReadingData)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }

}
