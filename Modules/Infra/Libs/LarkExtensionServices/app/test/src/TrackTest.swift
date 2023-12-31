//
//  TrackTest.swift
//  LarkExtensionServicesDevEEUnitTest
//
//  Created by 王元洵 on 2021/4/2.
//

import Foundation
import XCTest
@testable import LarkExtensionServices

class TrackTest: XCTestCase {
    let extensionEventListKey = "lark.extenisons.events"

    override func setUp() {
        super.setUp()

        ExtensionTracker.shared.maxTracks = 0
    }

//    func testTeaTrack() {
//        let expectation = XCTestExpectation(description: "test")
//        ExtensionTracker.shared.trackTeaEvent(key: "test TEA", params: ["testparam": "testparam"])
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//            guard let self = self else { return }
//            var events = UserDefaults.standard.array(forKey: self.extensionEventListKey) as? [[String: Any]]
//            let event = events?.popLast()
//            XCTAssertEqual(event?["type"] as? String ?? "", "TEA")
//            XCTAssertEqual(event?["key"] as? String ?? "", "test TEA")
//            XCTAssertEqual((event?["params"] as? [String: Any])?["testparam"] as? String ?? "", "testparam")
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 2)
//    }
//
//    func testSlardarTrack() {
//        let expectation = XCTestExpectation(description: "test")
//        ExtensionTracker.shared.trackSlardarEvent(key: "test Slardar",
//                                                  metric: ["testparam": "testparam"],
//                                                  category: ["testparam": "testparam"],
//                                                  params: ["testparam": "testparam"])
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//            guard let self = self else { return }
//            var events = UserDefaults.standard.array(forKey: self.extensionEventListKey) as? [[String: Any]]
//            let event = events?.popLast()
//            XCTAssertEqual(event?["type"] as? String ?? "", "Slardar")
//            XCTAssertEqual(event?["key"] as? String ?? "", "test Slardar")
//            XCTAssertEqual((event?["params"] as? [String: Any])?["testparam"] as? String ?? "", "testparam")
//            XCTAssertEqual((event?["metric"] as? [String: Any])?["testparam"] as? String ?? "", "testparam")
//            XCTAssertEqual((event?["category"] as? [String: Any])?["testparam"] as? String ?? "", "testparam")
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 2)
//    }

    override func tearDown() {
        UserDefaults.standard.setValue([], forKey: extensionEventListKey)

        super.tearDown()
    }
}
