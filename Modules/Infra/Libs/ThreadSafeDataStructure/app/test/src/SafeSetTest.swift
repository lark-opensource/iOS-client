//
//  SafeSetTest.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by PGB on 2019/11/19.
//

import Foundation
import XCTest
import ThreadSafeDataStructure
@testable import ThreadSafeDataStructure

class SafeSetTest: XCTestCase {
    let util = TestUtil.shared

    func testResultCorrectnessForValueType() {
        for i in 1 ... 4 {
            util.runCorrectnessCheck(for: .set, elementType: .value, testCaseNum: i)
        }
    }

    func testResultCorrectnessForReferenceType() {
        for i in 1 ... 4 {
            util.runCorrectnessCheck(for: .set, elementType: .reference, testCaseNum: i)
        }
    }

    func testMultiThreadStabilityForValueType() {
        util.runMultiThreadTest(for: .set, elementType: .value)
    }

    func testMultiThreadStabilityForReferenceType() {
        util.runMultiThreadTest(for: .set, elementType: .value)
    }
}
