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

final class FolderUserPermissionAPITests: XCTestCase {

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

    func testNoPermission() {
        let token = "MOCK_TOKEN"
        let api = FolderUserPermissionAPI(folderToken: token,
                                          sessionID: "MOCK_SESSION_ID")
        XCTAssertEqual(api.folderToken, token)
        XCTAssertEqual(api.entity, .ccm(token: token, type: .folder))

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getFolderUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.Folder.requirePassword)
            let response = HTTPStubsResponse(data: data ?? Data(),
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["token"] as? String, token)
            XCTAssertEqual(data["actions"] as? [String], [])
            return response
        }

        let expect = expectation(description: "update user permission require password")
        api.updateUserPermission()
            .subscribe { result in
                guard case let .noPermission(_, statusCode, applyUserInfo) = result else {
                    XCTFail("un-expected success found")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(statusCode, .passwordRequired)
                // 不细看内容了，内容解析单独测
                XCTAssertNil(applyUserInfo)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)
    }

    func testUpdateUserPermission() {
        let token = "MOCK_TOKEN"
        let api = FolderUserPermissionAPI(folderToken: token,
                                          sessionID: "MOCK_SESSION_ID")

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getFolderUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.Folder.read)
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
                // 这里对照 json 数据检查
                permission.assertAllow(action: .collect)
                permission.assertAllow(action: .download)
                permission.assertAllow(action: .inviteCanView)
                permission.assertAllow(action: .manageCollaborator)
                permission.assertAllow(action: .view)

                permission.assertForbidden(action: .beMoved)
                permission.assertForbidden(action: .createSubNode)
                permission.assertForbidden(action: .edit)
                permission.assertForbidden(action: .inviteCanEdit)
                permission.assertForbidden(action: .inviteFullAccess)
                permission.assertForbidden(action: .manageMeta)
                permission.assertForbidden(action: .moveFrom)
                permission.assertForbidden(action: .moveTo)
                permission.assertForbidden(action: .operateEntity)

                XCTAssertFalse(permission.isOwner)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 1)
    }
}

private extension FolderUserPermission {
    func assertAllow(action: Action) {
        XCTAssertTrue(check(action: action))
    }

    func assertForbidden(action: Action) {
        XCTAssertFalse(check(action: action))
    }
}
