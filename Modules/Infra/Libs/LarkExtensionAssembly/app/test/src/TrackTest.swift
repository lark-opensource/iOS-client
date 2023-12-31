//
//  TrackTest.swift
//  LarkExtensionAssemblyDevEEUnitTest
//
//  Created by 王元洵 on 2021/4/2.
//

import Foundation
import XCTest
@testable import LarkExtensionAssembly
@testable import LarkExtensionServices

class CleanTrackTests: XCTestCase {
    class TestPoster: Poster {
        var shouldPost: [[String: Any]] = []

        func postTeaEvent(_ event: [String: Any]) {
            shouldPost.append(event)
        }

        func postSlardarEvent(_ event: [String: Any]) {
            shouldPost.append(event)
        }
    }

    private let extensionEventListKey = "lark.extenisons.events"

    func testPost() {
        let testPoster = TestPoster()
        ExtensionTrackPoster.poster = testPoster
        ExtensionTrackPoster.extensionUserDefaults = .standard

        ExtensionTracker.shared.maxTracks = 0
        ExtensionTracker.shared.trackTeaEvent(key: "TEA Key", params: ["TEA params": "some params"])
        ExtensionTracker.shared.trackSlardarEvent(key: "Slardar Key",
                                                  metric: ["Slardar metric": "some metric"],
                                                  category: ["Slardar category": "some category"],
                                                  params: ["Slardar params": "some params"])

        let expectation = XCTestExpectation(description: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ExtensionTrackPoster.post()

            XCTAssertEqual(testPoster.shouldPost.count, 2)

            let teaEvent = testPoster.shouldPost.first
            XCTAssertEqual(teaEvent?["key"] as? String, "TEA Key")
            let teaParams = teaEvent?["params"] as? [String: String]
            XCTAssertEqual(teaParams?["TEA params"], "some params")

            let slardarEvent = testPoster.shouldPost.last
            XCTAssertEqual(slardarEvent?["key"] as? String, "Slardar Key")
            let slardarParams = slardarEvent?["params"] as? [String: Any]
            XCTAssertEqual(slardarParams?["Slardar params"] as? String, "some params")
            let slardarMertric = slardarEvent?["metric"] as? [String: String]
            XCTAssertEqual(slardarMertric?["Slardar metric"], "some metric")
            let slardarCategory = slardarEvent?["category"] as? [String: String]
            XCTAssertEqual(slardarCategory?["Slardar category"], "some category")

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    override func tearDown() {
        UserDefaults.standard.setValue([], forKey: extensionEventListKey)

        super.tearDown()
    }
}
