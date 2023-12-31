//
//  MockInterceptionManagerTests.swift
//  LarkRustClientDevEEUnitTest
//
//  Created by bytedance on 2020/5/22.
//

import Foundation
import XCTest
import RustPB
import SwiftProtobuf
@testable import LarkRustClient

class MockInterceptionManagerTests: XCTestCase {

    var expectedMessage: Message?

    func testPostMessageSuccessfully() {
        var message = Feed_V1_PushShortcutsResponse()

        var shortcuts = [Feed_V1_Shortcut]()

        for i in 0..<3 {
            var shortcut = Feed_V1_Shortcut()
            shortcut.channel.type = Basic_V1_Channel.TypeEnum.chat
            shortcut.channel.id = "Shortcut#\(i)"
            shortcut.position = Int32(i)
            shortcuts.append(shortcut)
        }

        message.shortcuts = shortcuts

        self.expectedMessage = message

        MockInterceptionManager.shared.registerCommand(cmd: .pushShortcuts) { data in
            do {
                let message = try Feed_V1_PushShortcutsResponse(serializedData: data,
                                                                options: .discardUnknownFieldsOption)
                let expect = self.expectedMessage as? Feed_V1_PushShortcutsResponse
                XCTAssert(message == expect, "Message input should match")
            } catch {
                XCTAssert(false, "This should not happend.")
            }
        }

        MockInterceptionManager.shared.postMessage(command: .pushShortcuts, message: self.expectedMessage!)

        // clean up
        cleanup()
    }

    func testPostMessageFailure() {
        var message = Feed_V1_PushLoadFeedCardsStatus()
        message.feedType = .inbox
        message.status = .start
        self.expectedMessage = message

        MockInterceptionManager.shared.registerCommand(cmd: .pushLoadFeedCardsStatus) { data in
            do {
                let message = try Feed_V1_PushLoadFeedCardsStatus(serializedData: data,
                                                                  options: .discardUnknownFieldsOption)
                let expect = self.expectedMessage as? Feed_V1_PushLoadFeedCardsStatus

                XCTAssert(message != expect, "Why they are matched...")
            } catch {
                XCTAssert(false, "This should not happend.")
            }
        }

        MockInterceptionManager.shared.postMessage(command: .pushLoadFeedCardsStatus, message: Feed_V1_Cursor())

        cleanup()
    }

    private func cleanup() {
        MockInterceptionManager.shared.unregisterCommands()
        self.expectedMessage = nil
    }
}
