//
//  MoreViewModelTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/7/13.
//  

import XCTest
import SKFoundation
import OHHTTPStubs
@testable import SKCommon
import RxSwift
import RxCocoa
import SpaceInterface
import SKInfra

class MoreViewModelTests: XCTestCase {

    lazy var bitableMoreViewModel: MoreViewModel = {
        let docsInfo = DocsInfo(type: .bitable, objToken: "basbcJqA1yY7qv4Ps1Y2KH6Bqoh")
        var listMoreItemClickTracker = ListMoreItemClickTracker(isShareFolder: false, type: .bitable, originInWiki: false)
        let dataProvider = InsideMoreDataProvider(docsInfo: docsInfo, fileEntry: SpaceEntry(type: .bitable,
                                                                                            nodeToken: "",
                                                                                            objToken: "basbcJqA1yY7qv4Ps1Y2KH6Bqoh"),
                                                  hostViewController: UIViewController(),
                                                  permissionService: nil,
                                                  followAPIDelegate: nil,
                                                  docComponentHostDelegate: nil)
        let moreViewModel = MoreViewModel(dataProvider: dataProvider, docsInfo: docsInfo, moreItemClickTracker: listMoreItemClickTracker)
        return moreViewModel
    }()

    override func setUp() {
        super.setUp()
        DocsContainer.shared.register(SpaceManagementAPI.self) {_ in
           return MockSpaceManagement()
        }.inObjectScope(.container)
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testNewReportForClickItem() {
        // 这里后续添加新增埋点，注意自己测的文档类型, 以及要确保的参数
        checkBitableReportParams(itemType: .timeZone)
    }

    private func checkBitableReportParams(itemType: MoreItemType) {
        bitableMoreViewModel.moreItemClickTracker?.setIsBitableHome(false)
        let params = bitableMoreViewModel.newReportForClickItem(actionType: itemType)
        XCTAssertTrue(params["click"] == itemType.clickValue && params["target"] == itemType.targetValue)
    }
}

class MockSpaceManagement: SpaceManagementAPI {

    func addStar(fileMeta: SpaceInterface.SpaceMeta, completion: ((Error?) -> Void)?) {}
    
    func removeStar(fileMeta: SpaceInterface.SpaceMeta, completion: ((Error?) -> Void)?) {}
    
    func addPin(fileMeta: SpaceInterface.SpaceMeta, completion: ((Error?) -> Void)?) {}
    
    func removePin(fileMeta: SpaceInterface.SpaceMeta, completion: ((Error?) -> Void)?) {}
    
    func addSubscribe(fileMeta: SpaceInterface.SpaceMeta, subType: Int, completion: ((Error?) -> Void)?) {}
    
    func removeSubscribe(fileMeta: SpaceInterface.SpaceMeta, subType: Int, completion: ((Error?) -> Void)?) {}

    func delete(objToken: String, docType: DocsType, completion: ((Error?) -> Void)?) {}
    
    func deleteInDoc(objToken: String, docType: SpaceInterface.DocsType, canApply: Bool) -> RxSwift.Maybe<SpaceInterface.AuthorizedUserInfo> {
        .empty()
    }
    
    func applyDelete(meta: SpaceInterface.SpaceMeta, reviewerID: String, reason: String?) -> RxSwift.Completable {
        .empty()
    }

    func renameBitable(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?) {}

    func renameSheet(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?) {}
    
    func renameSlides(objToken: String, wikiToken: String?, newName: String, completion: ((Error?) -> Void)?) {}

    func update(isFavorites: Bool, objToken: String, docType: DocsType) -> Single<Void> {
        return .just(())
    }
    func createShortCut(objToken: String, objType: DocsType, folderToken: FileListDefine.NodeToken) -> Single<String> {
        return .just("")
    }
    func copyToWiki(objToken: String, objType: DocsType, location: WikiPickerLocation, title: String, needAsync: Bool) -> Single<String> {
        .just("")
    }
    func getParentFolderToken(objToken: String, objType: DocsType) -> Single<String> {
        .just("")
    }

    func shortcutToWiki(objToken: String, objType: DocsType, title: String, location: WikiPickerLocation) -> Single<String> {
        .just("")
    }

    func move(nodeToken: String, from srcFolder: String, to destFolder: String) -> RxSwift.Completable {
        .empty()
    }

    func moveV2(nodeToken: String, from srcFolder: String?, to destFolder: String) -> RxSwift.Completable {
        .empty()
    }

    func moveToWiki(item: SpaceInterface.SpaceMeta, nodeToken: String, parentToken: String?, location: SpaceInterface.WikiPickerLocation) -> RxSwift.Single<SpaceInterface.MoveToWikiStatus> {
        .just(.moving)
    }

    func isParentFolderShareFolder(token: String, nodeType: Int) -> Bool {
        return false
    }
}
