//
//  AtomicSpec.swift
//  AsyncComponentDevEEUnitTest
//
//  Created by qihongye on 2019/9/23.
//

import UIKit
import Foundation
import XCTest

@testable import AsyncComponent

class Sub {
    let name: String
    let number: Int
    let desc: NSAttributedString
    init(name: String, number: Int) {
        self.name = name
        self.number = number
        self.desc = NSAttributedString(string: name)
    }
}

class Parent {
    var sub = AtomicReference(Sub(name: "Sub", number: 0))
    var subWrapper: Sub {
        get {
            return sub.value
        }
        set {
            sub.value = newValue
        }
    }
}

class ParentMutex {
    var lock = pthread_mutex_t()
    var sub = Sub(name: "Sub", number: 0)
    var subWrapper: Sub {
        get {
            pthread_mutex_lock(&lock)
            defer {
                pthread_mutex_unlock(&lock)
            }
            return sub
        }
        set {
            pthread_mutex_lock(&lock)
            sub = newValue
            pthread_mutex_unlock(&lock)
        }
    }

    init() {
        pthread_mutex_init(&lock, nil)
    }
}

class AtomicSpec: XCTestCase {
    var lock: Int32 = 1
    var parent: Parent!
    var parentMutex: ParentMutex!
    var dispatchQueue = DispatchQueue(label: "write")
//    @Atomic()
//    var atomicColor: UIColor?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        parent = Parent()
        parentMutex = ParentMutex()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAtomicPropertyWrapper() {
//        let expectation1 = XCTestExpectation(description: "AtomicPropertyWraprer1")
//        let expectation2 = XCTestExpectation(description: "AtomicPropertyWraprer2")
//        let count = 100
//        DispatchQueue.global().async {
//            for _ in 0..<count {
//                self.atomicColor.wrappedValue = UIColor.red
//            }
//            expectation1.fulfill()
//        }
//        DispatchQueue.global().async {
//            for _ in 0..<count {
//                self.atomicColor.wrappedValue = UIColor.black
//            }
//            expectation2.fulfill()
//        }
//        for _ in 0..<count {
//            print(atomicColor.wrappedValue)
//        }
//        wait(for: [expectation1, expectation2], timeout: 10)
    }

    /// 测试Atomic高频读写场景
    func testFastReadWriteForAtomic() {
        // 测试场景：主线程和子线程同时在修改，子线程在读取
        var testStr = Atomic<NSAttributedString>(nil)
        for _ in 0..<10 {
            // 子线程写
            DispatchQueue.global().async {
                for _ in 0..<100000 { testStr.wrappedValue = nil }
            }
            // 主线程写
            DispatchQueue.main.async {
                for _ in 0..<100000 { testStr.wrappedValue = nil }
            }
            // 子线程读
            DispatchQueue.global().async {
                for _ in 0..<100000 { print(testStr.wrappedValue?.length) }
            }
        }
    }

    func testUnsafeAtomicPtr() {
        let p1 = Parent()
        let p2 = Parent()
        let ptr1 = UInt(bitPattern: Unmanaged.passUnretained(p1).toOpaque())
        let ptr2 = UInt(bitPattern: Unmanaged.passUnretained(p2).toOpaque())
        let atomicPtr1 = UnsafeAtomicPtr(ptr1)
        let atomicPtr2 = UnsafeAtomicPtr(ptr2)
        XCTAssertFalse(ptr1 == ptr2)
        XCTAssertTrue(ptr1 == atomicPtr1.load())
        XCTAssertTrue(ptr2 == atomicPtr2.load())
        XCTAssertFalse(ptr1 == atomicPtr2.load())
        XCTAssertFalse(ptr2 == atomicPtr1.load())
        XCTAssertFalse(atomicPtr1.compareAndExchange(expected: ptr2, desired: ptr1))
        XCTAssertTrue(atomicPtr1.compareAndExchange(expected: ptr1, desired: ptr2))
        XCTAssertFalse(atomicPtr1.load() == ptr1)
        XCTAssertTrue(atomicPtr1.load() == ptr2)
        XCTAssertTrue(atomicPtr2.exchange(with: ptr1) == ptr2)
        XCTAssertTrue(atomicPtr2.load() == ptr1)
    }

    func testAtomicReferenceReadInMainWriteInSub_MainBusy() {
        let expectation = XCTestExpectation(description: "Main thread read and sub thread write.")
        self.lock = 1
        writeSubValue()
        DispatchQueue.main.async {
            while self.lock != 0 {
                XCTAssertNotNil(self.parent.sub.value.desc)
                XCTAssertNotNil(self.parent.sub.value.number)
                XCTAssertNotNil(self.parent.sub.value.name)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20)
    }

    func testAtomicReferenceReadInMainWriteInSub_MainBusy_Wrapper() {
        let expectation = XCTestExpectation(description: "Main thread read and sub thread write.")
        self.lock = 1
        writeSub()
        DispatchQueue.main.async {
            while self.lock != 1 {
                XCTAssertNotNil(self.parent.subWrapper.desc)
                XCTAssertNotNil(self.parent.subWrapper.number)
                XCTAssertNotNil(self.parent.subWrapper.name)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20)
    }

    private func writeSubValue(_ i: Int = 0) {
        if i > 10000 {
            OSAtomicDecrement32(&self.lock)
            return
        }
        dispatchQueue.asyncAfter(deadline: .now() + 0.001) {
            self.parent.sub.value = Sub(name: "\(i)", number: i)
            self.parent.sub.value = Sub(name: "\(i)-\(i)", number: i)
            self.writeSubValue(i+1)
        }
    }

    private func writeSub(_ i: Int = 0) {
        if i > 10000 {
            OSAtomicDecrement32(&self.lock)
            return
        }
        dispatchQueue.asyncAfter(deadline: .now() + 0.001) {
            self.parent.subWrapper = Sub(name: "\(i)", number: i)
            self.parent.subWrapper = Sub(name: "\(i)-\(i)", number: i)
            self.writeSub(i+1)
        }
    }

    func testPerformanceAtomicReference() {
        let count = 10000
        self.measure {
            self.writeSubValueLoop(count: count)
            let time = CACurrentMediaTime()
            for _ in 0..<count {
                XCTAssertNotNil(self.parent.subWrapper.desc)
                XCTAssertNotNil(self.parent.subWrapper.number)
                XCTAssertNotNil(self.parent.subWrapper.name)
            }
            print("ExecTime: ", CACurrentMediaTime() - time)
        }
    }

    private func writeSubValueLoop(count: Int = 0) {
        dispatchQueue.async {
            for i in 0..<count {
                self.parent.subWrapper = Sub(name: "\(i)", number: i)
            }
        }
    }

    func testPerformanceMutex() {
        let count = 10000
        self.measure {
            self.writeSubValueMutexLoop(count: count)
            let time = CACurrentMediaTime()
            for _ in 0..<count {
                XCTAssertNotNil(self.parentMutex.subWrapper.desc)
                XCTAssertNotNil(self.parentMutex.subWrapper.number)
                XCTAssertNotNil(self.parentMutex.subWrapper.name)
            }
            print("ExecTime: ", CACurrentMediaTime() - time)
        }
    }

    private func writeSubValueMutexLoop(count: Int = 0) {
        dispatchQueue.async {
            for i in 0..<count {
                self.parentMutex.subWrapper = Sub(name: "\(i)", number: i)
            }
        }
    }
}
