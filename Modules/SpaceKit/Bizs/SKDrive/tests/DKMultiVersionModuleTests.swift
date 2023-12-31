//
//  DKMultiVersionModuleTests.swift
//  SKDrive-Unit-Tests
//
//  Created by tanyunpeng on 2022/12/20.
//  


import XCTest
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra
@testable import SKDrive

class DKMultiVersionModuleTests: XCTestCase {

    override func setUp() {
        DocsContainer.shared.register(SKDriveDependency.self, factory: { (_) -> SKDriveDependency in
            return MockSKDriveDependencyImpl()
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(DriveSDK.self, factory: { (_) -> DriveSDK in
            return MockDriveSDKImpl()
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
    var multiVersionVCModule: DKMultiVersionModule!
    
    func testHandleSameVersionDeleted() {
        let expect = expectation(description: "did present")
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        multiVersionVCModule = DKMultiVersionModule(hostModule: hostModule, navigator: navigator)
        _ = multiVersionVCModule.bindHostModule()
        multiVersionVCModule.didReceiveVersion(version: "123", type: .versionDidDelete)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
        
    }
    
    func testHandleNotSameVersionUpdated() {
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        multiVersionVCModule = DKMultiVersionModule(hostModule: hostModule, navigator: navigator)
        _ = multiVersionVCModule.bindHostModule()
        multiVersionVCModule.didReceiveVersion(version: "456", type: .versionDidUpdate)

        XCTAssertFalse(navigator.didPresent)
    }
    
    func testReserveCurrentVersion() {
        let expect = expectation(description: "did present")
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        multiVersionVCModule = DKMultiVersionModule(hostModule: hostModule, navigator: navigator)
        multiVersionVCModule.reserveCurrentVersion()
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPush)
    }
    
}
