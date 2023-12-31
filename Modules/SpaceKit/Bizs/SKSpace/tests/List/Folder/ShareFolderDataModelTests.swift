//
//  ShareFolderDataModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/7/22.
//

@testable import SKSpace
import Foundation
import SKFoundation
import SKCommon
import XCTest
import RxSwift
import SKInfra

class ShareFolderDataModelTests: XCTestCase {
    private var bag = DisposeBag()
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        SKDataManager.shared.clear { _ in }
    }
    
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = .init()
    }
    
    func mockApiPath(type: ShareFolderAPIType) -> String {
        switch type {
        case .shareFolderV1, .shareFolderV2:
            return OpenAPI.APIPath.newShareFolder
        case .newShareFolder, .hiddenFolder:
            return OpenAPI.APIPath.newShareFolderV2
        }
    }
    
    func MockDataModel(usingApI: ShareFolderAPIType) -> ShareFolderDataModel {
        let dataModel = ShareFolderDataModel(userID: "123", usingAPI: usingApI)
        return dataModel
    }
    
    func testRefresh() {
        let expect = expectation(description: "test share folder list request success")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        dm.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        dm.refresh().subscribe(onCompleted: {
            XCTAssertTrue(true)
            expect.fulfill()
        }).disposed(by: bag)
        
//        dm.hiddenFolderVisableRelay.subscribe(onNext: { value in
//            XCTAssertFalse(value)
//            expect.fulfill()
//        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRefreshFailed() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test share folder list request failed")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        dm.refresh().subscribe(onCompleted: {
            XCTAssertTrue(false)
            expect.fulfill()
        }, onError: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testLoadMore() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        let expect = expectation(description: "test share folder list load more request success")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        dm.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        dm.loadMore().subscribe(onCompleted: {
            XCTAssertTrue(true)
            expect.fulfill()
        }, onError: { error in
            XCTAssertNil(error)
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testLoadMoreFailed() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test share folder list load more request failed")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        dm.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        dm.loadMore().subscribe(onCompleted: {
            XCTAssertTrue(false)
            expect.fulfill()
        }, onError: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testLoadMoreNativeFailed() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        let expect = expectation(description: "test share folder list load more native failed")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        dm.loadMore().subscribe(onCompleted: {
            XCTAssertTrue(false)
            expect.fulfill()
        }, onError: { error in
            if let listError = error as? RecentListDataModel.RecentDataError,
               listError == .unableToLoadMore {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testOldRemoveFromList() {
        let entry = FolderEntry(type: .folder, nodeToken: "nodeToken", objToken: "objToken")
        let mockDeleteToken = "mock-delete-token"
        MockSpaceNetworkAPI.mockRemoveFromFolder(successTokens: [entry.objToken, mockDeleteToken])
        let expect = expectation(description: "test share folder list old recomve from list")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .shareFolderV1)
        dm.removeFromList(fileEntry: entry)
            .subscribe { response in
                if case .success = response {
                } else {
                    XCTFail("un-expected response")
                }
                expect.fulfill()
            } onError: { error in
                XCTAssertNil(error)
                expect.fulfill()
            }
            .disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNewRemoveFromList() {
        let entry = FolderEntry(type: .folder, nodeToken: "nodeToken", objToken: "objToken")
        MockSpaceNetworkAPI.mockDeleteV2(type: MockSpaceNetworkAPI.DeleteV2Response.allSuccess)
        let expect = expectation(description: "test share folder list new delete from list")
        expect.expectedFulfillmentCount = 1
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        dm.removeFromList(fileEntry: entry)
            .subscribe { response in
                if case .success = response {
                } else {
                    XCTFail("un-expected response")
                }
                expect.fulfill()
            } onError: { error in
                XCTAssertNil(error)
                expect.fulfill()
            }
            .disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testIsLocalDataForShareFolderList() {
        let expect = expectation(description: "test share folder list new delete from list")
        expect.expectedFulfillmentCount = 1
        let dm = MockDataModel(usingApI: .newShareFolder)
        let data = MockSKListData()
        dm.dataChange(data: data, operational: .setHiddenV2)
        
        dm.hiddenFolderVisableRelay.subscribe(onNext: { value in
            XCTAssertTrue(value)
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testShowHiddenFolderTabIfNeed() {
        let expect = expectation(description: "test share folder list new delete from list")
        expect.expectedFulfillmentCount = 1
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        
        let dm = MockDataModel(usingApI: .newShareFolder)
        dm.hiddenFolderVisableRelay.subscribe(onNext: { _ in
            XCTAssertTrue(true)
            expect.fulfill()
        }).disposed(by: bag)
        dm.showHiddenFolderTabIfNeed()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSKListServiceType() {
        let dm_1 = MockDataModel(usingApI: .shareFolderV1)
        let dm_2 = MockDataModel(usingApI: .newShareFolder)
        let dm_3 = MockDataModel(usingApI: .hiddenFolder)
        
        XCTAssertTrue(dm_1.type == .specialList(folderKey: .shareFolder))
        XCTAssertTrue(dm_2.type == .specialList(folderKey: .shareFolderV2))
        XCTAssertTrue(dm_3.type == .specialList(folderKey: .hiddenFolder))
    }
    
}

class MockSKListData: SKListData {
    var folderNodeToken: String {
        "mock-folder-node-token"
    }
    
    var files: [SpaceEntry] {
        [SpaceEntry(type: .folder, nodeToken: "nodeToken-1", objToken: "objToken-1"),
         SpaceEntry(type: .folder, nodeToken: "nodeToken-2", objToken: "objToken-2"),
         SpaceEntry(type: .folder, nodeToken: "nodeToken-3", objToken: "objToken-3")]
    }
    
    var isHasMore: Bool? {
        true
    }
    
    var lastLabel: String? {
        "1234"
    }
    
    var total: Int {
        3
    }
}
