//
//  PerformanceTest.swift
//  SwinjectDevEEUnitTest
//
//  Created by CharlieSu on 5/13/20.
//

import Foundation
import XCTest
import Swinject

class PerformanceTest: XCTestCase {

    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    /// Register 200 objects, perfomance baseline around 0.001s
    func test_register_performance() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            self.container = Container()
            self.startMeasuring()
            registerAll(container: container)
            self.stopMeasuring()
        }
    }

    /// Serial resolve 200 objects, perfomance baseline around 1.107s
    func test_serial_resolve_performanace() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            self.container = Container()
            registerAll(container: container)
            self.startMeasuring()
            serialResolveAll(resolver: container)
            self.stopMeasuring()
        }
    }

    /// Concurrent resolve 200 objects, perfomance baseline around 0.013s
    func test_concurrent_resolve_perfomance() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            self.container = Container()
            registerAll(container: container)
            let expect = expectation(description: "Test")
            startMeasuring()
            concurrentResolveAll(resolver: container) {
                self.stopMeasuring()
                expect.fulfill()
            }
            wait(for: [expect], timeout: 2.0)
        }
    }
}

let testCount = 200

func registerAll(container: Container) {
    (0..<testCount).forEach { i in
        container.register(Int.self, name: "\(i)") { _ -> Int in
            usleep(5_000) // sleep for 5 ms
            return i
        }.inObjectScope(.container)
    }
}

func serialResolveAll(resolver: Resolver) {
    (0..<testCount).forEach { i in
        _ = resolver.resolve(Int.self, name: "\(i)")!
    }
}

func concurrentResolveAll(resolver: Resolver, completion: @escaping () -> Void) {
    let queue = DispatchQueue(label: "Test Queue", attributes: .concurrent)
    (0..<testCount).forEach { i in
        queue.async {
            _ = resolver.resolve(Int.self, name: "\(i)")!
            if i == testCount - 1 {
                queue.async(flags: .barrier) {
                    completion()
                }
            }
        }
    }
}
