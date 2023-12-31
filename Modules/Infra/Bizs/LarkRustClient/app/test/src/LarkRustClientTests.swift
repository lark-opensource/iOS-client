//
//  LarkRustClientTests.swift
//  LarkRustClientTests
//
//  Created by linlin on 2018/1/7.
//  Copyright © 2018年 linlin. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkRustClient
import EEAtomic

class ConcurrentTests: XCTestCase {
    class Lock {
        var structlock = os_unfair_lock()
        func lock() {
            os_unfair_lock_lock(&self.structlock)
        }
        func unlock() {
            os_unfair_lock_unlock(&self.structlock)
        }
    }
    var counter = 0
    var structlock = os_unfair_lock()
    let refLock = Lock()
    let lockPointer = UnfairLock()
    let semphore = DispatchSemaphore(value: 1)
    let closureLock = closureWrap()

    func testConcurrencyOK() {
        pointerWrapperCall()
        atomicAdd()
        semphoreCall()
        localStaticCFuncCall()
        closureWrapper()
    }

    func testConcurrencyOKButSanitizerWarn() {
        staticCFuncCall()
        mutatingWrapMethodCall()
        classWrapperCall()
        unsafePointerCastStaticCFuncCall()
    }

    let gettidCount = 1_000_000
    var id = 0
    func testBitcastThreadPerformance() {
        measure {
            let expectation = self.expectation(description: "testBitcastThreadPerformance")
            DispatchQueue.global().async {
                for _ in 0..<self.gettidCount {
                    self.id = unsafeBitCast(Thread.current, to: Int.self)
                }
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 5)
        }
    }

    func testObjectIDThreadPerformance() {
        measure {
            let expectation = self.expectation(description: "testObjectIDThreadPerformance")
            DispatchQueue.global().async {
                for _ in 0..<self.gettidCount {
                    self.id = Int(bitPattern: ObjectIdentifier(Thread.current))
                }
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 5)
        }
    }

    func testPthreadSelfPerformance() {
        measure {
            let expectation = self.expectation(description: "testPthreadSelfPerformance")
            DispatchQueue.global().async {
                for _ in 0..<self.gettidCount {
                    self.id = Int(bitPattern: pthread_self())
                }
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 5)
        }
    }

    @inline(never) func concurrencyRun(iterations: Int, _ action: @escaping (Int) -> Void) {
        DispatchQueue.concurrentPerform(iterations: iterations) { (i) in
            action(i)
        }
    }

    enum LockAPI {
        case lock, unlock
    }
    // closure var不能被内联，性能上会有损失
    static func closureWrap() -> (LockAPI) -> Void {
        var structLock = os_unfair_lock()
        return {
            switch $0 {
            case .lock:
                os_unfair_lock_lock(&structLock)
            case .unlock:
                os_unfair_lock_unlock(&structLock)
            }
        }
    }

    func closureWrapper() {
        counter = 0
        let total = Int(1e5)
        concurrencyRun(iterations: total) { (_) in
            // mutating func still warn
            self.closureLock(.lock)
            self.counter += 1
            self.closureLock(.unlock)
        }
        concurrencyRun(iterations: total) { (_) in
            // mutating func still warn
            self.closureLock(.lock)
            self.counter += 1
            self.closureLock(.unlock)
        }
        XCTAssertEqual(counter, total * 2)
    }

    func localStaticCFuncCall() {
        // 这个是好的可能是因为closurer捕获的是共享的指针，然后直接传指针了而没有访问地址，所以没触发warning
        counter = 0
        var structlock = os_unfair_lock()
        let total = Int(1e5)
        concurrencyRun(iterations: total) { (_) in
            // mutating func still warn
            os_unfair_lock_lock(&structlock)
            self.counter += 1
            os_unfair_lock_unlock(&structlock)
        }
        concurrencyRun(iterations: total) { (_) in
            // mutating func still warn
            os_unfair_lock_lock(&structlock)
            self.counter += 1
            os_unfair_lock_unlock(&structlock)
        }
        XCTAssertEqual(counter, total * 2)
    }
    func unsafePointerCastStaticCFuncCall() {
        var counter = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            withUnsafeMutablePointer(to: &structlock) { (lockPointer) in
                os_unfair_lock_lock(lockPointer)
                counter += 1
                os_unfair_lock_unlock(lockPointer)
            }
        }
        XCTAssertEqual(counter, total)
    }
    func pointerWrapperCall() {
        counter = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            lockPointer.withLocking {
                lockPointer.assertOwner()
                counter += 1
            }
        }
        XCTAssertEqual(counter, total)
    }

    func staticCFuncCall() {
        var counter = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            os_unfair_lock_lock(&structlock)
            counter += 1
            os_unfair_lock_unlock(&structlock)
        }
        XCTAssertEqual(counter, total)
    }
    func mutatingWrapMethodCall() {
        var counter = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            structlock.lock()
            counter += 1
            structlock.unlock()
        }
        XCTAssertEqual(counter, total)
    }
    func classWrapperCall() {
        var counter = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            refLock.lock()
            counter += 1
            refLock.unlock()
        }
        XCTAssertEqual(counter, total)
    }
    func atomicAdd() {
        var counter: Int64 = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            OSAtomicIncrement64(&counter)
        }
        XCTAssertEqual(counter, Int64(total))
    }
    func semphoreCall() {
        var counter = 0
        let total = Int(1e5)
        DispatchQueue.concurrentPerform(iterations: total) { (_) in
            semphore.wait()
            counter += 1
            semphore.signal()
        }
        XCTAssertEqual(counter, total)
    }
}

extension os_unfair_lock {
    mutating func lock() {
        os_unfair_lock_lock(&self)
    }
    mutating func unlock() {
        os_unfair_lock_unlock(&self)
    }
    // when in mutating func callback, if access the struct again, will trigger Simultaneous accesses
    // mutating func withLocking<R>(action: () throws -> R) rethrows -> R {
    //     os_unfair_lock_lock(&self); defer { os_unfair_lock_unlock(&self) }
    //     return try action()
    // }
    @inlinable
    mutating func assertOwner() {
        #if DEBUG
        os_unfair_lock_assert_owner(&self)
        #endif
    }
}
