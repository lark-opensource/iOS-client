//
//  DKShareVCModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by tanyunpeng on 2022/5/9.
//

import XCTest
import SKFoundation
import SKCommon
@testable import SKDrive
import SKInfra

class DKShareVCModuleTests: XCTestCase {
    override func setUp() {
        DocsContainer.shared.register(SKDriveDependency.self, factory: { (_) -> SKDriveDependency in
            return MockSKDriveDependencyImpl()
        }).inObjectScope(.container)
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }
    
    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    var hostModule: DKHostModuleType!
    var uiDependency: MockDependency!
    var shareVCModule: DKShareVCModule!
    
    func testShowPresentShareVC() {
        let expect = expectation(description: "did present")
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        shareVCModule = DKShareVCModule(hostModule: hostModule, uiDependency: uiDependency, navigator: navigator)
        _ = shareVCModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showShareVC)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }

    
    func testShowPopoverShareVC() {
        let expect = expectation(description: "did popover")
        let hostModuleVC = MockDKHostSubModule()
        hostModuleVC.complete = {
            expect.fulfill()
        }
        uiDependency = MockDependency()
        uiDependency.isMyWindowRegularSizeVaule = true
        hostModule = MockHostModule(hostController: hostModuleVC, windowSizeDependency: uiDependency, permissionMask: UserPermissionMask(rawValue: 1))
        let dependcy = MockShareVCModuleDependencyImpl()
        dependcy.isPad = true
        shareVCModule = DKShareVCModule(hostModule: hostModule, uiDependency: uiDependency, dependency: dependcy)
        _ = shareVCModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showShareVC)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(hostModuleVC.didPopover)
    }

}

class MockShareVCModuleDependencyImpl: DKShareVCModuleDependency {
    var isPad = false
    var pad: Bool {
        return isPad
    }
}
