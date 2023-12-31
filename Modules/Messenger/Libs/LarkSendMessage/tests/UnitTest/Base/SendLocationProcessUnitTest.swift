//
//  SendLocationProcessUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/6.
//

import XCTest
import Foundation
import ByteWebImage // jpegImageInfo

/// SendLocationProcess新增单测
final class SendLocationProcessUnitTest: CanSkipTestCase {
    /// image需要持有，不然调用jpegImageInfo时会释放（为啥会释放不清楚）
    private let image = Resources.image(named: "1200x1400-PNG")

    func testJpegImageInfo() {
        let result: ImageSourceResult = self.image.jpegImageInfo()
        XCTAssertEqual(result.sourceType, .jpeg)
        XCTAssertNotNil(result.data)
        XCTAssertNotNil(result.image)
        XCTAssertNotNil(result.compressCost)
    }
}
