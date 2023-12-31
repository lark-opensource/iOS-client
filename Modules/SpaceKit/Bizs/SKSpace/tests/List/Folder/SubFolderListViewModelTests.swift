//
//  SubFolderListViewModelTests.swift
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
import SKInfra

 //TODO: majie.7 单测crash，先注释掉
final class SubFolderListViewModelTests: XCTestCase {
    private var bag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        //SKDataManager.shared.clear { _ in }
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = DisposeBag()
    }

    static func mockVM() -> SubFolderListViewModelV1 {
        let info = SubFolderDataModelV1.FolderInfo(token: "folder", folderType: .personal)
        let dm = SubFolderDataModelV1(folderInfo: info)
        let vm = SubFolderListViewModelV1(dataModel: dm)
        return vm
    }

    func testDidVecomeActive() {
        let vm = Self.mockVM()
        vm.prepare()
        vm.didBecomeActive()
        XCTAssertTrue(vm.isActive)
    }

    func testWillResignActive() {
        let vm = Self.mockVM()
        vm.prepare()
        vm.willResignActive()
        XCTAssertFalse(vm.isActive)
    }

    func testNotifyPullToRefresh() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.folderDetail, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder v1 refresh success")
        expect.expectedFulfillmentCount = 5

        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.listStatusChanged.emit { action in
            switch action {
            case .success:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)

        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 10)
    }

    func testNotifyPullToRefreshFailed() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.folderDetail, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder v1 refresh success")

        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)

        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 10)
    }

    func testNotifyPullToLoadMore() {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.folderDetail, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder v1 refresh load more")
        expect.expectedFulfillmentCount = 2
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
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.folderDetail, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder v1 refresh load more failed")
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
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.folderDetail, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder sort panel")
        let panel = SpaceSortPanelController(options: vm.dataModel.sortHelper.legacyItemsForSortPanel, initialSelection: 0, canReset: false)
        expect.expectedFulfillmentCount = 4
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore, .showHUD:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.sortPanel(panel, didSelect: 0, descending: true)
        waitForExpectations(timeout: 10)
    }

    func testHandleMoreAction() {
        let entry = FolderEntry(type: .folder, nodeToken: "folder", objToken: "folder")
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "subfolder handle more action")
        let handler = vm.handleMoreAction(for: entry)
        XCTAssertNotNil(handler)
        vm.actionSignal.emit { action in
            switch action {
            case .present:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        handler?(UIView())
        waitForExpectations(timeout: 10)
    }

    func testGenerateSlideConfig() {
        let vm = Self.mockVM()
        vm.prepare()
        
        let expect = expectation(description: "generate slide config")
        let entry = FolderEntry(type: .folder, nodeToken: "folder", objToken: "folder")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.generateSlideConfig(for: entry)
        let cell = UIView()
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
        let handler = config?.handler
        handler?(cell, .delete)
        handler?(cell, .share)
        handler?(cell, .more)
        waitForExpectations(timeout: 10)
    }

    func testGenerateSlideConfigWithTheSameOwner() {
        let user = User.current
        user.reloadUser(basicInfo: BasicUserInfo("123456789"))
        let vm = Self.mockVM()
        vm.prepare()
        
        let expect = expectation(description: "generate slide config")
        let entry = SpaceEntry(type: .docX, nodeToken: "docX", objToken: "docX")
        entry.updateOwnerID("123456789")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.generateSlideConfig(for: entry)
        let cell = UIView()
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
        let handler = config?.handler
        handler?(cell, .delete)
        handler?(cell, .share)
        handler?(cell, .more)
        waitForExpectations(timeout: 10)
    }

    func testGenerateSlideNoPermission() {
        let vm = Self.mockVM()
        vm.prepare()
        let expect = expectation(description: "generate slide config no permission")
        let entry = FolderEntry(type: .folder, nodeToken: "folder", objToken: "folder")
        let config = vm.generateSlideConfigForNoPermissionEntry(entry: entry)
        let cell = UIView()
        let handler = config?.handler
        XCTAssertEqual(config?.actions, [.delete])
        vm.actionSignal.emit { action in
            switch action {
            case .present:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        handler?(cell, .delete)
        waitForExpectations(timeout: 10)
    }
}
