//
//  LoggerTest.swift
//  LoggerDev
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation
import XCTest
import RustPB
@testable import Logger

var eventNumber: Int = 0
var appenderNumber: Int = 0
var assertCount: Int = 0

class LoggerTest: XCTestCase {

    static let rootPath = "\(NSHomeDirectory())/Library/"

    static override func setUp() {
        RustMetricAppender.setupMetric(storePath: rootPath)

        let rustConfig = RustLogConfig(
            process: "test",
            logPath: rootPath,
            monitorEnable: true
        )
        RustLogAppender.setupRustLogSDK(config: rustConfig)

        print("init root path \(rootPath)")
    }

    override func setUp() {
        eventNumber = 0
        appenderNumber = 0
        assertCount = 0
        Logger.setup(appenders: [])
        LogCenter.setup(configs: [])

        let xlogPath = LoggerTest.rootPath + "xlog"
        FileManager.default.subpaths(atPath: xlogPath)?.forEach({ (path) in
            try? FileManager.default.removeItem(atPath: xlogPath + "/" + path)
        })
    }

    override func tearDown() {
    }

    func testLogCenter() {
        let config = LogCenter.Config(
            backend: "test",
            appenders: [MockAppender(), MockAppender2()],
            forwardToDefault: true
        )
        Logger.setup(appenders: [MockAppender()])
        LogCenter.setup(configs: [config])

        let logger = Logger.log(LoggerTest.self, category: "test", backendType: "test", forwardToDefault: true)
        logger.vender().writeEvent(mockLogEvent())
        let expect = expectation(description: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            /// 由于转发 defult 1 个 appender, 加上定制的 2 个 appender
            XCTAssert(eventNumber == 3)
            LogCenter.setup(config: [
                "demo": [
                    MockAppender()
                ]
                ]
            )
            let logger2 = Logger.log(LoggerTest.self, category: "test", backendType: "demo", forwardToDefault: false)
            logger2.vender().writeEvent(mockLogEvent())
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                XCTAssert(eventNumber == 4)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 10)

    }

    func testLog() {
        let log = Log(LoggerTest.self, category: "test") { () -> LogVendor in
            return MockLogVendor()
        }
        var condition: Bool = false
        let message = "test"
        log.assertTrace(condition, message)
        log.assertDebug(condition, message)
        log.assertInfo(condition, message)
        log.assertWarn(condition, message)
        log.assertError(condition, message)
        XCTAssert(eventNumber == 5)
        condition = true
        log.assertTrace(condition, message)
        log.assertDebug(condition, message)
        log.assertInfo(condition, message)
        log.assertWarn(condition, message)
        log.assertError(condition, message)
        XCTAssert(eventNumber == 5)
        log.trace(message)
        log.debug(message)
        log.info(message)
        log.warn(message)
        log.error(message)
        XCTAssert(eventNumber == 10)
    }

    func testVender() {
        let appenders = [MockAppender()]
        let vender = LogVendorImpl(appenders: appenders)
        XCTAssert(vender.appenders.count == appenders.count)
        vender.writeEvent(mockLogEvent())
        let expect = expectation(description: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(eventNumber, 1)
        }
        XCTAssert(vender.isActivate(MockAppender.self) != nil)
        let mock2 = MockAppender2()
        vender.addAppender(mock2, persistent: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssert(vender.appenders.count == 2)
            vender.removeAppender(mock2, persistent: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                XCTAssert(vender.appenders.count == 1)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 10)
    }

    func testLogReciver() {
        let events = LogReceiver.receiveEvent(event: mockLogEvent(), events: [mockLogEvent()])
        XCTAssert(events.count == 2)
        let appenders = [MockAppender()]
        LogReceiver.writeEventToAppender(event: mockLogEvent(), appenders: appenders)
        XCTAssert(eventNumber == 1)
        _ = LogReceiver.writeEventsToAppender(events: events, appenders: appenders)
        XCTAssert(eventNumber == 3)
    }

    func testAppender() {
        let consoleConfig = LoggerConsoleConfig(logLevel: .info)
        let consoleAppender = LoggerConsoleAppender(consoleConfig)
        consoleAppender.persistent(status: false)

        let metricAppender = RustMetricAppender()

        let rustAppender = RustLogAppender()

        let xcodeConsoleConfig = XcodeConsoleConfig(logLevel: .info)
        let xcodeConsoleAppender = ConsoleAppender(xcodeConsoleConfig)

        XCTAssert(!LoggerConsoleAppender.identifier().isEmpty)
        XCTAssert(!RustMetricAppender.identifier().isEmpty)
        XCTAssert(!RustLogAppender.identifier().isEmpty)
        XCTAssert(!ConsoleAppender.identifier().isEmpty)

        let appenders: [Appender] = [consoleAppender, metricAppender, rustAppender, xcodeConsoleAppender]
        appenders.forEach { (appender) in
            XCTAssert(!appender.template(message: "test", error: nil).isEmpty)
            XCTAssert(!appender.extractAdditionalData(additionalData: ["key": "value"]) .isEmpty)
            appender.doAppend(mockLogEvent())
        }
    }

    func testRustAppenderLogger() {
        let rustAppender = RustLogAppender()
        Logger.setup(appenders: [rustAppender])
        let logger = Logger.log(LoggerTest.self, category: "rust", backendType: "demo", forwardToDefault: true)

        logger.log(LogEvent(level: .debug, message: "这是一个中文测试"))
        logger.log(LogEvent(level: .debug, message: "This is an english test"))
        logger.log(LogEvent(level: .debug, message: "︻︼︽︾〒↑↓☉⊙●〇◎¤★☆■▓「」『』◆◇▲△▼▽◣◥◢◣◤ ◥№↑↓→←↘↙Ψ※㊣∑⌒∩【】〖〗＠ξζω□∮〓※》∏卐√ ╳々♀♂∞①ㄨ≡╬╭╮╰╯╱╲ ▂ ▂ ▃ ▄ ▅ ▆ ▇ █ ▂▃▅▆█ ▁▂▃▄▅▆▇█▇▆▅▄▃▂▁"))
        let expect = expectation(description: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 10)
    }

    func testLoggerRule() {
        let rustAppender = RustLogAppender()
        rustAppender.rules = [LogLengthRule()]

        Logger.setup(appenders: [rustAppender, MockRuleAppender()])
        let logger = Logger.log(LoggerTest.self, category: "rust", backendType: "demo", forwardToDefault: true)
        let expection = expectation(description: "test")
        logger.log(LogEvent(level: .debug, message: "t1"))
        logger.log(LogEvent(level: .debug, message: "t2"))
        logger.log(LogEvent(level: .debug, message: "this message conform rule"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(assertCount, 4)
            expection.fulfill()
        }
        wait(for: [expection], timeout: 10)
    }
}

func mockLogEvent() -> LogEvent {
    return LogEvent(level: .debug, message: "event")
}

class MockAppender: Appender {
    static func identifier() -> String {
        return "mock"
    }

    static func persistentStatus() -> Bool {
        return false
    }

    func doAppend(_ event: LogEvent) {
        print("mock 1 event name \(event.message)")
        eventNumber += 1
    }

    func persistent(status: Bool) {
    }
}

class MockRuleAppender: Appender {
    static func identifier() -> String {
        return "mockRule"
    }

    static func persistentStatus() -> Bool {
        return false
    }

    func doAppend(_ event: LogEvent) {
        print("mock rule event name \(event.message)")
        eventNumber += 1
    }

    func persistent(status: Bool) {
    }

    func debugLogRules() -> [LogRule] {
        return [LogLengthRule()]
    }
}

struct LogLengthRule: LogRule {
    var name: String = "LogLengthRule"

    func check(event: LogEvent) -> Bool {
        if event.message.count <= 5 {
            assertCount += 1
            return true
        }
        return true
    }
}

class MockAppender2: Appender {
    static func identifier() -> String {
        return "mock2"
    }

    static func persistentStatus() -> Bool {
        return false
    }

    func doAppend(_ event: LogEvent) {
        print("mock 2 event name \(event.message)")
        eventNumber += 1
    }

    func persistent(status: Bool) {
    }
}

class MockLogVendor: LogVendor {
    func writeEvent(_ event: LogEvent) {
        eventNumber += 1
    }

    func addAppender(_ appender: Appender, persistent status: Bool) {
        appenderNumber += 1
    }
}
