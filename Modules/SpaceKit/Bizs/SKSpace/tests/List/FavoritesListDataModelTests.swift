//
//  FavoritesListDataModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/9/30.
//
@testable import SKSpace
import Foundation
import XCTest
import SKCommon
import SKFoundation
import RxSwift
import OHHTTPStubs


class FavoritesDataModelTests: XCTestCase {
    static var mockUserID: String = "userID"
    static func mockDM(usingV2: Bool = true) -> FavoritesDataModel {
        return FavoritesDataModel(userID: Self.mockUserID, usingV2API: usingV2, homeType: .spaceTab)
    }
    
    private var bag = DisposeBag()
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        SKDataManager.shared.clear { _ in }
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = DisposeBag()
    }
    
    func testRefreshSuccess() {
        let expect = expectation(description: "test recent list request success")
        let dm = Self.mockDM()
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListSuccess)
        dm.refresh().subscribe(onCompleted: {
            expect.fulfill()
        }, onError: {_ in
            XCTFail("refresh-list-failed")
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10)
    }
    
    func testRefreshFailed() {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list request failed")
        let dm = Self.mockDM()
        dm.refresh().subscribe(onCompleted: {
            XCTFail("refresh-list-should-not-success")
        }, onError: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 10)
    }
    
    func testLoadMoreSuccess() {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list load more request success")
        
        let dm = Self.mockDM()
        dm.listContainer.update(pagingState: .hasMore(lastLabel: "51242"))
        dm.loadMore().subscribe(onCompleted: {
            expect.fulfill()
        }, onError: { _ in
            XCTFail("load-more-list-failed")
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10)
    }
    
    func testLoadMoreFailed() {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list load more request failed")
        
        let dm = Self.mockDM()
        dm.listContainer.update(pagingState: .hasMore(lastLabel: "51242"))
        dm.loadMore().subscribe(onCompleted: {
            XCTFail("load-more-should-not-success")
        }, onError: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10)
    }
}
