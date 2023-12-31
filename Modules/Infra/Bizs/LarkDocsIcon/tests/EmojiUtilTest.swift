//
//  EmojiUtilTest.swift
//  LarkDocsIcon-Unit-Tests
//
//  Created by huangzhikai on 2023/12/11.
//

import Foundation
import XCTest
@testable import LarkIcon

class EmojiUtilTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetFileInfoNewFrom() {
        var result = EmojiUtil.scannerStringChangeToEmoji(key: "1f636")
        XCTAssertEqual(result, "😶")
    
        result = EmojiUtil.scannerStringChangeToEmoji(key: "1f42f")
        XCTAssertEqual(result, "🐯")
        
        result = EmojiUtil.scannerStringChangeToEmoji(key: "0x11FFFF")
        XCTAssertEqual(result, "")
    }
}
