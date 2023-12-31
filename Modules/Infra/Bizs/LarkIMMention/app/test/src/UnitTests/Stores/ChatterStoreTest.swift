//
//  ChatterStoreTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/20.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class ChatterStoreTest: XCTestCase {
    
    let chatterId = UUID().uuidString
    let chatId = UUID().uuidString
    let tenantId = UUID().uuidString
    var store: ChatterStore!
    var context: IMMentionContext!
    
    override func setUp() {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 100, isEnableAtAll: true)
        store = ChatterStore(context: context)
    }
    
    /// 处理推荐数据, 无群外人员, 对人员进行首字母分组
    func testLoadRecommend() {
        let event = mockRecommendEvent()
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertEqual(sections.count, 6)
        // all
        XCTAssertEqual(sections[0].title, nil)
        XCTAssertEqual(sections[0].items.count, 1)
        XCTAssertEqual(sections[0].items[0].id, IMPickerOption.allId)
        // wanted
        XCTAssertEqual(sections[1].title, "You might want to mention...")
        XCTAssertEqual(sections[1].items.count, 1)
        // in chat
        XCTAssertEqual(sections[2].title, "All members")
        XCTAssertEqual(sections[2].items.count, 0)
        // A
        XCTAssertEqual(sections[3].title, "A")
        XCTAssertEqual(sections[3].items.count, 1)
        XCTAssertEqual(sections[3].items[0].actualName, "艾")
        // B
        XCTAssertEqual(sections[4].title, "B")
        XCTAssertEqual(sections[4].items.count, 2)
        XCTAssertEqual(sections[4].items[0].actualName, "包")
        XCTAssertEqual(sections[4].items[1].actualName, "包包")
        // C
        XCTAssertEqual(sections[5].title, "C")
        XCTAssertEqual(sections[5].items.count, 1)
        XCTAssertEqual(sections[5].items[0].actualName, "草")
    }
    
    /// 处理推荐数据, 推荐数据中不包含想要@的人部分, 直接去掉该section
    func testLoadRecommendWithoutWanted() {
        var m1 = Mocker.mockItem(id: "2")
        m1.actualName = "艾"
        var m2 = Mocker.mockItem(id: "3")
        m2.actualName = "草"
        var m3 = Mocker.mockItem(id: "4")
        m3.actualName = "包"
        let res = ProviderResult(result: [[], [m1, m2, m3], []], hasMore: false)
        let event = ProviderEvent.success(.init(query: nil, res: res))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertEqual(sections.count, 5)
        // all
        XCTAssertEqual(sections[0].title, nil)
        XCTAssertEqual(sections[0].items.count, 1)
        XCTAssertEqual(sections[0].items[0].id, IMPickerOption.allId)
        // all members
        XCTAssertEqual(sections[1].title, "All members")
        XCTAssertEqual(sections[1].items.count, 0)
        // A
        XCTAssertEqual(sections[2].title, "A")
        XCTAssertEqual(sections[2].items.count, 1)
        XCTAssertEqual(sections[2].items[0].actualName, "艾")
    }
    
    /// 处理搜索数据, 不包含想要@的人
    func testLoadSearch() {
        let event = mockSearchEvent()
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].title, "In chat")
        XCTAssertEqual(sections[1].title, "Not in chat (They won\'t receive this message)")
        XCTAssertEqual(sections[0].items.count, 2)
        XCTAssertEqual(sections[1].items.count, 1)
    }
    
    /// 推荐数据包含埋点信息
    func testChatterRecommendTrackInfo() {
        let event = mockRecommendEvent()
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertEqual(sections[1].items[0].trackerInfo.pageType, .user)
        XCTAssertEqual(sections[1].items[0].trackerInfo.chooseType, .recommend)
        XCTAssertEqual(sections[4].items[0].trackerInfo.pageType, .user)
        XCTAssertEqual(sections[4].items[0].trackerInfo.chooseType, .recommend)
    }
    
    /// 搜索数据包含埋点信息
    func testChatterSearchTrackInfo() {
        let event = mockSearchEvent()
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertNil(store.currentState.error)
        XCTAssertEqual(sections[0].items[0].trackerInfo.pageType, .user)
        XCTAssertEqual(sections[0].items[0].trackerInfo.chooseType, .search)
    }
    
    func testRecommendInitialSection() {
        let event = mockRecommendEvent()
        store.dispatch(event: event)
        XCTAssertFalse(store.currentItems.sections[0].isInitialSection)
        XCTAssertFalse(store.currentItems.sections[1].isInitialSection)
        XCTAssertFalse(store.currentItems.sections[2].isInitialSection)
        XCTAssertTrue(store.currentItems.sections[3].isInitialSection)
        XCTAssertTrue(store.currentItems.sections[4].isInitialSection)
        XCTAssertTrue(store.currentItems.sections[5].isInitialSection)
    }
    
    /// 推荐数据生成的首字母索引表
    func testRecommendNameIndexWithAtAll() {
        let event = mockRecommendEvent()
        store.dispatch(event: event)
        XCTAssertEqual(store.currentState.nameIndex, ["@", "A", "B", "C"])
        XCTAssertEqual(store.currentState.nameDict[0], 1)
        XCTAssertEqual(store.currentState.nameDict[1], 3)
        XCTAssertEqual(store.currentState.nameDict[2], 4)
        XCTAssertEqual(store.currentState.nameDict[3], 5)
    }
    
    /// 处理推荐数据, 推荐数据中不包含想要@的人部分, 首字母索引不包含@
    func testRecommendNameIndexWithoutWantedChatters() {
        let m1 = Mocker.mockItem(id: "2", name: "艾")
        let m2 = Mocker.mockItem(id: "3", name: "草")
        let m3 = Mocker.mockItem(id: "4", name: "包")
        let res = ProviderResult(result: [[], [m1, m2, m3], []], hasMore: false)
        let event = ProviderEvent.success(.init(query: nil, res: res))
        store.dispatch(event: event)
        XCTAssertEqual(store.currentState.nameIndex, ["A", "B", "C"])
        XCTAssertEqual(store.currentState.nameDict[0], 2)
        XCTAssertEqual(store.currentState.nameDict[1], 3)
        XCTAssertEqual(store.currentState.nameDict[2], 4)
    }
    
    /// 处理推荐数据, 推荐数据中不包含想要@的人部分, 且不包含@所有人时, 首字母索引不包含@
    func testRecommendNameIndexWithoutAtAll() {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 100, isEnableAtAll: false)
        store = ChatterStore(context: context)
        let m1 = Mocker.mockItem(id: "2", name: "艾")
        let m2 = Mocker.mockItem(id: "3", name: "草")
        let m3 = Mocker.mockItem(id: "4", name: "包")
        let res = ProviderResult(result: [[], [m1, m2, m3], []], hasMore: false)
        let event = ProviderEvent.success(.init(query: nil, res: res))
        store.dispatch(event: event)
        XCTAssertEqual(store.currentState.nameIndex, ["A", "B", "C"])
        XCTAssertEqual(store.currentState.nameDict[0], 1)
    }
    
    /// 切换至多选模式
    func testSwitchOnMulitSelect() {
        let event = mockRecommendEvent()
        store.dispatch(event: event)
        store.switchMultiSelect(isOn: true)
        XCTAssertTrue(store.currentState.isMultiSelected)
    }
    
    /// 多选模式下, 选择一个item
    func testSelectItem() {
        let event = mockSearchEvent()
        store.dispatch(event: event)
        store.switchMultiSelect(isOn: true)
        let m2 = Mocker.mockItem(id: "2")
        store.toggleItemSelected(item: m2)
        let sections = store.currentItems.sections
        XCTAssertTrue(sections[0].items[1].isMultipleSelected)
    }
    
    /// 多选模式下, 取消选择一个item
    func testDeselectItem() {
        let event = mockSearchEvent()
        store.dispatch(event: event)
        store.switchMultiSelect(isOn: true)
        let m2 = Mocker.mockItem(id: "2")
        store.toggleItemSelected(item: m2)
        store.toggleItemSelected(item: m2)
        let sections = store.currentItems.sections
        XCTAssertFalse(sections[0].items[1].isMultipleSelected)
    }
    
    /// 搜索数据中想要@人为空时, 保留该section, 但是显示无内容footer
    func testShowNoResultFooterInChatWhenSearch() {
        let res = ProviderResult(result: [[], [], []], hasMore: false)
        let event = ProviderEvent.success(.init(query: "nil", res: res))
        store.dispatch(event: event)
        let sections = store.currentItems.sections
        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(sections[0].isShowFooter)
    }
    
    // MARK: - Private
    private func mockRecommendEvent() -> ProviderEvent {
        let m0 = Mocker.mockItem(id: "1")
        var m1 = Mocker.mockItem(id: "2")
        m1.actualName = "艾"
        var m2 = Mocker.mockItem(id: "3")
        m2.actualName = "草"
        var m3 = Mocker.mockItem(id: "4")
        m3.actualName = "包"
        var m4 = Mocker.mockItem(id: "5")
        m4.actualName = "包包"
        let res = ProviderResult(result: [[m0], [m1, m2, m3, m4], []], hasMore: false)
        let event = ProviderEvent.success(.init(query: nil, res: res))
        return event
    }
    
    private func mockSearchEvent() -> ProviderEvent {
        let m1 = Mocker.mockItem(id: "1")
        let m2 = Mocker.mockItem(id: "2")
        let m3 = Mocker.mockItem(id: "3")
        let res = ProviderResult(result: [[], [m1, m2], [m3]], hasMore: false)
        let event = ProviderEvent.success(.init(query: "nil", res: res))
        return event
    }
}
// swiftlint:enable all
