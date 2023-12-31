//
//  LarkQRCodeTest.swift
//  LarkMessengerUnitTest
//
//  Created by SuPeng on 3/4/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import AppContainer
@testable import LarkQRCode
import Swinject
import LarkMessengerInterface
import EENavigator

class LarkQRCodeTest: XCTestCase {

    var container: Container!
    var context: AppContext!
    var forceTouchDele: ForceTouchApplicationDelegate!

    override func setUp() {
        super.setUp()
        Navigator.resetSharedNavigator()
        container = Container()
        context = AppInnerContext(config: .default, container: container)
        forceTouchDele = ForceTouchApplicationDelegate(context: context)
    }

    override func tearDown() {
        super.tearDown()
        container = nil
        context = nil
        Navigator.shared.deregisterRoute(QRCodeControllerBody.pattern)
    }

    func testForceTouchDelegate() {
        let expectation = XCTestExpectation(description: "QRCodeControllerBody handler called")
        Navigator.shared.registerRoute(type: QRCodeControllerBody.self) { (_, _, _) in
            expectation.fulfill()
        }
        let item = ShortcutItemsType.scan.shortCutItem()
        context.dispatcher.send(message: PerformAction(shortcutItem: item,
                                                       context: context,
                                                       completionHandler: { _ in }))
        wait(for: [expectation], timeout: 1.0)
    }
}
