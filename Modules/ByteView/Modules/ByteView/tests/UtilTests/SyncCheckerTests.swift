//
//  SyncCheckerTests.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/11/2.
//

import XCTest
@testable import ByteView
@testable import ByteViewMeeting

final class SyncCheckerTests: XCTestCase {

    func testSyncCheck() {
        var isRustMutedOrUnavailable = true
        var isRtcMutedOrUnavailable = true
        let stubs = (1..<10).map { Stub(id: $0) }
        for stub in stubs {
            stub.isMicMuted = true
        }

        // case 1: Rust、RTC、所有 UI 都一致时检查应该成功
        var result = DeviceSyncChecker.doCheck(isRustMutedOrUnavailable: isRustMutedOrUnavailable, isRtcMutedOrUnavailable: isRtcMutedOrUnavailable, uiMutes: stubs.map { $0.isMicMuted })
        XCTAssertTrue(result.isConsistant)
        XCTAssertTrue(result.isUIConsistant)
        XCTAssertTrue(result.isRtcConsistant)

        // case 2: Rust 与 Rtc 不一致监测失败
        isRtcMutedOrUnavailable = false
        result = DeviceSyncChecker.doCheck(isRustMutedOrUnavailable: isRustMutedOrUnavailable, isRtcMutedOrUnavailable: isRtcMutedOrUnavailable, uiMutes: stubs.map { $0.isMicMuted })
        XCTAssertFalse(result.isConsistant)
        XCTAssertTrue(result.isUIConsistant)
        XCTAssertFalse(result.isRtcConsistant)

        // case 3: 任意一项 UI 状态不符，监测失败
        isRtcMutedOrUnavailable = true
        stubs[1].isMicMuted = false
        result = DeviceSyncChecker.doCheck(isRustMutedOrUnavailable: isRustMutedOrUnavailable, isRtcMutedOrUnavailable: isRtcMutedOrUnavailable, uiMutes: stubs.map { $0.isMicMuted })
        XCTAssertFalse(result.isConsistant)
        XCTAssertFalse(result.isUIConsistant)
        XCTAssertTrue(result.isRtcConsistant)
    }

    private class Stub: MicrophoneStateRepresentable {
        var micIdentifier: String { "Stub_\(id)" }

        var isMicMuted: Bool?

        let id: Int
        init(id: Int) {
            self.id = id
        }
    }
}
