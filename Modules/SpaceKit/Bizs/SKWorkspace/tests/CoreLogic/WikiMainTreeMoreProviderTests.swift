//
//  WikiMainTreeMoreProviderTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/18.
//

import XCTest
import SKFoundation
import RxSwift
@testable import SKWorkspace

private extension WikiTreeNodePermission {
    static var noPermission: WikiTreeNodePermission {
        WikiTreeNodePermission(canCreate: false,
                               canMove: false,
                               canDelete: false,
                               showDelete: false,
                               showSingleDelete: false,
                               canAddShortCut: false,
                               canStar: false,
                               canCopy: false,
                               isLocked: false,
                               canRename: false,
                               showMove: false,
                               canDownload: false,
                               canExplorerStar: false,
                               canExplorerPin: false,
                               originCanCreate: false,
                               originCanAddShortCut: false,
                               originCanExplorerStar: false,
                               originCanCopy: false,
                               originCanDownload: false,
                               originCanExplorerPin: false,
                               parentNodeMovePermission: nil,
                               nodeMovePermission: nil)
    }

    static var allPermission: WikiTreeNodePermission {
        WikiTreeNodePermission(canCreate: true,
                               canMove: true,
                               canDelete: true,
                               showDelete: true,
                               showSingleDelete: true,
                               canAddShortCut: true,
                               canStar: true,
                               canCopy: true,
                               isLocked: true,
                               canRename: true,
                               showMove: true,
                               canDownload: false,
                               canExplorerStar: true,
                               canExplorerPin: true,
                               originCanCreate: true,
                               originCanAddShortCut: true,
                               originCanExplorerStar: true,
                               originCanCopy: true,
                               originCanDownload: true,
                               originCanExplorerPin: true,
                               parentNodeMovePermission: .init(isRoot: true, canMove: true),
                               nodeMovePermission: .init(canMove: true))
    }
}

class WikiMainTreeMoreProviderTests: XCTestCase {

    class PermissionNetworkAPI: MockWikiNetworkAPI {
        var result: Result<WikiTreeNodePermission, Error> = .failure(TestError.mockNotImplement)
        override func getNodePermission(spaceId: String, wikiToken: String) -> Single<WikiTreeNodePermission> {
            do {
                let permission = try result.get()
                return .just(permission)
            } catch {
                return .error(error)
            }
        }
    }

    private var bag = DisposeBag()
    typealias Provider = WikiMainTreeMoreProvider
    typealias Handler = WikiInteractionHandler
    typealias TestError = MockWikiNetworkAPI.MockNetworkError
    typealias Util = WikiTreeTestUtil

    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        bag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testPreloadPermission() {
        let networkAPI = PermissionNetworkAPI()
        networkAPI.result = .success(.noPermission)
        let handler = Handler(networkAPI: networkAPI, synergyUUID: nil)
        let provider = Provider(interactionHelper: handler)
        let expect = expectation(description: #function)
        provider.onPermissionUpdated.emit(onNext: {
            XCTAssertNotNil(provider.nodePermissionStorage["MOCK_TOKEN"])
            expect.fulfill()
        })
        .disposed(by: bag)

        provider.preloadPermission(meta: Util.mockNode(token: "MOCK_TOKEN", hasChild: false))
        waitForExpectations(timeout: 1)
    }

}
