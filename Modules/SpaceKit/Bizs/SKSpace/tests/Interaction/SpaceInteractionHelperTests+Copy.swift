//
//  SpaceInteractionHelperTests+Copy.swift
//  SKSpace-Unit-Tests
//
//  Created by majie.7 on 2023/4/13.
//

import XCTest
@testable import SKSpace
import SKCommon
import SKInfra
import SKFoundation
import OHHTTPStubs
import RxSwift
import SpaceInterface
import SKInfra

extension SpaceInteractionHelperTests {
    
    func testSpaceCopyToSpace() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.fileCopyV2)
        } response: { _ in
            let data = [
                "entities": [
                    "nodes": [
                        "MOCK_NODE_TOKEN": [
                            "create_time": 1681366110,
                            "delete_flag": 0,
                            "edit_time": 1681366110,
                            "edit_uid": "MOCK_UID",
                            "extra": [
                                "description": "",
                            ],
                            "name": "MOCK_COPY_FILE",
                            "node_type": 0,
                            "obj_token": "MOCK_OBJ_TOKEN",
                            "owner_id": "MOCK_OWNER_ID",
                            "owner_type": 5,
                            "secret_key_delete": false,
                            "share_version": 0,
                            "thumbnail": "",
                            "thumbnail_extra": [
                                "nonce": "",
                                "secret": "",
                                "type": 0,
                                "url": ""
                            ],
                            "token": "MOCK_NODE_TOKEN",
                            "type": 22,
                            "url": "https://bytedance.feishu.cn/wiki/xxx"
                        ]
                    ]
                ]
            ]
            let json = ["code": 0, "data": data, "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        let expection = expectation(description: "space copy file to space success")
        let trackParams = DocsCreateDirectorV2.TrackParameters(source: .larkCreate,
                                                               module: .wiki,
                                                               ccmOpenSource: .copy)
        let request = WorkspaceManagementAPI.Space.CopyToSpaceRequest(
            sourceMeta: SpaceMeta(objToken: "MOCK_TOKEN", objType: .docX),
            ownerType: 5,
            folderToken: "MOCK_FOLDER_TOKEN",
            originName: "MOCK_ORIGIN_NAME",
            fileSize: 12,
            trackParams: trackParams
        )
        let entrances: [WorkspacePickerEntrance] = .wikiAndSpace
        let tracker = WorkspacePickerTracker(actionType: .makeCopyTo,
                                             triggerLocation: .catalogListItem)
        let config = WorkspacePickerConfig(title: "",
                                           action: .copySpace,
                                           extraEntranceConfig: nil,
                                           entrances: entrances,
                                           ownerTypeChecker: { _ in
            return ""
        },
                                           disabledWikiToken: nil,
                                           usingLegacyRecentAPI: false,
                                           tracker: tracker) { _, _ in
            return
        }
        let router = WorkspacePickerFactory.createWorkspacePicker(config: config)
        helper.copyToSpace(request: request, picker: router)
            .subscribe(onSuccess: { url in
                XCTAssertEqual(url.absoluteString, "https://bytedance.feishu.cn/wiki/xxx")
                expection.fulfill()
            }) { _ in
                XCTFail("should succeed!")
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWikiCopyToSpace() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFileToSpace)
        } response: { _ in
            let data = ["obj_token": "MOCK_OBJ_TOKEN",
                        "token": "MOCK_NODE_TOKEN",
                        "url": "https://bytedance.feishu.cn/docx/xxx"]
            let json = ["code": 0, "data": data, "msg": "Success"]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        
        let expection = expectation(description: "wiki copy to space")
        helper.copyToSpace(sourceWikiToken: "MOCK_WIKI_TOKEN",
                           spaceId: "MOCK_SPACEID",
                           folderToken: "MOCK_FOLDER_TOKEN",
                           title: "MOCK_TITLE",
                           needAsync: false)
        .subscribe { url in
            XCTAssertEqual(url.absoluteString, "https://bytedance.feishu.cn/docx/xxx")
            expection.fulfill()
        } onError: { _ in
            XCTFail("should succeed")
        }
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)
    }
    
    func testWikiCopyToWiki() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFile)
        } response: { _ in
            let data = ["space_id": "TARGET_MOCK_SPACE_ID",
                        "parent_wiki_token": "MOCK_PARENT_WIKI_TOKEN",
                        "wiki_token": "TARGET_MOCK_TOKEN",
                        "obj_token": "MOCK_OBJ_TOKEN",
                        "obj_type": 22,
                        "title": "MOCK_WIKI_TITLE",
                        "sort_id": 4503602848595967,
                        "wiki_node_type": 0,
                        "origin_wiki_token": "TARGET_MOCK_TOKEN",
                        "origin_space_id": "TARGET_MOCK_SPACE_ID",
                        "origin_is_external": false,
                        "origin_url": "",
                        "has_child": false,
                        "url": "https://bytedance.feishu.cn/wiki/XXX",
                        "secret_key_delete": false,
                        "is_explorer_star": false,
                        "is_explorer_pin": false,
                        "entity_delete_flag": 0]
            let json = ["code": 0, "data": data, "msg": "Success"]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        
        let expection = expectation(description: "wiki copy file to wiki")
        let sourceMeta = WikiMeta(wikiToken: "SOURCE_MOCK_TOKEN", spaceID: "SOURCE_MOCK_SPACE_ID")
        let targetMeta = WikiMeta(wikiToken: "TARGET_MOCK_TOKEN", spaceID: "TARGET_MOCK_SPACE_ID")
        helper.copyToWiki(sourceMeta: sourceMeta, targetMeta: targetMeta, title: "MOCK_WIKI_TITLE", needAsync: false)
            .subscribe { wikiToken in
                XCTAssertEqual(wikiToken, targetMeta.wikiToken)
                expection.fulfill()
            } onError: { _ in
                XCTFail("should succeed!")
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)
    }
    
    func testWikiCopyToWikiFailed() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiCopyFile)
        } response: { _ in
            let data = ["url": "https://bytedance.feishu.cn/wiki/XXX"]
            let json = ["code": 0, "data": data, "msg": "Success"]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        
        let expection = expectation(description: "wiki copy file to wiki failed")
        let sourceMeta = WikiMeta(wikiToken: "SOURCE_MOCK_TOKEN", spaceID: "SOURCE_MOCK_SPACE_ID")
        let targetMeta = WikiMeta(wikiToken: "TARGET_MOCK_TOKEN", spaceID: "TARGET_MOCK_SPACE_ID")
        helper.copyToWiki(sourceMeta: sourceMeta, targetMeta: targetMeta, title: "MOCK_WIKI_TITLE", needAsync: false)
            .subscribe { wikiToken in
                XCTFail("should failed")
            } onError: { _ in
                expection.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)
    }
    
    func testWikiCreateShorcutToSpace() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.addShortCutTo)
        } response: { _ in
            let data = [
                "entities": [
                    "nodes": [
                        "MOCK_NODE_TOKEN": [
                            "create_time": 1678071156,
                            "delete_flag": 0,
                            "edit_time": 1681290084,
                            "edit_uid": "MOCK_UID",
                            "extra": [
                                "description": ""
                            ],
                            "name": "MOCK_NAME",
                            "node_type": 1,
                            "obj_token": "MOCK_OBJ_TOKEN",
                            "owner_id": "MOCK_OWNER_ID",
                            "owner_type": 5,
                            "share_version": 0,
                            "thumbnail": "",
                            "thumbnail_extra": [
                                "nonce": "",
                                "secret": "",
                                "type": 0,
                                "url": ""
                            ],
                            "token": "MOCK_NODE_TOKEN",
                            "type": 22,
                            "url": "https://bytedance.feishu.cn/docx/xxx"
                        ]
                    ]
                ]
            ]
            let json = ["code": 0, "data": data, "msg": "Success"]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        
        let expection = expectation(description: "wiki create shorcut to space")
        let item = SpaceItem(objToken: "MOCK_OBJ_TOKEN", objType: .wiki)
        helper.shortcutToSpace(item: item, folderToken: "MOCK_FOLDER_TOKEN")
            .subscribe { token in
                XCTAssertEqual(token, "MOCK_NODE_TOKEN")
                expection.fulfill()
            } onError: { _ in
                XCTFail("should succeed!")
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)
    }

    func testWikiCreateShortcutToWiki() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiAddRelationV2)
        } response: { _ in
            let data = ["space_id": "TARGET_MOCK_SPACE_ID",
                        "parent_wiki_token": "TARGET_MOCK_TOKEN",
                        "wiki_token": "MOCK_WIKI_TOKEN",
                        "obj_token": "MOCK_OBJ_TOKEN",
                        "obj_type": 22,
                        "title": "MOCK_TITLE",
                        "sort_id": 4503603922337791,
                        "wiki_node_type": 1,
                        "origin_wiki_token": "SOURCE_MOCK_TOKEN",
                        "origin_space_id": "SOURCE_MOCK_SPACE_ID",
                        "origin_is_external": false,
                        "origin_url": "",
                        "has_child": true,
                        "url": "https://bytedance.feishu.cn/wiki/XXX",
                        "secret_key_delete": false,
                        "is_explorer_star": false,
                        "is_explorer_pin": false,
                        "can_pre_heating": false,
                        "entity_delete_flag": 0]
            let json = ["code": 0, "data": data, "msg": "Success"]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        
        let expection = expectation(description: "")
        let sourceMeta = WikiMeta(wikiToken: "SOURCE_MOCK_TOKEN", spaceID: "SOURCE_MOCK_SPACE_ID")
        let targetMeta = WikiMeta(wikiToken: "TARGET_MOCK_TOKEN", spaceID: "TARGET_MOCK_SPACE_ID")
        helper.shortcutToWiki(sourceWikiMeta: sourceMeta, targetWikiMeta: targetMeta, title: "MOCK_TITLE")
            .subscribe { wikiToken in
                XCTAssertEqual(wikiToken, "MOCK_WIKI_TOKEN")
                expection.fulfill()
            } onError: { _ in
                XCTFail("should succeed!")
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)
    }
    
    func testWikiCreateShortcutToWikiFailed() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.wikiAddRelationV2)
        } response: { _ in
            let data = [AnyHashable: Any]()
            let json = ["code": 0, "data": data, "msg": "Success"]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }
        
        let expection = expectation(description: "")
        let sourceMeta = WikiMeta(wikiToken: "SOURCE_MOCK_TOKEN", spaceID: "SOURCE_MOCK_SPACE_ID")
        let targetMeta = WikiMeta(wikiToken: "TARGET_MOCK_TOKEN", spaceID: "TARGET_MOCK_SPACE_ID")
        helper.shortcutToWiki(sourceWikiMeta: sourceMeta, targetWikiMeta: targetMeta, title: "MOCK_TITLE")
            .subscribe { wikiToken in
                XCTFail("should failed!")
            } onError: { _ in
                expection.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 5)
    }
}
