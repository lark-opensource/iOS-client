//
//  ChatterProviderProcessorSearchTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/12.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class ChatterProviderProcessorSearchTest: XCTestCase {
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
    
    /// 处理本地的搜索数据
    func testSearchLocalResult() {
        let result = processor.processSearchResult(localRes, isRemote: false)
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.result.count, 3)
        // wanted chatters
        XCTAssertEqual(result.result[0].count, 0)
        // in chatters
        let inChatters = result.result[1]
        XCTAssertEqual(inChatters.count, 2)
        XCTAssertEqual(inChatters[0].id, "3")
        XCTAssertEqual(inChatters[1].id, "5")
        // out chatters
        let outChatters = result.result[2]
        XCTAssertEqual(outChatters.count, 3)
        XCTAssertEqual(outChatters[0].id, "2")
        XCTAssertEqual(outChatters[1].id, "4")
        XCTAssertEqual(outChatters[2].id, "6")
    }
    
    /// 处理本地搜索数据, 其中没有外部用户
    func testSearchLocalResultWithoutOutChatters() {
        localRes.outChatChatterIds = []
        let result = processor.processSearchResult(localRes, isRemote: false)
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.result.count, 3)
        XCTAssertEqual(result.result[2].count, 0)
    }
    
    /// 处理搜索远程数据, 对群内群外人员进行合并
    func testProcessSearchRemoteResult() {
        let remoteRes = Mocker.mockRemoteChatterResponse(chatId: chatId)
        _ = processor.processSearchResult(localRes, isRemote: false)
        let result = processor.processSearchResult(remoteRes, isRemote: true)
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.result.count, 3)
        // wanted chatters
        XCTAssertEqual(result.result[0].count, 0)
        // in chatters
        let inChatters = result.result[1]
        XCTAssertEqual(inChatters.count, 2)
        XCTAssertEqual(inChatters[0].id, "5")
        XCTAssertEqual(inChatters[1].id, "7")
        // out chatters
        let outChatters = result.result[2]
        XCTAssertEqual(outChatters.count, 3)
        XCTAssertEqual(outChatters[0].id, "2")
        XCTAssertEqual(outChatters[1].id, "6")
        XCTAssertEqual(outChatters[2].id, "8")
    }
}
// swiftlint:enable all
