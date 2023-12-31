//
//  ThreadSafeLazySpec.swift
//  LarkFoundationDevEEUnitTest
//
//  Created by qihongye on 2019/12/23.
//
// swiftlint:disable overridden_super_call

import Foundation
import XCTest

@testable import LarkFoundation

var initializeCount: Int32 = 0

@propertyWrapper
struct ThreadSafeLazy2<Value> {
    enum State {
        case uninitialized(() -> Value)
        case initialized(Value)
    }

    private var state: State
    private var mutex = pthread_mutex_t()

    public init(value: @autoclosure @escaping () -> Value) {
        state = .uninitialized(value)
        pthread_mutex_init(&mutex, nil)
    }

    public var wrappedValue: Value {
        mutating get {
            switch state {
            case .initialized(let value):
                return value
            case .uninitialized(let initializer):
                pthread_mutex_lock(&mutex)
                defer {
                    pthread_mutex_unlock(&mutex)
                }
                if case let .initialized(value) = state {
                    return value
                }
                let value = initializer()
                state = .initialized(value)
                return value
            }
        }
        set {
            state = .initialized(newValue)
        }
    }
}

class ThreadSafeLazySpec: XCTestCase {
    @ThreadSafeLazy(value: {
        OSAtomicIncrement32(&initializeCount)
        for _ in 0..<100000 {}
        return NSString()
    })
    var test: NSString

    @ThreadSafeLazy(value: {
        OSAtomicIncrement32(&initializeCount)
        for _ in 0..<100000 {}
        return NSString()
    })
    var perform1: NSString

    @ThreadSafeLazy2(value: {
        OSAtomicIncrement32(&initializeCount)
        for _ in 0..<100000 {}
        return NSString()
    }())
    var perform2: NSString

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMultiThreadInitialize() {
        let count = 1000
        initializeCount = 0
        var test = NSString()
        var runCount: Int32 = 0
        DispatchQueue.concurrentPerform(iterations: count) { (_) in
            test = self.test
            OSAtomicIncrement32(&runCount)
        }
        sleep(2)
        XCTAssertEqual(runCount, Int32(count))
        XCTAssertEqual(initializeCount, 1)
    }

    func testPerformance2() {
        self.measure {
            let count = 1000
            initializeCount = 0
            var test = NSString()
            var runCount: Int32 = 0
            DispatchQueue.concurrentPerform(iterations: count) { (_) in
                test = self.perform2
                OSAtomicIncrement32(&runCount)
            }
            while runCount < count {}
        }
    }

    func testPerformance1() {
        self.measure {
            let count = 1000
            initializeCount = 0
            var test = NSString()
            var runCount: Int32 = 0
            DispatchQueue.concurrentPerform(iterations: count) { (_) in
                test = self.perform1
                OSAtomicIncrement32(&runCount)
            }
            while runCount < count {}
        }
    }
}
