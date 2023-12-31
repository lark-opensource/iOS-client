//
//  KeyCommandKitTest.swift
//  LarkKeyCommandKitDevEEUnitTest
//
//  Created by 李晨 on 2020/3/20.
//

import UIKit
import Foundation
import XCTest
@testable import LarkKeyCommandKit

class KeyCommandKitTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testGlobalCommands() {
        let aCommand = KeyCommandBaseInfo(
            input: "A", modifierFlags: .command
        ).binding {
            print("123")
        }
        let bCommand = KeyCommandBaseInfo(
            input: "B", modifierFlags: .command
        ).binding {
            print("123")
        }

        KeyCommandKit.shared.register(
            keyBinding: aCommand
        )
        KeyCommandKit.shared.register(
            keyBinding: bCommand
        )
        assert(KeyCommandKit.shared.globalKeyCommands.values.contains(aCommand))
        assert(KeyCommandKit.shared.globalKeyCommands.values.contains(bCommand))
        KeyCommandKit.shared.unregister(keyBinding: aCommand)
        KeyCommandKit.shared.unregister(keyBinding: bCommand)
        assert(!KeyCommandKit.shared.globalKeyCommands.values.contains(aCommand))
        assert(!KeyCommandKit.shared.globalKeyCommands.values.contains(bCommand))
    }

    func testVCCommands() {
        if let weakWindow = UIApplication.shared.delegate?.window,
            var window = weakWindow {
            let nav = TestNavController(rootViewController: TestController())
            let originRoot = window.rootViewController
            window.rootViewController = nav

            if #available(iOS 13.0, *) {
                assert(KeyCommandKit.shared.keyCommands().count == 3)
            } else {
                assert(KeyCommandKit.shared.keyCommands().count == 2)
            }
            window.rootViewController = originRoot
        }
    }

}

class TestNavController: UINavigationController {
    @objc
    override func keyCommandContainers() -> [LarkKeyCommandKit.KeyCommandContainer] {
        return self.topViewController?.keyCommandContainers() ?? []
    }
}

class TestController: UIViewController {
    var testView = TestView()

    @objc
    override func keyBindings() -> [LarkKeyCommandKit.KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "B", modifierFlags: .command
            ).binding {
                print("123")
            }.wraper
        ]
    }

    @objc
    override func subProviders() -> [LarkKeyCommandKit.KeyCommandProvider] {
        return super.subProviders() + [self.testView]
    }
}

class TestView: UIView {
    @objc
    override func keyBindings() -> [LarkKeyCommandKit.KeyBindingWraper] {

        if #available(iOS 13.0, *) {
            return [
                KeyCommandInfo(
                    title: "123", input: "A", modifierFlags: .command
                ).binding {
                    print("123")
                }.wraper,
                KeyCommandInfo(
                    title: "123", input: "A", modifierFlags: .shift
                ).binding {
                    print("123")
                }.wraper
            ]
        } else {
            return [
                KeyCommandBaseInfo(
                    input: "A", modifierFlags: .command
                ).binding {
                    print("123")
                }.wraper
            ]
        }
    }
}
