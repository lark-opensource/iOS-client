//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
@testable import LKMetric
import Logger
import LKTracing

class TestSpec: XCTestCase {

    var isSetup = false

    static var exp: XCTestExpectation?
    static var logEvent: MetricEvent?

    override func setUp() {
        super.setUp()
        if !isSetup {
            isSetup = true
            LogCenter.setup(config: [LKMetricLogCategory: [TestAppender()]])
        }
    }

    func testDomain() {
        let rootDomain = Root.passport.domain
        XCTAssertTrue(rootDomain.value == [1])
        let loginDomain = rootDomain.s(Passport.login)
        XCTAssertTrue(loginDomain.value == [1, 1])
        let loginv3Domain = loginDomain.s(Login.loginTypeV3)
        XCTAssertTrue(loginv3Domain.value == [1, 1, 1])
    }

    func testMetricEventWithNSError() {
        metricEvent(useNSError: true)
    }

    func testMetricEventWithoutNSError() {
        metricEvent(useNSError: false)
    }

    func testDomainInit() {
        let domainValue = Root.passport.s(Passport.login).s(Login.verifyCodeV3).value
        let domain = MetricDomain.domain(rawValue: domainValue)
        XCTAssertEqual(domainValue, domain.value)
    }
}
extension TestSpec {

    enum TestData {
        static let domain = Root.passport.domain
        static let type = MetricType.network
        static let id: MetricID = 0
        static let msg = "msg"
        static let errCode = -1
        static let errMsg = NSLocalizedString("localized_error", comment: "")
        static let emitType: EmitType = .timer
        static let emitValue: EmitValue = 233
    }

    func metricEvent(useNSError: Bool) {
        TestSpec.exp = expectation(description: "for log")
        if useNSError {
            let error = NSError(domain: "test error domain",
                                code: TestData.errCode,
                                userInfo: [NSLocalizedDescriptionKey: TestData.errMsg])
            LKMetric.log(domain: TestData.domain,
                         type: TestData.type,
                         id: TestData.id,
                         emitType: TestData.emitType,
                         emitValue: TestData.emitValue,
                         params: [MetricConst.msg: TestData.msg],
                         error: error)
        } else {
            LKMetric.log(domain: TestData.domain,
                         type: TestData.type,
                         id: TestData.id,
                         params: [MetricConst.msg: TestData.msg,
                                  MetricConst.errorMsg: TestData.errMsg,
                                  MetricConst.errorCode: "\(TestData.errCode)"]
            )
        }

        waitForExpectations(timeout: 5)
        XCTAssertNotNil(TestSpec.logEvent)

        check(event: TestSpec.logEvent!, useNSError: useNSError)

        TestSpec.logEvent = nil
        TestSpec.exp = nil
    }

    func check(event: MetricEvent, useNSError: Bool) {
        XCTAssertEqual(event.tracingId, LKTracing.identifier)
        XCTAssertEqual(event.domain, TestData.domain.value)
        XCTAssertEqual(event.mType, TestData.type.rawValue)

        if useNSError {
            XCTAssertEqual(event.emitType, TestData.emitType.rawValue)
            XCTAssertEqual(event.emitValue, TestData.emitValue)
        } else {
            XCTAssertEqual(event.emitType, MetricConst.defaultEmitType.rawValue)
            XCTAssertEqual(event.emitValue, MetricConst.defaultEmitValue)
        }

        let data = event.params.data(using: .utf8)
        XCTAssertNotNil(data)
        let params = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
        XCTAssertNotNil(params)

        let errorCodeStr = params![MetricConst.errorCode] as? String
        let errorMsg = params![MetricConst.errorMsg] as? String
        let pvalue = params![MetricConst.msg] as? String
        XCTAssertNotNil(errorCodeStr)
        XCTAssertNotNil(errorMsg)
        XCTAssertNotNil(pvalue)

        let errorCode = Int(errorCodeStr!)
        XCTAssertNotNil(errorCode)
        XCTAssertEqual(pvalue!, TestData.msg)
        XCTAssertEqual(errorCode!, TestData.errCode)
        XCTAssertEqual(errorMsg!, TestData.errMsg)
    }
}
class TestAppender: Appender {

    static func identifier() -> String {
        return "\(TestAppender.self)"
    }

    static func persistentStatus() -> Bool {
        return false
    }

    func doAppend(_ event: LogEvent) {
        if let metricEvent = MetricEvent(time: event.time, logParams: event.params, error: event.error) {
            TestSpec.logEvent = metricEvent
            TestSpec.exp?.fulfill()
        }
    }

    func persistent(status: Bool) {}
}
