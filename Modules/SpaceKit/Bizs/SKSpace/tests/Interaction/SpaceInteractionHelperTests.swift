//
//  SpaceInteractionHelperTests.swift
//  SKSpace_Tests
//
//  Created by Weston Wu on 2022/6/9.
//
// swiftlint:disable file_length type_body_length function_body_length

import XCTest
@testable import SKSpace
import SKCommon
import SKFoundation
import OHHTTPStubs
import RxSwift
import SKDrive
import SpaceInterface
import SKInfra
import LarkContainer

class SpaceInteractionHelperTests: XCTestCase {

    var disposeBag = DisposeBag()
    override class func setUp() {
        DriveModule().setup()
        super.setUp()
    }
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }

    func testUpdateFavorites() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockUpdateFavorites(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-favorites-true", objType: .doc)
        var expect = expectation(description: "update-favorites-true")
        helper.update(isFavorites: true, item: item)
            .subscribe {
                XCTAssertTrue(dataManager.storage.starMap[item.objToken] ?? false)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-favorites-false")
        item = SpaceItem(objToken: "mock-favorites-false", objType: .doc)

        helper.update(isFavorites: false, item: item)
            .subscribe {
                XCTAssertFalse(dataManager.storage.starMap[item.objToken] ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateFavorites(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-favorites-failed")
        item = SpaceItem(objToken: "mock-favorites-failed", objType: .doc)

        helper.update(isFavorites: false, item: item)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.starMap[item.objToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testUpdatePin() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockUpdateIsPin(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-pin-true", objType: .doc)
        var expect = expectation(description: "update-pin-true")
        helper.update(isPin: true, item: item)
            .subscribe {
                XCTAssertTrue(dataManager.storage.pinMap[item.objToken] ?? false)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-pin-false")
        item = SpaceItem(objToken: "mock-pin-false", objType: .doc)

        helper.update(isPin: false, item: item)
            .subscribe {
                XCTAssertFalse(dataManager.storage.pinMap[item.objToken] ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateFavorites(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-pin-failed")
        item = SpaceItem(objToken: "mock-pin-failed", objType: .doc)

        helper.update(isFavorites: false, item: item)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.pinMap[item.objToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testUpdateSubscribe() {
        // 不涉及 DataManager，只检查网络请求是否正常
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockUpdateIsSubscribe(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-sub-true", objType: .doc)
        var expect = expectation(description: "update-sub-true")
        helper.update(isSubscribe: true, subType: 0, item: item)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-sub-false")
        item = SpaceItem(objToken: "mock-sub-false", objType: .doc)

        helper.update(isSubscribe: false, subType: 0, item: item)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateIsSubscribe(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-sub-failed")
        item = SpaceItem(objToken: "mock-sub-failed", objType: .doc)
        helper.update(isSubscribe: true, subType: 0, item: item)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testUpdateHidden() {
        // 不涉及 DataManager，只检查网络请求是否正常
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockUpdateIsHidden(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-hidden-true", objType: .doc)
        var expect = expectation(description: "update-hidden-true")
        helper.update(isHidden: true, folderToken: item.objToken)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-hidden-false")
        item = SpaceItem(objToken: "mock-hidden-false", objType: .doc)

        helper.update(isHidden: false, folderToken: item.objToken)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateIsHidden(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-hidden-failed")
        item = SpaceItem(objToken: "mock-hidden-failed", objType: .doc)
        helper.update(isHidden: true, folderToken: item.objToken)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.hiddenMap[item.objToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testUpdateHiddenV2() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockUpdateIsHiddenV2(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-hidden-true", objType: .doc)
        var expect = expectation(description: "update-hidden-true")
        helper.setHiddenV2(isHidden: true, folderToken: item.objToken)
            .subscribe {
                XCTAssertTrue(dataManager.storage.hiddenMap[item.objToken] ?? false)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-hidden-false")
        item = SpaceItem(objToken: "mock-hidden-false", objType: .doc)

        helper.setHiddenV2(isHidden: false, folderToken: item.objToken)
            .subscribe {
                XCTAssertFalse(dataManager.storage.hiddenMap[item.objToken] ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateIsHiddenV2(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-hidden-failed")
        item = SpaceItem(objToken: "mock-hidden-failed", objType: .doc)
        helper.setHiddenV2(isHidden: true, folderToken: item.objToken)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.hiddenMap[item.objToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testRename() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockRename(type: MockNetworkResponse.plainSuccess)
        var item = SpaceItem(objToken: "mock-rename", objType: .doc)
        var name = "mock-rename"
        var expect = expectation(description: "update-rename")
        helper.rename(objToken: item.objToken, with: name)
            .subscribe {
                XCTAssertEqual(dataManager.storage.nameMap[item.objToken], name)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockRename(type: MockNetworkResponse.noPermission)
        item = SpaceItem(objToken: "mock-rename-failed", objType: .doc)
        name = "mock-rename-failed"
        expect = expectation(description: "update-rename-failed")
        helper.rename(objToken: item.objToken, with: name)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.nameMap[item.objToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testRenameV2() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockRenameV2(type: MockNetworkResponse.plainSuccess)

        var nodeToken = "mock-shortcut-token-1"
        var item = SpaceItem(objToken: "mock-renameV2-1", objType: .doc)
        var name = "mock-renameV2-shortcut"
        var expect = expectation(description: "update-renameV2-shortcut")
        helper.renameV2(isShortCut: true, objToken: item.objToken, nodeToken: nodeToken, newName: name)
            .subscribe {
                XCTAssertEqual(dataManager.storage.nameMap[nodeToken], name)
                XCTAssertNil(dataManager.storage.nameMap[item.objToken])
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        nodeToken = "mock-shortcut-token-2"
        item = SpaceItem(objToken: "mock-renameV2-2", objType: .doc)
        name = "mock-renameV2-origin"
        expect = expectation(description: "update-renameV2-origin")
        helper.renameV2(isShortCut: false, objToken: item.objToken, nodeToken: nodeToken, newName: name)
            .subscribe {
                XCTAssertEqual(dataManager.storage.nameMap[item.objToken], name)
                XCTAssertNil(dataManager.storage.nameMap[nodeToken])
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockRenameV2(type: MockNetworkResponse.noPermission)
        item = SpaceItem(objToken: "mock-renameV2-failed", objType: .doc)
        nodeToken = "mock-renameV2-failed-shortcut"
        name = "mock-renameV2-failed"
        expect = expectation(description: "update-renameV2-failed")
        helper.renameV2(isShortCut: true, objToken: item.objToken, nodeToken: nodeToken, newName: name)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.nameMap[item.objToken])
                XCTAssertNil(dataManager.storage.nameMap[nodeToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-renameV2-failed")
        helper.renameV2(isShortCut: false, objToken: item.objToken, nodeToken: nodeToken, newName: name)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.nameMap[item.objToken])
                XCTAssertNil(dataManager.storage.nameMap[nodeToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testMove() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockMove(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-move-1", objType: .doc)
        var fromToken = "mock-parent-from-1"
        var fromChild: Set<String> = ["from-child-1", "from-child-2", item.objToken]
        var toToken = "mock-parent-to-1"
        var toChild: Set<String> = ["to-child-1", "to-child-2"]
        var expect = expectation(description: "mock-move-1")
        dataManager.storage.childMap[fromToken] = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.move(nodeToken: item.objToken, from: fromToken, to: toToken)
            .subscribe {
                XCTAssertEqual(dataManager.storage.parentMap[item.objToken], toToken)
                XCTAssertFalse(dataManager.storage.childMap[fromToken]?.contains(item.objToken) ?? true)
                XCTAssertTrue(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? false)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockMove(type: MockNetworkResponse.noPermission)

        item = SpaceItem(objToken: "mock-move-2", objType: .doc)
        fromToken = "mock-parent-from-2"
        fromChild = ["from-child-1", "from-child-2", item.objToken]
        toToken = "mock-parent-to-2"
        toChild = ["to-child-1", "to-child-2"]
        expect = expectation(description: "mock-move-2")
        dataManager.storage.parentMap[item.objToken] = fromToken
        dataManager.storage.childMap[fromToken] = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.move(nodeToken: item.objToken, from: fromToken, to: toToken)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertEqual(dataManager.storage.parentMap[item.objToken], fromToken)
                XCTAssertTrue(dataManager.storage.childMap[fromToken]?.contains(item.objToken) ?? false)
                XCTAssertFalse(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? true)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testMoveV2() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockMoveV2(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-move-1", objType: .doc)
        var fromToken = "mock-parent-from-1"
        var fromChild: Set<String> = ["from-child-1", "from-child-2", item.objToken]
        var toToken = "mock-parent-to-1"
        var toChild: Set<String> = ["to-child-1", "to-child-2"]
        var expect = expectation(description: "mock-move-1")
        dataManager.storage.childMap[fromToken] = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.moveV2(nodeToken: item.objToken, from: fromToken, to: toToken)
            .subscribe {
                XCTAssertEqual(dataManager.storage.parentMap[item.objToken], toToken)
                XCTAssertFalse(dataManager.storage.childMap[fromToken]?.contains(item.objToken) ?? true)
                XCTAssertTrue(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? false)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        item = SpaceItem(objToken: "mock-move-2", objType: .doc)
        fromChild = ["from-child-1", "from-child-2", item.objToken]
        toToken = "mock-parent-to-2"
        toChild = ["to-child-1", "to-child-2"]
        expect = expectation(description: "mock-move-2")
        dataManager.storage.personTokens = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.moveV2(nodeToken: item.objToken, from: nil, to: toToken)
            .subscribe {
                XCTAssertNil(dataManager.storage.parentMap[item.objToken])
                XCTAssertFalse(dataManager.storage.personTokens.contains(item.objToken))
                XCTAssertFalse(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        item = SpaceItem(objToken: "mock-move-3", objType: .doc)
        fromChild = ["from-child-1", "from-child-2", item.objToken]
        toToken = "mock-parent-to-3"
        toChild = ["to-child-1", "to-child-2"]
        expect = expectation(description: "mock-move-3")
        dataManager.storage.personTokens = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.moveV2(nodeToken: item.objToken, from: "", to: toToken)
            .subscribe {
                XCTAssertNil(dataManager.storage.parentMap[item.objToken])
                XCTAssertFalse(dataManager.storage.personTokens.contains(item.objToken))
                XCTAssertFalse(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockMoveV2(type: MockNetworkResponse.noPermission)

        item = SpaceItem(objToken: "mock-move-4", objType: .doc)
        fromToken = "mock-parent-from-4"
        fromChild = ["from-child-1", "from-child-2", item.objToken]
        toToken = "mock-parent-to-4"
        toChild = ["to-child-1", "to-child-2"]
        expect = expectation(description: "mock-move-4")
        dataManager.storage.parentMap[item.objToken] = fromToken
        dataManager.storage.childMap[fromToken] = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.moveV2(nodeToken: item.objToken, from: fromToken, to: toToken)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertEqual(dataManager.storage.parentMap[item.objToken], fromToken)
                XCTAssertTrue(dataManager.storage.childMap[fromToken]?.contains(item.objToken) ?? false)
                XCTAssertFalse(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? true)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        item = SpaceItem(objToken: "mock-move-5", objType: .doc)
        fromChild = ["from-child-1", "from-child-2", item.objToken]
        toToken = "mock-parent-to-5"
        toChild = ["to-child-1", "to-child-2"]
        expect = expectation(description: "mock-move-5")
        dataManager.storage.personTokens = fromChild
        dataManager.storage.childMap[toToken] = toChild

        helper.moveV2(nodeToken: item.objToken, from: fromToken, to: toToken)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertTrue(dataManager.storage.personTokens.contains(item.objToken))
                XCTAssertFalse(dataManager.storage.childMap[toToken]?.contains(item.objToken) ?? true)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testAddTo() {
        // 不涉及 DataManager，只检查网络请求是否正常
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockAddTo(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-add", objType: .doc)
        var folder = "mock-add-folder"
        var expect = expectation(description: "mock-add")
        helper.add(objToken: item.objToken, to: folder)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockAddTo(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "mock-add-failed")
        item = SpaceItem(objToken: "mock-add-failed", objType: .doc)
        folder = "mock-add-folder-failed"
        helper.add(objToken: item.objToken, to: folder)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testCreateShortcut() {
        // 不涉及 DataManager，只检查网络请求是否正常
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        MockSpaceNetworkAPI.mockCreateShortCut(type: MockNetworkResponse.createShortcutSuccess)

        var item = SpaceItem(objToken: "mock-add", objType: .doc)
        var folder = "mock-add-folder"
        var expect = expectation(description: "mock-add")
        helper.createShortCut(for: item, in: folder)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockCreateShortCut(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "mock-add-failed")
        item = SpaceItem(objToken: "mock-add-failed", objType: .doc)
        folder = "mock-add-folder-failed"
        helper.createShortCut(for: item, in: folder)
            .subscribe { _ in
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testDelete() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        var item = SpaceItem(objToken: "mock-delete-1", objType: .doc)
        var expect = expectation(description: "mock-delete-1")
        let parent = "mock-parent-1"
        let mockEntry = SpaceEntry(type: .doc, nodeToken: item.objToken, objToken: item.objToken)
        mockEntry.updateParent(parent)
        let otherDeletedToken = "mock-delete-1-1"
        dataManager.storage.personTokens = [item.objToken]
        dataManager.storage.childMap[parent] = [item.objToken, otherDeletedToken]
        dataManager.storage.entryMap[item.objToken] = mockEntry
        MockSpaceNetworkAPI.mockDelete(successTokens: [item.objToken, otherDeletedToken])
        helper.delete(item: item)
            .subscribe { tokens in
                XCTAssertEqual(tokens, [item.objToken, otherDeletedToken])
                XCTAssertFalse(dataManager.storage.personTokens.contains(item.objToken))
                XCTAssertFalse(dataManager.storage.childMap[parent]?.contains(item.objToken) ?? true)
                XCTAssertFalse(dataManager.storage.childMap[parent]?.contains(otherDeletedToken) ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        item = SpaceItem(objToken: "mock-delete-2", objType: .doc)
        expect = expectation(description: "mock-delete-2")
        dataManager.storage.personTokens = ["mock-delete-2"]
        MockSpaceNetworkAPI.mockDelete(type: MockNetworkResponse.noPermission)
        helper.delete(item: item)
            .subscribe { _ in
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertTrue(dataManager.storage.personTokens.contains(item.objToken))
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testDeleteFakeToken() {
        // 测试有网删除 fakeToken
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        let item = SpaceItem(objToken: "fake_delete-1", objType: .doc)
        let expect = expectation(description: "mock-delete-1")

        dataManager.storage.personTokens = [item.objToken]
        MockSpaceNetworkAPI.mockDelete(type: MockNetworkResponse.noPermission)
        helper.delete(item: item, isReachable: true)
            .subscribe { tokens in
                XCTAssertNil(tokens)
                XCTAssertFalse(dataManager.storage.personTokens.contains(item.objToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testRemoveFromFolder() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        var item = SpaceItem(objToken: "mock-delete-1", objType: .doc)
        var expect = expectation(description: "mock-delete-1")
        var parent = "mock-parent-1"
        var mockEntry = SpaceEntry(type: .doc, nodeToken: item.objToken, objToken: item.objToken)
        mockEntry.updateParent(parent)
        var otherDeletedToken = "mock-delete-1-1"
        dataManager.storage.childMap[parent] = [item.objToken, otherDeletedToken]
        dataManager.storage.entryMap[item.objToken] = mockEntry
        MockSpaceNetworkAPI.mockRemoveFromFolder(successTokens: [item.objToken])
        helper.removeFromFolder(nodeToken: item.objToken, folderToken: nil)
            .subscribe { tokens in
                XCTAssertEqual(tokens, [item.objToken])
                XCTAssertFalse(dataManager.storage.childMap[parent]?.contains(item.objToken) ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        item = SpaceItem(objToken: "mock-delete-2", objType: .doc)
        expect = expectation(description: "mock-delete-2")
        parent = "mock-parent-2"
        mockEntry = SpaceEntry(type: .doc, nodeToken: item.objToken, objToken: item.objToken)
        mockEntry.updateParent(parent)
        otherDeletedToken = "mock-delete-2-1"
        dataManager.storage.childMap[parent] = [item.objToken, otherDeletedToken]
        dataManager.storage.entryMap[item.objToken] = mockEntry
        MockSpaceNetworkAPI.mockRemoveFromFolder(successTokens: [item.objToken, otherDeletedToken])
        helper.removeFromFolder(nodeToken: item.objToken, folderToken: parent)
            .subscribe { tokens in
                XCTAssertEqual(tokens, [item.objToken, otherDeletedToken])
                XCTAssertFalse(dataManager.storage.childMap[parent]?.contains(item.objToken) ?? true)
                XCTAssertFalse(dataManager.storage.childMap[parent]?.contains(otherDeletedToken) ?? true)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        item = SpaceItem(objToken: "mock-delete-3", objType: .doc)
        expect = expectation(description: "mock-delete-3")
        parent = "mock-parent-3"
        mockEntry = SpaceEntry(type: .doc, nodeToken: item.objToken, objToken: item.objToken)
        mockEntry.updateParent(parent)
        otherDeletedToken = "mock-delete-3-1"
        dataManager.storage.childMap[parent] = [item.objToken, otherDeletedToken]
        dataManager.storage.entryMap[item.objToken] = mockEntry

        MockSpaceNetworkAPI.mockRemoveFromFolder(type: MockNetworkResponse.noPermission)
        helper.removeFromFolder(nodeToken: item.objToken, folderToken: nil)
            .subscribe { _ in
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertEqual(dataManager.storage.childMap[parent], [item.objToken, otherDeletedToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testRemoveFromShareFile() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockRemoveFromShareWithMeList(type: MockNetworkResponse.plainSuccess)

        var item = SpaceItem(objToken: "mock-delete-1", objType: .doc)
        var expect = expectation(description: "mock-delete-1")
        dataManager.storage.shareTokens = [item.objToken]

        helper.removeFromShareFileList(objToken: item.objToken)
            .subscribe {
                XCTAssertFalse(dataManager.storage.shareTokens.contains(item.objToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockRemoveFromShareWithMeList(type: MockNetworkResponse.noPermission)

        item = SpaceItem(objToken: "mock-delete-2", objType: .doc)
        expect = expectation(description: "mock-delete-2")
        dataManager.storage.shareTokens = [item.objToken]
        helper.removeFromShareFileList(objToken: item.objToken)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertTrue(dataManager.storage.shareTokens.contains(item.objToken))
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testDeleteV2() {
        typealias MockDeleteResponse = MockSpaceNetworkAPI.DeleteV2Response
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        var objToken = "mock-delete-obj-1"
        var nodeToken = "mock-delete-node-1"
        var expect = expectation(description: "mock-delete-1")
        dataManager.storage.personTokens = [objToken, nodeToken]
        MockSpaceNetworkAPI.mockDeleteV2(type: MockDeleteResponse.allSuccess)
        helper.deleteV2(objToken: objToken, nodeToken: nodeToken, type: .doc, isShortCut: false, canApply: false)
            .subscribe { response in
                if case .success = response {
                } else {
                    XCTFail("un-expected response")
                }
                XCTAssertFalse(dataManager.storage.personTokens.contains(objToken))
                XCTAssertTrue(dataManager.storage.personTokens.contains(nodeToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        objToken = "mock-delete-obj-2"
        nodeToken = "mock-delete-node-2"
        expect = expectation(description: "mock-delete-2")
        dataManager.storage.personTokens = [objToken, nodeToken]
        helper.deleteV2(objToken: objToken, nodeToken: nodeToken, type: .doc, isShortCut: true, canApply: true)
            .subscribe { response in
                if case .success = response {
                } else {
                    XCTFail("un-expected response")
                }
                XCTAssertTrue(dataManager.storage.personTokens.contains(objToken))
                XCTAssertFalse(dataManager.storage.personTokens.contains(nodeToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        objToken = "mock-delete-obj-3"
        nodeToken = "mock-delete-node-3"
        expect = expectation(description: "mock-delete-3")
        dataManager.storage.personTokens = [objToken, nodeToken]
        helper.deleteV2(objToken: objToken, nodeToken: nodeToken, type: .folder, isShortCut: false, canApply: true)
            .subscribe { response in
                if case .success = response {
                } else {
                    XCTFail("un-expected response")
                }
                XCTAssertTrue(dataManager.storage.personTokens.contains(objToken))
                XCTAssertFalse(dataManager.storage.personTokens.contains(nodeToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        objToken = "mock-delete-obj-4"
        nodeToken = "mock-delete-node-4"
        expect = expectation(description: "mock-delete-4")
        dataManager.storage.personTokens = [objToken, nodeToken]
        MockSpaceNetworkAPI.mockDeleteV2(type: MockDeleteResponse.partialFailed)
        helper.deleteV2(objToken: objToken, nodeToken: nodeToken, type: .folder, isShortCut: false, canApply: true)
            .subscribe { response in
                if case .partialFailed = response {
                } else {
                    XCTFail("un-expected response")
                }
                XCTAssertTrue(dataManager.storage.personTokens.contains(objToken))
                XCTAssertTrue(dataManager.storage.personTokens.contains(nodeToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        objToken = "mock-delete-obj-5"
        nodeToken = "mock-delete-node-5"
        expect = expectation(description: "mock-delete-5")
        dataManager.storage.personTokens = [objToken, nodeToken]
        MockSpaceNetworkAPI.mockDeleteV2(type: MockNetworkResponse.dataLockedForMigration)
        helper.deleteV2(objToken: objToken, nodeToken: nodeToken, type: .folder, isShortCut: false, canApply: true)
            .subscribe { _ in
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 900004230)
                XCTAssertTrue(dataManager.storage.personTokens.contains(objToken))
                XCTAssertTrue(dataManager.storage.personTokens.contains(nodeToken))
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        objToken = "mock-delete-obj-6"
        nodeToken = "mock-delete-node-6"
        expect = expectation(description: "mock-delete-6")
        dataManager.storage.personTokens = [objToken, nodeToken]
        MockSpaceNetworkAPI.mockDeleteV2(type: MockDeleteResponse.needApproval)
        helper.deleteV2(objToken: objToken, nodeToken: nodeToken, type: .folder, isShortCut: false, canApply: true)
            .subscribe { response in
                guard case let .needApply(reviewer) = response else {
                    XCTFail("unexpected response: \(response)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(reviewer.userID, "MOCK_USER_ID")
                XCTAssertEqual(reviewer.userName, "MOCK_USER_NAME")
                XCTAssertTrue(reviewer.i18nNames.isEmpty)
                XCTAssertEqual(reviewer.aliasInfo,
                               UserAliasInfo(displayName: "MOCK_DISPLAY_NAME",
                                             i18nDisplayNames: [
                                                "en_us": "MOCK_EN_DISPLAY_NAME",
                                                "zh_cn": "MOCK_CN_DISPLAY_NAME",
                                                "ja_jp": "MOCK_JP_DISPLAY_NAME"
                                             ]))
                XCTAssertTrue(dataManager.storage.personTokens.contains(objToken))
                XCTAssertTrue(dataManager.storage.personTokens.contains(nodeToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testDeleteV2FakeToken() {
        // 测试有网删除 fakeToken
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        let item = SpaceItem(objToken: "fake_delete-1", objType: .doc)
        let expect = expectation(description: "mock-delete-1")

        dataManager.storage.personTokens = [item.objToken]
        MockSpaceNetworkAPI.mockDeleteV2(type: MockNetworkResponse.noPermission)
        helper.deleteV2(objToken: item.objToken, nodeToken: item.objToken, type: .doc, isShortCut: false, canApply: true)
            .subscribe { response in
                if case .success = response {
                } else {
                    XCTFail("un-expected response")
                }
                XCTAssertFalse(dataManager.storage.personTokens.contains(item.objToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testApplyDelete() {
        let objToken = "MOCK_OBJ_TOKEN"
        let objType = DocsType.docX
        let reviewerID = "MOCK_REVIEWER_ID"
        let reason = "MOCK APPLY COMMENT"

        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceApplyDelete)
        } response: { request in
            let json = ["code": 0, "data": [:], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["obj_token"] as? String, objToken)
            XCTAssertEqual(data["obj_type"] as? Int, objType.rawValue)
            XCTAssertEqual(data["reviewer"] as? String, reviewerID)
            XCTAssertEqual(data["reason"] as? String, reason)
            return response
        }

        let expect = expectation(description: "apply delete in space")
        helper.applyDelete(meta: SpaceMeta(objToken: objToken, objType: objType), reviewerID: reviewerID, reason: reason)
        .subscribe {
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testUpdateSecretLabel() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockUpdateSecLabel(type: MockNetworkResponse.plainSuccess)
        var wikiToken = "mock-wiki-token-1"
        var objToken = "mock-token-1"
        var name = "mock-secret-label-name-1"
        var expect = expectation(description: "update-secret-label-1")
        var label = SecretLevelLabel(name: name, id: "1")
        helper.updateSecLabel(wikiToken: nil, token: objToken, type: 1, label: label, reason: "reason")
            .subscribe {
                XCTAssertEqual(dataManager.storage.secretLabelMap[objToken], name)
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        wikiToken = "mock-wiki-token-2"
        objToken = "mock-token-2"
        name = "mock-secret-label-name-2"
        expect = expectation(description: "update-secret-label-2")
        label = SecretLevelLabel(name: name, id: "1")
        helper.updateSecLabel(wikiToken: wikiToken, token: objToken, type: 1, label: label, reason: "reason")
            .subscribe {
                XCTAssertEqual(dataManager.storage.secretLabelMap[wikiToken], name)
                XCTAssertNil(dataManager.storage.secretLabelMap[objToken])
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateSecLabel(type: MockNetworkResponse.noPermission)
        wikiToken = "mock-wiki-token-3"
        objToken = "mock-token-3"
        name = "mock-secret-label-name-3"
        expect = expectation(description: "update-secret-label-3")
        helper.updateSecLabel(wikiToken: wikiToken, token: objToken, type: 1, label: label, reason: "reason")
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertNil(dataManager.storage.secretLabelMap[objToken])
                XCTAssertNil(dataManager.storage.secretLabelMap[wikiToken])
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        wikiToken = "mock-wiki-token-4"
        objToken = "mock-token-4"
        name = "mock-secret-label-name-4"
        helper.updateSecLabel(wikiToken: wikiToken, token: objToken, name: name)
        XCTAssertEqual(dataManager.storage.secretLabelMap[wikiToken], name)
        XCTAssertNil(dataManager.storage.secretLabelMap[objToken])

        wikiToken = "mock-wiki-token-5"
        objToken = "mock-token-5"
        name = "mock-secret-label-name-5"
        helper.updateSecLabel(wikiToken: nil, token: objToken, name: name)
        XCTAssertEqual(dataManager.storage.secretLabelMap[objToken], name)
    }

    // MARK: - SpaceManagementAPI 相关的 API 接口只测试闭包是否正确反映请求结果，业务逻辑不再单独测试
    func testUpdateStarForSpaceManagementAPI() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let item = SpaceEntry(type: .doc, nodeToken: "update-star-1", objToken: "update-star-1")

        MockSpaceNetworkAPI.mockUpdateFavorites(type: MockNetworkResponse.plainSuccess)
        var expect = expectation(description: "update-favorites-true")
        let fileMeta = SpaceMeta(objToken: item.objToken, objType: item.type)
        helper.addStar(fileMeta: fileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-favorites-false")
        helper.removeStar(fileMeta: fileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-favorites-signal")
        helper.update(isFavorites: true, objToken: "mock-test", docType: .doc)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("unexpected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateFavorites(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-favorites-failed")
        helper.addStar(fileMeta: fileMeta, completion: { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            expect.fulfill()
        })
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-favorites-failed")
        helper.removeStar(fileMeta: fileMeta, completion: { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            expect.fulfill()
        })
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-favorites-signal")
        helper.update(isFavorites: true, objToken: "mock-test", docType: .doc)
            .subscribe {
                XCTFail("unexpected success")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testUpdatePinForSpaceManagementAPI() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let item = SpaceEntry(type: .doc, nodeToken: "update-pin", objToken: "update-pin")

        MockSpaceNetworkAPI.mockUpdateIsPin(type: MockNetworkResponse.plainSuccess)
        var expect = expectation(description: "update-pin-true")
        let fileMeta = SpaceMeta(objToken: item.objToken, objType: item.type)
        helper.addPin(fileMeta: fileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-pin-false")
        helper.removePin(fileMeta: fileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateIsPin(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-favorites-failed")
        helper.addPin(fileMeta: fileMeta, completion: { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            expect.fulfill()
        })
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-favorites-failed")
        helper.removePin(fileMeta: fileMeta, completion: { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            expect.fulfill()
        })
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testAddSubscribeWithFileEntry() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockUpdateIsSubscribe(type: MockNetworkResponse.plainSuccess)
        let item = SpaceEntry(type: .doc, nodeToken: "update-sub", objToken: "update-sub")
        var expect = expectation(description: "update-sub-unreachable")
        let fileMeta = SpaceMeta(objToken: item.objToken, objType: item.type)
        helper.addSubscribe(fileMeta: fileMeta, forceUnreachable: true) { error in
            XCTAssertEqual((error as? NSError)?.code, -1)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "remove-sub-unreachable")
        helper.removeSubscribe(fileMeta: fileMeta, forceUnreachable: true) { error in
            XCTAssertEqual((error as? NSError)?.code, -1)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "update-non-wiki")
        helper.addSubscribe(fileMeta: fileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "remove-non-wiki")
        helper.removeSubscribe(fileMeta: fileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        let wikiEntry = WikiEntry(type: .wiki, nodeToken: "update-sub-wiki", objToken: "update-sub-wiki")
        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "wiki-token", objToken: "wiki-content-token", docsType: .doc, spaceId: "space-id"))
        let wikiFileMeta = SpaceMeta(objToken: wikiEntry.wikiInfo?.wikiToken ?? wikiEntry.objToken, objType: .wiki)
        expect = expectation(description: "update-wiki")
        helper.addSubscribe(fileMeta: wikiFileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "remove-wiki")
        helper.removeSubscribe(fileMeta: wikiFileMeta) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockUpdateIsSubscribe(type: MockNetworkResponse.noPermission)
        expect = expectation(description: "update-sub-failed")
        helper.addSubscribe(fileMeta: wikiFileMeta) { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        expect = expectation(description: "remove-sub-failed")
        helper.removeSubscribe(fileMeta: wikiFileMeta) { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testDeleteForSpaceManagementAPI() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let tokenToDelete = "token-to-delete"

        dataManager.storage.personTokens = [tokenToDelete]
        var expect = expectation(description: "mock-delete")
        MockSpaceNetworkAPI.mockDelete(type: MockNetworkResponse.plainSuccess)
        helper.delete(objToken: tokenToDelete, docType: .doc) { error in
            XCTAssertNil(error)
            XCTAssertFalse(dataManager.storage.personTokens.contains(tokenToDelete))
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        dataManager.storage.personTokens = [tokenToDelete]
        expect = expectation(description: "delete-failed")
        MockSpaceNetworkAPI.mockDelete(type: MockNetworkResponse.noPermission)
        helper.delete(objToken: tokenToDelete, docType: .doc, completion: { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            XCTAssertTrue(dataManager.storage.personTokens.contains(tokenToDelete))
            expect.fulfill()
        })
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testDeleteInDocForSpaceManagementAPI() {
        typealias MockDeleteResponse = MockSpaceNetworkAPI.DeleteV2Response
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let tokenToDelete = "token-to-delete"

        dataManager.storage.personTokens = [tokenToDelete]
        var expect = expectation(description: "mock-delete")
        MockSpaceNetworkAPI.mockDeleteV2Item(type: MockDeleteResponse.allSuccess)
        helper.deleteInDoc(objToken: tokenToDelete, docType: .doc, canApply: true)
            .subscribe { _ in
                XCTFail("un-expected reviewer found")
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTAssertFalse(dataManager.storage.personTokens.contains(tokenToDelete))
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        dataManager.storage.personTokens = [tokenToDelete]
        expect = expectation(description: "delete-failed")
        MockSpaceNetworkAPI.mockDeleteV2Item(type: MockNetworkResponse.noPermission)
        helper.deleteInDoc(objToken: tokenToDelete, docType: .doc, canApply: true)
            .subscribe { _ in
                XCTFail("un-expected reviewer found")
                expect.fulfill()
            } onError: { error in
                XCTAssertEqual((error as NSError).code, 4)
                XCTAssertTrue(dataManager.storage.personTokens.contains(tokenToDelete))
                expect.fulfill()
            } onCompleted: {
                XCTFail("un-expected success found")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        dataManager.storage.personTokens = [tokenToDelete]
        expect = expectation(description: "delete-require-approval")
        MockSpaceNetworkAPI.mockDeleteV2Item(type: MockDeleteResponse.needApproval)
        helper.deleteInDoc(objToken: tokenToDelete, docType: .doc, canApply: true)
            .subscribe { reviewer in
                XCTAssertEqual(reviewer.userID, "MOCK_USER_ID")
                XCTAssertEqual(reviewer.userName, "MOCK_USER_NAME")
                XCTAssertTrue(reviewer.i18nNames.isEmpty)
                XCTAssertEqual(reviewer.aliasInfo,
                               UserAliasInfo(displayName: "MOCK_DISPLAY_NAME",
                                             i18nDisplayNames: [
                                                "en_us": "MOCK_EN_DISPLAY_NAME",
                                                "zh_cn": "MOCK_CN_DISPLAY_NAME",
                                                "ja_jp": "MOCK_JP_DISPLAY_NAME"
                                             ]))
                XCTAssertTrue(dataManager.storage.personTokens.contains(tokenToDelete))
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("un-expected success found")
                expect.fulfill()
            }
            .disposed(by: disposeBag)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testRenameBitable() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockRenameBitable(type: MockNetworkResponse.plainSuccess)
        var token = "mock-rename-bitable-token"
        var name = "mock-rename"
        var expect = expectation(description: "update-bitable-rename")
        helper.renameBitable(objToken: token, wikiToken: nil, newName: name) { error in
            XCTAssertNil(error)
            XCTAssertEqual(dataManager.storage.nameMap[token], name)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        token = "mock-rename-bitable-in-wiki-token"
        name = "mock-rename"
        let wikiToken = "mock-rename-wiki-token"
        expect = expectation(description: "update-wiki-bitable-rename")
        helper.renameBitable(objToken: token, wikiToken: wikiToken, newName: name) { error in
            XCTAssertNil(error)
            XCTAssertEqual(dataManager.storage.nameMap[wikiToken], name)
            XCTAssertNil(dataManager.storage.nameMap[token])
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockRenameBitable(type: MockNetworkResponse.noPermission)
        token = "mock-rename-bitable-failed-token"
        name = "mock-rename-failed"
        expect = expectation(description: "update-bitable-rename-failed")
        helper.renameBitable(objToken: token, wikiToken: nil, newName: name) { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            XCTAssertNil(dataManager.storage.nameMap[token])
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testRenameSheet() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockRenameSheet(type: MockNetworkResponse.plainSuccess)
        var token = "mock-rename-sheet-token"
        var name = "mock-rename"
        var expect = expectation(description: "update-sheet-rename")
        helper.renameSheet(objToken: token, wikiToken: nil, newName: name) { error in
            XCTAssertNil(error)
            XCTAssertEqual(dataManager.storage.nameMap[token], name)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        token = "mock-rename-sheet-in-wiki-token"
        name = "mock-rename"
        let wikiToken = "mock-rename-wiki-token"
        expect = expectation(description: "update-wiki-sheet-rename")
        helper.renameSheet(objToken: token, wikiToken: wikiToken, newName: name) { error in
            XCTAssertNil(error)
            XCTAssertEqual(dataManager.storage.nameMap[wikiToken], name)
            XCTAssertNil(dataManager.storage.nameMap[token])
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }

        MockSpaceNetworkAPI.mockRenameSheet(type: MockNetworkResponse.noPermission)
        token = "mock-rename-sheet-failed-token"
        name = "mock-rename-failed"
        expect = expectation(description: "update-sheet-rename-failed")
        helper.renameSheet(objToken: token, wikiToken: nil, newName: name) { error in
            XCTAssertEqual((error as? NSError)?.code, 4)
            XCTAssertNil(dataManager.storage.nameMap[token])
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }
    
    func testRenameSlides() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        MockSpaceNetworkAPI.mockRenameSlides(type: MockNetworkResponse.plainSuccess)
        var token = "mock-rename-sheet-token"
        var name = "mock-rename"
        var expect = expectation(description: "update-sheet-rename")
        helper.renameSlides(objToken: token, wikiToken: nil, newName: name) { error in
            XCTAssertNil(error)
            XCTAssertEqual(dataManager.storage.nameMap[token], name)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("mock timeout, \(error.localizedDescription)")
            }
        }
    }

    func testCopyToWiki() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let item = SpaceItem(objToken: "MOCK_TOKEN", objType: .docX)
        let location = WikiPickerLocation(wikiToken: "MOCK_WIKI_TOKEN",
                                          nodeName: "MOCK_NODE_NAME",
                                          spaceID: "MOCK_SPACE_ID",
                                          spaceName: "MOCK_SPACE_NAME",
                                          isMylibrary: false)
        let title = "MOCK_TITLE"

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.copyToWiki)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: ["code": 0, "data": ["wiki_token": "RESPONSE_TOKEN"], "msg": ""],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["obj_token"] as? String, item.objToken)
            XCTAssertEqual(data["obj_type"] as? Int, item.objType.rawValue)
            XCTAssertEqual(data["target_wiki_token"] as? String, location.wikiToken)
            XCTAssertEqual(data["target_space_id"] as? String, location.spaceID)
            XCTAssertEqual(data["title"] as? String, title)
            XCTAssertEqual(data["async"] as? Bool, false)
            XCTAssertEqual(data["time_zone"] as? String, TimeZone.current.identifier)
            return response
        }

        let expect = expectation(description: "copy to wiki")
        helper.copyToWiki(objToken: item.objToken, objType: item.objType, location: location, title: title, needAsync: false)
            .subscribe { token in
                XCTAssertEqual(token, "RESPONSE_TOKEN")
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testGetParentToken() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let item = SpaceItem(objToken: "MOCK_TOKEN", objType: .docX)
        let parentToken = "MOCK_PARENT_TOKEN"
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getObjPath)
        } response: { request in
            let response = HTTPStubsResponse(jsonObject: ["code": 0, "data": ["path": [parentToken, item.objToken]], "msg": ""],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["obj_token"], item.objToken)
            XCTAssertEqual(query["obj_type"], String(item.objType.rawValue))
            return response
        }

        let expect = expectation(description: "get parent token")
        helper.getParentFolderToken(item: item)
            .subscribe { token in
                XCTAssertEqual(token, parentToken)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testGetParentTokenFailed() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let item = SpaceItem(objToken: "MOCK_TOKEN", objType: .docX)
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getObjPath)
        } response: { _ in
            let response = HTTPStubsResponse(jsonObject: ["code": 0, "data": ["path": [item.objToken]], "msg": ""],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "get parent token")
        helper.getParentFolderToken(objToken: item.objToken, objType: item.objType)
            .subscribe { _ in
                XCTFail("un-expected success")
                expect.fulfill()
            } onError: { error in
                guard let docsError = error as? DocsNetworkError,
                      docsError.code == .forbidden else {
                    XCTFail("un-expected error: \(error)")
                    expect.fulfill()
                    return
                }
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testGetMoveReviewerFailed() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        let expect = expectation(description: "get move reviewer params failed")
        helper.getMoveReviewer(nodeToken: nil, item: nil, targetToken: "TARGET_TOKEN")
            .subscribe { _ in
                XCTFail("un-expected success")
                expect.fulfill()
            } onError: { error in
                guard let docsError = error as? DocsNetworkError,
                      docsError.code == .invalidParams else {
                    XCTFail("un-expected error: \(error)")
                    expect.fulfill()
                    return
                }
                expect.fulfill()
            } onCompleted: {
                XCTFail("request should failed")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testGetMoveReviewerNotNeedApply() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let nodeToken = "MOCK_NODE_TOKEN"
        let targetToken = "MOCK_TARGET_TOKEN"
        let item = SpaceItem(objToken: "MOCK_TOKEN", objType: .docX)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getSpaceMoveReviewer)
        } response: { request in
            let json = ["code": 0, "data": ["not_need_apply": true], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["src_token"], nodeToken)
            XCTAssertEqual(query["dest_token"], targetToken)
            XCTAssertNil(query["src_obj_token"])
            XCTAssertNil(query["src_obj_type"])
            return response
        }


        let expect = expectation(description: "not need apply")
        helper.getMoveReviewer(nodeToken: nodeToken, item: item, targetToken: targetToken)
            .subscribe { _ in
                XCTFail("un-expected success")
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testGetMoveReviewer() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)
        let item = SpaceItem(objToken: "MOCK_TOKEN", objType: .docX)
        let reviewerID = "MOCK_REVIEWER_ID"
        let reviewerName = "MOCK_REVIEWER_NAME"
        let reviewerAlias = UserAliasInfo(displayName: "MOCK_DISPLAY_NAME", i18nDisplayNames: [
            "zh_cn": "MOCK_CN_DISPLAY_NAME",
            "en_us": "MOCK_EN_DISPLAY_NAME"
        ])
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.getSpaceMoveReviewer)
        } response: { request in
            let data = [
                "not_need_apply": false,
                "reviewer": reviewerID,
                "entities": [
                    "users": [
                        reviewerID: [
                            "name": reviewerName,
                            "cn_name": reviewerName + "CN",
                            "en_name": reviewerName + "EN",
                            "display_name": [
                                "value": reviewerAlias.displayName ?? "",
                                "i18n_value": reviewerAlias.i18nDisplayNames
                            ]
                        ]
                    ]
                ]
            ]
            let json = ["code": 0, "data": data, "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["src_obj_token"], item.objToken)
            XCTAssertEqual(query["src_obj_type"], String(item.objType.rawValue))
            return response
        }


        let expect = expectation(description: "get move reviewer")
        helper.getMoveReviewer(nodeToken: nil, item: item, targetToken: "")
            .subscribe { userInfo in
                XCTAssertEqual(userInfo.userID, reviewerID)
                XCTAssertEqual(userInfo.userName, reviewerName)
                XCTAssertEqual(userInfo.i18nNames, [
                    "en_us": reviewerName + "EN",
                    "zh_cn": reviewerName + "CN"
                ])
                XCTAssertEqual(userInfo.aliasInfo, reviewerAlias)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("expected success")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testApplyMoveToSpace() {

        let nodeToken = "MOCK_NODE_TOKEN"
        let targetToken = "MOCK_TARGET_TOKEN"
        let reviewerID = "MOCK_REVIEWER_ID"
        let comment = "MOCK APPLY COMMENT"

        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceApplyMoveToSpace)
        } response: { request in
            let json = ["code": 0, "data": [:], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let formData = String(data: body, encoding: .utf8) else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertTrue(formData.contains("src_token=\(nodeToken)"))
            XCTAssertTrue(formData.contains("dest_token=\(targetToken)"))
            XCTAssertTrue(formData.contains("reviewer=\(reviewerID)"))
            XCTAssertTrue(formData.contains("comment=\(comment.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"))
            return response
        }


        let expect = expectation(description: "apply move to space")
        helper.applyMoveToSpace(nodeToken: nodeToken, targetToken: targetToken,
                                reviewerID: reviewerID, comment: comment)
        .subscribe {
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error: \(error)")
            expect.fulfill()
        }
        .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testApplyMoveToWiki() {
        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        let item = SpaceItem(objToken: "MOCK_OBJ_TOKEN", objType: .docX)
        let location = WikiPickerLocation(wikiToken: "MOCK_WIKI_TOKEN",
                                          nodeName: "MOCK_NODE_NAME",
                                          spaceID: "MOCK_SPACE_ID",
                                          spaceName: "MOCK_SPACE_NAME",
                                          isMylibrary: false)
        let reviewerID = "MOCK_REVIEWER_ID"
        let comment = "MOCK APPLY COMMENT"

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceApplyMoveToWiki)
        } response: { request in
            let json = ["code": 0, "data": [:], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["obj_token"] as? String, item.objToken)
            XCTAssertEqual(data["obj_type"] as? Int, item.objType.rawValue)
            XCTAssertEqual(data["parent_wiki_token"] as? String, location.wikiToken)
            XCTAssertEqual(data["space_id"] as? String, location.spaceID)
            XCTAssertEqual(data["authorized_user_id"] as? String, reviewerID)
            XCTAssertEqual(data["reason"] as? String, comment)
            return response
        }

        let expect = expectation(description: "apply move to wiki")
        helper.applyMoveToWiki(item: item, location: location, reviewerID: reviewerID, comment: comment)
            .subscribe {
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testMoveToWikiSuccess() {
        let item = SpaceItem(objToken: "MOCK_OBJ_TOKEN", objType: .docX)
        let nodeToken = "MOCK_NODE_TOKEN"
        let otherNodeToken = "MOCK_NODE_TOKEN_OTHER"
        let parentToken = "MOCK_PARENT_TOKEN"
        let location = WikiPickerLocation(wikiToken: "MOCK_WIKI_TOKEN",
                                          nodeName: "MOCK_NODE_NAME",
                                          spaceID: "MOCK_SPACE_ID",
                                          spaceName: "MOCK_SPACE_NAME",
                                          isMylibrary: false)

        let taskID = "MOCK_TASK_ID"
        let wikiToken = "MOCK_WIKI_TOKEN"

        let dataManager = MockSpaceInteractionDataManager()
        dataManager.storage.childMap[parentToken] = [nodeToken, otherNodeToken]
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceStartMoveToWiki)
        } response: { request in
            let json = ["code": 0, "data": ["task_id": taskID], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                XCTFail("request body not found")
                return response
            }
            XCTAssertEqual(data["parent_wiki_token"] as? String, location.wikiToken)
            XCTAssertEqual(data["space_id"] as? String, location.spaceID)
            let objsData = data["objs"] as? [[String: Any]]
            XCTAssertNotNil(objsData)
            if let objsData {
                XCTAssertEqual(objsData.count, 1)
                XCTAssertNotNil(objsData.first)
                if let objData = objsData.first {
                    XCTAssertEqual(objData["obj_token"] as? String, item.objToken)
                    XCTAssertEqual(objData["obj_type"] as? Int, item.objType.rawValue)
                }
            }
            return response
        }

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceGetMoveToWikiStatus)
        } response: { request in
            let data = [
                "task_status": 1,
                "move_objs": [
                    [
                        "status": 1,
                        "wiki_token": wikiToken
                    ]
                ]
            ]
            let json = ["code": 0, "data": data, "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            guard let query = request.url?.queryParameters else {
                XCTFail("request query not found")
                return response
            }
            XCTAssertEqual(query["task_id"], taskID)
            return response
        }

        var expect = expectation(description: "apply move to wiki from folder")
        helper.moveToWiki(item: item, nodeToken: nodeToken, parentToken: parentToken, location: location)
            .subscribe { status in
                XCTAssertEqual(status, .succeed(wikiToken: wikiToken))
                XCTAssertEqual(dataManager.storage.childMap[parentToken], [otherNodeToken])
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)

        dataManager.storage.personTokens = [nodeToken, otherNodeToken]
        expect = expectation(description: "apply move to wiki from space root")
        helper.moveToWiki(item: item, nodeToken: nodeToken, parentToken: nil, location: location)
            .subscribe { status in
                XCTAssertEqual(status, .succeed(wikiToken: wikiToken))
                XCTAssertEqual(dataManager.storage.personTokens, [otherNodeToken])
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testMoveToWikiFailed() {
        let item = SpaceItem(objToken: "MOCK_OBJ_TOKEN", objType: .docX)
        let nodeToken = "MOCK_NODE_TOKEN"
        let parentToken = "MOCK_PARENT_TOKEN"
        let location = WikiPickerLocation(wikiToken: "MOCK_WIKI_TOKEN",
                                          nodeName: "MOCK_NODE_NAME",
                                          spaceID: "MOCK_SPACE_ID",
                                          spaceName: "MOCK_SPACE_NAME",
                                          isMylibrary: false)

        let taskID = "MOCK_TASK_ID"

        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceStartMoveToWiki)
        } response: { _ in
            let json = ["code": 0, "data": ["task_id": taskID], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceGetMoveToWikiStatus)
        } response: { _ in
            let data = [
                "task_status": 1,
                "move_objs": [
                    [
                        "status": 6
                    ]
                ]
            ]
            let json = ["code": 0, "data": data, "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "apply move to wiki")
        helper.moveToWiki(item: item, nodeToken: nodeToken, parentToken: parentToken, location: location)
            .subscribe { status in
                XCTAssertEqual(status, .failed(code: 6))
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testMoveToWikiPolling() {
        let item = SpaceItem(objToken: "MOCK_OBJ_TOKEN", objType: .docX)
        let nodeToken = "MOCK_NODE_TOKEN"
        let parentToken = "MOCK_PARENT_TOKEN"
        let location = WikiPickerLocation(wikiToken: "MOCK_WIKI_TOKEN",
                                          nodeName: "MOCK_NODE_NAME",
                                          spaceID: "MOCK_SPACE_ID",
                                          spaceName: "MOCK_SPACE_NAME",
                                          isMylibrary: false)

        let taskID = "MOCK_TASK_ID"
        let wikiToken = "MOCK_WIKI_TOKEN"

        let dataManager = MockSpaceInteractionDataManager()
        let helper = SpaceInteractionHelper(dataManager: dataManager)

        class Counter {
            var isFirstTime = true
        }
        let counter = Counter()

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceStartMoveToWiki)
        } response: { _ in
            let json = ["code": 0, "data": ["task_id": taskID], "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            return urlString.contains(OpenAPI.APIPath.spaceGetMoveToWikiStatus)
        } response: { _ in
            let taskStatus: Int
            if counter.isFirstTime {
                taskStatus = 0
                counter.isFirstTime = false
            } else {
                taskStatus = 1
            }
            let data = [
                "task_status": taskStatus,
                "move_objs": [
                    [
                        "status": 1,
                        "wiki_token": wikiToken
                    ]
                ]
            ]
            let json = ["code": 0, "data": data, "msg": ""]
            let response = HTTPStubsResponse(jsonObject: json,
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])
            return response
        }

        let expect = expectation(description: "apply move to wiki")
        helper.moveToWiki(item: item, nodeToken: nodeToken, parentToken: parentToken, location: location)
            .subscribe { status in
                XCTAssertEqual(status, .succeed(wikiToken: wikiToken))
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error: \(error)")
                expect.fulfill()
            }
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 3)
    }
}
