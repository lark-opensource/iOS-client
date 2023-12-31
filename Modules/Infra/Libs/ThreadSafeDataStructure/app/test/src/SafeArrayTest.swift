//
//  SafeArrayTest.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by PGB on 2019/11/14.
//

import Foundation
import XCTest
import ThreadSafeDataStructure
@testable import ThreadSafeDataStructure

class SafeArrayTest: XCTestCase {
    let util = TestUtil.shared

    func testResultCorrectnessForValueType() {
        for i in 1 ... 4 {
            util.runCorrectnessCheck(for: .array, elementType: .value, testCaseNum: i)
        }
    }

    func testResultCorrectnessForReferenceType() {
        for i in 1 ... 4 {
            util.runCorrectnessCheck(for: .array, elementType: .reference, testCaseNum: i)
        }
    }

//    func testMultiThreadStabilityForValueType() {
//        util.runMultiThreadTest(for: .array, elementType: .value)
//    }
//
//    func testMultiThreadStabilityForReferenceType() {
//        util.runMultiThreadTest(for: .array, elementType: .reference)
//    }
}
