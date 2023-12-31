//
//  PBMergeSpec.swift
//  LarkSecurityAuditDevEEUnitTest
//
//  Created by Yiming Qu on 2020/11/24.
//

import XCTest
@testable import LarkSecurityAudit

class PBMergeSpec: XCTestCase {

    func testExample() throws {
        var commonEvent = Event()
        commonEvent.module = .moduleBitable
        var env = SecurityEvent_Env()
        env.did = "TestDid"
        commonEvent.env = env

        var bizEvent = Event()
        bizEvent.operation = .operationComment
        bizEvent = bizEvent.fillCommonFields()
        bizEvent.operator = OperatorEntity()
        bizEvent.operator.type = .entityBitableID
        bizEvent.operator.value = .declaredDatatype

        let result = try Utils.merge(bizEvent, commonEvent)

        var expect = bizEvent
        expect.module = .moduleBitable
        expect.env = env

        XCTAssertEqual(result, expect)
    }

    func testExample1() throws {
        var commonEvent = Event()
        commonEvent.module = .moduleBitable
        var env = SecurityEvent_Env()
        env.did = "TestDid"
        commonEvent.env = env

        var bizEvent = Event()
        bizEvent.operation = .operationComment
        bizEvent.env.did = "NewDid"
        bizEvent = bizEvent.fillCommonFields()
        bizEvent.operator = OperatorEntity()
        bizEvent.operator.type = .entityBitableID
        bizEvent.operator.value = .declaredDatatype
        var obj = ObjectEntity()
        obj.type = .entityBitableID
        obj.value = .declaredDatatype
        bizEvent.objects = [obj]

        let res = try Utils.verify(bizEvent, commonEvent)
        let result = try Utils.merge(bizEvent, commonEvent)
        bizEvent = bizEvent.fillCommonFields()

        var expect = bizEvent
        expect.module = .moduleBitable

        XCTAssertEqual(result.env.did, "NewDid")
        XCTAssertEqual(result, expect)

        print("initialized \(expect.isInitialized)")
        print("commonEvent initialized \(commonEvent.isInitialized)")
    }

    func testExample2() throws {
        var commonEvent = Event()
        commonEvent.module = .moduleBitable

        XCTAssertEqual(commonEvent.isInitialized, false)
    }

    func testExample3() throws {
        var commonEvent = Event()
        commonEvent.module = .moduleBitable
        commonEvent.operation = .operationComment

        XCTAssertEqual(commonEvent.isInitialized, false)
    }

    func testExample4() throws {
        var commonEvent = Event()
        commonEvent.module = .moduleBitable
        commonEvent.operation = .operationComment
        commonEvent.timeStamp = String(Int64(Date().timeIntervalSince1970))
        commonEvent.operator = OperatorEntity()
        commonEvent.operator.type = .entityBitableID
        commonEvent.operator.value = .declaredDatatype

        XCTAssertEqual(commonEvent.isInitialized, true)
    }
}
