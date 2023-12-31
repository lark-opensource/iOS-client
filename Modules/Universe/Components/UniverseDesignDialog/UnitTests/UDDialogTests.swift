//
//  UDDialogTests.swift
//  UniverseDesignDialogTests
//
//  Created by 姚启灏 on 2020/11/10.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignDialog
import UniverseDesignColor

class UDDialogTests: XCTestCase {

    var dialog: UDDialog?

    override func setUp() {
        super.setUp()

        let config = UDDialogUIConfig()
        let dialog = UDDialog(config: config)
        self.dialog = dialog
    }

    override func tearDown() {
        super.tearDown()

        dialog = nil
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Test Dialog SetTitle
    func testSetTitle() {
        self.dialog?.setTitle(text: "测试标题")

        if let dialog = self.dialog {
            XCTAssertEqual(dialog.titleLabel?.text, "测试标题")
        }
    }

    /// Test Dialog AddButton
    func testAddNormalButton() {
        self.dialog?.addPrimaryButton(text: "测试按钮")
        if let button = self.dialog?.buttons.first {
            XCTAssertEqual(button.text, "测试按钮")
        }
    }

    /// Test Dialog AddSecondaryButton
    func testAddSecondaryButton() {
        self.dialog?.addSecondaryButton(text: "测试按钮")
        if let button = self.dialog?.buttons.first {
            XCTAssertEqual(button.text, "测试按钮")
            XCTAssertEqual(button.button.currentTitleColor, UIColor.ud.neutralColor12)
        }
    }

    /// Test Dialog AddDestructiveButton
    func testAddDestructiveButton() {
        self.dialog?.addDestructiveButton(text: "测试按钮")
        if let button = self.dialog?.buttons.first {
            XCTAssertEqual(button.text, "测试按钮")
            XCTAssertEqual(button.button.currentTitleColor, UIColor.ud.colorfulRed)
        }
    }

}
