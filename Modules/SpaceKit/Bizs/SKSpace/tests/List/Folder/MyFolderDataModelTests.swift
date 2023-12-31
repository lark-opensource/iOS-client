//
//  MyFolderDataModel.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/9/29.
// swiftlint:disable type_body_length

import XCTest
@testable import SKSpace
import SKFoundation
import SKCommon
import RxSwift


class MockMyFolderListAPI: MyFolderListAPIType {
    enum MockError: Error {
        case notImplement
        case expectedError
    }

    class func queryList(count: Int,
                         lastLabel: String?,
                         sortOption: SortOption?,
                         extraParams: [String: Any]?) -> Single<ListResult> {
        .error(MockError.notImplement)
    }

    class func listModifier(sortOption: SortOption) -> SpaceListModifier {
        SpaceListComplexModifier(subModifiers: [])
    }
}

final class MyFolderDataModelTests: XCTestCase {

    private var bag = DisposeBag()
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        bag = DisposeBag()
        SKDataManager.shared.clear { _ in }
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    static let mockFolderToken = "MOCK_FOLDER_TOKEN"
    static let mockUserID: String = "MOCK_USER_ID"

    static var mockSortHelper: SpaceSortHelper {
        let cache = MockSpaceListConfigCache()
        let sortHelper = SpaceSortHelper(listIdentifier: mockFolderToken,
                                         options: [
                                            .init(type: .title, descending: true, allowAscending: true),
                                            .init(type: .createTime, descending: true, allowAscending: true),
                                            .init(type: .updateTime, descending: true, allowAscending: false)
                                         ], configCache: cache)
        let cacheOption = SpaceSortHelper.SortOption(type: .createTime, descending: false, allowAscending: true)
        do {
            let data = try JSONEncoder().encode(cacheOption)
            cache.set(data: data, for: "space.sort.\(mockUserID)")
        } catch {
            XCTFail("setup mock sort helper failed, \(error)")
        }
        return sortHelper
    }

    static func mockDM(userID: String = mockUserID,
                       dataManager: SpaceListDataProvider = MockListDataProvider(),
                       sortHelper: SpaceSortHelper = mockSortHelper,
                       interactionHelper: SpaceInteractionHelper = SpaceInteractionHelper(dataManager: MockSpaceInteractionDataManager()),
                       listContainer: SpaceListContainer = SpaceListContainer(listIdentifier: mockUserID),
                       networkAPI: MyFolderListAPIType.Type = MockMyFolderListAPI.self
    ) -> MyFolderDataModel {
        MyFolderDataModel(userID: userID,
                          dataManager: dataManager,
                          sortHelper: sortHelper,
                          interactionHelper: interactionHelper,
                          listContainer: listContainer,
                          networkAPI: networkAPI)
    }

    func testSetup() {
        class NetworkAPI: MockMyFolderListAPI {
            static var queryListCalledCount = 0
            override class func queryList(count: Int, lastLabel: String?, sortOption: SortOption?, extraParams: [String: Any]?) -> Single<ListResult> {
                queryListCalledCount += 1
                XCTAssertEqual(count, MyFolderDataModel.myFolderListPageCount)
                XCTAssertNil(lastLabel)
                // restore 后的 sortOption
                XCTAssertEqual(sortOption, .init(type: .createTime, descending: false, allowAscending: true))
                return .error(MockError.expectedError)
            }
        }
        let dataProvider = MockListDataProvider()
        dataProvider.loadDataSuccess = false
        let dataModel = Self.mockDM(dataManager: dataProvider)
        dataModel.setup()
        NotificationCenter.default.post(name: MyFolderDataModel.myFolderNeedUpdate, object: nil)
        // 检查 observers
        XCTAssertEqual(dataProvider.observers.count, 1)
        if let observer = dataProvider.observers.first {
            XCTAssertNotNil(observer as? MyFolderDataModel)
        } else {
            XCTFail("observers count should be 1")
        }
        XCTAssertEqual(dataProvider.loadFolderFileEntriesCalled, [.myFolderList])
        XCTAssertEqual(dataProvider.loadDataCalled, [Self.mockUserID])
        // 重复 setup 测试
        dataModel.setup()
        XCTAssertEqual(dataProvider.observers.count, 1)
    }

    func testRefreshError() {
        class NetworkAPI: MockMyFolderListAPI {
            override class func queryList(count: Int, lastLabel: String?, sortOption: SortOption?, extraParams: [String: Any]?) -> Single<ListResult> {
                return .error(MockError.expectedError)
            }
        }
        let dataModel = Self.mockDM(networkAPI: NetworkAPI.self)
        let expect = expectation(description: "test refresh failed")
        dataModel.refresh().subscribe {
            XCTFail("un-expected success")
            expect.fulfill()
        } onError: { error in
            guard let mockError = error as? NetworkAPI.MockError,
                  mockError == .expectedError else {
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testRefreshSuccess() {
        class NetworkAPI: MockMyFolderListAPI {
            static var data = ListResult(dataDiff: FileDataDiff(), rootToken: nil)
            override class func queryList(count: Int, lastLabel: String?, sortOption: SortOption?, extraParams: [String: Any]?) -> Single<ListResult> {
                return .just(data)
            }
        }
        let dataProvider = MockListDataProvider()
        let dataModel = Self.mockDM(dataManager: dataProvider, networkAPI: NetworkAPI.self)
        var expect = expectation(description: "test has more")
        var data = FileDataDiff()
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: true, total: 20, pageTitle: nil, lastLabel: "last-label")
        var result = NetworkAPI.ListResult(dataDiff: data, rootToken: Self.mockFolderToken)
        NetworkAPI.data = result
        dataModel.refresh().subscribe {
            XCTAssertEqual(dataProvider.setRootFileCalled.count, 1)
            XCTAssertEqual(dataModel.listContainer.pagingState, .hasMore(lastLabel: "last-label"))
            XCTAssertEqual(dataModel.listContainer.totalCount, 20)
            XCTAssertEqual(MyFolderDataModel.rootToken, Self.mockFolderToken)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test no more")
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: false, total: nil, pageTitle: nil, lastLabel: nil)
        result = NetworkAPI.ListResult(dataDiff: data, rootToken: Self.mockFolderToken)
        NetworkAPI.data = result
        dataModel.refresh().subscribe {
            XCTAssertEqual(dataModel.listContainer.pagingState, .noMore)
            XCTAssertEqual(dataModel.listContainer.totalCount, 0)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test missing data")
        data.filePaingInfos[Self.mockFolderToken] = nil
        result = .init(dataDiff: data, rootToken: Self.mockFolderToken)
        NetworkAPI.data = result
        dataModel.refresh().subscribe {
            XCTAssertEqual(dataModel.listContainer.pagingState, .noMore)
            XCTAssertEqual(dataModel.listContainer.totalCount, 0)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testLoadMoreFailed() {
        let dataModel = Self.mockDM()
        let expect = expectation(description: "test refresh failed")
        dataModel.loadMore().subscribe {
            XCTFail("un-expected success")
            expect.fulfill()
        } onError: { error in
            guard let mockError = error as? RecentListDataModel.RecentDataError,
                  mockError == .unableToLoadMore else {
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testLoadMoreSuccess() {
        class NetworkAPI: MockMyFolderListAPI {
            static var data = ListResult(dataDiff: FileDataDiff(), rootToken: nil)
            override class func queryList(count: Int, lastLabel: String?, sortOption: SortOption?, extraParams: [String: Any]?) -> Single<ListResult> {
                XCTAssertEqual(lastLabel, "MOCK_LAST_LABEL")
                return .just(data)
            }
        }
        let container = SpaceListContainer(listIdentifier: Self.mockFolderToken)
        container.update(pagingState: .hasMore(lastLabel: "MOCK_LAST_LABEL"))
        let dataProvider = MockListDataProvider()
        let dataModel = Self.mockDM(dataManager: dataProvider, listContainer: container, networkAPI: NetworkAPI.self)
        var expect = expectation(description: "test load more")
        var data = FileDataDiff()
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: true, total: 20, pageTitle: nil, lastLabel: "last-label")
        var result = NetworkAPI.ListResult(dataDiff: data, rootToken: Self.mockFolderToken)
        NetworkAPI.data = result
        dataModel.loadMore().subscribe {
            XCTAssertEqual(dataProvider.appendFileListCalled.count, 1)
            XCTAssertEqual(dataModel.listContainer.pagingState, .hasMore(lastLabel: "last-label"))
            XCTAssertEqual(dataModel.listContainer.totalCount, 20)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test no more")
        container.update(pagingState: .hasMore(lastLabel: "MOCK_LAST_LABEL"))
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: false, total: nil, pageTitle: nil, lastLabel: nil)
        result = NetworkAPI.ListResult(dataDiff: data, rootToken: Self.mockFolderToken)
        NetworkAPI.data = result
        dataModel.loadMore().subscribe {
            XCTAssertEqual(dataModel.listContainer.pagingState, .noMore)
            XCTAssertEqual(dataModel.listContainer.totalCount, 0)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "test missing data")
        container.update(pagingState: .hasMore(lastLabel: "MOCK_LAST_LABEL"))
        data.filePaingInfos[Self.mockFolderToken] = nil
        result = NetworkAPI.ListResult(dataDiff: data, rootToken: Self.mockFolderToken)
        NetworkAPI.data = result
        dataModel.loadMore().subscribe {
            XCTAssertEqual(dataModel.listContainer.pagingState, .noMore)
            XCTAssertEqual(dataModel.listContainer.totalCount, 0)
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error found: \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testUpdateSortOption() {
        let dataModel = Self.mockDM()
        dataModel.update(sortIndex: 1, descending: false)
        XCTAssertEqual(dataModel.sortHelper.selectedIndex, 1)
        XCTAssertEqual(dataModel.sortHelper.selectedOption, .init(type: .createTime, descending: false, allowAscending: true))

        dataModel.resetSortFilterForPicker()
        XCTAssertEqual(dataModel.sortHelper.selectedOption, .init(type: .updateTime, descending: true, allowAscending: false))
    }

    func testDataChange() {
        class MockListModifier: SpaceListModifier {
            var handleCalled = false
            func handle(entries: [SpaceEntry]) -> [SpaceEntry] {
                handleCalled = true
                return entries
            }
        }
        class NetworkAPI: MockMyFolderListAPI {
            static var modifier: MockListModifier = MockListModifier()
            override class func listModifier(sortOption: MockMyFolderListAPI.SortOption) -> SpaceListModifier {
                XCTAssertEqual(sortOption, .init(type: .title, descending: true, allowAscending: true))
                return modifier
            }
        }
        MyFolderDataModel.update(rootToken: "MOCK_ROOT_TOKEN")
        let container = SpaceListContainer(listIdentifier: Self.mockFolderToken)
        let dataModel = Self.mockDM(listContainer: container, networkAPI: NetworkAPI.self)
        XCTAssertEqual(dataModel.type, .subFolder)
        XCTAssertEqual(dataModel.token, "MOCK_ROOT_TOKEN")
        let listData = MockListData(folderToken: Self.mockFolderToken)

        var expect = expectation(description: "load new db data")
        container.stateChanged.take(1)
            .asSingle()
            .subscribe { state in
                XCTAssertEqual(state, .syncing)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        dataModel.dataChange(data: listData, operational: .loadNewDBData)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "load folder")
        container.stateChanged.take(1)
            .asSingle()
            .subscribe { state in
                XCTAssertEqual(state, .syncing)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        dataModel.dataChange(data: listData, operational: .loadSpecialFolder(type: .myFolderList))
        waitForExpectations(timeout: 1)

        var tempBag = DisposeBag()
        container.sync(serverData: [])
        expect = expectation(description: "load other folder")
        expect.isInverted = true // 预期 state 不会变化
        container.stateChanged.take(1)
            .asSingle()
            .subscribe { _ in
                expect.fulfill()
            } onError: { _ in
                expect.fulfill()
            }
            .disposed(by: tempBag)
        dataModel.dataChange(data: listData, operational: .loadSpecialFolder(type: .recent))
        waitForExpectations(timeout: 1)
        tempBag = DisposeBag()

        container.restore(localData: [])
        expect = expectation(description: "set root file")
        container.stateChanged.take(1)
            .asSingle()
            .subscribe { state in
                XCTAssertEqual(state, .ready)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        dataModel.dataChange(data: listData, operational: .setRootFile)
        waitForExpectations(timeout: 1)
        container.restore(localData: [])

        expect = expectation(description: "append file list")
        container.stateChanged.take(1)
            .asSingle()
            .subscribe { state in
                XCTAssertEqual(state, .ready)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        dataModel.dataChange(data: listData, operational: .appendFileList)
        waitForExpectations(timeout: 1)
        container.restore(localData: [])

        tempBag = DisposeBag()
        expect = expectation(description: "un-related event")
        expect.isInverted = true // 预期 state 不会变化
        container.stateChanged.take(1)
            .asSingle()
            .subscribe { _ in
                expect.fulfill()
            } onError: { _ in
                expect.fulfill()
            }
            .disposed(by: tempBag)
        dataModel.dataChange(data: listData, operational: .addFile)
        waitForExpectations(timeout: 1)
    }

    func testFetchRootToken() {
        class NetworkAPI: MockMyFolderListAPI {
            override class func queryList(count: Int,
                                          lastLabel: String?,
                                          sortOption: SortOption?,
                                          extraParams: [String: Any]?) -> Single<ListResult> {
                XCTAssertEqual(count, 1)
                XCTAssertNil(lastLabel)
                XCTAssertNil(sortOption)
                XCTAssertNil(extraParams)
                return .just(ListResult(dataDiff: FileDataDiff(), rootToken: "MOCK_ROOT_TOKEN_TEST"))
            }
        }
        MyFolderDataModel.fetchRootToken(api: NetworkAPI.self)
            .disposed(by: bag)
        XCTAssertEqual(MyFolderDataModel.rootToken, "MOCK_ROOT_TOKEN_TEST")
    }
}
