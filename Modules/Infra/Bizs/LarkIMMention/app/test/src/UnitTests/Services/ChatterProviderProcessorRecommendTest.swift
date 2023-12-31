//
//  ChatterProviderProcessorRecommendTest.swift
//  unit-tests
//
//  Created by Yuri on 2022/12/9.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class ChatterProviderProcessorRecommendTest: XCTestCase {
    
    var processor: ChatterProviderProcessor!
    var localRes: ChatterResponse!
    var context: IMMentionContext!
    let chatterId = UUID().uuidString
    let chatId = UUID().uuidString
    let tenantId = UUID().uuidString
    
    override func setUp() {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 6, isEnableAtAll: true)
        processor = ChatterProviderProcessor(context: context)
        localRes = Mocker.mockLocalChatterResponse(chatId: chatId)
    }
    
    private func remakeProcessor(isEnableAtAll: Bool = true) {
        context = IMMentionContext(currentChatterId: chatterId, currentTenantId: tenantId, currentChatId: chatId, chatUserCount: 6, isEnableAtAll: isEnableAtAll)
        processor = ChatterProviderProcessor(context: context)
    }
    
    /// 处理推荐本地数据, 不包含群外人员
    func testProcessRecommendLocalResult() {
        let result = processor.processRecommendResult(localRes, isRemote: false)
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.result.count, 3)
        // wanted chat
        let wantedChatters = result.result[0]
        XCTAssertEqual(wantedChatters.count, 1)
        XCTAssertEqual(wantedChatters.first?.id, "1")
        // in chat
        let inChatters = result.result[1]
        XCTAssertEqual(inChatters.count, 2)
        XCTAssertEqual(inChatters[0].id, "3")
        XCTAssertEqual(inChatters[1].id, "5")
        // out chat
        XCTAssertEqual(result.result[2].count, 0)
    }
    
    /// 处理推荐远程数据, 不包含群外人员, 和本地数据进行合并
    func testProcessRecommendRemoteResult() {
        let remoteRes = Mocker.mockRemoteChatterResponse(chatId: chatId)
        _ = processor.processRecommendResult(localRes, isRemote: false)
        let result = processor.processRecommendResult(remoteRes, isRemote: true)
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.result.count, 3)
        // wanted chat
        let wantedChatters = result.result[0]
        XCTAssertEqual(wantedChatters.count, 1)
        XCTAssertEqual(wantedChatters[0].id, "1")
        // in chat
        let inChatters = result.result[1]
        XCTAssertEqual(inChatters.count, 2)
        XCTAssertEqual(inChatters[0].id, "5")
        XCTAssertEqual(inChatters[1].id, "7")
        // out chat
        XCTAssertEqual(result.result[2].count, 0)
    }
    
    /// 新旧数据合并
    func testUpdateLocalItemsWithRemoteItems() {
        // 1,2,3 + 3,1,4,5 = 1,3,4,5
        let oldItems = [
            Mocker.mockItem(id: "1"),
            Mocker.mockItem(id: "2"),
            Mocker.mockItem(id: "3"),
        ]
        let newItems = [
            Mocker.mockItem(id: "3"),
            Mocker.mockItem(id: "1"),
            Mocker.mockItem(id: "4"),
            Mocker.mockItem(id: "5"),
        ]
        let items = processor.updateItems(oldItems: oldItems, newItems: newItems)
        XCTAssertEqual(items[0].id, "1")
        XCTAssertEqual(items[1].id, "3")
        XCTAssertEqual(items[2].id, "4")
        XCTAssertEqual(items[3].id, "5")
    }
}
// swiftlint:enable all
