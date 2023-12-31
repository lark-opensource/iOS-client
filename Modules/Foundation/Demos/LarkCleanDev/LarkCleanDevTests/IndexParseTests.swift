//
//  IndexParseTests.swift
//  LarkCleanDevTests
//
//  Created by 7Up on 2023/7/24.
//

import XCTest
@testable import LarkClean

final class IndexParseTests: XCTestCase {

    func testParsePartialPath() {
        let ctx = CleanContext(userList: [
            .init(userId: "u123", tenantId: "t123"),
            .init(userId: "u456", tenantId: "t456")
        ])
        let kUid = SettingParams.userId.rawValue
        let kTid = SettingParams.tenantId.rawValue
        let results = CleanRegistry.debugParsePartialPath(with: [
            "a/b/c",                    // without uid or tid
            "b/\(kUid)/b/c",            // uid
            "c/\(kTid)/b/c",            // tid
            "d/\(kUid)/\(kTid)/b/c",    // uid + tid
            "e/\(kTid)/\(kUid)/b/c",    // tid + uid
            "f/\(kUid)/\(kUid)/b/c",    // uid + uid
            "g/\(kTid)/\(kTid)/b/c",    // tid + tid
        ], context: ctx)

        let expected: [String] = [
            "a/b/c",                    // without uid or tid

            "b/u123/b/c",               // uid
            "b/u456/b/c",               // uid

            "c/t123/b/c",               // tid
            "c/t456/b/c",               // tid

            "d/u123/t123/b/c",          // uid + tid
            "d/u456/t456/b/c",          // uid + tid


            "e/t123/u123/b/c",          // tid + uid
            "e/t456/u456/b/c",          // tid + uid

            "f/u123/u123/b/c",          // uid + uid
            "f/u456/u456/b/c",          // uid + uid

            "g/t123/t123/b/c",          // tid + tid
            "g/t456/t456/b/c",          // tid + tid
        ]

         XCTAssert(results.sorted() == expected)
    }

}
