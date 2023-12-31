//
//  LarkQRCodeAssemblyTest.swift
//  LarkMessengerUnitTest
//
//  Created by CharlieSu on 3/15/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkQRCode
import Swinject
import LarkRustClient
import LarkMessengerInterface
import EENavigator
@testable import AppContainer
import LarkContainer
import QRCode

class LarkQRCodeAssemblyTest: XCTestCase {

    var assembly: QRCodeAssembly!
    var container: Container!
    override func setUp() {
        super.setUp()
        Navigator.resetSharedNavigator()

        container = Container()
        container.register(RustService.self, factory: { _ in SimpleRustClient() })

        assembly = QRCodeAssembly()
        assembly.assembleService(container: container)

        _ = Assembler([], container: container)

        implicitResolver = container.synchronize()
    }

    override func tearDown() {
        super.tearDown()
        assembly = nil
    }

    func test_services_is_assembled() {
        // guard RustQRCodeAPI is assembled
        XCTAssertNotNil(container.resolve(QRCodeAPI.self))

        // guard QRCodeAnalysisService is assembled
        XCTAssertNotNil(container.resolve(QRCodeAnalysisService.self))
    }

    func test_request_handler_is_assembled() {
        assembly.assembleRequestHandler(container: container)

        let qrcodeBody = QRCodeControllerBody()
        XCTAssert(Navigator.shared.response(for: qrcodeBody).resource! is QRCodeViewController)

        let ssoBody = SSOVerifyBody(qrCode: "", bundleId: "")
        XCTAssert(Navigator.shared.response(for: ssoBody).resource! is CheckAuthTokenViewController)

        let suiteAuthBody = QRCodeAuthControllerBody(
            token: "",
            loginAuthInfo: LoginAuthInfo(
                displayMessage: "",
                showNotificationOption: false,
                template: LoginAuthInfo.Template(rawValue: "suite"),
                thirdPartyAuthInfo: nil,
                suiteAuthInfo: LoginAuthInfo.SuiteAuthInfo(
                    appName: "app name",
                    subTitle: "subTitle"
                )
            )
        )
        XCTAssert(Navigator.shared.response(for: suiteAuthBody).resource is SuiteAuthViewController)

        let thirdPartyAuthBody = QRCodeAuthControllerBody(
            token: "",
            loginAuthInfo: LoginAuthInfo(
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
        )
        XCTAssert(Navigator.shared.response(for: thirdPartyAuthBody).resource is ThirdPartyAuthViewController)
    }

    func test_application_delegate_is_assembled() {
        if BootLoader.shared.context == nil {
            BootLoader.shared.context = AppInnerContext(config: .default, container: container)
        }
        assembly.assembleApplicationDelegate()
        XCTAssert(
            BootLoader.shared.context!.applicationsRegistery.contains(where: { $0.type == ForceTouchApplicationDelegate.self && $0.config.name == ForceTouchApplicationDelegate.config.name })
        )
    }
}
