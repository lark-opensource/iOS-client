//
//  SpaceFolderContainerViewModelTests.swift
//  SKSpace-Unit-Tests
//
//  Created by Weston Wu on 2022/11/21.
//

import XCTest
@testable import SKSpace
import SKFoundation
import SKCommon
import OHHTTPStubs
import RxSwift
import RxCocoa
import RxRelay
import SKInfra
import LarkContainer

final class SpaceFolderContainerViewModelTests: XCTestCase {
    private var bag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        bag = DisposeBag()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()
    }
    
    func testReportOpenFolder() {
        let dataVM = SubFolderDataModelV2(folderToken: "MOCK_TOKEN", isShareFolder: false)
        let folderVM = SubFolderListViewModelV2(dataModel: dataVM)
        let containerViewModel = SpaceCommonFolderContainerViewModel(userResolver: userResolver,
                                                                     title: "MOCK_TITLE",
                                                                     viewModel: folderVM,
                                                                     initialState: .normal)
        let expect = expectation(description: "report open folder")
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceOpenReport)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: ["code": 0, "data": [:], "msg": "Success"],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let bodyString = String(data: body, encoding: .utf8) else {
                XCTFail("request body not found")
                expect.fulfill()
                return response
            }
            XCTAssertEqual(bodyString, "obj_token=MOCK_TOKEN&obj_type=0")
            expect.fulfill()
            return response
        }

        containerViewModel.viewDidAppear()
        waitForExpectations(timeout: 1)
    }

    func testTitle() {
        let mockUserID = "mock-owner-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID)
        mockUserInfo.userType = .standard
        User.current.reloadUserInfo(mockUserInfo)
        defer {
            if let info = originUserInfo {
                User.current.reloadUserInfo(info)
            }
        }
        let mockDataManager = MockFolderDataProvider()
        let mockEntry = FolderEntry(type: .folder, nodeToken: "MOCK_TOKEN", objToken: "MOCK_TOKEN")
        mockEntry.updateExtraValue(["is_external": true])
        mockDataManager.entries[TokenStruct(token: "MOCK_TOKEN")] = mockEntry

        let dataVM = SubFolderDataModelV2(folderToken: "MOCK_TOKEN",
                                          isShareFolder: false)
        let folderVM = SubFolderListViewModelV2(dataModel: dataVM)
        let containerVM = SpaceCommonFolderContainerViewModel(userResolver: userResolver,
                                                              title: "MOCK_TITLE",
                                                              viewModel: folderVM,
                                                              initialState: .normal,
                                                              dataManager: mockDataManager)
        var expect = expectation(description: "init title")
        containerVM.titleUpdated.drive(onNext: { (title, isExternal, showSecondTag) in
            XCTAssertEqual(title, "MOCK_TITLE")
            XCTAssertTrue(true)
            XCTAssertFalse(showSecondTag)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        bag = DisposeBag()
        mockEntry.updateName("UPDATED_MOCK_TITLE")
        mockEntry.updateExtraValue([:])
        expect = expectation(description: "update title")
        containerVM.titleUpdated.skip(1).drive(onNext: { (title, isExternal, showSecondTag) in
            XCTAssertEqual(title, "UPDATED_MOCK_TITLE")
            XCTAssertFalse(isExternal)
            XCTAssertFalse(showSecondTag)
            expect.fulfill()
        })
        .disposed(by: bag)
        containerVM.update(result: .success(()))
        waitForExpectations(timeout: 1)
    }

    func testUpdateTitleFromDataModel() {
        let mockUserID = "mock-owner-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID)
        mockUserInfo.userType = .standard
        User.current.reloadUserInfo(mockUserInfo)
        defer {
            if let info = originUserInfo {
                User.current.reloadUserInfo(info)
            }
        }
        let mockDataManager = MockFolderDataProvider()
        let mockEntry = FolderEntry(type: .folder, nodeToken: "MOCK_TOKEN", objToken: "MOCK_TOKEN")
        mockEntry.updateExtraValue(["is_external": true])
        mockEntry.updateName("UPDATED_MOCK_TITLE")
        mockDataManager.entries[TokenStruct(token: "MOCK_TOKEN")] = mockEntry

        let dataVM = SubFolderDataModelV2(folderToken: "MOCK_TOKEN",
                                          isShareFolder: false,
                                          dataManager: mockDataManager,
                                          sortHelper: SpaceSortHelper.subFolder(token: "MOCK_TOKEN"),
                                          interactionHelper: SpaceInteractionHelper(dataManager: MockSpaceInteractionDataManager()),
                                          listContainer: SpaceListContainer(listIdentifier: "MOCK_TOKEN"),
                                          permissionProvider: MockFolderPermissionProvider(),
                                          networkAPI: V2FolderListAPI.self)
        let folderVM = SubFolderListViewModelV2(dataModel: dataVM)
        let containerVM = SpaceCommonFolderContainerViewModel(userResolver: userResolver,
                                                              title: "MOCK_TITLE",
                                                              viewModel: folderVM,
                                                              initialState: .normal,
                                                              dataManager: MockFolderDataProvider())

        let expect = expectation(description: "update title")
        containerVM.titleUpdated.skip(1).drive(onNext: { (title, isExternal, showSecondTag) in
            XCTAssertEqual(title, "UPDATED_MOCK_TITLE")
            XCTAssertTrue(isExternal)
            XCTAssertFalse(showSecondTag)
            expect.fulfill()
        })
        .disposed(by: bag)
        containerVM.update(result: .success(()))
        waitForExpectations(timeout: 1)
    }
}
