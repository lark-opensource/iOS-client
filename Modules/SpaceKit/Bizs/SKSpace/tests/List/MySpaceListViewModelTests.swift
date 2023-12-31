//
//  MySpaceListViewModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/10/8.
//

@testable import SKSpace
import Foundation
import SKFoundation
import SKCommon
import SKResource
import RxSwift
import XCTest
import SKInfra

final class MySpaceListViewModelTests: XCTestCase {
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
    
    static func mockVM(usingV2API: Bool = true) -> MySpaceViewModel {
        let dm = PersonalFileDataModel(userID: "userID", usingV2API: usingV2API)
        let vm = MySpaceViewModel(dataModel: dm)
        return vm
    }
    
    func testGenerateSlideConfig() {
        let vm = Self.mockVM()
        let expect = expectation(description: "my space list generate slide config")
        let cell = UIView()
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.generateSlideConfig(for: entry)
        let handler = config?.handler
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
        let expect = expectation(description: "my space vm test will resign active")
        vm.actionSignal.emit { action in
            if case .dismissRefreshTips = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        vm.willResignActive()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToRefresh() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.mySpaceListV3, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "my space vm test notify pull to refresh")
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
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.mySpaceListV3, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "my space vm test notify pull to refresh failed")
        vm.actionSignal.emit { action in
            if case let .stopPullToRefresh(total) = action {
                XCTAssertNil(total)
                expect.fulfill()
            }
        }.disposed(by: bag)
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToRefrshLoadMore() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.getPersonFileListInHome, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM(usingV2API: false)
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "123"))
        let expect = expectation(description: "my space vm test notify pull to load more success")
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 5)
    }
    
    func testNotifyPullToRefrshLoadMoreFailed() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.mySpaceListV3, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "my space vm test notify pull to load more failed")
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
        let expect = expectation(description: "test my space list contextMenuConfig")
        let cell = UIView()
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.contextMenuConfig(for: entry)
        let handler = config?.handler
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
    
    func testSortPanel() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.mySpaceListV3, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let sortVC = SpaceSortPanelController(options: vm.dataModel.sortHelper.legacyItemsForSortPanel, initialSelection: 0, canReset: false)
        let expect = expectation(description: "test myspace sort panel")
        expect.expectedFulfillmentCount = 4
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
    
    func testSortConfig() {
        let vm = Self.mockVM()
        let config = vm.generateSortFilterConfig()
        XCTAssertEqual(config?.sortItems, vm.dataModel.sortHelper.legacyItemsForSortPanel)
        XCTAssertEqual(config?.defaultSortItems, vm.dataModel.sortHelper.defaultLegacyItemsForSortPanel)
        XCTAssertEqual(config?.filterItems, vm.dataModel.filterHelper.legacyItemsForFilterPanel)
        XCTAssertEqual(config?.defaultFilterItems, vm.dataModel.filterHelper.defaultLegacyItemsForFilterPanel)
    }
    
    func testDidClickResetFor() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.mySpaceListV3, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let filterVC = SpaceFilterPanelController(options: vm.dataModel.filterHelper.legacyItemsForFilterPanel, initialSelection: 0)
        let expect = expectation(description: "test myspace sort panel reset")
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
    
    func testRefreshForMoreAction() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.mySpaceListV3, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        let expect = expectation(description: "my space vm test notify pull to refresh")
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
    
    func testHandleDelete() {
        let expect = expectation(description: "myspace vm test handle delete")
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "Node_Token", objToken: "Obj_Token")
        vm.actionSignal.emit { action in
            if case .present = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        vm.handleDelete(for: entry)
        waitForExpectations(timeout: 5)
    }
    
    func testDeleteFolder() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .folder, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "myspace vm test delete folder")
        expect.expectedFulfillmentCount = 3
        MockSpaceNetworkAPI.mockRemoveFromFolder(successTokens: [entry.objToken])
        
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
    
    func testDeleteFolderFailed() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .folder, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "myspace vm test delete folder")
        expect.expectedFulfillmentCount = 3
        MockSpaceNetworkAPI.mockRemoveFromFolder(type: MockNetworkResponse.recentListFailed)
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD(let hudAction):
                switch hudAction {
                case .failure:
                    expect.fulfill()
                case .customLoading(let content):
                    XCTAssertEqual(content, BundleI18n.SKResource.CreationMobile_Recent_Deleting_Toast)
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
    
    func testDeleteFile() {
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "myspace vm test delete file")
        expect.expectedFulfillmentCount = 3
        MockSpaceNetworkAPI.mockDelete(successTokens: [entry.objToken])
        
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
        let expect = expectation(description: "myspace vm test delete file failed")
        expect.expectedFulfillmentCount = 3
        MockSpaceNetworkAPI.mockDelete(type: MockNetworkResponse.recentListFailed)
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD(let hudAction):
                switch hudAction {
                case .customLoading(let content):
                    XCTAssertEqual(content, BundleI18n.SKResource.CreationMobile_Recent_Deleting_Toast)
                    expect.fulfill()
                case .failure:
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
    
    func testDeleteFileV2() {
        MockSpaceNetworkAPI.mockDeleteV2(type: MockSpaceNetworkAPI.DeleteV2Response.allSuccess)
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "myspace vm test delete file v2")
        expect.expectedFulfillmentCount = 2
        
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD(let hudAction):
                switch hudAction {
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
        vm.deleteV2(entry: entry)
        waitForExpectations(timeout: 5)
    }
    
    func testDeletedFileV2Failed() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.deleteV2, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let expect = expectation(description: "myspace vm test delete file V2 failed")
        expect.expectedFulfillmentCount = 2

        vm.actionSignal.emit { action in
            switch action {
            case .showHUD(let hudAction):
                switch hudAction {
                case .failure:
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
        vm.deleteV2(entry: entry)
        waitForExpectations(timeout: 5)
    }
}
