//
//  OfflineViewModelTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/7/12.
//

@testable import SKSpace
import Foundation
import XCTest
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import LarkContainer



class OfflineViewModelTests: XCTestCase {
    private var disposeBag = DisposeBag()
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
        SKDataManager.shared.clear { _ in }
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }
    
    private func createMockOffLineViewModel() -> OfflineViewModel {
        let dataModel = ManuOffLineDataModel(userResolver: userResolver)
        let viewModel = OfflineViewModel(dataModel: dataModel)
        return viewModel
    }
    
    func testGenerateSlideConfig() {
        let sharedActions: [SlideAction] = [.remove, .share, .more]
        let sharedEntry = SpaceEntry(type: .docX, nodeToken: "nodeToken_1", objToken: "objToken_1")
        sharedEntry.updateShareURL("https://bytedance.feishu.cn/docx/N5S5dyok7oyW8ox9D2fcE4cwnCJ")
        let viewModel = createMockOffLineViewModel()
        let sharedConfig = viewModel.generateSlideConfig(for: sharedEntry)
        let handler = sharedConfig?.handler
        let cell = UIView()
        let expect = expectation(description: "offline slide more item")
        expect.expectedFulfillmentCount = 3
        viewModel.actionSignal.emit { action in
            switch action {
            case .openShare, .present, .confirmRemoveManualOffline:
                expect.fulfill()
            default:
                XCTFail("func failed")
            }
        }.disposed(by: disposeBag)
        handler?(cell, .share)
        handler?(cell, .more)
        handler?(cell, .delete)
        
        XCTAssertEqual(sharedConfig?.actions, sharedActions)
        waitForExpectations(timeout: 1)
    }
    
    func testDidBecomeActive() {
        let vm = createMockOffLineViewModel()
        let expect = expectation(description: "offline viewmodel active failed")
        vm.actionSignal.emit { action in
            if case let .stopPullToLoadMore(hasMore) = action {
                XCTAssertFalse(hasMore)
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: disposeBag)
        vm.didBecomeActive()
        XCTAssertTrue(vm.isActive)
        waitForExpectations(timeout: 1)
    }
    
    func testWillResignActive() {
        let vm = createMockOffLineViewModel()
        vm.willResignActive()
        XCTAssertFalse(vm.isActive)
    }
    
    func testNotifyPullToRefresh() {
        let vm = createMockOffLineViewModel()
        let expect = expectation(description: "offline viewmodel active failed")
        vm.actionSignal.emit { action in
            if case .stopPullToRefresh = action {
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: disposeBag)
        vm.notifyPullToRefresh()
        waitForExpectations(timeout: 1)
    }
    
    func testNotifyPullToLoadMore() {
        let vm = createMockOffLineViewModel()
        let expect = expectation(description: "offline viewmodel active failed")
        vm.actionSignal.emit { action in
            if case .stopPullToLoadMore = action {
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: disposeBag)
        vm.notifyPullToLoadMore()
        waitForExpectations(timeout: 1)
    }
    
    func testHandleMoreAction() {
        let vm_1 = createMockOffLineViewModel()
        let vm_2 = createMockOffLineViewModel()
        let entry_1 = SpaceEntry(type: .docX, nodeToken: "docx123", objToken: "docx123")
        let entry_2 = SpaceEntry(type: .docX, nodeToken: "dox456", objToken: "docx456")
        entry_2.update(secretKeyDelete: true)
        let handle_1 = vm_1.handleMoreAction(for: entry_1)
        let handle_2 = vm_2.handleMoreAction(for: entry_2)
        let view = UIView()
        
        let expect = expectation(description: "offline viewmodel active failed")
        expect.expectedFulfillmentCount = 2
        vm_1.actionSignal.emit { action in
            if case .present = action {
                expect.fulfill()
            } else {
                XCTFail("func failed")
            }
        }.disposed(by: disposeBag)
        vm_2.actionSignal.emit { action in
            switch action {
            case let .showHUD(result):
                if case .failure = result {
                    expect.fulfill()
                }
            default:
                XCTFail("func failed")
            }
        }.disposed(by: disposeBag)
        handle_1?(view)
        handle_2?(view)
        waitForExpectations(timeout: 1)
    }
    
    func testHanldePermissionTips() {
        let vm = createMockOffLineViewModel()
        let entry = SpaceEntry(type: .docX, nodeToken: "123", objToken: "123")
        let handle = vm.handlePermissionTips(for: entry)
        XCTAssertNil(handle)
    }
}
