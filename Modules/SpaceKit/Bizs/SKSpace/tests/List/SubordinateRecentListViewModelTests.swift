//
//  SubordinateRecentListViewModelTests.swift
//  SKSpace-Unit-Tests
//
//  Created by peilongfei on 2023/9/18.
//  

@testable import SKSpace
import Foundation
import SKCommon
import XCTest
import SKResource
import SKFoundation
import RxSwift
import LarkContainer


class SubordinateRecentListViewModelTests: XCTestCase {
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

    private func createRecentListViewModel() -> SubordinateRecentListViewModel {
        let mockContainer = SpaceListContainer(listIdentifier: "MOCK_RECENT_TEST")
        let mockInteractionManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: mockInteractionManager)
        let mockDM = SubordinateRecentListDataModel(userID: "MOCK_USER_ID",
                                                    subordinateID: "MOCK_SUBORDINATE_ID",
                                                    dataManager: MockSubordinateRecentDataProvider(),
                                                    interactionHelper: helper,
                                                    sortHelper: .recent,
                                                    filterHelper: .recent,
                                                    listContainer: mockContainer,
                                                    listAPI: SubordinateRecentListAPI.self)
        let viewModel = SubordinateRecentListViewModel(dataModel: mockDM)
        return viewModel
    }

    func testModel() {
        _testGenerateSlideConfig()
        _testNotifyPullToRefreashSuccess()
        _testNotifyPullToRefreshFailed()
        _testNotifyPullToLoadMoreSuccess()
        _testNotifyPullToLoadMoreNetFailed()
        _testNotifyPullToLoadMoreNativeFailed()
        _testWillResignActive()
        _testContextMenuConfig()
        _testHandleMoreAction()
        _testGenerateSlideConfigHandler()
        _testIsActive()
        _testItemChangedEvent()
        _testSelectItem()
        _testInvalidFilterSortCombination()
    }

    func _testGenerateSlideConfig() {
        let actions: [SlideAction] = [.share, .more]
        let vm = createRecentListViewModel()
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        let config = vm.generateSlideConfig(for: entry)

        XCTAssertEqual(actions, config?.actions)
    }

    func _testNotifyPullToRefreashSuccess() {
        MockSpaceNetworkAPI.mockSubordinateRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list vm pull to refresh success")
        expect.expectedFulfillmentCount = 2

        let vm = createRecentListViewModel()
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

    func _testNotifyPullToRefreshFailed() {
        MockSpaceNetworkAPI.mockSubordinateRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list vm pull to refresh failed")
        expect.expectedFulfillmentCount = 1

        let vm = createRecentListViewModel()
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

    func _testNotifyPullToLoadMoreSuccess() {
        MockSpaceNetworkAPI.mockSubordinateRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list vm pull to load more success")
        expect.expectedFulfillmentCount = 1

        let vm = createRecentListViewModel()
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

    func _testNotifyPullToLoadMoreNetFailed() {
        MockSpaceNetworkAPI.mockSubordinateRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list vm pull to load more failed")
        expect.expectedFulfillmentCount = 1

        let vm = createRecentListViewModel()
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

    func _testNotifyPullToLoadMoreNativeFailed() {
        MockSpaceNetworkAPI.mockSubordinateRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list vm pull to load more native failed")
        expect.expectedFulfillmentCount = 1

        let vm = createRecentListViewModel()
        vm.prepare()
        vm.actionSignal.emit(onNext: { action in
            print("test notify load more vm has more action : \(action)")
            switch action {
            case let .stopPullToLoadMore(hasMore):
                print("test notify load more vm has more: \(hasMore)")
                XCTAssertTrue(hasMore)
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

    func _testWillResignActive() {
        let vm = createRecentListViewModel()
        vm.actionSignal.emit(onNext: { action in
            if case .dismissRefreshTips = action {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        vm.willResignActive()
    }

    func _testContextMenuConfig() {
        let actions: [SlideAction] = [.share, .more]
        let vm = createRecentListViewModel()
        let entry = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        let config = vm.contextMenuConfig(for: entry)

        XCTAssertEqual(actions, config?.actions)
    }

    func _testHandleMoreAction() {
        let expect = expectation(description: "test recent list handle more action")
        expect.expectedFulfillmentCount = 2

        let entry_1 = SpaceEntry(type: .docX, nodeToken: "nodeToken", objToken: "objToken")
        entry_1.update(secretKeyDelete: true)
        let entry_2 = SpaceEntry(type: .docX, nodeToken: "nodeToken-2", objToken: "objToken-2")
        let vm = createRecentListViewModel()
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

    func _testGenerateSlideConfigHandler() {
        let expect = expectation(description: "test recent list slide action handler")
        expect.expectedFulfillmentCount = 2

        let vm = createRecentListViewModel()
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
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func _testIsActive() {
        let viewModel = createRecentListViewModel()
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

    func _testItemChangedEvent() {
        let mockContainer = SpaceListContainer(listIdentifier: "MOCK_RECENT_TEST")
        let mockInteractionManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: mockInteractionManager)
        let mockDM = SubordinateRecentListDataModel(userID: "MOCK_USER_ID",
                                                    subordinateID: "MOCK_SUBORDINATE_ID",
                                                    dataManager: MockSubordinateRecentDataProvider(),
                                                    interactionHelper: helper,
                                                    sortHelper: .recent,
                                                    filterHelper: .recent,
                                                    listContainer: mockContainer,
                                                    listAPI: SubordinateRecentListAPI.self)
        let viewModel = SubordinateRecentListViewModel(dataModel: mockDM)
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

    func _testSelectItem() {
        let expect = expectation(description: "test recent list select item")
        expect.expectedFulfillmentCount = 1
        let vm = createRecentListViewModel()
        let entry = SpaceEntry(type: .bitable,
                               nodeToken: "nodeToken",
                               objToken: "objToken")
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
                                  sortType: .lastModifiedTime)
        vm.updateItemTypes(items: [item])
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

    func _testInvalidFilterSortCombination() {
        let controller = SpaceFilterSortPanelController(filterOptions: [.wiki],
                                                        filterSelectionIndex: 0,
                                                        defaultFilterOption: .wiki,
                                                        sortOptions: [.init(type: .lastModifiedTime, descending: true, allowAscending: false)],
                                                        sortSelectionIndex: 0,
                                                        defaultSortOption: .init(type: .lastModifiedTime, descending: true, allowAscending: false))
        let viewModel = createRecentListViewModel()
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

class MockSubordinateRecentDataProvider: MockListDataProvider, SubordinateRecentListDataProvider {

    var loadSubordinateRecentEntries: [String] = []
    func loadSubordinateRecentEntries(subordinateID: String) {
        loadSubordinateRecentEntries.append(subordinateID)
    }

    func userInfoFor(subordinateID: String, callBack: @escaping (UserInfo?) -> Void) {
        let mockUserInfo = UserInfo(subordinateID)
        callBack(mockUserInfo)
    }
}
