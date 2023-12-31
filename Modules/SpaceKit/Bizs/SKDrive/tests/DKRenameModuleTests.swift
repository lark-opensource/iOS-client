//
//  DKRenameModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by tanyunpeng on 2022/10/10.
//  


import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
@testable import SKDrive
import SKInfra

class DKRenameModuleTests: XCTestCase {
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
    var renameModuleVC: DKRenameModule!
    var bag = DisposeBag()
    
    func testShowPresentMoreVC() {
        let expect = expectation(description: "did present")
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        renameModuleVC = DKRenameModule(hostModule: hostModule, navigator: navigator)
        _ = renameModuleVC.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.rename)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.didPresent)
    }
    
    func testSuccessModifyFileName() {
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1), isFromCardMode: true)
        let navigator = MockNavigator()

        renameModuleVC = DKRenameModule(hostModule: hostModule, navigator: navigator)
        renameModuleVC.modifyFileName("ohhh")
        XCTAssertTrue(renameModuleVC.fileInfo.name == "ohhh")
        XCTAssertTrue(renameModuleVC.docsInfo.title == "ohhh")
    }

    func testFailureModifyFileName() {
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1), isFromCardMode: false)
        let navigator = MockNavigator()

        renameModuleVC = DKRenameModule(hostModule: hostModule, navigator: navigator)
        renameModuleVC.modifyFileName("ohhh")
        XCTAssertTrue(renameModuleVC.fileInfo.name == "test.pptx")
    }

    func testNoChangeFileName() {
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1))
        let navigator = MockNavigator()
        renameModuleVC = DKRenameModule(hostModule: hostModule, navigator: navigator)
        renameModuleVC.preCheckModifyFileName(newTitle: "test.pptx")
        XCTAssertTrue(renameModuleVC.fileInfo.name == "test.pptx")
    }

    func testChangeFileName() {
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1), isFromCardMode: true)
        print("=====subModuleActionsCenter")
        let navigator = MockNavigator()
        renameModuleVC = DKRenameModule(hostModule: hostModule, navigator: navigator)
        renameModuleVC.preCheckModifyFileName(newTitle: "change.pptx")

        print("===== \(renameModuleVC.fileInfo.name)")
        XCTAssertTrue(renameModuleVC.fileInfo.name == "change.pptx")
    }

    func testChangeFileNameAndExtension() {
        uiDependency = MockDependency()
        hostModule = MockHostModule(permissionMask: UserPermissionMask(rawValue: 1), isFromCardMode: true)
        let navigator = MockNavigator()
        renameModuleVC = DKRenameModule(hostModule: hostModule, navigator: navigator)
        renameModuleVC.preCheckModifyFileName(newTitle: "change.mov")
        XCTAssertTrue(renameModuleVC.fileInfo.name == "test.pptx")
    }
    
}
