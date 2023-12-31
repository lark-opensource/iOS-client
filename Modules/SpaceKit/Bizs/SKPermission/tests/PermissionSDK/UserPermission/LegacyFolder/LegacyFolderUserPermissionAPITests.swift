//
//  FolderUserPermissionAPITests.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/23.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import SpaceInterface
import SwiftyJSON
import OHHTTPStubs
import RxSwift

final class LegacyFolderUserPermissionAPITests: XCTestCase {

    private var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()
    }

    func testPersonalPermission() {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .personal)
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getLegacyFolderUserPermission)
        } response: { request in
            XCTFail("personal folder should not initiate network request")
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.LegacyFolder.noPermission)
            let response = HTTPStubsResponse(data: data ?? Data(),
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        let expect = expectation(description: "test update personal folder permission")
        let api = LegacyFolderUserPermissionAPI(userID: "MOCK_USER_ID", folderInfo: folderInfo,
                                                sessionID: "MOCK_SESSION_ID")
        api.updateUserPermission().subscribe { result in
            guard case let .success(permission) = result else {
                XCTFail("un-expected result found: \(result)")
                expect.fulfill()
                return
            }
            XCTAssertEqual(permission.role, .editor)
            XCTAssertTrue(permission.isOwner)
            XCTAssertEqual(permission.folderInfo, folderInfo)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testNoPermission() {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "MOCK_SPACE_ID", isRoot: true, ownerID: nil))
        let api = LegacyFolderUserPermissionAPI(userID: "MOCK_USER_ID", folderInfo: folderInfo,
                                                sessionID: "MOCK_SESSION_ID")
        XCTAssertEqual(api.entity, .ccm(token: folderInfo.token, type: .folder))

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getLegacyFolderUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.LegacyFolder.noPermission)
            let response = HTTPStubsResponse(data: data ?? Data(),
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["space_id"], "MOCK_SPACE_ID")
            return response
        }

        let expect = expectation(description: "update user permission with no permission response")
        api.updateUserPermission()
            .subscribe { result in
                guard case let .success(permission) = result else {
                    XCTFail("un-expected result found: \(result)")
                    expect.fulfill()
                    return
                }
                XCTAssertFalse(permission.isOwner)
                XCTAssertEqual(permission.folderInfo, folderInfo)
                XCTAssertEqual(permission.role, .none)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)
    }

    func testUpdateReadUserPermission() {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "MOCK_SPACE_ID", isRoot: true, ownerID: "OTHER"))
        let api = LegacyFolderUserPermissionAPI(userID: "MOCK_USER_ID", folderInfo: folderInfo,
                                                sessionID: "MOCK_SESSION_ID")

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getLegacyFolderUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.LegacyFolder.read)
            let response = HTTPStubsResponse(data: data ?? Data(),
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "get user permission with read role")
        api.updateUserPermission()
            .subscribe { result in
                guard case let .success(permission) = result else {
                    XCTFail("un-expected no permisison found: \(result)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(permission.role, .viewer)
                XCTAssertFalse(permission.isOwner)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)
    }

    func testUpdateEditUserPermission() {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "MOCK_SPACE_ID", isRoot: true, ownerID: "MOCK_USER_ID"))
        let api = LegacyFolderUserPermissionAPI(userID: "MOCK_USER_ID", folderInfo: folderInfo,
                                                sessionID: "MOCK_SESSION_ID")

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getLegacyFolderUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.LegacyFolder.edit)
            let response = HTTPStubsResponse(data: data ?? Data(),
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "get user permission with read role")
        api.updateUserPermission()
            .subscribe { result in
                guard case let .success(permission) = result else {
                    XCTFail("un-expected no permisison found: \(result)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(permission.role, .editor)
                XCTAssertTrue(permission.isOwner)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)
    }

    func testUpdateUnknownUserPermission() {
        let folderInfo = SpaceV1FolderInfo(token: "MOCK_TOKEN", folderType: .share(spaceID: "MOCK_SPACE_ID", isRoot: true, ownerID: "MOCK_USER_ID"))
        let api = LegacyFolderUserPermissionAPI(userID: "MOCK_USER_ID", folderInfo: folderInfo,
                                                sessionID: "MOCK_SESSION_ID")

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getLegacyFolderUserPermission)
        } response: { request in
            let result = [
                "code": 0,
                "msg": "",
                "data": [
                    "perm": -1
                ]
            ]
            let response = HTTPStubsResponse(jsonObject: result,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        var expect = expectation(description: "get user permission with -1")
        api.updateUserPermission()
            .subscribe { result in
                guard case let .success(permission) = result else {
                    XCTFail("un-expected no permisison found: \(result)")
                    expect.fulfill()
                    return
                }
                XCTAssertTrue(permission.isOwner)
                XCTAssertEqual(permission.role, .none)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getLegacyFolderUserPermission)
        } response: { request in
            let result = [
                "code": 0,
                "msg": "",
                "data": [
                    "perm": 1024
                ]
            ]
            let response = HTTPStubsResponse(jsonObject: result,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        expect = expectation(description: "get user permission with 1024")
        api.updateUserPermission()
            .subscribe { result in
                guard case let .success(permission) = result else {
                    XCTFail("un-expected no permisison found: \(result)")
                    expect.fulfill()
                    return
                }
                XCTAssertTrue(permission.isOwner)
                XCTAssertEqual(permission.role, .editor)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)
    }
}
