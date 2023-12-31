//
//  MentionStoreTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/21.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class MentionStoreTest: XCTestCase {

    let chatterId = UUID().uuidString
    let chatId = UUID().uuidString
    let tenantId = UUID().uuidString
    var store: MentionStore!
    var context: IMMentionContext!
    
    override func setUp() {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 100, isEnableAtAll: true)
        store = MentionStore(context: context)
    }
    
    /// 加载中, 展示骨架屏
    func testLoading() {
        store.dispatch(event: .loading(nil))
        XCTAssertEqual(store.currentState.isShowSkeleton, true)
        let sections = store.currentItems.sections
        let items = sections[0].items
        XCTAssertEqual(items.count, 20)
        XCTAssertTrue(store.currentState.isLoading)
    }
    
    /// 请求错误时展示错误
    func testRequestError() {
        let error = NSError(domain: "error", code: 400)
        let event = ProviderEvent.fail(.request(error))
        store.dispatch(event: .loading(nil))
        store.dispatch(event: event)
        XCTAssertNotNil(store.currentState.error)
        XCTAssertFalse(store.currentState.isShowSkeleton)
    }
    
    /// 推荐的请求内容为空时展示空结果错误
    func testEmptyRecommandResponse() {
        let res = ProviderResult(result: [[]], hasMore: false)
        let event = ProviderEvent.success(.init(query: "", res: res))
        store.dispatch(event: event)
        guard case .noResult = store.currentState.error else {
            XCTFail()
            return
        }
        XCTAssertFalse(store.currentState.isLoading)
    }
    
    /// 搜索的请求内容为空时展示空结果错误
    func testEmptySearchResponse() {
        let res = ProviderResult(result: [[]], hasMore: false)
        let event = ProviderEvent.success(.init(query: "123", res: res))
        store.dispatch(event: event)
        guard case .noResult = store.currentState.error else {
            XCTFail()
            return
        }
        XCTAssertFalse(store.currentState.isLoading)
    }
    
    /// 推荐数据有加载更多时
    func testRecommendResultHasMore() {
        let event = ProviderEvent.success(.init(query: nil, res: .init(result: [], hasMore: true)))
        store.dispatch(event: event)
        XCTAssertTrue(store.currentState.hasMore)
    }
    
    /// 搜索数据有加载更多时
    func testSearchResultHasMore() {
        let event = ProviderEvent.success(.init(query: "nil", res: .init(result: [], hasMore: true)))
        store.dispatch(event: event)
        XCTAssertTrue(store.currentState.hasMore)
    }
    
    /// 开始搜索时展示骨架屏
    func testShowSkeletonWhenStartSearch() {
        store.dispatch(event: .startSearch(""))
        XCTAssertFalse(store.currentState.isShowSkeleton)
    }
    
    /// 已选择的Item, 新数据覆盖时也需要选择
    func testSelectItemAfterNewItems() {
        let m1 = Mocker.mockItem(id: "1")
        let m2 = Mocker.mockItem(id: "2")
        store.selectedCache = ["1": 1]
        let res = ProviderResult(result: [[m1, m2]], hasMore: false)
        let event = ProviderEvent.success(.init(query: nil, res: res))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertTrue(sections[0].items[0].isMultipleSelected)
        XCTAssertFalse(sections[0].items[1].isMultipleSelected)
    }
}
// swiftlint:enable all
