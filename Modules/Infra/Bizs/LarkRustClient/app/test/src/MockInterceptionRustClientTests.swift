//
//  MockInterceptionRustClientTests.swift
//  LarkRustClientDevEEUnitTest
//
//  Created by bytedance on 2020/5/22.
//

import Foundation
import XCTest
import RustPB
import SwiftProtobuf
import RxSwift
@testable import LarkRustClient

class MockInterceptionRustClientTests: XCTestCase {
    func testCommandsIntercepted() {
        let bag = DisposeBag()

        let storagePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let config = RustClientConfiguration(identifier: "testid",
                                             storagePath: storagePath,
                                             version: "0.1",
                                             userAgent: "iPhone",
                                             envV2: .init(),
                                             appId: "testAppId",
                                             localeIdentifier: "localeId",
                                             clientLogStoragePath: "testLog.log",
                                             domainInitConfig: DomainInitConfig())
        let commands: [Basic_V1_Command] = [ .pushLoadFeedCardsStatus, .pushInboxCards ]
        let client = MockInterceptionRustClient(configuration: config, commands: commands)

        client.register(pushCmd: .pushLoadFeedCardsStatus) { _ in
            //
        }.disposed(by: bag)

        client.register(pushCmd: .pushFeedCursor) { _ in
            //
        }.disposed(by: bag)

        XCTAssert(MockInterceptionManager.shared.getRegisteredHandlersCount() == 1,
                  "There should be only one handler registered.")

        client.unregisterPushHanlders()

        XCTAssert(MockInterceptionManager.shared.getRegisteredHandlersCount() == 0, "It should be cleared.")
    }
}
