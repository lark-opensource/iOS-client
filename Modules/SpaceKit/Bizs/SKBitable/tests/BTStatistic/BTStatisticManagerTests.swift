//
//  BTStatisticManagerTests.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/12/1.
//

import XCTest
@testable import SKBitable
@testable import SKFoundation
import SKCommon

class BTStatisticManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.statistic_trace", value: true)
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.mobile.statistic_trace")
    }

    func testGetStatisticManagerNotNil() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.statistic_trace", value: true)
        XCTAssertNotNil(BTStatisticManager.shared)
    }

    func testCreateNormalTraceSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        let trace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId!, point: BTStatisticNormalPoint(name: "test", extra: ["test": "123"]))
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId!, consumer: BTOpenFileConsumer(type: .main))
        XCTAssertTrue(BTStatisticManager.shared?.isTraceEnd(traceId: traceId!) == false)
        XCTAssertNotNil(trace)
    }

    func testStopTraceSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        BTStatisticManager.shared?.stopTrace(traceId: traceId!)
        let expect = expectation(description: "testStopTraceSuccess")
        BTStatisticManager.serialQueue.async {
            let nilTrace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
            XCTAssertNil(nilTrace)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testStopAllTraceSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        BTStatisticManager.shared?.stopAllTrace()
        let expect = expectation(description: "testStopAllTraceSuccess")
        BTStatisticManager.serialQueue.async {
            let nilTrace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
            XCTAssertNil(nilTrace)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testCreateFPSTraceSuccess() {
        let fpsTrace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        let trace = BTStatisticManager.shared?.getTrace(traceId: fpsTrace!.traceId, includeStop: true)
        BTStatisticManager.shared?.addNormalPoint(traceId: trace!.traceId, point: BTStatisticNormalPoint(name: "test", extra: ["test": "123"]))
        BTStatisticManager.shared?.addFPSConsumer(traceId: trace!.traceId, consumer: BTRecordFPSConsumer(scene: .faster))
        XCTAssertNotNil(trace)
    }

    func testAddExtraSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId!, extra: ["test": "123"])
        let trace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
        XCTAssertTrue(trace!.getExtra(includeParent: false)["test"] as! String == "123")
    }

    func testNormalAddConsumerSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId!, consumer: BTOpenFileConsumer(type: .main))
        let trace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
        XCTAssertTrue((trace as! BTStatisticBaseTrace).consumers.count == 1)
    }

    func testFPSAddConsumerSuccess() {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        BTStatisticManager.shared?.addFPSConsumer(traceId: trace!.traceId, consumer: BTRecordFPSConsumer(scene: .faster))
        XCTAssertTrue((trace! as BTStatisticBaseTrace).consumers.count == 1)
    }

    func testRemoveNormalConsumerSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        let consumer = BTOpenFileConsumer(type: .main)
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId!, consumer: consumer)
        BTStatisticManager.shared?.removeNormalConsumer(traceId: traceId!, consumer: consumer)
        let trace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
        XCTAssertTrue((trace as! BTStatisticBaseTrace).consumers.count == 0)
    }

    func testRemoveFPSConsumerSuccess() {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        let consumer = BTRecordFPSConsumer(scene: .faster)
        BTStatisticManager.shared?.addFPSConsumer(traceId: trace!.traceId, consumer: consumer)
        BTStatisticManager.shared?.removeFPSConsumer(traceId: trace!.traceId, consumer: consumer)
        XCTAssertTrue((trace! as BTStatisticBaseTrace).consumers.count == 0)
    }

    func testRemoveAllConsumerSuccess() {
        let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        let consumer = BTOpenFileConsumer(type: .main)
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId!, consumer: consumer)
        BTStatisticManager.shared?.removeAllConsumer(traceId: traceId!)
        let trace = BTStatisticManager.shared?.getTrace(traceId: traceId!, includeStop: true)
        XCTAssertTrue((trace as! BTStatisticBaseTrace).consumers.count == 0)
    }

    func testForceStopFPSTraceSuccess() {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        let consumer = BTRecordFPSConsumer(scene: .faster)
        BTStatisticManager.shared?.addFPSConsumer(traceId: trace!.traceId, consumer: consumer)
        trace?.bind(scrollView: UIScrollView())
        trace?.forceStopAndReportAll()
        let expect = expectation(description: "testForceStopFPSTraceSuccess")
        BTStatisticManager.serialQueue.async {
            expect.fulfill()
        }
        waitForExpectations(timeout: 0.1)
        BTStatisticManager.shared?.removeFPSConsumer(traceId: trace!.traceId, consumer: consumer)
        XCTAssertTrue((trace! as BTStatisticBaseTrace).consumers.count == 0)
    }
}
