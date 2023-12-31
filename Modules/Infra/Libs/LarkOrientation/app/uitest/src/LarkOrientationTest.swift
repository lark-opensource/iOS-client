//
//  LarkOrientationTest.swift
//  LarkOrientationDev
//
//  Created by 李晨 on 2020/3/23.
//

import UIKit
import Foundation
import XCTest
@testable import LarkOrientation

class KeyCommandKitTest: XCTestCase {

    override func setUp() {
        Orientation.swizzledIfNeeed()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testVCExtension() {
        let vc = UIViewController()
        vc.orientationAutorotate = true
        vc.supportOrientations = .landscape
        vc.preferredOrientationForPresentation = .landscapeLeft

        XCTAssert(vc.shouldAutorotate)
        XCTAssert(vc.supportedInterfaceOrientations == .landscape)
        XCTAssert(vc.preferredInterfaceOrientationForPresentation == .landscapeLeft)
    }

    func testDefaultSetting() {
        Orientation.defaultAutorotate = true
        Orientation.defaultOrientations = .landscapeRight
        Orientation.defaultOrientationForPresentation = .landscapeRight

        let vc = UIViewController()
        XCTAssert(vc.shouldAutorotate)
        XCTAssert(vc.supportedInterfaceOrientations == .landscapeRight)
        XCTAssert(vc.preferredInterfaceOrientationForPresentation == .landscapeRight)
    }

    func testPatch() {
        Orientation.add(patches: [
            Orientation.Patch(
                identifier: "test",
                description: "",
                options: [
                    .shouldAutorotate(true),
                    .supportedInterfaceOrientations(.portrait),
                    .preferredInterfaceOrientationForPresentation(.landscapeLeft)
                ], matcher: { (vc) -> Bool in
                    return vc is TestViewController
            })
        ])
        let vc = TestViewController()
        XCTAssert(vc.shouldAutorotate)
        XCTAssert(vc.supportedInterfaceOrientations == .portrait)
        XCTAssert(vc.preferredInterfaceOrientationForPresentation == .landscapeLeft)
    }

}

class TestViewController: UIViewController {

}
