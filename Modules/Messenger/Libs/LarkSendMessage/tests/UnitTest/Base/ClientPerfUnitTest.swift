//
//  ClientPerfUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/5.
//

import XCTest
import Foundation
import LarkPerf // ClientPerf

/// ClientPerf新增单测，还没想好怎么写
final class ClientPerfUnitTest: CanSkipTestCase {
    func testTemp() {
        XCTAssertNotNil(ClientPerf.shared)
    }
}
