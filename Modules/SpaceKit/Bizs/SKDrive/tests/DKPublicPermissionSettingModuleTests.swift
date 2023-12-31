//
//  DKPublicPermissionSettingModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/4/26.
//

import XCTest
import SKFoundation
@testable import SKDrive

class DKPublicPermissionSettingModuleTests: XCTestCase {
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
    var publicPermissionSettingModule: DKPublicPermissionSettingModule!
    
    func testShowPushPublicPermissionSettingVC() {
        let expect = expectation(description: "did push")
        uiDependency = MockDependency()
        uiDependency.isMyWindowRegularSizeVaule = true        
        hostModule = MockHostModule(hostController: MockDKHostSubModule(), windowSizeDependency: uiDependency)

        let navigator = MockNavigator()

        navigator.complete = {
            expect.fulfill()
        }
        publicPermissionSettingModule = DKPublicPermissionSettingModule(hostModule: hostModule,
                                                                        windowSizeDependency: uiDependency,
                                                                        navigator: navigator)
        _ = publicPermissionSettingModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.publicPermissionSetting)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
        XCTAssertFalse(navigator.didPush)
    }
    
    func testShowPresentPublicPermissionSettingVC() {
        let expect = expectation(description: "did push")
        hostModule = MockHostModule()
        uiDependency = MockDependency()
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        publicPermissionSettingModule = DKPublicPermissionSettingModule(hostModule: hostModule,
                                                                        windowSizeDependency: uiDependency,
                                                                        navigator: navigator)

        _ = publicPermissionSettingModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.publicPermissionSetting)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPush)
        XCTAssertFalse(navigator.didPresent)
    }
}
