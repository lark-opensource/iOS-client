//
//  DriveAttachmentPermissionHelperTests.swift
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
import SKInfra

class DriveAttachmentPermissionHelperTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // 没有设置baseURL，网路请求会中assert
        print("xxxx - setup")
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        print("xxxx - tearDown")
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }

    func testStartMonitorOnlyUserPermission() {
        stubNet(userPermJson: "DriveUserPermissionOwner.json")
        let sut = DriveAttachmentPermissionHelper(fileToken: "testtoken", type: .file, permissionService: MockUserPermissionService())
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
    
    private func stubNet(userPermJson: String) {
        // stub user permission
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissonDocumentActionsState)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile(userPermJson, type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }
}
