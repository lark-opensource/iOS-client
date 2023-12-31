//
//  MyFolderListViewModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/10/8.
//
@testable import SKSpace
import Foundation
import SKFoundation
import SKCommon
import XCTest
import RxSwift

final class MyFolderListViewModelTests: XCTestCase {
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
    
    static func mockVM() -> MyFolderListViewModel {
        let dm = MyFolderDataModel(userID: "userID")
        let vm = MyFolderListViewModel(dataModel: dm)
        return vm
    }
    
    func testDidBecomeActive() {
        let expect = expectation(description: "myfolder did become active")
        let vm = Self.mockVM()
        vm.actionSignal.emit { action in
            if case let .stopPullToLoadMore(hasMore) = action {
                XCTAssertFalse(hasMore)
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.didBecomeActive()
        XCTAssertTrue(vm.isActive)
        
        waitForExpectations(timeout: 10)
    }
    
    func testWillResignActive() {
        let vm = Self.mockVM()
        XCTAssertFalse(vm.isActive)
    }
    
    func testNotifyPullToRefresh() {
        MockSpaceNetworkAPI.mockMyFolderList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "myfolder list pull to refresh success")
        expect.expectedFulfillmentCount = 2
        let vm = Self.mockVM()
        
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 10)
    }
    
    func testNotifyPullToRefreshFailed() {
        MockSpaceNetworkAPI.mockMyFolderList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "my folder list pull to refresh failed")
        let vm = Self.mockVM()
        vm.actionSignal.emit { action in
            switch action {
            case let .stopPullToRefresh(total):
                XCTAssertNil(total)
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 10)
    }
    
    func testNotifyPullToLoadMore() {
        MockSpaceNetworkAPI.mockMyFolderList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "my folder list pull to load more success")
        let vm = Self.mockVM()
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToLoadMore:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 10)
    }
    
    func testNotifyPullToLoadMoreFailed() {
        MockSpaceNetworkAPI.mockMyFolderList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "my folder list pull to load more failed")
        let vm = Self.mockVM()
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "1234"))
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToLoadMore:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 10)
    }
    
    func testSortPanel() {
        MockSpaceNetworkAPI.mockMyFolderList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "my folder list sort panel")
        expect.expectedFulfillmentCount = 2
        let vm = Self.mockVM()
        let panel = SpaceSortPanelController(options: vm.dataModel.sortHelper.legacyItemsForSortPanel, initialSelection: 0, canReset: false)
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToLoadMore:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        vm.sortPanel(panel, didSelect: 0, descending: true)
        waitForExpectations(timeout: 10)
    }
    
    func testFolderMoreAction() {
        let vm = Self.mockVM()
        let action = vm.folderMoreAction()
        XCTAssertNil(action)
    }
    
    func testHandleMoreAction() {
        let vm = Self.mockVM()
        let expect = expectation(description: "my folder list handle more action")
        let entry_1 = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        let entry_2 = SpaceEntry(type: .file, nodeToken: "file", objToken: "file")
        entry_2.update(secretKeyDelete: true)
        expect.expectedFulfillmentCount = 2
        let handle_1 = vm.handleMoreAction(for: entry_1)
        let handle_2 = vm.handleMoreAction(for: entry_2)
        XCTAssertNotNil(handle_1)
        XCTAssertNotNil(handle_2)
        
        vm.actionSignal.emit { action in
            switch action {
            case .present, .showHUD:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        handle_1?(UIView())
        handle_2?(UIView())
        waitForExpectations(timeout: 10)
    }
    
    func testHandlePermissionTips() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        let handle = vm.handlePermissionTips(for: entry)
        XCTAssertNil(handle)
    }
    
    func testGenerateSlideConfig() {
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let expect = expectation(description: "my folder list slide config")
        let vm = Self.mockVM()
        let config = vm.generateSlideConfig(for: entry)
        let handler = config?.handler
        let cell = UIView()
        expect.expectedFulfillmentCount = 3
        entry.updateShareURL("https://www.doc.xxx")
        XCTAssertEqual(config?.actions, [.delete, .share, .more])
        
        vm.actionSignal.emit { action in
            switch action {
            case .present, .openShare:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        handler?(cell, .delete)
        handler?(cell, .share)
        handler?(cell, .more)
        waitForExpectations(timeout: 10)
    }
    
    func testDeleteFile() {
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        MockSpaceNetworkAPI.mockRemoveFromFolder(successTokens: [entry.objToken])
        let expect = expectation(description: "my folder list delete file")
        expect.expectedFulfillmentCount = 3
        let vm = Self.mockVM()
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD, .hideHUD:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.deleteFile(entry)
        waitForExpectations(timeout: 10)
    }
    
    func testDeleteFileFailed() {
        MockSpaceNetworkAPI.mockRemoveFromFolder(type: MockNetworkResponse.recentListFailed)
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        let expect = expectation(description: "my folder list delete file failed")
        expect.expectedFulfillmentCount = 3
        let vm = Self.mockVM()
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD, .hideHUD:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.deleteFile(entry)
        waitForExpectations(timeout: 10)
    }
}
