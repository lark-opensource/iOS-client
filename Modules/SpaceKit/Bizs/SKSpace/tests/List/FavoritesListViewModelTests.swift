//
//  FavoritesListViewModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/9/30.
//

@testable import SKSpace
import Foundation
import SKCommon
import SKFoundation
import RxSwift
import XCTest
import LarkContainer


final class FavoritesListViewModelTests: XCTestCase {
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
    
    static func mockVM(homeType: SpaceHomeType = .spaceTab) -> FavoritesViewModel {
        FavoritesViewModel(dataModel: FavoritesDataModelTests.mockDM(), homeType: homeType)
    }
    
    func testModel() {
        var homeType: SpaceHomeType = .spaceTab
        _testDidBecomeActive(homeType: homeType)
        _testWillRsignActive(homeType: homeType)
        _testNotifyPullToRefresh(homeType: homeType)
        _testNotifyPullToRefreshFailed(homeType: homeType)
        _testNotifyPullToLoadMore(homeType: homeType)
        _testNotifyPullToLoadMoreFailed(homeType: homeType)
        _testGenerateSortFilterConfig(homeType: homeType)
        _testDidClcikResetFor(homeType: homeType)
        _testHandleMoreAction(homeType: homeType)
        _testHandleMoreActionSecretKeyDeleted(homeType: homeType)
        _testGenerateSlideConfig(homeType: homeType)
        
        homeType = .baseHomeType(context: BaseHomeContext(userResolver: userResolver, containerEnv: .workbench, baseHpFrom: nil, version: .original))
        _testDidBecomeActive(homeType: homeType)
        _testWillRsignActive(homeType: homeType)
        _testNotifyPullToRefresh(homeType: homeType)
        _testNotifyPullToRefreshFailed(homeType: homeType)
        _testNotifyPullToLoadMore(homeType: homeType)
        _testNotifyPullToLoadMoreFailed(homeType: homeType)
        _testGenerateSortFilterConfig(homeType: homeType)
        _testDidClcikResetFor(homeType: homeType)
        _testHandleMoreAction(homeType: homeType)
        _testHandleMoreActionSecretKeyDeleted(homeType: homeType)
        _testGenerateSlideConfig(homeType: homeType)
    }
    
    func _testDidBecomeActive(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "favorites-vm-test-becomeActive")
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
    
    func _testWillRsignActive(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        vm.willResignActive()
        XCTAssertFalse(vm.isActive)
    }
    
    
    func _testNotifyPullToRefresh(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "favorite-vm-refresh")
        expect.expectedFulfillmentCount = 2
        let vm = Self.mockVM(homeType: homeType)
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
    
    func _testNotifyPullToRefreshFailed(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "favorite-vm-refresh")
        let vm = Self.mockVM(homeType: homeType)
        vm.actionSignal.emit { action in
            if case let .stopPullToRefresh(total) = action {
                XCTAssertNil(total)
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 10)
    }
    
    func _testNotifyPullToLoadMore(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "favorite-vm-loadmore")
        let vm = Self.mockVM(homeType: homeType)
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
    
    func _testNotifyPullToLoadMoreFailed(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockFavoritesList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "favorite-vm-refresh")
        let vm = Self.mockVM(homeType: homeType)
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore = action {
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 10)
    }
    
    func _testGenerateSortFilterConfig(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let config = vm.generateSortFilterConfig()
        XCTAssertEqual(vm.dataModel.filterHelper.legacyItemsForFilterPanel, config?.filterItems)
        XCTAssertEqual(vm.dataModel.filterHelper.defaultLegacyItemsForFilterPanel, config?.defaultFilterItems)
        XCTAssertTrue(config?.sortItems.isEmpty == true)
        XCTAssertTrue(config?.defaultSortItems.isEmpty == true)
    }
    
    func _testDidClcikResetFor(homeType: SpaceHomeType = .spaceTab) {
        let vm = Self.mockVM(homeType: homeType)
        let expect = expectation(description: "favorite-vm-reset-filter")
        expect.expectedFulfillmentCount = 3
        vm.actionSignal.emit { action in
            switch action {
            case .stopPullToRefresh, .stopPullToLoadMore:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        let panel = SpaceFilterPanelController(options: vm.dataModel.filterHelper.defaultLegacyItemsForFilterPanel, initialSelection: nil)
        vm.didClickResetFor(filterPanel: panel)
        waitForExpectations(timeout: 10)
    }
    
    func _testHandleMoreAction(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "favorites-vm-more-action")
        let entry = SpaceEntry(type: .docX, nodeToken: "token", objToken: "token")
        let vm = Self.mockVM(homeType: homeType)
        vm.actionSignal.emit { action in
            if case .present = action {
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        let handler = vm.handleMoreAction(for: entry)
        handler?(UIView())
        waitForExpectations(timeout: 10)
    }
    
    func _testHandleMoreActionSecretKeyDeleted(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "favorites-vm-more-action")
        let entry = SpaceEntry(type: .docX, nodeToken: "token", objToken: "token")
        let vm = Self.mockVM(homeType: homeType)
        entry.update(secretKeyDelete: true)
        vm.actionSignal.emit { action in
            if case .showHUD = action {
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        let handler = vm.handleMoreAction(for: entry)
        handler?(UIView())
        waitForExpectations(timeout: 10)
    }
    
    func _testGenerateSlideConfig(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "favorites-vm-more-action")
        expect.expectedFulfillmentCount = 3
        let entry = SpaceEntry(type: .docX, nodeToken: "token", objToken: "token")
        let vm = Self.mockVM(homeType: homeType)
        entry.updateShareURL("https://www.doc.xxx")
        let config = vm.generateSlideConfig(for: entry)
        let actions: [SlideAction] = [.unstar, .share, .more]
        XCTAssertEqual(actions, config?.actions)
        let handler = config?.handler
        vm.actionSignal.emit { action in
            switch action {
            case .showHUD, .present, .openShare:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: bag)
        
        let cell = UIView()
        handler?(cell, .more)
        handler?(cell, .unstar)
        handler?(cell, .share)
        waitForExpectations(timeout: 10)
    }
}
