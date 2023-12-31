//
//  RecentListViewModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/7/12.
//
@testable import SKSpace
import Foundation
import SKCommon
import XCTest
import SKResource
import SKFoundation
import RxSwift
import LarkContainer


class RecentListViewModelTests: XCTestCase {
    private var bag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = .init()
    }
    
    private func createRecentListViewModel(homeType: SpaceHomeType = .spaceTab) -> RecentListViewModel {
        let mockContainer = SpaceListContainer(listIdentifier: "MOCK_RECENT_TEST")
        let mockInteractionManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: mockInteractionManager)
        let mockDM = RecentListDataModel(userResolver: self.userResolver,
                                         dataManager: MockRecentDataProvider(),
                                         interactionHelper: helper,
                                         sortHelper: .recent,
                                         filterHelper: .recent,
                                         listContainer: mockContainer,
                                         listAPI: StandardRecentListAPI.self,
                                         homeType: homeType)
        let viewModel = RecentListViewModel(dataModel: mockDM)
        return viewModel
    }
    
    func testModel() {
        var homeType: SpaceHomeType = .spaceTab
        _testGenerateSlideConfig(homeType: homeType)
        _testNotifyPullToRefreashSuccess(homeType: homeType)
        _testNotifyPullToRefreshFailed(homeType: homeType)
        _testNotifyPullToLoadMoreSuccess(homeType: homeType)
        _testNotifyPullToLoadMoreNetFailed(homeType: homeType)
        _testNotifyPullToLoadMoreNativeFailed(homeType: homeType)
        _testWillResignActive(homeType: homeType)
        _testContextMenuConfig(homeType: homeType)
        _testHandleMoreAction(homeType: homeType)
        _testHanldePremissionTips(homeType: homeType)
        _testGenerateSlideConfigHandler(homeType: homeType)
        _testGenerateSlideConfigDeleteHandler(homeType: homeType)
        _testIsActive(homeType: homeType)
        _testItemChangedEvent(homeType: homeType)
        _testSelectItem(homeType: homeType)
        _testInvalidFilterSortCombination(homeType: homeType)
        
        homeType = .baseHomeType(context: BaseHomeContext(userResolver: userResolver, containerEnv: .workbench, baseHpFrom: nil, version: .original))
        _testGenerateSlideConfig(homeType: homeType)
        _testNotifyPullToRefreashSuccess(homeType: homeType)
        _testNotifyPullToRefreshFailed(homeType: homeType)
        _testNotifyPullToLoadMoreSuccess(homeType: homeType)
        _testNotifyPullToLoadMoreNetFailed(homeType: homeType)
        _testNotifyPullToLoadMoreNativeFailed(homeType: homeType)
        _testWillResignActive(homeType: homeType)
        _testContextMenuConfig(homeType: homeType)
        _testHandleMoreAction(homeType: homeType)
        _testHanldePremissionTips(homeType: homeType)
        _testGenerateSlideConfigHandler(homeType: homeType)
        _testGenerateSlideConfigDeleteHandler(homeType: homeType)
        _testIsActive(homeType: homeType)
        _testItemChangedEvent(homeType: homeType)
        _testSelectItem(homeType: homeType)
        _testInvalidFilterSortCombination(homeType: homeType)
    }
    
    func _testGenerateSlideConfig(homeType: SpaceHomeType = .spaceTab) {
        let actions: [SlideAction] = [.remove, .share, .more]
        let vm = createRecentListViewModel(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        let config = vm.generateSlideConfig(for: entry)
        
        XCTAssertEqual(actions, config?.actions)
    }
    
    func _testNotifyPullToRefreashSuccess(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list vm pull to refresh success")
        expect.expectedFulfillmentCount = 2
        
        let vm = createRecentListViewModel(homeType: homeType)
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
    
    func _testNotifyPullToRefreshFailed(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list vm pull to refresh failed")
        expect.expectedFulfillmentCount = 1
        
        let vm = createRecentListViewModel(homeType: homeType)
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .stopPullToRefresh:
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
    
    func _testNotifyPullToLoadMoreSuccess(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list vm pull to load more success")
        expect.expectedFulfillmentCount = 1
        
        let vm = createRecentListViewModel(homeType: homeType)
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "51242"))
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .stopPullToLoadMore:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.notifyPullToLoadMore()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func _testNotifyPullToLoadMoreNetFailed(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list vm pull to load more failed")
        expect.expectedFulfillmentCount = 1
        
        let vm = createRecentListViewModel(homeType: homeType)
        vm.dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "51242"))
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case let .stopPullToLoadMore(hasMore):
                print("test notify load more vm_1 has more: \(hasMore)")
                XCTAssertTrue(hasMore)
                expect.fulfill()
            default:
                print("test notify load more vm_1 default")
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.notifyPullToLoadMore()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func _testNotifyPullToLoadMoreNativeFailed(homeType: SpaceHomeType = .spaceTab) {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list vm pull to load more native failed")
        expect.expectedFulfillmentCount = 1
        
        let vm = createRecentListViewModel(homeType: homeType)
        vm.prepare()
        vm.actionSignal.emit(onNext: { action in
            print("test notify load more vm has more action : \(action)")
            switch action {
            case let .stopPullToLoadMore(hasMore):
                print("test notify load more vm has more: \(hasMore)")
                XCTAssertFalse(hasMore)
                expect.fulfill()
            default:
                print("test notify load more vm default")
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.notifyPullToLoadMore()
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func _testWillResignActive(homeType: SpaceHomeType = .spaceTab) {
        let vm = createRecentListViewModel(homeType: homeType)
        vm.actionSignal.emit(onNext: { action in
            if case .dismissRefreshTips = action {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        vm.willResignActive()
    }
    
    func _testContextMenuConfig(homeType: SpaceHomeType = .spaceTab) {
        let actions: [SlideAction] = [.remove, .share, .more]
        let vm = createRecentListViewModel(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        let config = vm.contextMenuConfig(for: entry)
        
        XCTAssertEqual(actions, config?.actions)
    }
    
    func _testHandleMoreAction(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "test recent list handle more action")
        expect.expectedFulfillmentCount = 2
        
        let entry_1 = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        entry_1.update(secretKeyDelete: true)
        let entry_2 = SpaceEntry(type: .docX, nodeToken: "nodeToken-2", objToken: "objToken-2")
        let vm = createRecentListViewModel(homeType: homeType)
        let testView = UIView()
        
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
        
        let handler_1 = vm.handleMoreAction(for: entry_1)
        let handler_2 = vm.handleMoreAction(for: entry_2)
        handler_1?(testView)
        handler_2?(testView)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func _testHanldePremissionTips(homeType: SpaceHomeType = .spaceTab) {
        let vm = createRecentListViewModel(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        
        let handle = vm.handlePermissionTips(for: entry)
        XCTAssertNil(handle)
    }
    
    func _testGenerateSlideConfigHandler(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "test recent list slide action handler")
        expect.expectedFulfillmentCount = 3
        
        let vm = createRecentListViewModel(homeType: homeType)
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        entry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let config = vm.contextMenuConfig(for: entry)
        let handler = config?.handler
        let cell = UIView()
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .openShare, .present, .confirmDeleteAction:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        

        handler?(cell, .share)
        handler?(cell, .more)
        handler?(cell, .remove)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    
    func _testGenerateSlideConfigDeleteHandler(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "test recent list slide action handler")
        expect.expectedFulfillmentCount = 3
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        let mockDeleteToken = "mock-delete-token"
        MockSpaceNetworkAPI.mockDelete(successTokens: [entry.objToken, mockDeleteToken])
        
        let vm = createRecentListViewModel(homeType: homeType)
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .showHUD, .hideHUD:
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
    
        vm.delete(file: entry, shouldDeleteOriginFile: true)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        
    }

    func _testIsActive(homeType: SpaceHomeType = .spaceTab) {
        let viewModel = createRecentListViewModel(homeType: homeType)
        XCTAssertFalse(viewModel.isActive)
        XCTAssertFalse(viewModel.dataFlowActive)

        viewModel.notifySectionDidAppear()
        XCTAssertTrue(viewModel.dataFlowActive)
        XCTAssertFalse(viewModel.isActive)
        viewModel.notifySectionWillDisappear()
        XCTAssertFalse(viewModel.dataFlowActive)
        XCTAssertFalse(viewModel.isActive)

        viewModel.didBecomeActive()
        XCTAssertTrue(viewModel.isActive)
        XCTAssertFalse(viewModel.dataFlowActive)
        viewModel.willResignActive()
        XCTAssertFalse(viewModel.isActive)
        XCTAssertFalse(viewModel.dataFlowActive)
    }

    func _testItemChangedEvent(homeType: SpaceHomeType = .spaceTab) {
        let mockContainer = SpaceListContainer(listIdentifier: "MOCK_RECENT_TEST")
        let mockInteractionManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: mockInteractionManager)
        let mockDM = RecentListDataModel(userResolver: self.userResolver,
                                         dataManager: MockRecentDataProvider(),
                                         interactionHelper: helper,
                                         sortHelper: .recent,
                                         filterHelper: .recent,
                                         listContainer: mockContainer,
                                         listAPI: StandardRecentListAPI.self,
                                         homeType: homeType)
        let viewModel = RecentListViewModel(dataModel: mockDM)
        var expect = expectation(description: "test inactive")
        expect.isInverted = true
        viewModel.datatUpdatedFrom = { _ in
            expect.fulfill()
        }
        viewModel.prepare()
        mockContainer.restore(localData: [])
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test resume active and replay")
        viewModel.datatUpdatedFrom = { from in
            XCTAssertEqual(from, .database(isEmpty: true))
            expect.fulfill()
        }
        viewModel.notifySectionDidAppear()
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test normal when active")
        viewModel.datatUpdatedFrom = { from in
            XCTAssertEqual(from, .server)
            expect.fulfill()
        }
        mockContainer.sync(serverData: [])
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test enter inactive")
        expect.isInverted = true
        viewModel.datatUpdatedFrom = { from in
            expect.fulfill()
        }
        viewModel.notifySectionWillDisappear()
        mockContainer.sync(serverData: [])
        waitForExpectations(timeout: 1)
    }
    
    func _testSelectItem(homeType: SpaceHomeType = .spaceTab) {
        let expect = expectation(description: "test recent list select item")
        expect.expectedFulfillmentCount = 1
        let vm = createRecentListViewModel(homeType: homeType)
        let entry = SpaceEntry(type: .bitable, nodeToken: "nodeToken", objToken: "objToken")
        let item = SpaceListItem(enable: true,
                                 title: "mock_title",
                                 moreEnable: false,
                                 moreHandler: nil,
                                 needRedPoint: false,
                                 isStar: false,
                                 isShortCut: false,
                                 accessoryItem: nil,
                                 hasTemplateTag: false,
                                 isExternal: false,
                                 listIconType: .icon(image: nil),
                                 gridIconType: .icon(image: nil),
                                 syncStatus: .init(show: false, image: nil, title: "", isSyncing: false),
                                 subtitle: nil,
                                 secureLabelName: nil,
                                 thumbnailType: nil,
                                 slideConfig: nil,
                                 entry: entry,
                                 itemID: "mock_itemID",
                                 organizationTagValue: nil,
                                 sortType: vm.dataModel.sortHelper.selectedOption.type)
        vm.updateItemTypes(driveConfig: DriveListConfig(), items: [item])
        
        vm.actionSignal.emit(onNext: { action in
            switch action {
            case .open:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        vm.select(at: 0, item: .spaceItem(item: item))
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func _testInvalidFilterSortCombination(homeType: SpaceHomeType = .spaceTab) {
        let controller = SpaceFilterSortPanelController(filterOptions: [.wiki],
                                                        filterSelectionIndex: 0,
                                                        defaultFilterOption: .wiki,
                                                        sortOptions: [.init(type: .lastModifiedTime, descending: true, allowAscending: false)],
                                                        sortSelectionIndex: 0,
                                                        defaultSortOption: .init(type: .lastModifiedTime, descending: true, allowAscending: false))
        let viewModel = createRecentListViewModel(homeType: homeType)
        var result = viewModel.invalidReasonForCombination(filterOption: .wiki,
                                                           sortOption: .init(type: .lastModifiedTime, descending: true, allowAscending: false),
                                                           panel: controller)
        XCTAssertEqual(result, BundleI18n.SKResource.LarkCCM_Drive_UnsupportedAction_Toast)

        result = viewModel.invalidReasonForCombination(filterOption: .folder,
                                                       sortOption: .init(type: .lastModifiedTime, descending: true, allowAscending: false),
                                                       panel: controller)
        XCTAssertNil(result)

        result = viewModel.invalidReasonForCombination(filterOption: .wiki,
                                                       sortOption: .init(type: .lastOpenTime, descending: true, allowAscending: false),
                                                       panel: controller)
        XCTAssertNil(result)
    }

    //TODO: 补充删除error case
    
}
