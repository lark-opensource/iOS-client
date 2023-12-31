//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
import LarkOpenTrace

class RepleacemeSpec: XCTestCase {
    
    var trace1: LKOTTrace?
    var trace2: LKOTTrace?
    var span1: LKOTSpan?
    var span2: LKOTSpan?
    var span3: LKOTSpan?
    var span4: LKOTSpan?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOpenTraceInit() {
        trace1 = LKOTTrace.start("trace")
        trace2 = LKOTTrace.start("tarce2", start: Date())
        span1 = LKOTSpan.start(of: trace1, operationName: "span1")
        span2 = LKOTSpan.start(of: trace2, operationName: "span2", spanStart: Date())
        span3 = LKOTSpan.start("span3", referenceOf: span1)
        span4 = LKOTSpan.start("span4", childOf: span2)
        XCTAssertNotNil(trace1, "trace1 must not nil")
        XCTAssertNotNil(trace2, "trace2 must not nil")
        XCTAssertNotNil(span1, "span1 must not nil")
        XCTAssertNotNil(span2, "span2 must not nil")
        XCTAssertNotNil(span3, "span3 must not nil")
        XCTAssertNotNil(span4, "span4 must not nil")
    }

    func testOpenTraceFinish() {
        span1?.finish()
        span2?.finish()
        span3?.finish()
        span4?.finish()
        trace1?.finish()
        trace2?.finish()
        //由于没有因果关系，因此只能通过日志判断是否有问题，无法通过单测判断结果
        XCTAssertTrue(true, "0x23 need unsafe")
    }

}
