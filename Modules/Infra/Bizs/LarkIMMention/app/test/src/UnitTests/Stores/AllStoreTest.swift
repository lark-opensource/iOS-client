//
//  AllStoreTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/21.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class AllStoreTest: XCTestCase {
    
    let chatterId = UUID().uuidString
    let chatId = UUID().uuidString
    let tenantId = UUID().uuidString
    var store: AllStore!
    var context: IMMentionContext!
    
    override func setUp() {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 100, isEnableAtAll: true)
        store = AllStore(context: context)
    }

    /// 处理推荐数据
    func testLoadRecommend() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertFalse(store.currentState.hasMore)
        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(items[0].id, IMPickerOption.allId)
    }
    
    /// 处理搜索数据
    func testLoadSearch() {
        let event = ProviderEvent.success(.init(query: "123", res: mockResult()))
        store.dispatch(event: event)
        XCTAssertFalse(store.currentState.hasMore)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 3)
    }
    
    /// 搜索结果为空但请求未完成时, 展示骨架屏
    func testShowSkeletonWithEmptyResult() {
        let event = ProviderEvent.success(.init(query: "123", res: .init(result: [], hasMore: false)))
        store.dispatch(event: event)
        XCTAssertNil(store.currentState.error)
        XCTAssertTrue(store.currentState.isShowSkeleton)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 20)
    }
    
    /// 搜索结果为空但请求完成时, 不展示骨架屏, 展示错误
    func testShowSkeletonWithEmptyResultCompleted() {
        let event = ProviderEvent.success(.init(query: "123", res: .init(result: [], hasMore: false)))
        store.dispatch(event: event)
        store.dispatch(event: .complete)
        XCTAssertNotNil(store.currentState.error)
        XCTAssertFalse(store.currentState.isShowSkeleton)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 0)
    }
    
    /// 显示骨架屏后再搜索出结果后, 隐藏骨架屏
    func testSearchResultAfterSkeleton() {
        let event = ProviderEvent.success(.init(query: "123", res: .init(result: [], hasMore: false)))
        store.dispatch(event: event)
        let event1 = ProviderEvent.success(.init(query: "123", res: mockResult()))
        store.dispatch(event: event1)
        store.dispatch(event: .complete)
        XCTAssertFalse(store.currentState.isShowSkeleton)
    }
    
    /// 显示无结果错误后再搜索出结果, 不再展示错误
    func testSearchResultAfterEmptyResult() {
        let event = ProviderEvent.success(.init(query: "123", res: .init(result: [], hasMore: false)))
        store.dispatch(event: event)
        store.dispatch(event: .complete)
        XCTAssertNotNil(store.currentState.error)
        let event1 = ProviderEvent.success(.init(query: "123", res: mockResult()))
        store.dispatch(event: .startSearch("123"))
        store.dispatch(event: event1)
        store.dispatch(event: .complete)
        XCTAssertFalse(store.currentState.isShowSkeleton)
        XCTAssertNil(store.currentState.error)
    }
    
    /// 推荐数据包含埋点信息
    func testChatterRecommendTrackInfo() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items[0].trackerInfo.pageType, .all)
        XCTAssertEqual(items[0].trackerInfo.chooseType, .recommend)
    }
    
    /// 搜索数据包含埋点信息
    func testChatterSearchTrackInfo() {
        let event = ProviderEvent.success(.init(query: "123", res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items[0].trackerInfo.pageType, .all)
        XCTAssertEqual(items[0].trackerInfo.chooseType, .search)
    }
    
    // MARK: - Select
    /// 切换到多选模式
    func testSwitchOnMulitSelect() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        store.switchMultiSelect(isOn: true)
        XCTAssertTrue(store.currentState.isMultiSelected)
    }
    
    /// 切换到多选模式后, 选中一个item
    func testSelectItem() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        store.switchMultiSelect(isOn: true)
        let m2 = Mocker.mockItem(id: "2")
        store.toggleItemSelected(item: m2)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertTrue(items[2].isMultipleSelected)
    }
    
    /// 切换到多选模式后, 选中一个item, 再取消选择该item
    func testDeselectItemByPlainItems() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        store.switchMultiSelect(isOn: true)
        let m2 = Mocker.mockItem(id: "2")
        store.toggleItemSelected(item: m2)
        store.toggleItemSelected(item: m2)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertFalse(items[2].isMultipleSelected)
    }
    
    // MARK: - Private
    private func mockResult() -> ProviderResult {
        let m1 = Mocker.mockItem(id: "1")
        let m2 = Mocker.mockItem(id: "2")
        let m3 = Mocker.mockItem(id: "3")
        let res = ProviderResult(result: [[m1, m2, m3], [m1]], hasMore: true)
        return res
    }

}
// swiftlint:enable all
