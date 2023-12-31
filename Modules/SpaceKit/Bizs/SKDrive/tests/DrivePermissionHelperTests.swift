//
//  DrivePermissionHelperTests.swift
//  SpaceDemoTests
//
//  Created by bupozhuang on 2022/3/4.
//  Copyright © 2022 Bytedance. All rights reserved.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
@testable import SKDrive
import SpaceInterface
import SKInfra

class DrivePermissionHelperTests: XCTestCase {
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        print("xxxx - setup")
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        print("xxxx - tearDown")
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }

    func testOwerPermission() {
        stubNet(userPermJson: "DriveUserPermissionOwner.json",
                publicPermJson: "DrivePublicPermissionOwner.json")
        
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        let expect = expectation(description: "test fetch permission")
        sut.fetchAllPermission(completion: { model in
            XCTAssertNil(model.error)
            XCTAssertTrue(model.permissionStatusCode?.rawValue == 0)
            XCTAssertTrue(model.userPermissions?.isOwner == true)
            XCTAssertTrue(model.userPermissions?.canCopy() == true)
            XCTAssertTrue(model.userPermissions?.canEdit() == true)
            XCTAssertTrue(model.userPermissions?.canComment() == true)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(sut.canExport)
        XCTAssertTrue(sut.isReadable)
        XCTAssertTrue(sut.canComment)
        XCTAssertTrue(sut.isEditable)
        XCTAssertTrue(sut.canCopy)
    }
    
    func testDeletedPermission() {
        stubNet(userPermJson: "DriveUserPermissionDeleted.json",
                publicPermJson: "DrivePublicPermissionDeleted.json")
        
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        let expect = expectation(description: "test fetch permission")
        sut.fetchAllPermission(completion: { model in
            let docsError = model.error as? DocsNetworkError
            XCTAssertTrue(docsError?.code == .entityDeleted)
            XCTAssertNotNil(model.error)
            XCTAssertTrue(model.permissionStatusCode?.rawValue == 0)
            XCTAssertTrue(model.userPermissions?.canCopy() == false)
            XCTAssertTrue(model.userPermissions?.canEdit() == false)
            XCTAssertTrue(model.userPermissions?.canComment() == false)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(!sut.canExport)
        XCTAssertTrue(!sut.isReadable)
        XCTAssertTrue(!sut.canComment)
        XCTAssertTrue(!sut.isEditable)
    }
    
    func testCanReadPermission() {
        stubNet(userPermJson: "DriveUserPermissionCanRead.json",
                publicPermJson: "DrivePublicPermissionCanRead.json")
        
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        let expect = expectation(description: "test fetch permission")
        sut.fetchAllPermission(completion: { model in
            XCTAssertNil(model.error)
            XCTAssertTrue(model.permissionStatusCode?.rawValue == 0)
            XCTAssertTrue(model.userPermissions?.canCopy() == true)
            XCTAssertTrue(model.userPermissions?.canEdit() == false)
            XCTAssertTrue(model.userPermissions?.canComment() == true)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(sut.canExport)
        XCTAssertTrue(sut.isReadable)
        XCTAssertTrue(sut.canComment)
        XCTAssertTrue(!sut.isEditable)
    }
    
    func testCanPreviewPermission() {
        stubNet(userPermJson: "DriveUserPermissionCanPreview.json",
                publicPermJson: "DrivePublicPermissionCanRead.json")
        let expect = expectation(description: "test fetch permission")
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        sut.fetchAllPermission(completion: { model in
            sut.handlePermission(model)
            XCTAssertNotNil(model.error)
            XCTAssertTrue(model.permissionStatusCode?.rawValue == 0)
            XCTAssertTrue(model.userPermissions?.canPerceive() == true)
            XCTAssertFalse(model.userPermissions?.canPreview() == true)
            XCTAssertFalse(model.userPermissions?.canView() == true)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNoPermission() {
        stubNet(userPermJson: "DriveUserPermissionNoPerm.json",
                publicPermJson: "DrivePublicPermisionNoPerm.json")
        
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        let expect = expectation(description: "test fetch permission")
        sut.fetchAllPermission(completion: { model in
            let docsError = model.error as? DocsNetworkError
            XCTAssertTrue(docsError?.code == DocsNetworkError.Code.forbidden)
            XCTAssertTrue(model.permissionStatusCode?.rawValue == 0)
            XCTAssertTrue(model.userPermissions?.canCopy() == false)
            XCTAssertTrue(model.userPermissions?.canEdit() == false)
            XCTAssertTrue(model.userPermissions?.canComment() == false)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(!sut.canExport)
        XCTAssertTrue(!sut.isReadable)
        XCTAssertTrue(!sut.canComment)
        XCTAssertTrue(!sut.isEditable)
    }
    
    func testPasswordPermission() {
        stubNet(userPermJson: "DriveUserPermissionNeedPass.json",
                publicPermJson: "DrivePublicPermissionNeedPass.json")
        
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        let expect = expectation(description: "test fetch permission")
        sut.fetchAllPermission(completion: { model in
            let docsError = model.error as? DocsNetworkError
            XCTAssertTrue(docsError?.code == .forbidden)
            XCTAssertTrue(model.permissionStatusCode?.rawValue == 10016)
            XCTAssertTrue(model.userPermissions?.canCopy() == false)
            XCTAssertTrue(model.userPermissions?.canEdit() == false)
            XCTAssertTrue(model.userPermissions?.canComment() == false)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(!sut.canExport)
        XCTAssertTrue(!sut.isReadable)
        XCTAssertTrue(!sut.canComment)
        XCTAssertTrue(!sut.isEditable)
    }
    
    func testMonitorOwnerPermission() {
        stubNet(userPermJson: "DriveUserPermissionOwner.json",
                publicPermJson: "DrivePublicPermissionOwner.json")
        
        let sut = DrivePermissionHelper(fileToken: "testToken", type: DocsType.file,
                                        permissionService: MockUserPermissionService())
        let expect = expectation(description: "test fetch permission")
        expect.expectedFulfillmentCount = 2
    
        var didStart: Bool = false
        var permissionInfo: DrivePermissionInfo!
        var didFailed: Bool = false
        sut.startMonitorPermission(startFetch: {
            didStart = true
            expect.fulfill()
        }, permissionChanged: { info in
            permissionInfo = info
            expect.fulfill()
        }) { _ in
            didFailed = true
        }
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(didStart)
        XCTAssertTrue(!didFailed)
        XCTAssertTrue(permissionInfo.canExport)
        XCTAssertTrue(permissionInfo.canComment)
        XCTAssertTrue(permissionInfo.canCopy)
        XCTAssertTrue(permissionInfo.isEditable)
        XCTAssertTrue(permissionInfo.isReadable)
    }

    private func stubNet(userPermJson: String, publicPermJson: String) {
        // stub user permission
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissonDocumentActionsState)
            print("xxxx - \(OpenAPI.APIPath.suitePermissonDocumentActionsState) contain:\(contain)")
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile(userPermJson, type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        // stub public permission
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionPublicV4)
            print("xxxx - \(OpenAPI.APIPath.suitePermissionPublicV4) contain:\(contain)")

            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile(publicPermJson, type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }
}
