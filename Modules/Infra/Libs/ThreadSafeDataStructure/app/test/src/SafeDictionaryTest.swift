//
//  SafeDictionaryTest.swift
//  ThreadSafeDataStructureDevEEUnitTest
//
//  Created by PGB on 2019/11/17.
//

import Foundation
import XCTest
import ThreadSafeDataStructure
@testable import ThreadSafeDataStructure

class SafeDictionaryTest: XCTestCase {
    let util = TestUtil.shared

    func testResultCorrectnessForValueType() {
        for i in 1 ... 4 {
            util.runCorrectnessCheck(for: .dictionary, elementType: .value, testCaseNum: i)
        }
    }

    func testResultCorrectnessForReferenceType() {
        for i in 1 ... 4 {
            util.runCorrectnessCheck(for: .dictionary, elementType: .reference, testCaseNum: i)
        }
    }

    func testMultiThreadStabilityForValueType() {
        util.runMultiThreadTest(for: .dictionary, elementType: .value)
    }

    func testMultiThreadStabilityForReferenceType() {
        util.runMultiThreadTest(for: .dictionary, elementType: .reference)
    }
}
