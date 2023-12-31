//
//  LKCommonsLoggingTests.swift
//  Efficiency Engineering
//
//  Created by lvdaqian on 2018/3/25.
//  Copyright © 2018 Efficiency Engineering. All rights reserved.
//

import Foundation
import XCTest
@testable import LKCommonsLogging

var logNumber: Int = 0

class LKCommonsLoggingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        logNumber = 0
        SimpleFactory.proxies = [:]
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLogFactory() {
        let defaultLogger = MockLogType()
        Logger.setup(for: "") { (_, _) -> Log in
            return defaultLogger
        }
        let logger = Logger.log(MockLogType.self, category: "123")
        if let log = logger as? MockLogType {
            assert(defaultLogger === log)
        } else {
            assertionFailure()
        }
    }

    func testLogFactoryStore() {
        let store = LogFactoryStore { (_, _) -> Log in
            return MockLogType()
        }
        store.setupLogFactory(for: "abc.") { (_, _) -> Log in
            return MockLogType2()
        }
        store.setupLogFactory(for: "123.") { (_, _) -> Log in
            return MockLogType3()
        }
        var logger = store.findLogFactory(for: "abc.def")(MockLogType.self, "")
        assert(logger is MockLogType2)
        logger = store.findLogFactory(for: "123.456")(MockLogType.self, "")
        assert(logger is MockLogType3)
        logger = store.findLogFactory(for: "zzz.zzz")(MockLogType.self, "")
        assert(logger is MockLogType)
    }

    func testLog() {
        let logger = MockLogType()
        logger.debug("debug")
        logger.info("info")
        logger.trace("trace")
        logger.warn("warn")
        logger.error("error")
        logger.log(level: .fatal, "fatal")
        assert(logNumber == 6)
        var condition = true
        logger.assertInfo(condition, "")
        logger.assertTrace(condition, "")
        logger.assertWarn(condition, "")
        logger.assertDebug(condition, "")
        logger.assertError(condition, "")
        assert(logNumber == 6)
        condition = false
        logger.assertInfo(condition, "")
        logger.assertTrace(condition, "")
        logger.assertWarn(condition, "")
        logger.assertDebug(condition, "")
        logger.assertError(condition, "")
        assert(logNumber == 11)
    }

    func testLoggingProxy() {
        let proxy = LoggingProxy(MockLogType.self, category: "test")
        assert(proxy.isDebug())
        assert(proxy.isTrace())
        proxy.log(event: mockEvent())
        assert(logNumber == 0)
        proxy.setupLogFactory { (_, _) -> Log in
            return MockLogType()
        }
        assert(!proxy.isDebug())
        assert(!proxy.isTrace())
        proxy.log(event: mockEvent())
        assert(logNumber == 2)
    }

    func testSimpleFactory() {
        var number = 0
        _ = SimpleFactory.createLog(MockLogType.self, category: "test")
        SimpleFactory.setupLogFactory(for: "test") { (_, _) -> Log in
            number += 1
            return MockLogType()
        }
        assert(number == 1)
    }
}

class MockLogType: Log {
    func log(event: LogEvent) {
        logNumber += 1
    }

    func isDebug() -> Bool {
        return false
    }

    func isTrace() -> Bool {
        return false
    }
}

class MockLogType2: Log {
    func log(event: LogEvent) {
        logNumber += 1
    }

    func isDebug() -> Bool {
        return false
    }

    func isTrace() -> Bool {
        return false
    }
}

class MockLogType3: Log {
    func log(event: LogEvent) {
        logNumber += 1
    }

    func isDebug() -> Bool {
        return false
    }

    func isTrace() -> Bool {
        return false
    }
}

func mockEvent() -> LogEvent {
    return LogEvent(logId: "", time: 0, level: .info, tags: [], message: "info", thread: "main", file: "", function: "", line: 0, error: nil, additionalData: [:], params: [:])
}
