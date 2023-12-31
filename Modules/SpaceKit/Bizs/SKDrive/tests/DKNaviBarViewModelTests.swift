//
//  DKNaviBarViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/12.
//

import XCTest
import SKFoundation
import RxSwift
import RxCocoa
@testable import SKDrive

class DKNaviBarViewModelTests: XCTestCase {
    var leftBarItemsRelay: BehaviorRelay<[DKNaviBarItem]>!
    var rightBarItemsRelay: BehaviorRelay<[DKNaviBarItem]>!

    var dependency: DKNaviBarViewModel.Dependency!
    var disposeBag = DisposeBag()
    override func setUp() {
        leftBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
        rightBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
        dependency = DKNaviBarDependencyImpl(titleRelay: BehaviorRelay<String>(value: "title"),
                                            fileDeleted: BehaviorRelay<Bool>(value: false),
                                            leftBarItems: leftBarItemsRelay.asObservable(),
                                            rightBarItems: rightBarItemsRelay.asObservable())
        super.setUp()
    }

    override func tearDown() {
        disposeBag = DisposeBag()
        super.tearDown()
    }

    func testTitleUpdated() {
        let sut = DKNaviBarViewModel(dependency: dependency)
        XCTAssertTrue(sut.title == "title")
        let expect = expectation(description: "wait for title update")
        expect.expectedFulfillmentCount = 2
        var titles = [String]()
        sut.titleUpdated
            .drive(onNext: { title in
                titles.append(title)
                expect.fulfill()
            }).disposed(by: disposeBag)
        dependency.titleRelay.accept("newtitle")
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(titles[0] == "title")
        XCTAssertTrue(titles[1] == "newtitle")
    }

    func testDeleted() {
        let sut = DKNaviBarViewModel(dependency: dependency)
        let expect = expectation(description: "wait for deleted")
        expect.expectedFulfillmentCount = 2
        var deletedActions = [Bool]()
        sut.fileDeleted
            .drive(onNext: { isDeleted in
                deletedActions.append(isDeleted)
                expect.fulfill()
            }).disposed(by: disposeBag)
        dependency.fileDeleted.accept(true)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(deletedActions[0] == false)
        XCTAssertTrue(deletedActions[1] == true)
    }
    
    func testRightBarItemsUpdated() {
        let sut = DKNaviBarViewModel(dependency: dependency)
        let expect = expectation(description: "wait for right bar items upated")
        XCTAssertTrue(sut.rightBarItems.count == 0)
        expect.expectedFulfillmentCount = 2
        var updatedItems = [DKNaviBarItem]()
        sut.rightBarItemsUpdated
            .drive(onNext: { items in
                updatedItems = items
                expect.fulfill()
            }).disposed(by: disposeBag)
        let feedItem = DKFeedItemViewModel(enable: Observable<Bool>.just(true),
                                        visable: Observable<Bool>.just(true),
                                        isReachable: Observable<Bool>.just(true))

        rightBarItemsRelay.accept([feedItem])
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(updatedItems.count == 1)
    }
    
    func testLeftBarItemsUpdated() {
        let sut = DKNaviBarViewModel(dependency: dependency)
        let expect = expectation(description: "wait for left bar items upated")
        XCTAssertTrue(sut.leftBarItems.count == 0)
        expect.expectedFulfillmentCount = 2
        var updatedItems = [DKNaviBarItem]()
        sut.leftBarItemsUpdated
            .drive(onNext: { items in
                updatedItems = items
                expect.fulfill()
            }).disposed(by: disposeBag)
        let feedItem = DKFeedItemViewModel(enable: Observable<Bool>.just(true),
                                        visable: Observable<Bool>.just(true),
                                        isReachable: Observable<Bool>.just(true))

        leftBarItemsRelay.accept([feedItem])
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(updatedItems.count == 1)
    }
    
    func testTitleVisableRelay() {
        let sut = DKNaviBarViewModel(dependency: dependency)
        let expect = expectation(description: "wait for title visable upated")
        expect.expectedFulfillmentCount = 2
        var results = [Bool]()
        sut.titleVisableRelay
            .subscribe(onNext: { visable in
                results.append(visable)
                expect.fulfill()
            }).disposed(by: disposeBag)
        sut.titleVisableRelay.accept(false)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(results[0] == true)
        XCTAssertTrue(results[1] == false)
    }
    
    func testEmptyBarViewModel() {
        let vm = DKNaviBarViewModel.emptyBarViewModel
        XCTAssertNotNil(vm)
    }

}
