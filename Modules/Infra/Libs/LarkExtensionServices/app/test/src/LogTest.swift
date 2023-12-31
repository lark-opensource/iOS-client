//
//  LogTest.swift
//  LarkExtensionServicesDevTests
//
//  Created by 王元洵 on 2021/4/2.
//

import Foundation
import XCTest
@testable import LarkExtensionServices

class LogTester: LogHandler {
    var history: [Logger.Message] = []

    func log(eventMessage: Logger.Message) {
        history.append(eventMessage)
    }

}

class LoggerTests: XCTestCase {
    func getCorrectLog(label: String,
                       level: Logger.Level,
                       message: Logger.Message,
                       tag: String = "",
                       additionalData params: [String: String]? = nil,
                       error: Error? = nil,
                       file: String = #fileID,
                       function: String = #function,
                       line: Int = #line) -> String {
        return Logger.Event(
            label: label,
            time: Date().addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT())).timeIntervalSince1970,
            level: level,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params).description
    }

    // swiftlint:disable function_body_length
    func testLog() {
        let tester = LogTester()
        let logger = Logger(label: "testLog", tester)
        var answer = getCorrectLog(label: "testLog",
                                   level: .info,
                                   message: "info",
                                   tag: "info tag",
                                   additionalData: ["info": "info"],
                                   line: 54)
        logger.info("info", tag: "info tag", additionalData: ["info": "info"], error: nil)
        XCTAssertEqual(answer, tester.history.popLast()?.description)

        answer = getCorrectLog(label: "testLog",
                               level: .trace,
                               message: "trace",
                               tag: "trace tag",
                               additionalData: ["trace": "trace"],
                               line: 63)
        logger.trace("trace", tag: "trace tag", additionalData: ["trace": "trace"], error: nil)
        XCTAssertEqual(answer, tester.history.popLast()?.description)

        answer = getCorrectLog(label: "testLog",
                               level: .debug,
                               message: "debug",
                               tag: "debug tag",
                               additionalData: ["debug": "debug"],
                               line: 72)
        logger.debug("debug", tag: "debug tag", additionalData: ["debug": "debug"], error: nil)
        XCTAssertEqual(answer, tester.history.popLast()?.description)

        answer = getCorrectLog(label: "testLog",
                               level: .warn,
                               message: "warn",
                               tag: "warn tag",
                               additionalData: ["warn": "warn"],
                               line: 81)
        logger.warn("warn", tag: "warn tag", additionalData: ["warn": "warn"], error: nil)
        XCTAssertEqual(answer, tester.history.popLast()?.description)

        answer = getCorrectLog(label: "testLog",
                               level: .error,
                               message: "error",
                               tag: "error tag",
                               additionalData: ["error": "error"],
                               line: 90)
        logger.error("error", tag: "error tag", additionalData: ["error": "error"], error: nil)
        XCTAssertEqual(answer, tester.history.popLast()?.description)
    }

    func testMultiplexHandler() {
        let tester = LogTester()
        let logger = MultiplexLogHandler([tester])
        logger.log(eventMessage: "test")
        XCTAssertEqual("test", tester.history.popLast()?.description)
    }

    func testFileLogHandler() {
        let expectation = XCTestExpectation(description: "test")
        let logger = FileLogHandler()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        logger.maxBufferSize = 0
        var temporaryDirectory = NSTemporaryDirectory()
        temporaryDirectory.removeLast()
        logger.logDirPath = temporaryDirectory
        let logFile = NSTemporaryDirectory() + "\(dateFormatter.string(from: Date()))"
        logger.log(eventMessage: "test")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let fileHandler = FileHandle(forReadingAtPath: logFile)
            let data = fileHandler?.readDataToEndOfFile()
            let log = String(data: data!, encoding: .utf8)
            XCTAssertEqual(log, "test")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    override func tearDown() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let logFile = NSTemporaryDirectory() + "\(dateFormatter.string(from: Date()))"
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: logFile))
        } catch {}

        super.tearDown()
    }
}
