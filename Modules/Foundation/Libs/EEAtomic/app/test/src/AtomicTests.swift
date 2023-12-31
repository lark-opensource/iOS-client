//
//  AtomicTests.swift
//  EEAtomicDev
//
//  Created by SolaWing on 2020/4/30.
//

import Foundation
import XCTest
@testable import EEAtomic

class TestObject {
    @AtomicObject var v = [""]
}

class RepleacemeSpec: XCTestCase {

    func testAtomicObject() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let v = TestObject()
        DispatchQueue.concurrentPerform(iterations: 999) { (_) in
            for _ in 0..<100 {
                v.v = Array()
                v.$v.value = Array()
                v.v.append("sss")
                v.v += ["xccx"]
                v.$v.value += [""]
            }
        }
    }
}
