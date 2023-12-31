//
//  ShareSpaceViewModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/10/8.
//

@testable import SKSpace
import Foundation
import SKFoundation
import SKCommon
import RxSwift
import XCTest
import SKResource
import SKInfra

final class SharedSpaceViewModelTests: XCTestCase {
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
    
    static func mockVM(apiType: SharedFileApiType = .sharedFileV3) -> SharedSpaceViewModel {
        let dm = SharedFileDataModel(userID: "userID", usingAPI: apiType)
        let vm = SharedSpaceViewModel(dataModel: dm)
        return vm
    }
    
    func testGenerateSlideConfig() {
        let dm = SharedFileDataModel(userID: "userID", usingAPI: .sharedFileV1)
        let vm = SharedSpaceViewModel(dataModel: dm)
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.generateSlideConfig(for: entry)
        let handler = config?.handler
        let cell = UIView()
        let expect = expectation(description: "shared space viewModel slide config")
        expect.expectedFulfillmentCount = 3
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
    
    func testDidBecomeActive() {
        let vm = Self.mockVM()
        vm.didBecomeActive()
        XCTAssertTrue(vm.isActive)
    }
    
    func testWillResignActive() {
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test will resign active")
        vm.actionSignal.emit { action in
            if case .dismissRefreshTips(let needScrollToTop) = action {
                XCTAssertFalse(needScrollToTop)
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.willResignActive()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToRefresh() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test notify pull to refresh")
        expect.expectedFulfillmentCount = 2
        
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToRefreshFailed() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test notify pull to refresh failed")
        
        vm.actionSignal.emit { action in
            if case .stopPullToRefresh(let total) = action {
                XCTAssertNil(total)
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToLoadMore() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test notify to load more")
        
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "123"))
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToLoadMoreFailed() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test notify to load more failed")
        
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "123"))
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 5)
    }
    
    func testContextMenuConfig() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        
        let config = vm.generateSlideConfig(for: entry)
        XCTAssertEqual(config?.actions, [.star, .share, .more])
    }
    
    func testSortPanel() {
        let vm = Self.mockVM()
        let sortVC = SpaceSortPanelController(options: vm.dataModel.sortHelper.legacyItemsForSortPanel, initialSelection: 0, canReset: false)
        let expect = expectation(description: "share space vm test sort panel")
        expect.expectedFulfillmentCount = 4
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.sortPanel(sortVC, didSelect: 0, descending: false)
        waitForExpectations(timeout: 5)
    }
    
    func testGenerateSortFilterConfig() {
        let vm = Self.mockVM()
        let config = vm.generateSortFilterConfig()
        
        XCTAssertEqual(config?.sortItems, vm.dataModel.sortHelper.legacyItemsForSortPanel)
        XCTAssertEqual(config?.defaultSortItems, vm.dataModel.sortHelper.defaultLegacyItemsForSortPanel)
        XCTAssertEqual(config?.filterItems, vm.dataModel.filterHelper.legacyItemsForFilterPanel)
        XCTAssertEqual(config?.defaultFilterItems, vm.dataModel.filterHelper.defaultLegacyItemsForFilterPanel)
    }
    
    func testDidClickResetFor() {
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test did click reset for")
        let filterVC = SpaceFilterPanelController(options: vm.dataModel.filterHelper.legacyItemsForFilterPanel,
                                                  initialSelection: nil)
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        
        expect.expectedFulfillmentCount = 4
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.didClickResetFor(filterPanel: filterVC)
        waitForExpectations(timeout: 5)
    }
    
    func testHandleMoreAction() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let handler = vm.handleMoreAction(for: entry)
        let expect = expectation(description: "myspace vm test handle more action")
        
        vm.actionSignal.emit { action in
            if case .present = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        handler?(UIView())
        waitForExpectations(timeout: 5)
    }
    
    func testHandlePermission() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let handler = vm.handlePermissionTips(for: entry)
        
        XCTAssertNil(handler)
    }
    
    func testRefreshForMoreAction() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.shareFilesV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "share space vm test refresh for more action")
        expect.expectedFulfillmentCount = 2
        
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.refreshForMoreAction()
        waitForExpectations(timeout: 5)
    }
    
    func testDidSelectDeleteAction() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "share space vm test did select delete action")
        
        vm.actionSignal.emit { action in
            if case .present = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.didSelectDeleteAction(file: entry) { confirm in
            return
        }
        waitForExpectations(timeout: 5)
    }
    
    func testDeleteFile() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "share space test delete file")
        expect.expectedFulfillmentCount = 3
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.deleteShareWithMeListFileByObjToken,
                                 jsonFile: MockSpaceNetworkAPI.DeleteV2Response.allSuccess.rawValue)
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD(let hudAction):
                switch hudAction {
                case .customLoading(let content):
                    XCTAssertEqual(content, BundleI18n.SKResource.CreationMobile_Recent_Deleting_Toast)
                    expect.fulfill()
                case .success(let content):
                    XCTAssertEqual(content, BundleI18n.SKResource.Doc_Facade_DeleteSuccessfullyToastTip)
                    expect.fulfill()
                default:
                    return
                }
            case .hideHUD:
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.deleteFile(entry)
        waitForExpectations(timeout: 5)
    }
    
    func testDeleteFileFailed() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "share space test delete file failed")
        expect.expectedFulfillmentCount = 3
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.deleteShareWithMeListFileByObjToken,
                                 jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD, .hideHUD:
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.deleteFile(entry)
        waitForExpectations(timeout: 5)
    }
}
