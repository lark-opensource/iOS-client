//
//  SyncContainerViewModelTest.swift
//  SKDoc
//
//  Created by liujinwei on 2023/12/21.
//  


import Foundation
import XCTest
import OHHTTPStubs
import LarkContainer
@testable import SKInfra
@testable import SKCommon
@testable import SKFoundation
@testable import SKDoc

class SyncContainerViewModelTests: XCTestCase {
    
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    let successToken = "HCZqdNylvsWi69buGgZcuzcKnze"
    let noPermissionToken = "JBehdGze6secMfbnvnecfGIWnkd"
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.syncedBlockPermission)
            return contain
        }, response: { request in
            let success = request.url?.absoluteString.contains(self.successToken) ?? false
            let code = success ? 0 : 4
            let obj = ["code": code, "msg": "", "data": ["parent_doc_info": ["token": self.successToken]]]
            return HTTPStubsResponse(
                jsonObject: obj,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
    }
    
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }
    
    func testLoadSyncInfoIfNeed() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.docs.synced_block.permission", value: true)
        let expectation1 = self.expectation(description: "request_syncblock_parent_info1")
        let viewModel1 = SyncContainerViewModel(userResolver: userResolver, token: successToken, type: .sync)
        viewModel1.bindState = { state in
            switch state {
            case .prepare:
                break
            case .success(let token):
                XCTAssertEqual(token, viewModel1.parentToken ?? "")
                expectation1.fulfill()
            default:
                XCTFail()
            }
        }
        viewModel1.loadSyncInfoIfNeed()
        let expectation2 = self.expectation(description: "request_syncblock_parent_info2")
        let viewModel2 = SyncContainerViewModel(userResolver: userResolver, token: noPermissionToken, type: .sync)
        viewModel2.bindState = { state in
            switch state {
            case .prepare:
                break
            case .noPermission:
                expectation2.fulfill()
            default:
                XCTFail()
            }
        }
        viewModel2.loadSyncInfoIfNeed()
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
}
