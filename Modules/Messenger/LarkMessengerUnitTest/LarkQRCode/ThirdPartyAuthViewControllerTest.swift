//
//  QRCodeAuthViewControllerTest.swift
//  LarkMessengerUnitTest
//
//  Created by SuPeng on 3/6/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import LarkQRCode
import RxSwift
import RxCocoa
import LarkMessengerInterface

class MockQRCodeAPI: QRCodeAPI {
    var checkTokenForLoginCalled: (() -> Void)?
    var confirmTokenForLoginCalled: (() -> Void)?
    var cancelTokenForLoginCalled: (() -> Void)?

    func checkTokenForLogin(token: String) -> Observable<LoginAuthInfo> {
        let mockResult = LoginAuthInfo(
            displayMessage: "",
            showNotificationOption: false,
            template: LoginAuthInfo.Template(rawValue: "auth"),
            thirdPartyAuthInfo: LoginAuthInfo.ThirdPartyAuthInfo(
                appName: "app name",
                subTitle: "subTitle",
                scopeTitle: "permission scope",
                scopeInfo: [],
                buttonTitle: "confirm"
            ),
            suiteAuthInfo: nil
        )
        checkTokenForLoginCalled?()
        return Observable.just(mockResult)
    }

    func confirmTokenForLogin(token: String) -> Observable<Void> {
        confirmTokenForLoginCalled?()
        return .empty()
    }

    func cancelTokenForLogin(token: String) -> Observable<Void> {
        cancelTokenForLoginCalled?()
        return .empty()
    }
}

class QRCodeAuthViewControllerMockDependency: QRCodeAuthViewControllerDependency {
    let qrcode: QRCodeAPI = MockQRCodeAPI()
    var notifyDisableDriver: Driver<Bool> { return .empty() }
    func updateNotificaitonStatus(notifyDisable: Bool, retry: Int) {}
}

class ThirdPartyAuthViewControllerTest: XCTestCase {

    var dependency: QRCodeAuthViewControllerMockDependency!
    var qrcode: MockQRCodeAPI { return (dependency.qrcode as? MockQRCodeAPI)! }
    var qrCodeAuthVC: ThirdPartyAuthViewController!

    override func setUp() {
        super.setUp()
        dependency = QRCodeAuthViewControllerMockDependency()
        qrCodeAuthVC = ThirdPartyAuthViewController(token: "Test Token",
                                                    bundleId: "Test Message",
                                                    qrCodeAPI: qrcode,
                                                    authInfo: LoginAuthInfo.ThirdPartyAuthInfo(appName: "app name",
                                                                                               subTitle: "subTitle",
                                                                                               scopeTitle: "permission scope",
                                                                                               scopeInfo: [],
                                                                                               buttonTitle: "confirm"))
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
        qrCodeAuthVC.confirmButtonClick(UIButton())
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
