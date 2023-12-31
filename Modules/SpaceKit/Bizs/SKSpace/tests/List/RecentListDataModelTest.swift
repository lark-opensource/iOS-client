//
//  RecentListDataModelTest.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/7/19.
//

@testable import SKSpace
import Foundation
import XCTest
import SKFoundation
import SKCommon
import OHHTTPStubs
import RxSwift
import SKDrive
import SpaceInterface
import LarkContainer


class MockRecentDataProvider: MockListDataProvider, SpaceRecentListDataProvider {

    var mergeRecentFilesCalled: [FileDataDiff] = []
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    
    func mergeRecentFiles(data: FileDataDiff, folderKey: DocFolderKey, callback: ((SKSpace.ResourceState) -> Void)?) {
        mergeRecentFilesCalled.append(data)
        callback?(ResourceState())
    }

    var appendRecentFileCalled: [FileDataDiff] = []
    func appendRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)?) {
        appendRecentFileCalled.append(data)
        callback?(ResourceState())
    }

    var resetRecentFileCalled: [FileDataDiff] = []
    func resetRecentFileListOld(data: FileDataDiff, folderKey: DocFolderKey, callback: ((ResourceState) -> Void)?) {
        resetRecentFileCalled.append(data)
        callback?(ResourceState())
    }

    var resetRecentFilesCalled: [[String]] = []
    func resetRecentFilesByTokens(tokens: [String], folderKey: DocFolderKey) {
        resetRecentFilesCalled.append(tokens)
    }

    var deleteRecentFileCalled: [[String]] = []
    func deleteRecentFile(tokens: [String]) {
        deleteRecentFileCalled.append(tokens)
    }


    var entries: [TokenStruct: SpaceEntry] = [:]
    var spaceEntryCalled: [TokenStruct] = []
    func spaceEntry(token: TokenStruct, callBack: @escaping (SpaceEntry?) -> Void) {
        spaceEntryCalled.append(token)
        callBack(entries[token])
    }

    var loadSubFolderEntriesCalled: [String] = []
    func loadSubFolderEntries(nodeToken: String) {
        loadSubFolderEntriesCalled.append(nodeToken)
    }
}

class RecentListDataModelTest: XCTestCase {
    var bag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)

    override func setUp() {
        super.setUp()
        bag = .init()
        DriveModule().setup()
        AssertionConfigForTest.disableAssertWhenTesting()
        SKDataManager.shared.clear { _ in }
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func createMockDataModel(usingLeanModelAPI: Bool = false) -> RecentListDataModel {
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
                                         homeType: .spaceTab)
        return mockDM
    }

    func testRefreshSuccess() {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list request success")
        expect.expectedFulfillmentCount = 2

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.refresh().subscribe(onCompleted: {
            XCTAssertTrue(true)
            expect.fulfill()
        }, onError: { error in
            XCTAssertNil(error)
            expect.fulfill()
        }).disposed(by: bag)

        dataModel.reloadSignal.subscribe(onNext: { _ in
            XCTAssertTrue(true)
            expect.fulfill()
        }).disposed(by: bag)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testRefreshFailed() {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list request failed")
        expect.expectedFulfillmentCount = 2

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.refresh().subscribe(onCompleted: {
            XCTAssertTrue(false)
            expect.fulfill()
        }, onError: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        }).disposed(by: bag)

        dataModel.loadMore().subscribe(onCompleted: {
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

    func testLoadMoreSuccess() {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list load more request success")
        expect.expectedFulfillmentCount = 1

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "51242"))
        dataModel.loadMore().subscribe(onCompleted: {
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
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list load more request fialed")
        expect.expectedFulfillmentCount = 1

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.listContainer.update(pagingState: .hasMore(lastLabel: "51242"))
        dataModel.loadMore().subscribe(onCompleted: {
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

    func testBackgroundReloadSuccess() {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list reload")
        expect.expectedFulfillmentCount = 1

        NotificationCenter.default
            .rx
            .notification(Notification.Name.Docs.addToPreloadQueue)
            .subscribe(onNext: { _ in
                XCTAssertTrue(true)
                expect.fulfill()
            }).disposed(by: bag)

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.backgroundReload(size: 1, handler: {})
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testFetchCurrentListSuccess() {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
        let expect = expectation(description: "test recent list fetch current list")
        expect.expectedFulfillmentCount = 1

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.fetchCurrentList(size: 1, handler: { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                expect.fulfill()
            case .failure:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        })

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testFetchCurrentListFailed() {
        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListFailed)
        let expect = expectation(description: "test recent list fetch current list failed")
        expect.expectedFulfillmentCount = 1

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.fetchCurrentList(size: 1) { result in
            switch result {
            case .success:
                XCTAssertTrue(false)
                expect.fulfill()
            case .failure:
                XCTAssertTrue(true)
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testPreloadFirstPage() {
//        MockSpaceNetworkAPI.mockRecentList(type: MockNetworkResponse.recentListSuccess)
//        let expect = expectation(description: "test recent list preload first page")
//        expect.expectedFulfillmentCount = 1
//
//        NotificationCenter.default
//            .rx
//            .notification(Notification.Name.Docs.addToPreloadQueue)
//            .subscribe(onNext: { _ in
//                expect.fulfill()
//            }).disposed(by: bag)
//
//        RecentListDataModel.preloadFirstPage()
//        waitForExpectations(timeout: 20) { error in
//            XCTAssertNil(error)
//        }
    }

    func testDeleteFromRecentList() {
        MockSpaceNetworkAPI.mockRecentListDeleteFile(type: MockNetworkResponse.recentListDelete)
        let expect = expectation(description: "test recent list delete file")
        expect.expectedFulfillmentCount = 1

        let dataModel = createMockDataModel()
        dataModel.setup()
        dataModel.deleteFromRecentList(objToken: "docx1234", objType: DocsType.docX)
            .subscribe(onCompleted: {
                XCTAssertTrue(true)
                expect.fulfill()
            }).disposed(by: bag)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testBitableHomeDataModel() {
        let dataModel = RecentListDataModel(userResolver: self.userResolver,
                                            usingLeanModeAPI: false,
                                            homeType: .baseHomeType(context: BaseHomeContext(userResolver: self.userResolver, containerEnv: .workbench, baseHpFrom: nil, version: .original)))
        dataModel.setup()

        let spaceBanner = SpaceBannerViewModel(reachPointId: "RP_BITABLE_HOME_TOP", scenarioId: "SCENE_BITABLE_COMMON")
        spaceBanner.startPullUgBannerData()
        
        dataModel.notifyWillUpdateFilterSortOption()
        dataModel.notifyDidUpdateFilterSortOption()

        XCTAssertTrue(dataModel.homeType.isBaseHomeType())
    }

    func testInvalidFilterSortCombination() {
        typealias SortOption = SpaceSortHelper.SortOption
        typealias FilterOption = SpaceFilterHelper.FilterOption
        let options = [
            SortOption(type: .allTime, descending: true, allowAscending: true),
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: true)
        ]
        var sortHelper = SpaceSortHelper(listIdentifier: "unit-test", options: options, configCache: MockSpaceListConfigCache())
        sortHelper.update(sortIndex: 1, descending: true)

        let filterOptions = [
            FilterOption.all,
            FilterOption.wiki
        ]
        var filterHelper = SpaceFilterHelper(listIdentifier: "unit-test", options: filterOptions, configCache: MockSpaceListConfigCache())
        filterHelper.update(filterIndex: 1)

        let mockContainer = SpaceListContainer(listIdentifier: "MOCK_RECENT_TEST")
        let mockInteractionManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: mockInteractionManager)
        let dataModel = RecentListDataModel(userResolver: self.userResolver,
                                            dataManager: MockRecentDataProvider(),
                                            interactionHelper: helper,
                                            sortHelper: sortHelper,
                                            filterHelper: filterHelper,
                                            listContainer: mockContainer,
                                            listAPI: StandardRecentListAPI.self,
                                            homeType: .spaceTab)
        dataModel.setup()
        XCTAssertEqual(dataModel.sortHelper.selectedIndex, 0)
        XCTAssertEqual(dataModel.filterHelper.selectedIndex, 0)
    }
}
