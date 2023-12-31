//
//  DriveThirdPartyFilePermissionTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/28.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
@testable import SKDrive
import SKInfra

class DriveThirdPartyFilePermissionTests: XCTestCase {
    var netStatus: MockNetworkStatusMonitor!
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    
    func testStartMonitorPermission() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.attachmentPermission)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveThirdPermission.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        netStatus = MockNetworkStatusMonitor()
        netStatus.isReachable = true
        let sut = DriveThirdPartyFilePermission(with: "token",
                                                authExtra: nil,
                                                mountPoint: "mountpoint",
                                                permissionService: MockUserPermissionService(),
                                                networkMonitor: netStatus)
        let expect = expectation(description: "fetch permission")
        sut.startMonitorPermission(startFetch: {}, permissionChanged: { info in
            XCTAssertTrue(info.canCopy)
            XCTAssertTrue(info.canExport)
            XCTAssertTrue(info.isReadable)
            expect.fulfill()
        }) { _ in
            XCTFail("fetch permission failed")
        }
        
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testStartMonitorPermissionWithNetworkChange() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.attachmentPermission)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveThirdPermission.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        netStatus = MockNetworkStatusMonitor()
        netStatus.isReachable = false
        let sut = DriveThirdPartyFilePermission(with: "token",
                                                authExtra: nil,
                                                mountPoint: "mountpoint",
                                                permissionService: MockUserPermissionService(),
                                                networkMonitor: netStatus)
        let expect = expectation(description: "fetch permission")
        var changeCount = 0
        sut.startMonitorPermission(startFetch: {}, permissionChanged: { _ in
            changeCount += 1
            expect.fulfill()
        }) { _ in
            XCTFail("fetch permission failed")
        }
        netStatus.changeTo(networkType: .wifi, reachable: true)
        waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssertTrue(changeCount == 1)
    }
}
