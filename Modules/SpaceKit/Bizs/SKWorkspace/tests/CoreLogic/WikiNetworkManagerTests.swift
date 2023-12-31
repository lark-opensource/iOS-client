//
//  WikiNetworkManagerTests.swift
//  SKWikiV2-Unit-Tests
//
//  Created by Weston Wu on 2022/11/22.
//

import XCTest
@testable import SKWorkspace
import SKFoundation
import SKCommon
import OHHTTPStubs
import SwiftyJSON
import RxSwift
import SpaceInterface
import SKInfra

final class WikiNetworkManagerTests: XCTestCase {
    private var bag = DisposeBag()
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        bag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }

    func testCopyWikiNode() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFile)
        } response: { request in
            guard let data = try? WikiTestUtil.loadFile(path: JSONPath.copyToWiki) else {
                XCTFail("failed to read response json data")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(data: data,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["time_zone"] as? String, TimeZone.current.identifier)
            XCTAssertEqual(data["space_id"] as? String, "MOCK_SOURCE_SPACE_ID")
            XCTAssertEqual(data["wiki_token"] as? String, "MOCK_SOURCE_WIKI_TOKEN")
            XCTAssertEqual(data["target_space_id"] as? String, "MOCK_TARGET_SPACE_ID")
            XCTAssertEqual(data["target_wiki_token"] as? String, "MOCK_TARGET_WIKI_TOKEN")
            XCTAssertEqual(data["title"] as? String, "MOCK_TITLE")
            XCTAssertEqual(data["async"] as? Bool, false)
            XCTAssertEqual(data["synergy_uuid"] as? String, "MOCK_UUID")
            return response
        }

        let expect = expectation(description: "copy docx wiki node")
        WikiNetworkManager.shared.copyWikiNode(sourceMeta: WikiMeta(wikiToken: "MOCK_SOURCE_WIKI_TOKEN", spaceID: "MOCK_SOURCE_SPACE_ID"),
                                               objType: .docX,
                                               targetMeta: WikiMeta(wikiToken: "MOCK_TARGET_WIKI_TOKEN", spaceID: "MOCK_TARGET_SPACE_ID"),
                                               title: "MOCK_TITLE",
                                               synergyUUID: "MOCK_UUID")
        .subscribe { node, url in
            XCTAssertEqual(node.parent, "MOCK_PARENT_TOKEN")
            XCTAssertEqual(node.sortID, 100)
            XCTAssertEqual(node.meta.wikiToken, "MOCK_WIKI_TOKEN")
            XCTAssertEqual(node.meta.spaceID, "MOCK_SPACE_ID")
            XCTAssertEqual(node.meta.nodeType, .normal)
            XCTAssertEqual(url, URL(string: "www.test.com/mock_url"))
            expect.fulfill()
        } onError: { error in
            XCTFail("unexpected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testAsyncCopyWikiNode() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFile)
        } response: { request in
            guard let data = try? WikiTestUtil.loadFile(path: JSONPath.copyToWiki) else {
                XCTFail("failed to read response json data")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(data: data,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["async"] as? Bool, true)
            return response
        }

        let expect = expectation(description: "copy sheet wiki node")
        WikiNetworkManager.shared.copyWikiNode(sourceMeta: WikiMeta(wikiToken: "MOCK_SOURCE_WIKI_TOKEN", spaceID: "MOCK_SOURCE_SPACE_ID"),
                                               objType: .sheet,
                                               targetMeta: WikiMeta(wikiToken: "MOCK_TARGET_WIKI_TOKEN", spaceID: "MOCK_TARGET_SPACE_ID"),
                                               title: "MOCK_TITLE",
                                               synergyUUID: "MOCK_UUID")
        .subscribe { _, _ in
            expect.fulfill()
        } onError: { error in
            XCTFail("unexpected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCopyWikiToSpace() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFileToSpace)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: [
                "code": 0,
                "msg": "Success",
                "data": [
                    "url": "www.test.com/mock_url",
                    "obj_token": "MOCK_FILE_TOKEN"
                ]
            ],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["time_zone"] as? String, TimeZone.current.identifier)
            XCTAssertEqual(data["space_id"] as? String, "MOCK_SOURCE_SPACE_ID")
            XCTAssertEqual(data["wiki_token"] as? String, "MOCK_SOURCE_WIKI_TOKEN")
            XCTAssertEqual(data["title"] as? String, "MOCK_TITLE")
            XCTAssertEqual(data["async"] as? Bool, false)
            XCTAssertEqual(data["parent_token"] as? String, "MOCK_FOLDER_TOKEN")

            return response
        }

        let expect = expectation(description: "copy docx wiki node to space")
        WikiNetworkManager.shared.copyWikiToSpace(sourceSpaceID: "MOCK_SOURCE_SPACE_ID",
                                                  sourceWikiToken: "MOCK_SOURCE_WIKI_TOKEN",
                                                  objType: .docX,
                                                  title: "MOCK_TITLE",
                                                  folderToken: "MOCK_FOLDER_TOKEN")
        .subscribe { token, url in
            XCTAssertEqual(token, "MOCK_FILE_TOKEN")
            XCTAssertEqual(url, URL(string: "www.test.com/mock_url"))
            expect.fulfill()
        } onError: { error in
            XCTFail("unexpected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testAsyncCopyWikiToSpace() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFileToSpace)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: [
                "code": 0,
                "msg": "Success",
                "data": [
                    "url": "www.test.com/mock_url",
                    "obj_token": "MOCK_FILE_TOKEN"
                ]
            ],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["async"] as? Bool, true)
            return response
        }

        let expect = expectation(description: "copy sheet wiki node to space")
        WikiNetworkManager.shared.copyWikiToSpace(sourceSpaceID: "MOCK_SOURCE_SPACE_ID",
                                                  sourceWikiToken: "MOCK_SOURCE_WIKI_TOKEN",
                                                  objType: .sheet,
                                                  title: "MOCK_TITLE",
                                                  folderToken: "MOCK_FOLDER_TOKEN")
        .subscribe { _, _ in
            expect.fulfill()
        } onError: { error in
            XCTFail("unexpected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCreateShortcut() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiAddRelationV2)
        } response: { request in
            guard let data = try? WikiTestUtil.loadFile(path: JSONPath.copyToWiki) else {
                XCTFail("failed to read response json data")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(data: data,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["time_zone"] as? String, TimeZone.current.identifier)
            XCTAssertEqual(data["space_id"] as? String, "MOCK_TARGET_SPACE_ID")
            XCTAssertEqual(data["parent_wiki_token"] as? String, "MOCK_TARGET_WIKI_TOKEN")
            XCTAssertEqual(data["node_type"] as? Int, 1)
            XCTAssertEqual(data["wiki_token"] as? String, "MOCK_SOURCE_WIKI_TOKEN")
            XCTAssertEqual(data["title"] as? String, "MOCK_TITLE")
            XCTAssertEqual(data["expand_shortcut"] as? Bool, true)
            XCTAssertEqual(data["synergy_uuid"] as? String, "MOCK_UUID")
            return response
        }

        let expect = expectation(description: "shortcut wiki node")
        WikiNetworkManager.shared.createShortcut(spaceID: "MOCK_TARGET_SPACE_ID",
                                                 parentWikiToken: "MOCK_TARGET_WIKI_TOKEN",
                                                 originWikiToken: "MOCK_SOURCE_WIKI_TOKEN",
                                                 title: "MOCK_TITLE",
                                                 synergyUUID: "MOCK_UUID")
        .subscribe { node in
            XCTAssertEqual(node.parent, "MOCK_PARENT_TOKEN")
            XCTAssertEqual(node.sortID, 100)
            XCTAssertEqual(node.meta.wikiToken, "MOCK_WIKI_TOKEN")
            XCTAssertEqual(node.meta.spaceID, "MOCK_SPACE_ID")
            XCTAssertEqual(node.meta.nodeType, .normal)
            expect.fulfill()
        } onError: { error in
            XCTFail("unexpected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testShortcutWikiToSpace() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.addShortCutTo)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: [
                "code": 0,
                "msg": "Success",
                "data": [
                    "entities": [
                        "nodes": [
                            "MOCK_SHORTCUT_TOKEN": [
                                "token": "MOCK_SHORTCUT_TOKEN"
                            ]
                        ]
                    ]
                ]
            ],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["parent_token"] as? String, "MOCK_FOLDER_TOKEN")
            if let entities = data["entities"] as? [[String: Any]] {
                XCTAssertEqual(entities.count, 1)
                let entity = entities.first
                XCTAssertEqual(entity?["obj_token"] as? String, "MOCK_OBJ_TOKEN")
                XCTAssertEqual(entity?["obj_type"] as? Int, DocsType.docX.rawValue)
            } else {
                XCTFail("parse entities failed")
            }
            return response
        }

        let expect = expectation(description: "shortcut wiki node to space")
        WikiNetworkManager.shared.shortcutWikiToSpace(objToken: "MOCK_OBJ_TOKEN",
                                                      objType: .docX,
                                                      folderToken: "MOCK_FOLDER_TOKEN")
        .subscribe { token, url in
            XCTAssertEqual(token, "MOCK_SHORTCUT_TOKEN")
            XCTAssertEqual(url, DocsUrlUtil.url(type: .folder, token: "MOCK_FOLDER_TOKEN"))
            expect.fulfill()
        } onError: { error in
            XCTFail("unexpected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testGetSpaceInfo() {
        let mockSpaceID = "MOCK_SPACE_ID"
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiGetMembers)
        } response: { request in
            guard let url = try? Self.getURL(path: JSONPath.getSpaceMembers) else {
                XCTFail("failed to get json url")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(fileURL: url,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["space_id"], mockSpaceID)
            return response
        }

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiGetSpaceInfoV2)
        } response: { request in
            guard let url = try? Self.getURL(path: JSONPath.getSpaceDetail) else {
                XCTFail("failed to get json url")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(fileURL: url,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["space_id"], mockSpaceID)
            return response
        }

        let expect = expectation(description: "get space info")
        WikiNetworkManager.shared.getSpaceInfo(spaceID: mockSpaceID)
            .subscribe { spaceInfo in
                XCTAssertEqual(spaceInfo.members.count, 2)
                guard spaceInfo.members.count == 2 else {
                    return
                }
                let member1 = spaceInfo.members[0]
                XCTAssertEqual(member1.memberID, "MEMBER_ID_1")
                XCTAssertEqual(member1.type, 0)
                XCTAssertEqual(member1.name, "MEMBER_CN_NAME_1")
                XCTAssertEqual(member1.enName, "MEMBER_EN_NAME_1")
                XCTAssertEqual(member1.iconURL, URL(string: "www.apple.com/MEMBER_ICON_URL_1"))
                XCTAssertEqual(member1.memberDescription, "MEMBER_DESCRIPTION_1")
                XCTAssertEqual(member1.role, 1)
                XCTAssertEqual(member1.aliasInfo, UserAliasInfo(displayName: "MEMBER_ALIAS_DEFAULT_1",
                                                                i18nDisplayNames: [
                                                                    "zh_cn": "MEMBER_ALIAS_CN_1",
                                                                    "en_us": "MEMBER_ALIAS_EN_1",
                                                                    "ja_jp": "MEMBER_ALIAS_JP_1"
                                                                ]))
                let member2 = spaceInfo.members[1]
                XCTAssertEqual(member2.memberID, "MEMBER_ID_2")
                XCTAssertEqual(member2.type, 2)
                XCTAssertEqual(member2.name, "MEMBER_CN_NAME_2")
                XCTAssertEqual(member2.enName, "MEMBER_EN_NAME_2")
                XCTAssertEqual(member2.iconURL, URL(string: "www.apple.com/MEMBER_ICON_URL_2"))
                XCTAssertEqual(member2.memberDescription, "MEMBER_DESCRIPTION_2")
                XCTAssertEqual(member2.role, 2)
                XCTAssertEqual(member2.aliasInfo, UserAliasInfo(displayName: "MEMBER_ALIAS_DEFAULT_2",
                                                                i18nDisplayNames: [
                                                                    "zh_cn": "MEMBER_ALIAS_CN_2",
                                                                    "en_us": "MEMBER_ALIAS_EN_2",
                                                                    "ja_jp": "MEMBER_ALIAS_JP_2"
                                                                ]))

                XCTAssertEqual(spaceInfo.spaceName, "MOCK_SPACE_NAME")
                XCTAssertEqual(spaceInfo.spaceDescription, "MOCK_SPACE_DESCRIPTION")
                XCTAssertTrue(spaceInfo.isStar)
                XCTAssertEqual(spaceInfo.wikiScope, 1)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testPinInExplorer() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.addPins)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: [
                "code": 0,
                "msg": "Success"
            ],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "pin in explorer")
        WikiNetworkManager.shared.pinInExplorer(addPin: true, objToken: "MOCK_OBJ_TOKEN", docsType: .docX)
            .subscribe(onCompleted: {
                expect.fulfill()
            }) { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testPinInExplorerFailed() {
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.addPins)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: [
                "code": -1,
                "msg": "Failed"
            ],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "pin in explorer")
        WikiNetworkManager.shared.pinInExplorer(addPin: true, objToken: "MOCK_OBJ_TOKEN", docsType: .docX)
            .subscribe(onCompleted: {
                XCTFail("add pins should error")
                expect.fulfill()
            }) { error in
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testDeleteNodeSuccess() {
        let spaceID = "MOCK_SPACE_ID"
        let wikiToken = "MOCK_WIKI_TOKEN"
        let synergyUUID = "MOCK_UUID"
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiDeleteNodeV2)
        } response: { request in
            guard let url = try? Self.getURL(path: JSONPath.plainSuccess) else {
                XCTFail("failed to get json url")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(fileURL: url,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["space_id"] as? String, spaceID)
            XCTAssertEqual(data["wiki_token"] as? String, wikiToken)
            XCTAssertEqual(data["synergy_uuid"] as? String, synergyUUID)
            XCTAssertEqual(data["auto_delete_mode"] as? Int, 2)
            XCTAssertEqual(data["apply"] as? Int, 0)
            return response
        }

        let expect = expectation(description: "delete node success")
        WikiNetworkManager.shared.deleteNode(wikiToken, spaceId: spaceID, canApply: false, synergyUUID: synergyUUID)
            .subscribe { _ in
                XCTFail("un-expected reviewer found")
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testDeleteNodeFailed() {
        let spaceID = "MOCK_SPACE_ID"
        let wikiToken = "MOCK_WIKI_TOKEN"

        MockWikiNetworkAPI.mock(path: OpenAPI.APIPath.wikiDeleteNodeV2, jsonFile: JSONPath.noPermission.fullPath)
        let expect = expectation(description: "delete node failed")
        WikiNetworkManager.shared.deleteNode(wikiToken, spaceId: spaceID, canApply: false)
            .subscribe { _ in
                XCTFail("un-expected reviewer found")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                expect.fulfill()
            } onCompleted: {
                XCTFail("un-expected success found")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testDeleteNodeNeedApply() {
        let spaceID = "MOCK_SPACE_ID"
        let wikiToken = "MOCK_WIKI_TOKEN"
        let synergyUUID = "MOCK_UUID"
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiDeleteNodeV2)
        } response: { request in
            guard let url = try? Self.getURL(path: JSONPath.needApproval) else {
                XCTFail("failed to get json url")
                return HTTPStubsResponse()
            }
            let response = HTTPStubsResponse(fileURL: url,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["space_id"] as? String, spaceID)
            XCTAssertEqual(data["wiki_token"] as? String, wikiToken)
            XCTAssertEqual(data["synergy_uuid"] as? String, synergyUUID)
            XCTAssertEqual(data["auto_delete_mode"] as? Int, 2)
            XCTAssertEqual(data["apply"] as? Int, 1)
            return response
        }

        let expect = expectation(description: "delete node need apply")
        WikiNetworkManager.shared.deleteNode(wikiToken, spaceId: spaceID, canApply: true, synergyUUID: synergyUUID)
            .subscribe { reviewer in
                XCTAssertEqual(reviewer.userID, "MOCK_USER_ID")
                XCTAssertEqual(reviewer.userName, "MOCK_USER_NAME")
                XCTAssertTrue(reviewer.i18nNames.isEmpty)
                XCTAssertEqual(reviewer.aliasInfo,
                               UserAliasInfo(displayName: "MOCK_DISPLAY_NAME",
                                             i18nDisplayNames: [
                                                "en_us": "MOCK_EN_DISPLAY_NAME",
                                                "zh_cn": "MOCK_CN_DISPLAY_NAME",
                                                "ja_jp": "MOCK_JP_DISPLAY_NAME"
                                             ]))
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("un-expected success found")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testApplyDelete() {
        let wikiToken = "MOCK_WIKI_TOKEN"
        let spaceID = "MOCK_SPACE_ID"
        let reviewerID = "MOCK_REVIEWER_ID"
        let reason = "MOCK APPLY COMMENT"

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiApplyDelete)
        } response: { request in
            let json = ["code": 0, "data": [:], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["token"] as? String, wikiToken)
            XCTAssertEqual(data["space_id"] as? String, spaceID)
            XCTAssertEqual(data["reviewer"] as? String, reviewerID)
            XCTAssertEqual(data["reason"] as? String, reason)
            XCTAssertEqual(data["delete_opt"] as? Int, 1)
            return response
        }

        var expect = expectation(description: "apply delete in wiki")
        WikiNetworkManager.shared.applyDelete(wikiMeta: WikiMeta(wikiToken: wikiToken, spaceID: spaceID),
                                              isSingleDelete: false,
                                              reason: reason,
                                              reviewerID: reviewerID)
        .subscribe {
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiApplyDelete)
        } response: { request in
            let json = ["code": 0, "data": [:], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["token"] as? String, wikiToken)
            XCTAssertEqual(data["space_id"] as? String, spaceID)
            XCTAssertEqual(data["reviewer"] as? String, reviewerID)
            XCTAssertEqual(data["reason"] as? String, reason)
            XCTAssertEqual(data["delete_opt"] as? Int, 2)
            return response
        }

        expect = expectation(description: "apply single delete in wiki")
        WikiNetworkManager.shared.applyDelete(wikiMeta: WikiMeta(wikiToken: wikiToken, spaceID: spaceID),
                                              isSingleDelete: true,
                                              reason: reason,
                                              reviewerID: reviewerID)
        .subscribe {
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
}

extension WikiNetworkManagerTests {
    static func getURL(path: PathRepresentable) throws -> URL {
        guard let path = Bundle(for: WikiNetworkManagerTests.self)
            .url(forResource: path.fullPath, withExtension: nil) else {
            throw LoadJSONError.fileNotFound
        }
        return path
    }

    static func loadJSON(path: PathRepresentable) throws -> JSON {
        let path = try getURL(path: path)
        let data = try Data(contentsOf: path)
        let json = try JSON(data: data)
        return json
    }
}
