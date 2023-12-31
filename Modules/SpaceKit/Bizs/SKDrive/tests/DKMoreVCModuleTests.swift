//
//  DKMoreVCModule.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by tanyunpeng on 2022/10/9.
//  


import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import SKInfra
@testable import SKDrive


class DKMoreVCModuleTests: XCTestCase {
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
    var moreVCModule: DKMoreVCModule!
    
    func testShowPresentMoreVC() {
        let expect = expectation(description: "did present")
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        moreVCModule = DKMoreVCModule(hostModule: hostModule, windowSizeDependency: uiDependency, navigator: navigator)
        _ = moreVCModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showMoreVC)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }
    
    func testShowPopoverMoreVC() {
        let expect = expectation(description: "did popover")
        uiDependency = MockDependency()
        uiDependency.isMyWindowRegularSizeVaule = true
        let hostModuleVC = MockDKHostSubModule()
        hostModuleVC.complete = {
            expect.fulfill()
        }
        hostModule = MockHostModule(hostController: hostModuleVC, windowSizeDependency: uiDependency, permissionMask: UserPermissionMask(rawValue: 1))
        let dependcy = MockShareVCModuleDependencyImpl()
        dependcy.isPad = true
        moreVCModule = DKMoreVCModule(hostModule: hostModule, windowSizeDependency: uiDependency, dependency: dependcy)
        _ = moreVCModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.showMoreVC)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(hostModuleVC.didPopover)
    }
    
    func testImportToOnlneFileEnabled() {
            uiDependency = MockDependency()
            hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
            let navigator = MockNavigator()
            moreVCModule = DKMoreVCModule(hostModule: hostModule, windowSizeDependency: uiDependency, navigator: navigator)
            XCTAssertFalse(moreVCModule.importToOnlneFileEnabled())
        }
        
    func testPushConvertFileVC() {
        let expect = expectation(description: "did present")
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        moreVCModule = DKMoreVCModule(hostModule: hostModule, windowSizeDependency: uiDependency, navigator: navigator)
        moreVCModule.pushConvertFileVC(actionSource: .attachmentMore, previewFrom: .docsList)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPush)
    }
}
