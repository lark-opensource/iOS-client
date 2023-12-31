//
//  CollaboratorSearchTableViewModelTests.swift
//  SpaceDemoTests
//
//  Created by gupqingping on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.
// swiftlint:disable force_try line_length


import XCTest
import OHHTTPStubs
@testable import SKCommon
@testable import SKUIKit
import RxSwift
import RxRelay
import SKFoundation
import SwiftyJSON
import SKInfra

class CollaboratorSearchTableViewModelTests: XCTestCase {

    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.searchPermissionCandidates)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("permission_candidates.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionCollaboratorsExist)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("members_existV2.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.generateEmailInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("generateEmail.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDocSearch() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []
        let searchConfig = CollaboratorSearchConfig(shouldSearchOrganization: true,
                                                    shouldSearchUserGroup: false,
                                                    inviteExternalOption: .all)

        let viewModel = CollaboratorSearchTableViewModel(objToken: "doccns41WeN2txY4OA95Yj3ebvK",
                                                         docsType: .doc,
                                                         wikiV2SingleContainer: false,
                                                         spaceSingleContainer: true,
                                                         isBitableAdvancedPermissions: false,
                                                         ownerId: "6807206588324069377",
                                                         existedCollaborators: existedCollaborators,
                                                         selectedItems: selectedItems,
                                                         searchConfig: searchConfig)
        let expect = expectation(description: "test CollaboratorSearchTableViewModel search")
        viewModel.searchCollaborator(with: "") { items in
            XCTAssertTrue(items.count > 0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testFolderSearch() {
        let path = Bundle(for: type(of: self)).path(forResource: "membersv2", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let obj = try! JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let originDict = (obj as? [String: Any])?["data"] as? [String: Any] ?? [:]
        let collaboratorsDict = originDict["members"] as? [[String: Any]] ?? [[:]]
        let existedCollaborators = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
        let selectedItems: [Collaborator] = []
        let searchConfig = CollaboratorSearchConfig(shouldSearchOrganization: true,
                                                    shouldSearchUserGroup: false,
                                                    inviteExternalOption: .all)

        let viewModel = CollaboratorSearchTableViewModel(objToken: "fldcnRHLMIttPq76VD98eVtNbOg",
                                                         docsType: .folder,
                                                         wikiV2SingleContainer: false,
                                                         spaceSingleContainer: true,
                                                         isBitableAdvancedPermissions: false,
                                                         ownerId: "6807206588324069377",
                                                         existedCollaborators: existedCollaborators,
                                                         selectedItems: selectedItems,
                                                         searchConfig: searchConfig)
        let expect = expectation(description: "test CollaboratorSearchTableViewModel search")
        viewModel.searchCollaborator(with: "") { items in
            XCTAssertTrue(items.count > 0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testWikiBitableAdPermSearch() {
        
        let path = Bundle(for: type(of: self)).path(forResource: "wiki_bitable_collaborators", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let json = try! JSON(data: data)
        let arr = json["data"]["members"].arrayObject as? [[String: Any]] ?? []
        let items = Collaborator.collaborators(arr, isOldShareFolder: false)
        
        let wikiMembers = items.filter({ $0.type == .newWikiMember })
        
        let config = CollaboratorSearchConfig(
            shouldSearchOrganization: true,
            shouldSearchUserGroup: true,
            inviteExternalOption: .none
        )
        
        let vm = CollaboratorSearchTableViewModel(
            objToken: "fldcnRHLMIttPq76VD98eVtNbOg",
            docsType: .bitable,
            wikiV2SingleContainer: false,
            spaceSingleContainer: false,
            isBitableAdvancedPermissions: true,
            ownerId: "",
            existedCollaborators: [],
            selectedItems: [],
            wikiMembers: wikiMembers,
            statistics: nil,
            searchConfig: config
        )
        
        let expect = expectation(description: "testWikiBitableAdPermSearch")
        vm.searchCollaborator(with: "") { list in
            guard list.count >= wikiMembers.count else {
                XCTFail("search result count not equal")
                expect.fulfill()
                return
            }
            let val = Array(list[0..<wikiMembers.count]) == wikiMembers
            XCTAssertTrue(val)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testUniversalSearch() {
        let query = "MOCK_QUERY"
        class MockSearchAPI: CollaboratorSearchAPI {
            func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
                XCTAssertEqual(request.query, "MOCK_QUERY")
                var pagingInfo = CollaboratorSearchResponse.PagingInfo.hasMore(pageToken: "MOCK_PAGE_TOKEN")
                if let pageToken = request.pageToken {
                    pagingInfo = .noMore
                    XCTAssertEqual(pageToken as? String, "MOCK_PAGE_TOKEN")
                }
                let mockCollaborator = Collaborator(rawValue: CollaboratorType.user.rawValue,
                                                    userID: "MOCK_USER_ID",
                                                    name: "MOCK_USER_NAME",
                                                    avatarURL: "",
                                                    avatarImage: nil,
                                                    userPermissions: UserPermissionMask(),
                                                    groupDescription: nil)
                mockCollaborator.v2SearchSubTitle = "MOCK_SUB_TITLE"
                let response = CollaboratorSearchResponse(collaborators: [mockCollaborator],
                                                          pagingInfo: pagingInfo)
                return .just(response)
            }
        }
        let searchConfig = CollaboratorSearchConfig(shouldSearchOrganization: true,
                                                    shouldSearchUserGroup: false,
                                                    inviteExternalOption: .all)

        let viewModel = CollaboratorSearchTableViewModel(objToken: "doccns41WeN2txY4OA95Yj3ebvK",
                                                         docsType: .doc,
                                                         wikiV2SingleContainer: false,
                                                         spaceSingleContainer: true,
                                                         isBitableAdvancedPermissions: false,
                                                         ownerId: "6807206588324069377",
                                                         existedCollaborators: [],
                                                         selectedItems: [],
                                                         searchConfig: searchConfig,
                                                         searchAPI: MockSearchAPI())
        var expect = expectation(description: "test CollaboratorSearchTableViewModel search")
        viewModel.searchCollaborator(with: query) { items in
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(viewModel.datas.count, 1)
            guard let item = viewModel.datas.first else {
                expect.fulfill()
                return
            }
            XCTAssertEqual(item.detail, "MOCK_SUB_TITLE")
            XCTAssertTrue(viewModel.hasMore)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }

        expect = expectation(description: "test load more")
        viewModel.updateSearchRequest(query: query) { error in
            XCTAssertNil(error)
            XCTAssertFalse(viewModel.hasMore)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testCorrectEmailSearch() {
        class MockSearchAPI: CollaboratorSearchAPI {
            func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
                let response = CollaboratorSearchResponse(collaborators: [],
                                                          pagingInfo: .noMore)
                return .just(response)
            }
        }
        let searchConfig = CollaboratorSearchConfig(shouldSearchOrganization: true,
                                                    shouldSearchUserGroup: false,
                                                    inviteExternalOption: .all)

        let viewModel = CollaboratorSearchTableViewModel(objToken: "doccns41WeN2txY4OA95Yj3ebvK",
                                                         docsType: .doc,
                                                         wikiV2SingleContainer: false,
                                                         spaceSingleContainer: true,
                                                         isBitableAdvancedPermissions: false,
                                                         ownerId: "6807206588324069377",
                                                         existedCollaborators: [],
                                                         selectedItems: [],
                                                         searchConfig: searchConfig,
                                                         searchAPI: MockSearchAPI(),
                                                         isEmailSharingEnabled: true,
                                                         canInviteEmailCollaborator: true,
                                                         adminCanInviteEmailCollaborator: true)
        let correctEmail = "MOCK_QUERY@qq.com"
        let correctExpect = expectation(description: "test correct email search")
        viewModel.searchCollaborator(with: correctEmail) { items in
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(viewModel.datas.count, 1)
            guard let item = viewModel.datas.first else {
                correctExpect.fulfill()
                return
            }
            XCTAssertTrue(item.roleType == .email)
            XCTAssertFalse(viewModel.hasMore)
            correctExpect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testInvalidEmailSearch() {
        class MockSearchAPI: CollaboratorSearchAPI {
            func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
                let response = CollaboratorSearchResponse(collaborators: [],
                                                          pagingInfo: .noMore)
                return .just(response)
            }
        }
        let searchConfig = CollaboratorSearchConfig(shouldSearchOrganization: true,
                                                    shouldSearchUserGroup: false,
                                                    inviteExternalOption: .all)

        let viewModel = CollaboratorSearchTableViewModel(objToken: "doccns41WeN2txY4OA95Yj3ebvK",
                                                         docsType: .doc,
                                                         wikiV2SingleContainer: false,
                                                         spaceSingleContainer: true,
                                                         isBitableAdvancedPermissions: false,
                                                         ownerId: "6807206588324069377",
                                                         existedCollaborators: [],
                                                         selectedItems: [],
                                                         searchConfig: searchConfig,
                                                         searchAPI: MockSearchAPI(),
                                                         isEmailSharingEnabled: true,
                                                         canInviteEmailCollaborator: true,
                                                         adminCanInviteEmailCollaborator: true)
        let invalidEmail = "MOCK_QUERY@@qq..com"
        let expect = expectation(description: "test invalid email search")
        viewModel.searchCollaborator(with: invalidEmail) { items in
            XCTAssertEqual(items.count, 0)
            XCTAssertEqual(viewModel.datas.count, 0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testInviteEmailCollaborator() {
        let query = "MOCK_QUERY@qq.com"
        class MockSearchAPI: CollaboratorSearchAPI {
            func search(request: CollaboratorSearchRequest) -> Single<CollaboratorSearchResponse> {
                XCTAssertEqual(request.query, "MOCK_QUERY@qq.com")
                var pagingInfo = CollaboratorSearchResponse.PagingInfo.hasMore(pageToken: "MOCK_PAGE_TOKEN")
                if let pageToken = request.pageToken {
                    pagingInfo = .noMore
                    XCTAssertEqual(pageToken as? String, "MOCK_PAGE_TOKEN")
                }
                let mockCollaborator = Collaborator(rawValue: CollaboratorType.user.rawValue,
                                                    userID: "MOCK_USER_ID",
                                                    name: "MOCK_USER_NAME",
                                                    avatarURL: "",
                                                    avatarImage: nil,
                                                    userPermissions: UserPermissionMask(),
                                                    groupDescription: nil)
                mockCollaborator.enterpriseEmail = "MOCK_QUERY@qq.com"
                mockCollaborator.v2SearchSubTitle = "MOCK_SUB_TITLE"
                let response = CollaboratorSearchResponse(collaborators: [mockCollaborator],
                                                          pagingInfo: pagingInfo)
                return .just(response)
            }
        }
        let searchConfig = CollaboratorSearchConfig(shouldSearchOrganization: true,
                                                    shouldSearchUserGroup: false,
                                                    inviteExternalOption: .all)

        let viewModel = CollaboratorSearchTableViewModel(objToken: "doccns41WeN2txY4OA95Yj3ebvK",
                                                         docsType: .doc,
                                                         wikiV2SingleContainer: false,
                                                         spaceSingleContainer: true,
                                                         isBitableAdvancedPermissions: false,
                                                         ownerId: "6807206588324069377",
                                                         existedCollaborators: [],
                                                         selectedItems: [],
                                                         searchConfig: searchConfig,
                                                         searchAPI: MockSearchAPI(),
                                                         isEmailSharingEnabled: true,
                                                         canInviteEmailCollaborator: true,
                                                         adminCanInviteEmailCollaborator: true)
        let correctExpect = expectation(description: "test InviteEmailCollaborator")
        viewModel.searchCollaborator(with: query) { items in
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(viewModel.datas.count, 1)
            guard let item = viewModel.datas.first else {
                correctExpect.fulfill()
                return
            }
            XCTAssertTrue(item.roleType == .user)
            correctExpect.fulfill()
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
}
