//
//  WikiHomePageViewModelV2Tests.swift
//  SKWikiV2-Unit-Tests
//
//  Created by majie.7 on 2022/12/20.
//

@testable import SKWikiV2
@testable import SKFoundation
@testable import SKWorkspace
import XCTest
import Foundation
import RxSwift
import LarkContainer


class WikiHomePageViewModelV2Tests: XCTestCase {
    
    var bag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        UserScopeNoChangeFG.setMockFG(key: "spacekit.mobile.wiki2.0_space_classify_enable", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.wiki.mobile.space_classification_enable", value: true)
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }
    
    static func mockSpaces(spaceID: String, spaceName: String) -> WikiSpace {
        let space = WikiSpace(spaceId: spaceID,
                              spaceName: spaceName,
                              rootToken: "MOCK_ROOT_TOKEN",
                              tenantID: "1234",
                              wikiDescription: "description",
                              isStar: true,
                              cover: .init(originPath: "OriginPath",
                                           thumbnailPath: "ThumbnailPath",
                                           name: "Name",
                                           isDarkStyle: false,
                                           rawColor: "Red"),
                              lastBrowseTime: nil,
                              wikiScope: nil,
                              ownerPermType: nil,
                              migrateStatus: nil,
                              openSharing: nil,
                              spaceType: nil,
                              createUID: nil,
                              displayTag: nil)
        return space
    }
    
    class MockApi: MockWikiNetworkAPI {
        override func getStarWikiSpaces(lastLabel: String?) -> RxSwift.Single<WorkSpaceInfo> {
            let space_1 = WikiHomePageViewModelV2Tests.mockSpaces(spaceID: "1", spaceName: "space_1")
            let space_2 = WikiHomePageViewModelV2Tests.mockSpaces(spaceID: "2", spaceName: "space_2")
            let spaces: [WikiSpace] = [space_1, space_2]
            let spaceInfo = WorkSpaceInfo(spaces: spaces, lastLabel: "", hasMore: false)
            return .just(spaceInfo)
        }
        
        override func rxGetWikiSpacesV2(lastLabel: String, size: Int, type: Int?, classId: String?) -> RxSwift.Single<WorkSpaceInfo> {
            let space_1 = WikiHomePageViewModelV2Tests.mockSpaces(spaceID: "1", spaceName: "space_1")
            let space_2 = WikiHomePageViewModelV2Tests.mockSpaces(spaceID: "2", spaceName: "space_2")
            let spaces: [WikiSpace] = [space_1, space_2]
            let spaceInfo = WorkSpaceInfo(spaces: spaces, lastLabel: "", hasMore: false)
            return .just(spaceInfo)
        }
        
        override func getWikiFilter() -> RxSwift.Single<WikiFilterList> {
            let filter_1 = WikiFilter(classId: "1", className: "Class_1")
            let filter_2 = WikiFilter(classId: "2", className: "Class_2")
            let filters: [WikiFilter] = [filter_1, filter_2]
            let list = WikiFilterList(filters: filters)
            return .just(list)
        }
    }
    
    func testDidAppear() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        let expect = expectation(description: "wiki.home.didAppear")
        expect.expectedFulfillmentCount = 3
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .stopPullToRefresh, .updateList:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.didAppear(isFirstTime: true)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRefreshFilter() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        let expect = expectation(description: "wiki.home.refresh.Filter")
        expect.expectedFulfillmentCount = 3
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .stopPullToRefresh, .updateList:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.filterShowEnableRelay.subscribe(onNext: { show in
            if show {
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.refreshFilter()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRefreshHeaderList() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        let expect = expectation(description: "wiki.home.refresh.header.list")
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .updateHeaderList:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.refreshHeaderList()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRefreshList() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        let expect = expectation(description: "wiki.home.refresh.list")
        expect.expectedFulfillmentCount = 2
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .stopPullToRefresh, .updateList:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.refreshList()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadMoreHeaderList() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        vm.listManager.update(starHasMore: true, starLastLabel: "1234")
        let expect = expectation(description: "wiki.home.refresh.loadMore.header.list")
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .updateHeaderList:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.loadMoreHeaderList()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadMoreHeaderListNoMore() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        vm.loadMoreHeaderList()
        XCTAssertEqual(vm.listManager.starListHasMore, false)
        XCTAssertNil(vm.listManager.starListLastLabel)
    }
    
    func testLoadMoreList() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        vm.listManager.update(hasMore: true, lastLabel: "1234")
        let expect = expectation(description: "wiki.home.refresh.loadMore.list")
        expect.expectedFulfillmentCount = 2
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .stopLoadMoreList, .updateList:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.loadMoreList()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testLoadMoreListNoMore() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockApi())
        let expect = expectation(description: "wiki.home.refresh.loadMore.list.noMore")
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case let .stopLoadMoreList(hasMore):
                XCTAssertNotNil(hasMore)
                XCTAssertEqual(hasMore, false)
                XCTAssertEqual(vm.listManager.hasMore, false)
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.loadMoreList()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRefreshListError() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockWikiNetworkAPI())
        let expect = expectation(description: "wiki.home.refresh.list.error")
        expect.expectedFulfillmentCount = 2
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .stopLoadMoreList, .stopPullToRefresh:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.refreshList()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRefreshFilterListError() {
        let vm = WikiHomePageViewModelV2(userResolver: userResolver, apiManager: MockWikiNetworkAPI())
        let expect = expectation(description: "wiki.home.refresh.filter.list.error")
        expect.expectedFulfillmentCount = 4
        vm.actionOutput.drive(onNext: { action in
            switch action {
            case .stopPullToRefresh, .stopLoadMoreList:
                XCTAssertEqual(vm.listManager.spaceClassType, .all)
                XCTAssertEqual(vm.listManager.spaceType, .all)
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.filterStateRelay.subscribe(onNext: { state in
            switch state {
            case .deactivated:
                expect.fulfill()
            default:
                return
            }
        }).disposed(by: bag)
        vm.refreshFilter()
        waitForExpectations(timeout: 10, handler: nil)
    }
}
