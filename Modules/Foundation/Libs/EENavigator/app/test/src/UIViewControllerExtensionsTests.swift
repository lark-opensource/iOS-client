//
//  UIViewControllerExtensionsTests.swift
//  EENavigatorDemoTests
//
//  Created by liuwanlin on 2018/9/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import EENavigator

class UIViewControllerExtensionsTests: XCTestCase {

    override class func setUp() {
        UIViewController.hook()
    }

    func testUIViewControllerExtensions() {
        let vcFeed = UIViewController()
        let tabFeed = UINavigationController(rootViewController: vcFeed)
        tabFeed.identifier = "/tab/feed"

        let vcCalendar = UIViewController()
        let tabCalendar = UINavigationController(rootViewController: vcCalendar)
        tabCalendar.identifier = "/tab/calendar"

        let vcMine = UIViewController()
        let tabMine = UINavigationController(rootViewController: vcMine)
        tabMine.identifier = "/tab/mine"

        let rootViewController = UITabBarController()
        rootViewController.identifier = "/root"
        rootViewController.viewControllers = [tabFeed, tabCalendar, tabMine]

        UIApplication.shared.keyWindow?.rootViewController = rootViewController

        let vcChat = UIViewController()
        vcChat.identifier = "/feed/chat"
        tabFeed.pushViewController(vcChat, animated: false)

        let vcChatSetting = UIViewController()
        vcChatSetting.identifier = "/feed/chat/setting"
        tabFeed.pushViewController(vcChatSetting, animated: false)

        let present = UIViewController()
        present.identifier = "/feed/chat/setting/present"
        vcChatSetting.present(present, animated: false, completion: nil)

        XCTAssert(present.presenter === vcChatSetting)
        XCTAssert(vcChatSetting.presentee === present)

        // Test findAncestor
        var vc = present.findAncestor(by: vcChat.identifier)
        XCTAssert(vc === vcChat)

        vc = present.findAncestor(by: tabFeed.identifier)
        XCTAssert(vc === tabFeed)

        vc = present.findAncestor(by: "/fake")
        XCTAssert(vc == nil)

        // Top most
//        vc = UIViewController.topMost
//        XCTAssert(vc === present)
//
////        present.dismiss(animated: false, completion: nil)
////        vc = UIViewController.topMost
////        XCTAssert(vc === present.dismiss)
//
//        let expectation = XCTestExpectation(description: "Dismiss presented view controller")
//        present.dismiss(animated: false) {
//            vc = UIViewController.topMost
//            XCTAssert(vc === vcChatSetting)
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: 2)
    }
}
