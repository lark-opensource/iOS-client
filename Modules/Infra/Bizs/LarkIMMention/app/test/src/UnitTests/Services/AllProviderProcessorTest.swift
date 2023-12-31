//
//  AllProviderProcessorTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/14.
//

import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class AllProviderProcessorTest: XCTestCase {
    
    /// 合并多个信号的值
    func testReduce() {
        let item3 = Mocker.mockItem(id: "3")
        let result2 = ProviderResult(result: [[item3]], hasMore: false)
        
        let event1 = mockSuccessEvent()
        let event2 = ProviderEvent.success(.init(query: nil, res: result2))
        let event = AllProviderProcessor.reduce(query: nil, events: [event1, event2])
        if case .success(let response) = event {
            XCTAssertEqual(response.res.result.count, 1)
            XCTAssertEqual(response.res.result[0].count, 3)
        } else {
            XCTFail()
        }
    }
    
    /// 合并多个信号时, 如果有网络错误且包括结果时, 返回结果
    func testReduceResultWithNetworkError() {
        let event1 = mockSuccessEvent()
        let error = NSError(domain: "network error", code: 500)
        let event2 = ProviderEvent.fail(.request(error))
        
        let event = AllProviderProcessor.reduce(query: nil, events: [event1, event2])
        if case .success(let response) = event {
            XCTAssertEqual(response.res.result.count, 1)
            XCTAssertEqual(response.res.result[0].count, 2)
        } else {
            XCTFail()
        }
    }
    
    /// 合并多个信号时, 如果有网络错误且不包括结果时, 返回请求错误
    func testReduceEmptyResultWithNetworkError() {
        let result = ProviderResult(result: [[]], hasMore: false)
        let event1 = ProviderEvent.success(.init(query: nil, res: result))
        let error = NSError(domain: "network error", code: 500)
        let event2 = ProviderEvent.fail(.request(error))
        
        let event = AllProviderProcessor.reduce(query: nil, events: [event1, event2])
        if case .fail(let providerError) = event {
            if case .request(let error) = providerError {
                XCTAssertNotNil(error)
                return
            }
        }
        XCTFail()
    }
    
    /// 合并多个信号时, 如果每个信号的内容都为空, 返回无推荐内容的错误
    func testReduceAllEmptyResult() {
        let event1 = {
            let result = ProviderResult(result: [[]], hasMore: false)
            return ProviderEvent.success(.init(query: nil, res: result))
        }()
        let event2 = {
            let result = ProviderResult(result: [[]], hasMore: false)
            return ProviderEvent.success(.init(query: nil, res: result))
        }()
        
        let event = AllProviderProcessor.reduce(query: nil, events: [event1, event2])
        if case .fail(let providerError) = event {
            if case .noRecommendResult = providerError {
                return
            }
        }
        XCTFail()
    }
    
    private func mockSuccessEvent() -> ProviderEvent {
        let item1 = Mocker.mockItem(id: "1")
        let item2 = Mocker.mockItem(id: "2")
        let result1 = ProviderResult(result: [[item1], [item2]], hasMore: false)
        return ProviderEvent.success(.init(query: nil, res: result1))
    }
}
// swiftlint:enable all
