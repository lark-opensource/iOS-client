//
//  SuiteAuthViewControllerTest.swift
//  LarkMessengerUnitTest
//
//  Created by Miaoqi Wang on 2020/3/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkQRCode
import LarkMessengerInterface
import LarkButton

class SuiteAuthViewControllerTest: XCTestCase {

    var dependency: QRCodeAuthViewControllerMockDependency!
    var qrcode: MockQRCodeAPI { return (dependency.qrcode as? MockQRCodeAPI)! }
    var qrCodeAuthVC: SuiteAuthViewController!

    override func setUp() {
        super.setUp()
        dependency = QRCodeAuthViewControllerMockDependency()
        qrCodeAuthVC = SuiteAuthViewController(token: "test token",
                                               bundleId: "test bundle",
                                               showNotificationOption: false,
                                               displayMessage: "Confirm login to Feishu App",
                                               dependency: dependency)
        qrCodeAuthVC.viewDidLoad()
    }

    override func tearDown() {
        super.tearDown()
        dependency = nil
        qrCodeAuthVC = nil
    }

    func testConfirmTokenForLoginCalledWhenConfirmButtonClicked() {
        var called: Bool = false
        qrcode.confirmTokenForLoginCalled = {
            called = true
        }
        qrCodeAuthVC.confirmButtonClick(TypeButton())
        XCTAssertTrue(called)
    }

    func testCancelTokenForLoginCalledWhenCloaseButtonClicked() {
        var called: Bool = false
        qrcode.cancelTokenForLoginCalled = {
            called = true
        }
        qrCodeAuthVC.closeBtnClick()
        XCTAssertTrue(called)
    }

}
