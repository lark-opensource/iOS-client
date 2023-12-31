//
//  SubFolderDataModelV1Tests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/9/29.
// swiftlint:disable type_body_length

import XCTest
@testable import SKSpace
import SKFoundation
import SKCommon
import RxSwift
import SKInfra
import SpaceInterface

class MockFolderDataProvider: MockListDataProvider, SpaceFolderListDataProvider {

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

    func deleteSubFolderEntries(nodeToken: String) {
    }
}

class MockFolderPermissionProvider: FolderPermissionProvider {
    var result: Result<Bool, Error> = .success(true)
    var checkCanCreateCalled: [String] = []
    func checkCanCreate(folderToken: String) -> Single<Bool> {
        checkCanCreateCalled.append(folderToken)
        switch result {
        case let .success(canCreate):
            return .just(canCreate)
        case let .failure(error):
            return .error(error)
        }
    }

    func update(tenantID: String) {}
}

class MockFolderListAPI: FolderListAPI {
    enum MockError: Error {
        case notImplement
        case expectedError
    }
    /// 拉取子文件夹列表
    class func queryList(folderToken: FileListDefine.ObjToken,
                          count: Int,
                          lastLabel: String?,
                          sortOption: SortOption?,
                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
        .error(MockError.notImplement)
    }

    // 拉取共享文件夹列表的外部授权信息，仅 V1 共享文件夹才需要请求此接口，对 V2 无意义
    class func fetchExternalInfo(items: [SpaceItem]) -> Single<[FileListDefine.ObjToken: Bool]> {
        .error(MockError.notImplement)
    }
    // 申请文件夹权限
    class func requestPermission(folderToken: FileListDefine.ObjToken, message: String, roleToRequest: Int) -> Completable {
        .error(MockError.notImplement)
    }
}

final class SubFolderDataModelV2Tests: XCTestCase {

    private var bag = DisposeBag()
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        bag = DisposeBag()
        SKDataManager.shared.clear { _ in }
        DocsContainer.shared.register(PermissionSDK.self) { _ in
            MockPermissionSDK()
        }
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    static let mockFolderToken = "MOCK_FOLDER_TOKEN"
    static let mockTokenStruct = TokenStruct(token: mockFolderToken)
    static var mockFolderEntry: FolderEntry {
        FolderEntry(type: .folder, nodeToken: mockFolderToken, objToken: mockFolderToken)
    }

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
            cache.set(data: data, for: "space.sort.MOCK_FOLDER_TOKEN")
        } catch {
            XCTFail("setup mock sort helper failed, \(error)")
        }
        return sortHelper
    }

    static func mockDM(folderToken: String = mockFolderToken,
                       isShareFolder: Bool = true,
                       dataManager: SpaceFolderListDataProvider = MockFolderDataProvider(),
                       sortHelper: SpaceSortHelper = mockSortHelper,
                       interactionHelper: SpaceInteractionHelper = SpaceInteractionHelper(dataManager: MockSpaceInteractionDataManager()),
                       listContainer: SpaceListContainer = SpaceListContainer(listIdentifier: mockFolderToken),
                       permissionProvider: FolderPermissionProvider = MockFolderPermissionProvider(),
                       networkAPI: FolderListAPI.Type = MockFolderListAPI.self
    ) -> SubFolderDataModelV2 {
        SubFolderDataModelV2(folderToken: folderToken,
                             isShareFolder: isShareFolder,
                             dataManager: dataManager,
                             sortHelper: sortHelper,
                             interactionHelper: interactionHelper,
                             listContainer: listContainer,
                             permissionProvider: permissionProvider,
                             networkAPI: networkAPI)
    }

    func testCheckFolderPermission() {
        let mockUserID = "mock-owner-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID)
        User.current.reloadUserInfo(mockUserInfo)
        defer {
            if let info = originUserInfo {
                User.current.reloadUserInfo(info)
            }
        }

        let entry = Self.mockFolderEntry
        entry.updateOwnerID(mockUserID)

        // Case 1, 是 owner 场景
        let mockProvider = MockFolderDataProvider()
        let permissionProvider = MockFolderPermissionProvider()
        mockProvider.entries[Self.mockTokenStruct] = entry
        var dataModel = Self.mockDM(dataManager: mockProvider, permissionProvider: permissionProvider)
        var expect = expectation(description: "wait-for-owner-check-permission-called")
        DispatchQueue.main.async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(dataModel.folderEntry)
        var result = dataModel.createPermRelay.value
        XCTAssertEqual(mockProvider.spaceEntryCalled, [Self.mockTokenStruct])
        XCTAssertTrue(result)
        XCTAssertTrue(permissionProvider.checkCanCreateCalled.isEmpty)

        // Case 2, 非 owner，有权限
        entry.updateOwnerID("another-id")
        dataModel = Self.mockDM(dataManager: mockProvider, permissionProvider: permissionProvider)
        expect = expectation(description: "wait for non-owner with permission called")
        DispatchQueue.main.async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
        result = dataModel.createPermRelay.value
        XCTAssertTrue(result)
        XCTAssertEqual(permissionProvider.checkCanCreateCalled, [Self.mockFolderToken])

        // Case 3, 非 owner，无权限
        permissionProvider.result = .success(false)
        dataModel = Self.mockDM(dataManager: mockProvider, permissionProvider: permissionProvider)
        expect = expectation(description: "wait for non-owner without permission called")
        DispatchQueue.main.async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
        result = dataModel.createPermRelay.value
        XCTAssertFalse(result)

        // Case 3, 非 owner，拉权限失败
        permissionProvider.result = .failure(DocsNetworkError.invalidData)
        dataModel = Self.mockDM(dataManager: mockProvider, permissionProvider: permissionProvider)
        expect = expectation(description: "wait for non-owner without permission called")
        DispatchQueue.main.async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
        result = dataModel.createPermRelay.value
        XCTAssertFalse(result)
    }

    func testSetup() {
        class NetworkAPI: MockFolderListAPI {
            static var queryListCalledCount = 0
            override class func queryList(folderToken: FileListDefine.ObjToken,
                                          count: Int,
                                          lastLabel: String?,
                                          sortOption: MockFolderListAPI.SortOption?,
                                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
                queryListCalledCount += 1
                XCTAssertEqual(folderToken, SubFolderDataModelV2Tests.mockFolderToken)
                XCTAssertEqual(count, 100)
                XCTAssertNil(lastLabel)
                // restore 后的 sortOption
                XCTAssertEqual(sortOption, .init(type: .createTime, descending: false, allowAscending: true))
                return .error(MockError.expectedError)
            }
        }
        let dataProvider = MockFolderDataProvider()
        let dataModel = Self.mockDM(dataManager: dataProvider, networkAPI: NetworkAPI.self)
        dataModel.setup()
        NotificationCenter.default.post(name: SubFolderDataModelV2.subFolderNeedUpdate, object: nil)
        // 检查 observers
        XCTAssertEqual(dataProvider.observers.count, 1)
        if let observer = dataProvider.observers.first {
            XCTAssertNotNil(observer as? SubFolderDataModelV2)
        } else {
            XCTFail("observers count should be 1")
        }
        XCTAssertEqual(dataProvider.loadSubFolderEntriesCalled, [Self.mockFolderToken])
        XCTAssertEqual(NetworkAPI.queryListCalledCount, 1)
        // 重复 setup 测试
        dataModel.setup()
        XCTAssertEqual(dataProvider.observers.count, 1)
    }

    func testRefreshError() {
        class NetworkAPI: MockFolderListAPI {
            override class func queryList(folderToken: FileListDefine.ObjToken,
                                          count: Int,
                                          lastLabel: String?,
                                          sortOption: MockFolderListAPI.SortOption?,
                                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
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
        class NetworkAPI: MockFolderListAPI {
            static var data = FileDataDiff()
            override class func queryList(folderToken: FileListDefine.ObjToken,
                                          count: Int,
                                          lastLabel: String?,
                                          sortOption: MockFolderListAPI.SortOption?,
                                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
                return .just(data)
            }
        }
        let dataProvider = MockFolderDataProvider()
        let dataModel = Self.mockDM(dataManager: dataProvider, networkAPI: NetworkAPI.self)
        dataProvider.entries[Self.mockTokenStruct] = Self.mockFolderEntry
        dataProvider.spaceEntryCalled = []
        var expect = expectation(description: "test has more")
        var data = FileDataDiff()
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: true, total: 20, pageTitle: nil, lastLabel: "last-label")
        NetworkAPI.data = data
        dataModel.refresh().subscribe {
            XCTAssertEqual(dataProvider.setRootFileCalled.count, 1)
            XCTAssertEqual(dataProvider.spaceEntryCalled.count, 1)
            XCTAssertNotNil(dataModel.folderEntry)
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
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: false, total: nil, pageTitle: nil, lastLabel: nil)
        NetworkAPI.data = data
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
        NetworkAPI.data = data
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
        class NetworkAPI: MockFolderListAPI {
            static var data = FileDataDiff()
            override class func queryList(folderToken: FileListDefine.ObjToken,
                                          count: Int,
                                          lastLabel: String?,
                                          sortOption: MockFolderListAPI.SortOption?,
                                          extraParams: [String: Any]?) -> Single<FileDataDiff> {
                XCTAssertEqual(lastLabel, "MOCK_LAST_LABEL")
                return .just(data)
            }
        }
        let container = SpaceListContainer(listIdentifier: Self.mockFolderToken)
        container.update(pagingState: .hasMore(lastLabel: "MOCK_LAST_LABEL"))
        let dataProvider = MockFolderDataProvider()
        let dataModel = Self.mockDM(dataManager: dataProvider, listContainer: container, networkAPI: NetworkAPI.self)
        dataProvider.entries[Self.mockTokenStruct] = Self.mockFolderEntry
        dataProvider.spaceEntryCalled = []
        var expect = expectation(description: "test load more")
        var data = FileDataDiff()
        data.filePaingInfos[Self.mockFolderToken] = PagingInfo(hasMore: true, total: 20, pageTitle: nil, lastLabel: "last-label")
        NetworkAPI.data = data
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
        NetworkAPI.data = data
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
        NetworkAPI.data = data
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

    func testRequestPermission() {
        class NetworkAPI: MockFolderListAPI {
            override class func requestPermission(folderToken: FileListDefine.ObjToken, message: String, roleToRequest: Int) -> Completable {
                XCTAssertEqual(folderToken, SubFolderDataModelV2Tests.mockFolderToken)
                XCTAssertEqual(message, "TEST_MESSAGE")
                XCTAssertEqual(roleToRequest, 1)
                return .error(MockError.expectedError)
            }
        }
        let dataModel = Self.mockDM(networkAPI: NetworkAPI.self)
        let expect = expectation(description: "test request failed")
        dataModel.requestPermission(message: "TEST_MESSAGE", roleToRequest: 1).subscribe {
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

    func testUpdateSortOption() {
        let dataModel = Self.mockDM()
        dataModel.update(sortIndex: 1, descending: false)
        XCTAssertEqual(dataModel.sortHelper.selectedIndex, 1)
        XCTAssertEqual(dataModel.sortHelper.selectedOption, .init(type: .createTime, descending: false, allowAscending: true))

        dataModel.resetSortFilterForPicker()
        XCTAssertEqual(dataModel.sortHelper.selectedOption, .init(type: .updateTime, descending: true, allowAscending: false))
    }

    func testDataChange() {
        let container = SpaceListContainer(listIdentifier: Self.mockFolderToken)
        let dataModel = Self.mockDM(listContainer: container)
        XCTAssertEqual(dataModel.type, .subFolder)
        XCTAssertEqual(dataModel.token, Self.mockFolderToken)
        let listData = MockListData(folderToken: Self.mockFolderToken)

        dataModel.dataChange(data: listData, operational: .openNoCacheFolderLink)
        XCTAssertEqual(container.state, .syncing)

        dataModel.dataChange(data: listData, operational: .loadSubFolder(nodeToken: Self.mockFolderToken))
        XCTAssertEqual(container.state, .syncing)

        dataModel.dataChange(data: listData, operational: .setRootFile)
        XCTAssertEqual(container.state, .ready)
        container.restore(localData: [])

        dataModel.dataChange(data: listData, operational: .appendFileList)
        XCTAssertEqual(container.state, .ready)
        container.restore(localData: [])

        dataModel.dataChange(data: listData, operational: .addFile)
        XCTAssertEqual(container.state, .syncing)
    }

    func testV2PermissionService() {
        let mockService = MockUserPermissionService()
        let service = V2FolderPermissionService(permissionService: mockService)
        service.update(tenantID: "MOCK_TENANT_ID")
        XCTAssertEqual(mockService.tenantID, "MOCK_TENANT_ID")

        mockService.updateResponse = .noPermission(statusCode: .auditError, applyUserInfo: nil)
        var checkCanCreateExpect = expectation(description: "expect check can create failed when update permission failed")
        service.checkCanCreate(folderToken: "")
            .subscribe(onSuccess: { result in
                XCTAssertFalse(result)
                checkCanCreateExpect.fulfill()
            })
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        mockService.updateResponse = .success
        mockService.syncResponse = .pass
        checkCanCreateExpect = expectation(description: "expect can create")
        service.checkCanCreate(folderToken: "")
            .subscribe(onSuccess: { result in
                XCTAssertTrue(result)
                checkCanCreateExpect.fulfill()
            })
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        mockService.updateResponse = .success
        mockService.syncResponse = PermissionResponse(traceID: "MOCK_TRACE_ID",
                                                      result: .forbidden(denyType: .blockBySecurityAudit,
                                                                         preferUIStyle: .default),
                                                      behavior: { _, _ in })
        checkCanCreateExpect = expectation(description: "expect can create failed")
        service.checkCanCreate(folderToken: "")
            .subscribe(onSuccess: { result in
                XCTAssertFalse(result)
                checkCanCreateExpect.fulfill()
            })
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
}
