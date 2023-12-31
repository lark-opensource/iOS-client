//
//  PopSelfTests.swift
//  EENavigatorDevEEUnitTest
//
//  Created by liuwanlin on 2018/12/29.
//

import UIKit
import Foundation
import XCTest
@testable import EENavigator

class PopSelfTests: XCTestCase {

    func testPopSelf() {
        let expectation = XCTestExpectation(description: "testPopSelfWithPresent")
        let vc1 = UIViewController()
        let nvc = UINavigationController(rootViewController: vc1)
        UIApplication.shared.keyWindow?.rootViewController = nvc

        let vc2 = UIViewController()
        nvc.pushViewController(vc2, animated: false)

        let vc3 = UIViewController()
        nvc.pushViewController(vc3, animated: false)

        let vc4 = UIViewController()
        nvc.pushViewController(vc4, animated: false)

        vc2.popSelf(animated: false) {
            XCTAssert(nvc.viewControllers.count == 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testPopSelfWithPresent() {
        let expectation = XCTestExpectation(description: "testPopSelfWithPresent")
        let vc1 = UIViewController()
        let nvc = UINavigationController(rootViewController: vc1)
        UIApplication.shared.keyWindow?.rootViewController = nvc

        let vc2 = UIViewController()
        nvc.pushViewController(vc2, animated: false)

        let vc3 = UIViewController()
        nvc.pushViewController(vc3, animated: false)

        let vc4 = UIViewController()
        nvc.pushViewController(vc4, animated: false)

        let vc5 = UIViewController()
        vc4.present(vc5, animated: false, completion: nil)
        XCTAssert(nvc.presentedViewController == vc5)

        vc2.popSelf(animated: false, dismissPresented: true) {
            print("hhh", nvc.viewControllers.count)
            XCTAssert(nvc.viewControllers.count == 1)
            XCTAssert(nvc.presentedViewController == nil)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }
}
