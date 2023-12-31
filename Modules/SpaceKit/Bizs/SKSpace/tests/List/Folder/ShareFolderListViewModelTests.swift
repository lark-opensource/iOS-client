//
//  ShareFolderListViewModel.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/7/12.
//

@testable import SKSpace
import Foundation
import SKCommon
import XCTest
import RxSwift
import SKFoundation
import SKInfra


class ShareFolderListViewModelTests: XCTestCase {
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
    
    private func mockViewModel() -> ShareFolderListViewModel {
        let dataModel = ShareFolderDataModel(userID: "userid", usingAPI: .newShareFolder)
        let viewModel = ShareFolderListViewModel(dataModel: dataModel)
        return viewModel
    }
    
    func testDidSelectDeleteAction() {
        let viewModel = mockViewModel()
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        let expect = expectation(description: "test share folder list did select delete action")
        expect.expectedFulfillmentCount = 1
        
        viewModel.actionSignal.emit(onNext: { action in
            switch action {
            case .present:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        viewModel.didSelectDeleteAction(file: entry, completion: { _ in })
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testDidBecomeActive() {
        let vm = mockViewModel()
        
        
        vm.actionSignal.emit(onNext: { action in
            if case .stopPullToLoadMore = action {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        
        vm.didBecomeActive()
        XCTAssertTrue(vm.isActive)
    }
    
    func testWillResignActive() {
        let vm = mockViewModel()
        vm.willResignActive()
        XCTAssertFalse(vm.isActive)
    }
    
    func testNotifyPullToRefresh() {
        let vm = mockViewModel()
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        let expect = expectation(description: "test share folder list request success")
        expect.expectedFulfillmentCount = 2
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.notifyPullToRefresh()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNotifyPullToRefreshFailed() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test share folder list request failed")
        expect.expectedFulfillmentCount = 2
        let vm = mockViewModel()
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .stopPullToRefresh, .showHUD:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.notifyPullToRefresh()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNotifyPullToLoadMore() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        let expect = expectation(description: "test share folder list request load more success")
        expect.expectedFulfillmentCount = 1
        let vm = mockViewModel()
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        vm.actionSignal.emit(onNext: { action in
            if case .stopPullToLoadMore = action {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        vm.notifyPullToLoadMore()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNotifyPullToLoadMoreNativeFailed() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.sharefolderListSuccess)
        let expect = expectation(description: "test share folder list request load more native failed")
        expect.expectedFulfillmentCount = 1
        let vm = mockViewModel()
        
        vm.actionSignal.emit(onNext: { action in
            if case .stopPullToLoadMore(let hasMore) = action {
                XCTAssertFalse(hasMore)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        vm.notifyPullToLoadMore()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNotifyPullToLoadMoreRequestFailed() {
        MockSpaceNetworkAPI.mockShareFolderList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test share folder list request load more request failed")
        expect.expectedFulfillmentCount = 1
        let vm = mockViewModel()
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        
        vm.actionSignal.emit(onNext: { action in
            if case .stopPullToLoadMore(let hasMore) = action {
                XCTAssertTrue(hasMore)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        vm.notifyPullToLoadMore()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleMoreAction() {
        let expect = expectation(description: "test share folder list handle more action")
        expect.expectedFulfillmentCount = 2
        let vm = mockViewModel()
        let entry = FolderEntry(type: .folder, nodeToken: "fld123", objToken: "fld123")
        entry.update(secretKeyDelete: true)
        let handle = vm.handleMoreAction(for: entry)
        let view = UIView()
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .showHUD, .present:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        handle?(view)
        entry.update(secretKeyDelete: false)
        handle?(view)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandlePremissionTips() {
        let vm = mockViewModel()
        let entry = FolderEntry(type: .folder, nodeToken: "fld123", objToken: "fld123")
        let handle = vm.handlePermissionTips(for: entry)
        
        XCTAssertNil(handle)
    }
    
    func testGenerateSlideConfig() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.addFavorites, jsonFile: MockNetworkResponse.plainSuccess.rawValue)
        let vm = mockViewModel()
        let expect = expectation(description: "test share folder list slide more config")
        expect.expectedFulfillmentCount = 3
        let entry = FolderEntry(type: .folder, nodeToken: "fld123", objToken: "fld123")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let cell = UIView()
        
        let config = vm.generateSlideConfig(for: entry)
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .showHUD, .openShare, .present:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        config?.handler(cell, .unstar)
        config?.handler(cell, .share)
        config?.handler(cell, .more)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleDelete() {
        let vm = mockViewModel()
        let expect = expectation(description: "test share folder list handle delete")
        expect.expectedFulfillmentCount = 1
        let entry = FolderEntry(type: .folder, nodeToken: "fld123", objToken: "fld123")
        
        vm.actionSignal.emit(onNext: { action in
            if case .present = action {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        
        vm.handleDelete(for: entry)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testDeleteFile() {
        MockSpaceNetworkAPI.mockDeleteV2(type: MockNetworkResponse.plainSuccess)
        let expect = expectation(description: "test share folder list delete file")
        expect.expectedFulfillmentCount = 3
        let vm = mockViewModel()
        let entry = FolderEntry(type: .folder, nodeToken: "fld123", objToken: "fld123")
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .showHUD, .hideHUD:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.deleteFile(entry)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testDeleteFileFailed() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.deleteV2, jsonFile: MockNetworkResponse.noPermission.rawValue)
        let expect = expectation(description: "test share folder list delete file failed")
        expect.expectedFulfillmentCount = 3
        let vm = mockViewModel()
        let entry = FolderEntry(type: .folder, nodeToken: "fld123", objToken: "fld123")

        vm.actionSignal.emit { action in
            switch action {
            case let .showHUD(hudAction):
                switch hudAction {
                case .failure:
                    expect.fulfill()
                case .customLoading:
                    expect.fulfill()
                default:
                    return
                }
            case .hideHUD:
                expect.fulfill()
            default:
                return
            }
        }
        .disposed(by: bag)
        vm.deleteFile(entry)
        waitForExpectations(timeout: 3)
    }
}
