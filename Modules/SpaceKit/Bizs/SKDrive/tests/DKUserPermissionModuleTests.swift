//
//  DKUserPermissionModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/5/5.
//

import XCTest
import SKFoundation
@testable import SKDrive
import SKCommon

class DKUserPermissionModuleTests: XCTestCase {
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    var userPermissionModule: DKUserPermissionModule!
    var hostModule: DKHostModuleType!
    
    func testHandleApplyEditPermission() {
        let expect = expectation(description: "did push")
        let navigator = MockNavigator()

        hostModule = MockHostModule()
        navigator.complete = {
            expect.fulfill()
        }
        userPermissionModule = DKUserPermissionModule(hostModule: hostModule, navigator: navigator)
        _ = userPermissionModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.applyEditPermission(scene: .userPermission))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }

}
