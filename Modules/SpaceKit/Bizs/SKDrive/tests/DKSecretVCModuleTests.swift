//
//  DKSecretVCModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by tanyunpeng on 2022/10/10.
//  


import XCTest
import SKFoundation
import SKCommon
import SwiftyJSON
@testable import SKDrive
import SKInfra

class DKSecretVCModuleTests: XCTestCase {
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        DocsContainer.shared.register(SKDriveDependency.self, factory: { (_) -> SKDriveDependency in
            return MockSKDriveDependencyImpl()
        }).inObjectScope(.container)
        super.setUp()
    }
    
    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    var hostModule: DKHostModuleType!
    var uiDependency: MockDependency!
    var secretVCModule: DKSecretSettingVCModule!
    
    func testShowPresentPadSecretVC() {
        let expect = expectation(description: "did present pad ")
        uiDependency = MockDependency()
        uiDependency.isMyWindowRegularSizeVaule = true
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        let dependcy = MockShareVCModuleDependencyImpl()
        dependcy.isPad = true
        secretVCModule = DKSecretSettingVCModule(hostModule: hostModule, windowSizeDependency: uiDependency, dependency: dependcy, navigator: navigator)
        _ = secretVCModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showSecretVC)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }
    
    func testShowPresentNotPadSecretVC() {
        let expect = expectation(description: "did present not pad")
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        let dependcy = MockShareVCModuleDependencyImpl()
        secretVCModule = DKSecretSettingVCModule(hostModule: hostModule, windowSizeDependency: uiDependency, dependency: dependcy, navigator: navigator)
        _ = secretVCModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showSecretVC)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }
    
}
