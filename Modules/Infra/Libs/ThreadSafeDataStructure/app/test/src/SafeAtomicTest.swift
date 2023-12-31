//
//  SafeAtomicTest.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by PGB on 2019/11/29.
//

import Foundation
import XCTest
import ThreadSafeDataStructure
@testable import ThreadSafeDataStructure

class SafeAtomicTest: XCTestCase {
    let util = TestUtil.shared

    func testResultCorrectnessForValueType() {
        util.runCorrectnessCheck(for: .atomic, elementType: .value, testCaseNum: 1)
    }

    func testResultCorrectnessForReferenceType() {
        util.runCorrectnessCheck(for: .atomic, elementType: .reference, testCaseNum: 1)
    }

    func testMultiThreadStabilityForValueType() {
        util.runMultiThreadTest(for: .set, elementType: .value, testCaseCountPerThread: 100)
    }

    func testMultiThreadStabilityForReferenceType() {
        util.runMultiThreadTest(for: .set, elementType: .value, testCaseCountPerThread: 100)
    }
}
