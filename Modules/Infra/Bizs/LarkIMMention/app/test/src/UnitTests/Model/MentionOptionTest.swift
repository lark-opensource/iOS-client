//
//  MentionOptionTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/2/8.
//

import Foundation
import XCTest
@testable import LarkIMMention

// swiftlint:disable all
final class MentionOptionTest: XCTestCase {
    /*
        所有人选项在群内, 选中后为蓝色
     */
    func testAllChatterInChat() {
        let option = IMPickerOption.all(count: 10)
        XCTAssertTrue(option.isInChat)
    }
}
// swiftlint:enable all
