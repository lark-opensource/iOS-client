//
//  DocumentStoreTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/20.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class DocumentStoreTest: XCTestCase {
    
    let chatterId = UUID().uuidString
    let chatId = UUID().uuidString
    let tenantId = UUID().uuidString
    var store: DocumentStore!
    var context: IMMentionContext!
    
    override func setUp() {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 100, isEnableAtAll: true)
        store = DocumentStore(context: context)
    }

    /// 加载推荐数据
    func testLoadRecommend() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 3)
    }
    
    /// 加载搜索数据
    func testLoadSearch() {
        let event = ProviderEvent.success(.init(query: "nil", res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 3)
    }
    
    /// 加载推荐数据, 有加载更多
    func testLoadRecommendHasMore() {
        let event = ProviderEvent.success(.init(query: nil, res: mockHasMoreResult()))
        store.dispatch(event: event)
        XCTAssertTrue(store.currentState.hasMore)
    }
    
    /// 加载搜索数据, 有加载更多
    func testLoadSearchHasMore() {
        let event = ProviderEvent.success(.init(query: "nil", res: mockHasMoreResult()))
        store.dispatch(event: event)
        XCTAssertTrue(store.currentState.hasMore)
    }
    
    /// 推荐数据埋点
    func testChatterRecommendTrackInfo() {
        let event = ProviderEvent.success(.init(query: nil, res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items[0].trackerInfo.pageType, .doc)
        XCTAssertEqual(items[0].trackerInfo.chooseType, .recommend)
    }
    
    /// 搜索数据埋点信息
    func testChatterSearchTrackInfo() {
        let event = ProviderEvent.success(.init(query: "nil", res: mockResult()))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items[0].trackerInfo.pageType, .doc)
        XCTAssertEqual(items[0].trackerInfo.chooseType, .search)
    }
    
    /// 开始搜索后, 展示骨架屏
    func testShowSkeletonWhenStartSearch() {
        store.dispatch(event: .startSearch(""))
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 20)
        XCTAssertTrue(store.currentState.isShowSkeleton)
    }
    
    private func mockResult() -> ProviderResult {
        let m1 = Mocker.mockItem(id: "1")
        let m2 = Mocker.mockItem(id: "2")
        let m3 = Mocker.mockItem(id: "3")
        let res = ProviderResult(result: [[m1, m2, m3]], hasMore: false)
        return res
    }
    
    private func mockHasMoreResult() -> ProviderResult {
        let m1 = Mocker.mockItem(id: "1")
        let m2 = Mocker.mockItem(id: "2")
        let m3 = Mocker.mockItem(id: "3")
        let res = ProviderResult(result: [[m1, m2, m3]], hasMore: true)
        return res
    }
}
// swiftlint:enable all
