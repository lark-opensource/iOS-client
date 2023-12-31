//
//  UDNoticeTests.swift
//  UniverseDesignNotice
//
//  Created by 龙伟伟 on 2020/11/20.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignNotice
import UniverseDesignColor

class UDNoticeTests: XCTestCase {

    var notice: UDNotice?

    override func setUp() {
        super.setUp()

        let config = UDNoticeUIConfig(type: .info,
                                      attributedText: NSAttributedString(string: "是一条常规提示的文本信息"))
        let notice = UDNotice(config: config)
        self.notice = notice
    }

    override func tearDown() {
        super.tearDown()

        notice = nil
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Test Notice config
    func testUpdateConfig() {
        let newConfig = UDNoticeUIConfig(type: .success,
                                         attributedText: NSAttributedString(string: "是一条成功提示的文本信息"))
        self.notice?.updateConfigAndRefreshUI(newConfig)

        if let notice = self.notice {
            XCTAssertEqual(notice.backgroundColor, UDNoticeColorTheme.noticeSuccessBgColor)
        }
    }
}
