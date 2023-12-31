//
//  DocumentUserPermissionAPITests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/20.
//

import Foundation
import XCTest
@testable import SKPermission
import SKFoundation
import SpaceInterface
import SwiftyJSON
import OHHTTPStubs
import RxSwift

final class DocumentUserPermissionAPITests: XCTestCase {

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
        let objType = DocsType.docX
        let parentMeta = SpaceMeta(objToken: "PARENT_TOKEN", objType: .bitable)
        let cache = DocumentUserPermissionCache(userID: "MOCK_USERID")
        let api = DocumentUserPermissionAPI(meta: SpaceMeta(objToken: token, objType: objType),
                                            parentMeta: parentMeta,
                                            sessionID: "MOCK_SESSION_ID", cache: cache)
        XCTAssertEqual(api.objType, objType)
        XCTAssertEqual(api.objToken, token)
        XCTAssertEqual(api.parentMeta, SpaceMeta(objToken: "PARENT_TOKEN", objType: .bitable))
        XCTAssertEqual(api.entity, .ccm(token: token, type: objType, parentMeta: parentMeta))

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getDocumentUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.Document.requirePassword)
            let response = HTTPStubsResponse(data: data ?? Data(),
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["token"] as? String, token)
            XCTAssertEqual(data["type"] as? Int, objType.rawValue)
            XCTAssertEqual(data["actions"] as? [String], DocumentUserPermission.Action.allCases.map(\.rawValue))
            if let relation = data["relation"] as? [String: Any] {
                XCTAssertEqual(relation["entity_token"] as? String, "PARENT_TOKEN")
                XCTAssertEqual(relation["entity_type"] as? Int, DocsType.bitable.rawValue)
                XCTAssertEqual(relation["relation_type"] as? Int, 1)
            } else {
                XCTFail("failed to get relation info from request body")
            }
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
                XCTAssertNotNil(applyUserInfo)
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
        let objType = DocsType.docX
        let cache = DocumentUserPermissionCache(userID: "MOCK_USERID")
        let api = DocumentUserPermissionAPI(meta: SpaceMeta(objToken: token, objType: objType),
                                            parentMeta: nil,
                                            sessionID: "MOCK_SESSION_ID", cache: cache)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getDocumentUserPermission)
        } response: { request in
            let data = try? Resource.loadFile(path: Resource.JSON.UserPermission.Document.read)
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
                permission.assertAllow(action: .applyEmbed)
                permission.assertAllow(action: .collect)
                permission.assertAllow(action: .comment)
                permission.assertAllow(action: .copy)
                permission.assertAllow(action: .download)
                permission.assertAllow(action: .duplicate)
                permission.assertAllow(action: .export)
                permission.assertAllow(action: .inviteContainerCanView)
                permission.assertAllow(action: .manageContainerCollaborator)
                permission.assertAllow(action: .perceive)
                permission.assertAllow(action: .preview)
                permission.assertAllow(action: .print)
                permission.assertAllow(action: .showCollaboratorInfo)
                permission.assertAllow(action: .view)
                permission.assertAllow(action: .visitSecretLevel)

                permission.assertForbidden(action: .createSubNode)
                permission.assertForbidden(action: .beMoved)
                permission.assertForbidden(action: .edit)
                permission.assertForbidden(action: .inviteContainerCanEdit)
                permission.assertForbidden(action: .inviteContainerFullAccess)
                permission.assertForbidden(action: .inviteSinglePageCanEdit)
                permission.assertForbidden(action: .inviteSinglePageCanView)
                permission.assertForbidden(action: .inviteSinglePageFullAccess)
                permission.assertForbidden(action: .manageContainerMeta)
                permission.assertForbidden(action: .manageSinglePageCollaborator)
                permission.assertForbidden(action: .manageSinglePageMeta)
                permission.assertForbidden(action: .manageVersion)
                permission.assertForbidden(action: .modifySecretLevel)
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

private extension DocumentUserPermission {
    func assertAllow(action: Action, reason: AuthReason? = .collaborator, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(check(action: action), file: file, line: line)
        XCTAssertEqual(authReason(for: action), reason, file: file, line: line)
    }

    func assertForbidden(action: Action, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(check(action: action), file: file, line: line)
        XCTAssertNil(authReason(for: action), file: file, line: line)
    }
}
