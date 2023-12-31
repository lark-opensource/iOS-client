//
//  SpaceSubSectionStateHelperTests.swift
//  SKSpace-Unit-Tests
//
//  Created by Weston Wu on 2023/2/27.
//

import Foundation
@testable import SKSpace
import SKCommon
import RxSwift
import RxCocoa
import RxRelay
import SKFoundation
import XCTest

class MockSpaceListItemDiffer: SpaceListItemTypeDiffer {
    var diffResult: [SpaceListDiffResult<Item>]?

    func handle(currentList: [Item], newList: [Item]) -> [SpaceListDiffResult<Item>] {
        diffResult ?? []
    }
}

class MockSpaceSubSectionStateProvider: SpaceSubSectionStateProvider {
    var canReloadState: Bool = true
    var didShowListAfterLoadingHandler: (() -> Void)?
    func didShowListAfterLoading() { didShowListAfterLoadingHandler?() }
    var handleNewStateHandler: ((SpaceListSubSection.ListState, SpaceSubSectionStateHelper) -> Void)?
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        handleNewStateHandler?(newState, helper)
    }
}

class SpaceSubSectionStateHelperTests: XCTestCase {
    private var bag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = DisposeBag()
    }

    func testChangeSpecialState() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 3
        let provider = MockSpaceSubSectionStateProvider()
        provider.didShowListAfterLoadingHandler = {
            XCTFail("this func should not be called")
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case .loading = newState else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        let stateDiffer = SpaceListStateDiffer(initialState: .networkUnavailable, differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { action in
            switch action {
            case let .reloadSection(animated):
                XCTAssertFalse(animated)
            default:
                XCTFail("un-expect reload action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            switch action {
            case let .stopPullToLoadMore(hasMore):
                XCTAssertFalse(hasMore)
            default:
                XCTFail("un-expect action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.handle(newState: .loading)

        waitForExpectations(timeout: 1)
    }

    func testDisplayListAfterLoading() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 4
        let provider = MockSpaceSubSectionStateProvider()
        provider.didShowListAfterLoadingHandler = {
            expect.fulfill()
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case let .normal(items) = newState, items.isEmpty else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        let stateDiffer = SpaceListStateDiffer(initialState: .loading, differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { action in
            switch action {
            case let .reloadSection(animated):
                XCTAssertFalse(animated)
            default:
                XCTFail("un-expect reload action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            switch action {
            case let .stopPullToLoadMore(hasMore):
                XCTAssertTrue(hasMore)
            default:
                XCTFail("un-expect action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.handle(newState: .normal(itemTypes: []))

        waitForExpectations(timeout: 1)
    }

    func testDisplayListAfterSpecialState() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 3
        let provider = MockSpaceSubSectionStateProvider()
        provider.didShowListAfterLoadingHandler = {
            XCTFail("this func should not be called")
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case let .normal(items) = newState, items.isEmpty else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        let stateDiffer = SpaceListStateDiffer(initialState: .networkUnavailable, differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { action in
            switch action {
            case let .reloadSection(animated):
                XCTAssertFalse(animated)
            default:
                XCTFail("un-expect reload action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            switch action {
            case let .stopPullToLoadMore(hasMore):
                XCTAssertTrue(hasMore)
            default:
                XCTFail("un-expect action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.handle(newState: .normal(itemTypes: []))

        waitForExpectations(timeout: 1)
    }

    func testUpdateNone() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 1
        let provider = MockSpaceSubSectionStateProvider()
        provider.didShowListAfterLoadingHandler = {
            XCTFail("this func should not be called")
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case let .normal(items) = newState, items.count == 1 else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        itemDiffer.diffResult = [.none(list: [SpaceListItemType.gridPlaceHolder])]
        let stateDiffer = SpaceListStateDiffer(initialState: .normal(itemTypes: []), differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { _ in
            XCTFail("un-expect reload action")
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            XCTFail("un-expect action")
        }).disposed(by: bag)

        helper.handle(newState: .normal(itemTypes: []))
        waitForExpectations(timeout: 1)
    }

    func testUpdateReload() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 2
        let provider = MockSpaceSubSectionStateProvider()
        provider.didShowListAfterLoadingHandler = {
            XCTFail("this func should not be called")
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case let .normal(items) = newState, items.count == 1 else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        itemDiffer.diffResult = [.reload(list: [SpaceListItemType.gridPlaceHolder])]
        let stateDiffer = SpaceListStateDiffer(initialState: .normal(itemTypes: []), differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { action in
            switch action {
            case let .reloadSection(animated):
                XCTAssertFalse(animated)
            default:
                XCTFail("un-expect reload action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            XCTFail("un-expect action")
        }).disposed(by: bag)

        helper.handle(newState: .normal(itemTypes: []))
        waitForExpectations(timeout: 1)
    }

    func testUpdateWithDiff() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 2
        let provider = MockSpaceSubSectionStateProvider()
        provider.didShowListAfterLoadingHandler = {
            XCTFail("this func should not be called")
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case let .normal(items) = newState, items.count == 1 else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        itemDiffer.diffResult = [
            .update(list: [.gridPlaceHolder],
                    inserts: [0],
                    deletes: [0],
                    updates: [0],
                    moves: [(0,1)]
                   )
        ]
        let stateDiffer = SpaceListStateDiffer(initialState: .normal(itemTypes: []), differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { action in
            switch action {
            case let .update(inserts, deletes, updates, moves, willUpdate):
                willUpdate()
                XCTAssertEqual(inserts, [0])
                XCTAssertEqual(deletes, [0])
                XCTAssertEqual(updates, [0])
                XCTAssertEqual(moves.count, 1)

                if let (from, to) = moves.first {
                    XCTAssertEqual(from, 0)
                    XCTAssertEqual(to, 1)
                }
            default:
                XCTFail("un-expect reload action")
            }
            expect.fulfill()
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            XCTFail("un-expect action")
        }).disposed(by: bag)

        helper.handle(newState: .normal(itemTypes: []))
        waitForExpectations(timeout: 1)
    }

    func testUpdateWhenCannotReload() {
        let expect = expectation(description: #function)
        expect.expectedFulfillmentCount = 1
        let provider = MockSpaceSubSectionStateProvider()
        provider.canReloadState = false
        provider.didShowListAfterLoadingHandler = {
            XCTFail("this func should not be called")
        }
        provider.handleNewStateHandler = { newState, _ in
            guard case let .normal(items) = newState, items.count == 1 else {
                XCTFail("un-expect new state")
                expect.fulfill()
                return
            }
            expect.fulfill()
        }
        let itemDiffer = MockSpaceListItemDiffer()
        itemDiffer.diffResult = [
            .update(list: [.gridPlaceHolder],
                    inserts: [0],
                    deletes: [0],
                    updates: [0],
                    moves: [(0,1)]
                   )
        ]
        let stateDiffer = SpaceListStateDiffer(initialState: .normal(itemTypes: []), differ: itemDiffer)
        let helper = SpaceSubSectionStateHelper(differ: stateDiffer,
                                                listID: "mock-list-id",
                                                stateProvider: provider)
        helper.reloadSignal.emit(onNext: { action in
            XCTFail("un-expect reload action")
        }).disposed(by: bag)

        helper.actionSignal.emit(onNext: { action in
            XCTFail("un-expect action")
        }).disposed(by: bag)

        helper.handle(newState: .normal(itemTypes: []))
        waitForExpectations(timeout: 1)
    }
}

