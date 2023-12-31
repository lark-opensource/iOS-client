//
//  DriveCopyManangerTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/9/25.
//

import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import SpaceInterface
@testable import SKDrive

final class DriveCopyManangerTests: XCTestCase {
    let bag = DisposeBag()
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // 开启复制保护，有编辑权限，没有有copy权限，返回（token, true）
    func testNeedSecurityCopyAndCopyEnableWithCanEditCantCopySecurityCopyEnable() {
        let canEdit = BehaviorRelay<Bool>(value: true)
        let canCopy = BehaviorRelay<Bool>(value: false)
        MockDLPManager.statu = .Safe
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.needSecurityCopyAndCopyEnable(token: "token",
                                                       canEdity: canEdit,
                                                       canCopy: canCopy,
                                                       enableSecurityCopy: true)
        let expect = expectation(description: "wait for result")
        result.drive(onNext: { (token, canCopy) in
            XCTAssertNotNil(token)
            XCTAssertTrue(canCopy)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    // 关闭复制保护，有编辑权限，没有有copy权限，返回（nil, false）
    func testNeedSecurityCopyAndCopyEnableWithCanEditCantCopySecurityCopyDisable() {
        let canEdit = BehaviorRelay<Bool>(value: true)
        let canCopy = BehaviorRelay<Bool>(value: false)
        MockDLPManager.statu = .Safe
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.needSecurityCopyAndCopyEnable(token: "token",
                                                       canEdity: canEdit,
                                                       canCopy: canCopy,
                                                       enableSecurityCopy: false)
        let expect = expectation(description: "wait for result")
        result.drive(onNext: { (token, canCopy) in
            XCTAssertNil(token)
            XCTAssertFalse(canCopy)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    // 关闭复制保护，有编辑权限，有copy权限, dlp false，返回（nil, false）
    func testNeedSecurityCopyAndCopyEnableWithCanEditCantCopySecurityCopyDisableDLPFailed() {
        let canEdit = BehaviorRelay<Bool>(value: true)
        let canCopy = BehaviorRelay<Bool>(value: true)
        MockDLPManager.statu = .Sensitive
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.needSecurityCopyAndCopyEnable(token: "token",
                                                       canEdity: canEdit,
                                                       canCopy: canCopy,
                                                       enableSecurityCopy: false)
        let expect = expectation(description: "wait for result")
        result.drive(onNext: { (token, canCopy) in
            XCTAssertNil(token)
            XCTAssertFalse(canCopy)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    // 关闭复制保护，有编辑权限，有copy权限, adminCanCopy false，返回（nil, false）
    func testNeedSecurityCopyAndCopyEnableWithCanEditCantCopySecurityCopyDisableAdminFailed() {
        let canEdit = BehaviorRelay<Bool>(value: true)
        let canCopy = BehaviorRelay<Bool>(value: true)
        MockAdminManager.canCopy = false
        MockDLPManager.statu = .Safe
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.needSecurityCopyAndCopyEnable(token: "token",
                                                       canEdity: canEdit,
                                                       canCopy: canCopy,
                                                       enableSecurityCopy: false)
        let expect = expectation(description: "wait for result")
        result.drive(onNext: { (token, canCopy) in
            XCTAssertNil(token)
            XCTAssertTrue(canCopy)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    // 关闭复制保护，有编辑权限，有copy权限, adminCanCopy false，返回（nil, false）
    func testNeedSecurityCopyAndCopyEnableWithCanEditCantCopySecurityCopyDisableAdminFailedIm() {
        let canEdit = BehaviorRelay<Bool>(value: true)
        let canCopy = BehaviorRelay<Bool>(value: true)
        MockAdminManager.canCopy = false
        MockDLPManager.statu = .Safe
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: .im,
                                    permissionService: MockUserPermissionService())
        let result = sut.needSecurityCopyAndCopyEnable(token: "token",
                                                       canEdity: canEdit,
                                                       canCopy: canCopy,
                                                       enableSecurityCopy: false)
        let expect = expectation(description: "wait for result")
        result.drive(onNext: { (token, canCopy) in
            XCTAssertNil(token)
            XCTAssertFalse(canCopy)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    // 开启复制保护， 可编辑不可复制，不弹提示 （false, nil, nil）
    func testNeedInterceptCopyWithSecurityEnableCanEditCantCopy() {
        MockDLPManager.statu = .Safe
        MockAdminManager.canCopy = true
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.interceptCopy(token: "token",
                                       canEdit: true,
                                       canCopy: false,
                                       enableSecurityCopy: true)
        XCTAssertFalse(result.needInterceptCopy)
        XCTAssertNil(result.reason)
        XCTAssertNil(result.type)
    }
    
    // 开启复制保护， 可编辑可复制，不弹提示 （false, nil, nil）
    func testNeedInterceptCopyWithSecurityDisableCanEditCanCopy() {
        MockDLPManager.statu = .Safe
        MockAdminManager.canCopy = true
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.interceptCopy(token: "token",
                                       canEdit: true,
                                       canCopy: true,
                                       enableSecurityCopy: true)
        XCTAssertFalse(result.needInterceptCopy)
        XCTAssertNil(result.reason)
        XCTAssertNil(result.type)
    }
    
    // 关闭复制保护， 可编辑不可复制，弹提示 （true, Doc_Doc_CopyFailed, failure）
    func testNeedInterceptCopyWithSecurityDisableCanEditCantCopy() {
        MockDLPManager.statu = .Safe
        MockAdminManager.canCopy = true
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self, previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.interceptCopy(token: "token",
                                       canEdit: true,
                                       canCopy: false,
                                       enableSecurityCopy: false)
        XCTAssertTrue(result.needInterceptCopy)
        XCTAssertNotNil(result.reason)
        XCTAssertNotNil(result.type)
    }
    
    // 关闭复制保护， 可编辑可复制，admin失败，弹提示 （true, CreationMobile_ECM_AdminDisableToast, failure）
    func testNeedInterceptCopyWithSecurityDisableCanEditCantCopyAdminFailed() {
        MockDLPManager.statu = .Safe
        MockAdminManager.canCopy = false
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self,
                                    permissionService: MockUserPermissionService())
        let result = sut.interceptCopy(token: "token",
                                       canEdit: true,
                                       canCopy: true,
                                       enableSecurityCopy: false)
        XCTAssertFalse(result.needInterceptCopy)
        XCTAssertNil(result.reason)
        XCTAssertNil(result.type)
    }
    
    // 关闭复制保护， 可编辑可复制，dlp失败，弹提示 （true, reason, failure）
    func testNeedInterceptCopyWithSecurityDisableCanEditCantCopyDLPFailed() {
        MockDLPManager.statu = .Sensitive
        MockAdminManager.canCopy = true
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self,
                                    previewFrom: nil,
                                    permissionService: MockUserPermissionService())
        let result = sut.interceptCopy(token: "token",
                                       canEdit: true,
                                       canCopy: true,
                                       enableSecurityCopy: false)
        XCTAssertTrue(result.needInterceptCopy)
        XCTAssertNotNil(result.reason)
        XCTAssertNotNil(result.type)
    }
    
    // 关闭复制保护， 可编辑可复制，dlp失败，弹提示 （true, reason, failure）
    func testNeedInterceptCopyWithSecurityDisableCanEditCantCopyDLPFailedIm() {
        MockDLPManager.statu = .Sensitive
        MockAdminManager.canCopy = true
        let sut = DriveCopyMananger(adminManagerType: MockAdminManager.self,
                                    dlpManagerType: MockDLPManager.self,
                                    previewFrom: .im,
                                    permissionService: MockUserPermissionService())
        let result = sut.interceptCopy(token: "token",
                                       canEdit: true,
                                       canCopy: true,
                                       enableSecurityCopy: false)
        XCTAssertTrue(result.needInterceptCopy)
        XCTAssertNil(result.reason)
        XCTAssertNil(result.type)
    }
}

class MockDLPManager: DLPManagerBridge {
    static var statu: DlpCheckStatus = .Safe
    static func status(with token: String, type: DocsType, action: DlpCheckAction) -> DlpCheckStatus {
        return statu
    }
}

class MockAdminManager: AdminManagerBridge {
    static var canCopy = true
    static func adminCanCopy(docType: DocsType?, token: String?) -> Bool {
        return canCopy
    }
}
