//
//  SpaceListContainerTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/6/15.
//

import Foundation
@testable import SKSpace
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import XCTest
import RxTest
import RxBlocking

extension SpaceEntry: Equatable {
    public static func == (lhs: SpaceEntry, rhs: SpaceEntry) -> Bool {
        lhs.equalTo(rhs)
    }
}

class SpaceListContainerTests: XCTestCase {

    typealias State = SpaceListContainer.State
    typealias PagingState = SpaceListContainer.PagingState

    enum ContainerOperation {
        case restore([SpaceEntry])
        case sync([SpaceEntry])
        case update([SpaceEntry])
    }

    var disposeBag = DisposeBag()
    var scheduler = TestScheduler(initialClock: 0)
    var container = SpaceListContainer(listIdentifier: "unit-test")

    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        container = SpaceListContainer(listIdentifier: "unit-test")
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testStateTransaction() {
        XCTAssertEqual(container.state, SpaceListContainer.State.restoring)

        // 1
        let resultState = scheduler.createObserver(State.self)

        // 2
        container.stateChanged
            .bind(to: resultState)
            .disposed(by: disposeBag)

        // 3
        scheduler.createColdObservable([
            .next(10, ContainerOperation.restore([])),
            .next(20, ContainerOperation.sync([])),
            .next(30, ContainerOperation.update([])),
            .next(40, ContainerOperation.update([])),
            .next(50, ContainerOperation.sync([])),
            .next(60, ContainerOperation.update([])),
            .next(70, ContainerOperation.restore([])),
            .next(80, ContainerOperation.update([])),
            .next(90, ContainerOperation.sync([])),
            .next(100, ContainerOperation.restore([]))
        ])
        .subscribe(onNext: { [self] operation in
            switch operation {
            case let .restore(entries):
                container.restore(localData: entries)
            case let .sync(entries):
                container.sync(serverData: entries)
            case let .update(entries):
                container.update(data: entries)
            }
        })
        .disposed(by: disposeBag)

        // 4
        scheduler.start()

        // 5
        XCTAssertEqual(resultState.events, [
            .next(10, .syncing),
            .next(20, .ready),
            .next(50, .ready),
            .next(70, .syncing),
            .next(90, .ready),
            .next(100, .syncing)
        ])
    }

    func testProperties() {
        let count = Int.random(in: 0...100)
        container.update(totalCount: count)
        XCTAssertEqual(container.totalCount, count)

        var pagingState = PagingState.noMore
        container.update(pagingState: pagingState)
        XCTAssertFalse(container.hasMore)
        XCTAssertEqual(container.pagingState, pagingState)

        pagingState = PagingState.hasMore(lastLabel: "mock-label")
        container.update(pagingState: pagingState)
        XCTAssertTrue(container.hasMore)
        XCTAssertEqual(container.pagingState, pagingState)
    }


    func testRestore() {
        let mockEntry = SpaceEntry(type: .doc, nodeToken: "mock-node-token", objToken: "mock-obj-token")
        container.restore(localData: [mockEntry])
        XCTAssertTrue(container.restored)
        XCTAssertFalse(container.synced)
        XCTAssertFalse(container.isEmpty)
        XCTAssertEqual([mockEntry], container.items)
    }

    func testSync() {
        let mockEntry = SpaceEntry(type: .doc, nodeToken: "mock-node-token", objToken: "mock-obj-token")
        container.sync(serverData: [mockEntry])
        XCTAssertFalse(container.restored)
        XCTAssertTrue(container.synced)
        XCTAssertFalse(container.isEmpty)
        XCTAssertEqual([mockEntry], container.items)
    }

    func testUpdate() {
        let mockEntry = SpaceEntry(type: .doc, nodeToken: "mock-node-token", objToken: "mock-obj-token")
        container.update(data: [mockEntry])
        XCTAssertFalse(container.restored)
        XCTAssertFalse(container.synced)
        XCTAssertFalse(container.isEmpty)
        XCTAssertEqual([mockEntry], container.items)
    }
}
