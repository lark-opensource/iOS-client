//
//  BTStatisticOpenFileHandleTests.swift
//  SKBitable-Unit-Tests
//
//  Created by 刘焱龙 on 2023/12/2.
//

import XCTest
@testable import SKBitable
@testable import SKFoundation
import SKCommon
import SKUIKit
@testable import SKBrowser
import LarkContainer
import LarkWebViewContainer

final class BTOpenFileConsumerMock: BTStatisticConsumer, BTStatisticNormalConsumer {
    var points = [BTStatisticNormalPoint]()

    func consume(
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        points = allPoint
        return []
    }

    func consumeTempPoint(
        trace: BTStatisticBaseTrace,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        return []
    }
}

class BTStatisticOpenFileHandleTests: XCTestCase {
    var traceId: String?
    var isBitable = false

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // func testOpenFileHandleReportSuccessWhenIsBitable() {
    //     isBitable = true
    //     traceId = BTStatisticManager.shared!.createNormalTrace(parentTrace: nil)

    //     let openFileConsumerMain = BTOpenFileConsumer(type: .main)
    //     let openFileConsumerInRecord = BTOpenFileConsumer(type: .share_record)
    //     let openFileConsumerBaseAdd = BTOpenFileConsumer(type: .base_add)
    //     let consumer = BTOpenFileConsumerMock()
    //     BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: consumer)
    //     BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: openFileConsumerMain)
    //     BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: openFileConsumerInRecord)
    //     BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: openFileConsumerBaseAdd)

    //     let helper = BTBaseReportServiceHelper()
    //     helper.setupRouter(delegate: self)
    //     helper.handle(params: mockReportItems(), serviceName: DocsJSService.baseReport.rawValue)

    //     let expect = expectation(description: "testOpenFileHandleReportSuccessWhenIsBitable")
    //     BTStatisticManager.serialQueue.async {
    //         XCTAssertTrue(consumer.points.count > 0)
    //         expect.fulfill()
    //     }
    //     waitForExpectations(timeout: 0.1)
    // }

    func testOpenFileHandleReportSuccessWhenNotBitable() {
        isBitable = false
        traceId = BTStatisticManager.shared!.createNormalTrace(parentTrace: nil)

        let openFileConsumer = BTOpenFileConsumer(type: .main)
        let consumer = BTOpenFileConsumerMock()
        BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: consumer)
        BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: openFileConsumer)

        let helper = BTBaseReportServiceHelper()
        helper.setupRouter(delegate: self)
        helper.handle(params: mockReportItems(), serviceName: DocsJSService.baseReport.rawValue)

        let expect = expectation(description: "testOpenFileHandleReportSuccessWhenNotBitable")
        BTStatisticManager.serialQueue.async {
            XCTAssertTrue(consumer.points.count > 0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testOpenFileHandleReportSuccessWhenSwitchView() {
        isBitable = false
        traceId = BTStatisticManager.shared!.createNormalTrace(parentTrace: nil)

        let consumer = BTOpenFileConsumerMock()
        BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: consumer)

        let helper = BTBaseReportServiceHelper()
        helper.setupRouter(delegate: self)
        helper.handle(params: mockFailReportItems(), serviceName: DocsJSService.baseReport.rawValue)

        let expect = expectation(description: "testOpenFileHandleReportSuccessWhenSwitchView")
        BTStatisticManager.serialQueue.async {
            XCTAssertTrue(consumer.points.count > 0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testOpenFileHandleReportSuccessWhenOpenFileFail() {
        isBitable = false
        traceId = BTStatisticManager.shared!.createNormalTrace(parentTrace: nil)

        let consumer = BTOpenFileConsumerMock()
        BTStatisticManager.shared!.addNormalConsumer(traceId: traceId!, consumer: consumer)

        let helper = BTBaseReportServiceHelper()
        helper.setupRouter(delegate: self)
        helper.handle(params: mockSwitchViewReportItems(), serviceName: DocsJSService.baseReport.rawValue)

        let expect = expectation(description: "testOpenFileHandleReportSuccessWhenOpenFileFail")
        BTStatisticManager.serialQueue.async {
            XCTAssertTrue(consumer.points.count > 0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }

    private func mockReportItems() -> [String: Any] {
        let itemsString = """
{
  "list": [{
    "event": "BITABLE_SDK_FIRST_SCREEN_SUCCESS",
    "extra": {
        "viewType": "grid",
        "blockType": "BITABLE_TABLE"
    }
}, {
    "event": "BITABLE_SDK_BITABLE_IS_READY",
    "extra": {
        "viewType": "grid",
        "blockType": "BITABLE_TABLE"
    }
}, {
    "event": "docs_render_end",
    "extra": {
        "docs_result_key": "other",
        "docs_result_code": 0
    }
}, {
    "event": "docs_edit_doc"
}, {
    "event": "mobile_dashboard-ttu"
}, {
    "event": "bitable_view_or_block_switch"
}, {
    "event": "BITABLE_SDK_LOAD_COST",
    "extra": {
        "SDK_COST": {}
    }
}, {
    "event": "BITABLE_SDK_LOAD_COST",
    "extra": {
        "SDK_COST": {}
    },
    "router": ["invalidRouter"]
}
]
}
"""
        return itemsString.toDictionary()!
    }

    private func mockSwitchViewReportItems() -> [String: Any] {
        let itemsString = """
{
  "list": [{
    "event": "BITABLE_SDK_FIRST_SCREEN_SUCCESS",
    "extra": {
        "viewType": "grid",
        "blockType": "BITABLE_TABLE"
    }
}, {
    "event": "BITABLE_SDK_BITABLE_IS_READY",
    "extra": {
        "viewType": "grid",
        "blockType": "BITABLE_TABLE"
    }
}, {
    "event": "docs_render_end",
    "extra": {
        "docs_result_key": "other",
        "docs_result_code": 0
    }
}, {
    "event": "docs_edit_doc"
}, {
    "event": "mobile_dashboard-ttu"
}, {
    "event": "bitable_view_or_block_switch"
}, {
    "event": "BITABLE_SDK_LOAD_COST",
    "extra": {
        "SDK_COST": {}
    }
}, {
    "event": "POINT_VIEW_OR_BLOCK_SWITCH",
    "extra": {
        "source": "show_card"
    }
}
]
}
"""
        return itemsString.toDictionary()!
    }

    private func mockFailReportItems() -> [String: Any] {
        let itemsString = """
{
  "list": [{
    "event": "BITABLE_SDK_FIRST_SCREEN_SUCCESS",
    "extra": {
        "viewType": "grid",
        "blockType": "BITABLE_TABLE"
    }
}, {
    "event": "BITABLE_SDK_BITABLE_IS_READY",
    "extra": {
        "viewType": "grid",
        "blockType": "BITABLE_TABLE"
    }
}, {
    "event": "docs_render_end",
    "extra": {
        "docs_result_key": "fail",
        "docs_result_code": 100
    }
}, {
    "event": "docs_edit_doc"
}, {
    "event": "mobile_dashboard-ttu"
}, {
    "event": "bitable_view_or_block_switch"
}
]
}
"""
        return itemsString.toDictionary()!
    }
}

extension BTStatisticOpenFileHandleTests: BTStatisticReportHandleDelegate {
    var token: String? {
        return "123"
    }
    
    var baseToken: String? {
        return "123"
    }
    
    var objTokenInLog: String? {
        return "123"
    }
    
    func addObserver(_ o: SKCommon.BrowserViewLifeCycleEvent) {}
}
