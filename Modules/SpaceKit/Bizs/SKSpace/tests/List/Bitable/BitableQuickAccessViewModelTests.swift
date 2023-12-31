//
//  QuickAccessViewModelTests.swift
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
import LarkContainer

final class BitableQuickAccessViewModelTests: XCTestCase {
    private var bag = DisposeBag()
    
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    
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
    
    static func mockVM(usingV2API: Bool = true, homeType: SpaceHomeType = .spaceTab) -> BitableQuickAccessViewModel {
        let dm = QuickAccessDataModel(userID: "userID", apiType: usingV2API ? .v2 : .v1)
        let vm = BitableQuickAccessViewModel(dataModel: dm, homeType: homeType)
        return vm
    }
    
    func testModel() {
        var homeType: SpaceHomeType = .spaceTab
        _testGenerateSlideConfig(homeType: homeType)
        _testDidBecomeActive(homeType: homeType)
        _testWillResignActive(homeType: homeType)
        _testNotifyPullToRefresh(homeType: homeType)
        _testNotifyPullToRefreshFailed(homeType: homeType)
        _testNotifyPullToLoadMore(homeType: homeType)
        _testContextMenuConfig(homeType: homeType)
        _testHandleMoreAction(homeType: homeType)
        _testHandlePermissionTips(homeType: homeType)
        _testRefreshForMoreAction(homeType: homeType)
        
        homeType = .baseHomeType(context: BaseHomeContext(userResolver: userResolver, containerEnv: .workbench, baseHpFrom: nil, version: .original))
        _testGenerateSlideConfig(homeType: homeType)
        _testDidBecomeActive(homeType: homeType)
        _testWillResignActive(homeType: homeType)
        _testNotifyPullToRefresh(homeType: homeType)
        _testNotifyPullToRefreshFailed(homeType: homeType)
        _testNotifyPullToLoadMore(homeType: homeType)
        _testContextMenuConfig(homeType: homeType)
        _testHandleMoreAction(homeType: homeType)
        _testHandlePermissionTips(homeType: homeType)
        _testRefreshForMoreAction(homeType: homeType)
    }
    
    func _testGenerateSlideConfig(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockUpdateIsPin(type: MockNetworkResponse.plainSuccess)
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "quick access list generate slide config")
        let cell = UIView()
        let entry = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.generateSlideConfig(for: entry)
        let handler = config?.handler
        expect.expectedFulfillmentCount = 3
        XCTAssertEqual(config?.actions, [.removeFromPin, .share, .more])
        
        vm.actionSignal.emit { action in
            switch action {
            case .present, .openShare, .showHUD:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        handler?(cell, .removeFromPin)
        handler?(cell, .share)
        handler?(cell, .more)
        waitForExpectations(timeout: 10)
    }
    
    func _testDidBecomeActive(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "quick access list vm test become active")
        
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore(let hasMore) = action {
                XCTAssertFalse(hasMore)
                expect.fulfill()
            }
        }.disposed(by: bag)
        vm.didBecomeActive()
        XCTAssertTrue(vm.isActive)
        waitForExpectations(timeout: 5)
    }
    
    func _testWillResignActive(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        vm.willResignActive()
        XCTAssertFalse(vm.isActive)
    }
    
    func _testNotifyPullToRefresh(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.getPinsV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "qucik access list vm test pull to refresh success")
        expect.expectedFulfillmentCount = 2
        
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh:
                expect.fulfill()
            case .stopPullToLoadMore(let hasMore):
                XCTAssertFalse(hasMore)
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 5)
    }
    
    func _testNotifyPullToRefreshFailed(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.getPinsV2, jsonFile: MockNetworkResponse.recentListFailed.rawValue)
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "quick access list vm test pull to refresh failed")
        
        vm.actionSignal.emit { action in
            if case .stopPullToRefresh(let total) = action {
                XCTAssertNil(total)
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.refreshForMoreAction()
        waitForExpectations(timeout: 5)
    }
    
    func _testNotifyPullToLoadMore(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "quick access list vm test pull to load more")
        
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore(let hasMore) = action {
                XCTAssertFalse(hasMore)
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 1)
    }
    
    func _testContextMenuConfig(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.contextMenuConfig(for: entry)
        XCTAssertEqual(config?.actions, [.removeFromPin, .share, .more])
    }
    
    func _testHandleMoreAction(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let handler = vm.handleMoreAction(for: entry)
        let expect = expectation(description: "qucik access list handle more action")
        vm.actionSignal.emit { action in
            if case .present = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        
        handler?(UIView())
        waitForExpectations(timeout: 5)
    }
    
    func _testHandlePermissionTips(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "NODE_TOKEN", objToken: "OBJ_TOKEN")
        let handler = vm.handlePermissionTips(for: entry)
        XCTAssertNil(handler)
    }
    
    func _testRefreshForMoreAction(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mock(path: OpenAPI.APIPath.getPinsV2, jsonFile: MockNetworkResponse.recentListSuccess.rawValue)
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "qucik access list vm test refresh for more action")
        expect.expectedFulfillmentCount = 2
        
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh:
                expect.fulfill()
            case .stopPullToLoadMore(let hasMore):
                XCTAssertFalse(hasMore)
                expect.fulfill()
            default:
                return
            }
        }.disposed(by: bag)
        
        vm.refreshForMoreAction()
        waitForExpectations(timeout: 5)
        
    }
    
}
