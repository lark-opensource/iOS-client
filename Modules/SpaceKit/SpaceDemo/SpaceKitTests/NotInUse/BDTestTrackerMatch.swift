//
//  BDTestTrackerMatch.swift
//  DocsTests
//
//  Created by huahuahu on 2018/9/27.
//  Copyright © 2018 Bytedance. All rights reserved.
// swiftlint:disable line_length

import XCTest
@testable import SpaceKit
@testable import Docs

class BDTestTrackerMatch: BDTestBase {

    private let jsonString = """
                        [{"event":"dev_performance_stage","probability":0.23,"failName":"test","items":[{"key":"stage","value":"load_url","relation":"equal"},{"key":"file_type","value":"doc","relation":"notEqual"}]},{"event":"dev_performance_stage","probability":-0.23,"failName":"test","items":[]}]
                        """

    let str1 = """
                {"event":"event1","probability":0.23,"failName":"dfads","items":[{"key":"stage","value":"1","relation":"equal"},{"key":"length","value":"0.23","relation":"notEqual"}]}
                """

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMatch() {
        guard let jsonData = jsonString.data(using: .utf8),
            let eventMatchs = try? JSONDecoder().decode([EventMatchItem].self, from: jsonData) else {
                fatalError("cannot decode json data")
        }
        XCTAssertEqual(eventMatchs.count, 2)
        let firstEvent = eventMatchs.first
        XCTAssertNotNil(firstEvent)
        varifyFirstEvent(firstEvent!)

        XCTAssertTrue(firstEvent!.isMatch("dev_performance_stage", params: ["stage": "load_url", "file_type": "sheet"]))
        XCTAssertTrue(firstEvent!.isMatch("dev_performance_stage", params: ["stage": "load_url", "file_type": "sheet", "another": 123]))
        // event 不一样
        XCTAssertFalse(firstEvent!.isMatch("dev_performance_stage1", params: ["stage": "load_url", "file_type": "sheet"]))
        // 有一个key不存在 （不存在 stage）
        XCTAssertFalse(firstEvent!.isMatch("dev_performance_stage", params: ["stage1": "load_url", "file_type": "sheet"]))
        // 有一个key不满足条件 （stage 不满足）
        XCTAssertFalse(firstEvent!.isMatch("dev_performance_stage", params: ["stage": "load_url1", "file_type": "sheet"]))
        // 有一个key不满足 (file_type 不满足)
        XCTAssertFalse(firstEvent!.isMatch("dev_performance_stage", params: ["stage": "load_url", "file_type": "doc"]))

        guard let eventMatch2 = try? JSONDecoder().decode(EventMatchItem.self, from: str1.data(using: .utf8)!) else {
            XCTAssert(false, "decode fail")
            fatalError("cannot decode json data")
        }
        XCTAssertTrue(eventMatch2.isMatch("event1", params: ["stage": "1", "length": "0.24"]))
        XCTAssertTrue(eventMatch2.isMatch("event1", params: ["stage": 1, "length": 0.24]))
        // 1.0 -> "1.0" 和 "1" 不一样
        XCTAssertFalse(eventMatch2.isMatch("event1", params: ["stage": 1.0, "length": "0.24"]))
        XCTAssertFalse(eventMatch2.isMatch("event1", params: ["stage": "1.0", "length": "0.24"]))
    }

    func testEncode() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let jsonData = jsonString.data(using: .utf8),
            let eventMatchs = try? JSONDecoder().decode([EventMatchItem].self, from: jsonData) else {
            fatalError("cannot decode json data")
        }
        XCTAssertEqual(eventMatchs.count, 2)
        let firstEvent = eventMatchs.first
        XCTAssertNotNil(firstEvent)
        varifyFirstEvent(firstEvent!)

        let lastEvent = eventMatchs.last
        XCTAssertNotNil(lastEvent)
        varifySecondEvent(lastEvent!)

        guard let eventMatch2 = try? JSONDecoder().decode(EventMatchItem.self, from: str1.data(using: .utf8)!) else {
            XCTAssert(false, "decode fail")
            fatalError("cannot decode json data")
        }
        varifyThirdEvent(eventMatch2)
    }

    func testNoPrelad() {
        let str1 = """
            {"event":"dev_performance_stage","probability":1,"failName":"nopreload","items":[{"key":"file_type","value":"doc","relation":"equal"},{"key":"stage","value":"load_url","relation":"equal"},{"key":"doc_timeSince_sdk_init","value":"30","relation":"bigger"},{"key":"docs_open_type","value":"pull","relation":"equal"}]}
            """
        guard let jsonData = str1.data(using: .utf8),
            let eventMatch = try? JSONDecoder().decode(EventMatchItem.self, from: jsonData) else {
                fatalError("cannot decode json data")
        }
        XCTAssertTrue(eventMatch.isMatch("dev_performance_stage", params: ["file_type": "doc", "docs_open_type": "pull", "doc_timeSince_sdk_init": 300.0, "stage": "load_url"]))
        XCTAssertFalse(eventMatch.isMatch("dev_performance_stage", params: ["file_type": "doc", "docs_open_type": "pull", "doc_timeSince_sdk_init": 29, "stage": "load_url"]))
        XCTAssertFalse(eventMatch.isMatch("dev_performance_stage", params: ["file_type": "doc", "docs_open_type": "render", "doc_timeSince_sdk_init": 300, "stage": "load_url"]))

    }

    func testBigger() {
        let str1 = """
                {"event":"event1","probability":0.23,"failName":"dfads","items":[{"key":"stage","value":"1.0","relation":"smaller"}]}
                """
        guard let jsonData = str1.data(using: .utf8),
            let eventMatch = try? JSONDecoder().decode(EventMatchItem.self, from: jsonData) else {
                fatalError("cannot decode json data")
        }
        XCTAssertTrue(eventMatch.isMatch("event1", params: ["stage": 0.9, "length": "0.24"]))
        XCTAssertFalse(eventMatch.isMatch("event1", params: ["stage": 1.0, "length": "0.24"]))
        XCTAssertFalse(eventMatch.isMatch("event1", params: ["stage": 1.1, "length": "0.24"]))
        XCTAssertFalse(eventMatch.isMatch("event1", params: ["stage": "234s", "length": "0.24"]))
        XCTAssertFalse(eventMatch.isMatch("event12", params: ["stage": 1.1, "length": "0.24"]))

        let str11 = """
                {"event":"event1","probability":0.23,"failName":"dfads","items":[{"key":"stage","value":"-300","relation":"smaller"}]}
                """
        guard let jsonData1 = str11.data(using: .utf8),
            let eventMatch1 = try? JSONDecoder().decode(EventMatchItem.self, from: jsonData1) else {
                fatalError("cannot decode json data")
        }
        XCTAssertTrue(eventMatch1.isMatch("event1", params: ["stage": -301, "length": "0.24"]))
        XCTAssertFalse(eventMatch1.isMatch("event1", params: ["stage": -300, "length": "0.24"]))
        XCTAssertFalse(eventMatch1.isMatch("event1", params: ["stage": "234s", "length": "0.24"]))

        let str13 = """
                {"event":"event1","probability":0.23,"failName":"dfads","items":[{"key":"stage","value":"-300","relation":"smaller"},{"key":"stage","value":"-306","relation":"bigger"}]}
                """
        guard let jsonData3 = str13.data(using: .utf8),
            let eventMatch3 = try? JSONDecoder().decode(EventMatchItem.self, from: jsonData3) else {
                fatalError("cannot decode json data")
        }
        XCTAssertTrue(eventMatch3.isMatch("event1", params: ["stage": -301, "length": "0.24"]))
        XCTAssertTrue(eventMatch3.isMatch("event1", params: ["stage": -302, "length": "0.24"]))
        XCTAssertFalse(eventMatch3.isMatch("event1", params: ["stage": -300, "length": "0.24"]))
        XCTAssertFalse(eventMatch3.isMatch("event1", params: ["stage": -306, "length": "0.24"]))
        XCTAssertFalse(eventMatch3.isMatch("event1", params: ["stage": -566, "length": "0.24"]))
    }

    private func varifyFirstEvent(_ eventMatch: EventMatchItem) {
        XCTAssertEqual(eventMatch.event, "dev_performance_stage")
        XCTAssertEqual(eventMatch.items.count, 2)
        let param1 = eventMatch.items[0]
        XCTAssertEqual(param1.key, "stage")
        XCTAssertEqual(param1.value, "load_url")
        XCTAssertEqual(param1.relation.rawValue, "equal")

        let param2 = eventMatch.items[1]
        XCTAssertEqual(param2.key, "file_type")
        XCTAssertEqual(param2.value, "doc")
        XCTAssertEqual(param2.relation.rawValue, "notEqual")
    }

    private func varifySecondEvent(_ eventMatch: EventMatchItem) {
        XCTAssertEqual(eventMatch.event, "dev_performance_stage")
        XCTAssertEqual(eventMatch.items.count, 0)
    }

    private func varifyThirdEvent(_ eventMatch: EventMatchItem) {
        XCTAssertEqual(eventMatch.event, "event1")
        XCTAssertEqual(eventMatch.probability, 0.23)
        XCTAssertEqual(eventMatch.items.count, 2)
        let param1 = eventMatch.items[0]
        XCTAssertEqual(param1.key, "stage")
        XCTAssertEqual(param1.value, "1")
        XCTAssertEqual(param1.relation.rawValue, "equal")

        let param2 = eventMatch.items[1]
        XCTAssertEqual(param2.key, "length")
        XCTAssertEqual(param2.value, "0.23")
        XCTAssertEqual(param2.relation.rawValue, "notEqual")

    }

}
