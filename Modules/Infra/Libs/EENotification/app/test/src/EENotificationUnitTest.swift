//
//  suibian.swift
//  EENotificationDevEEUnitTest
//
//  Created by 姚启灏 on 2018/12/10.
//

import UIKit
import Foundation
import XCTest
import UserNotifications
@testable import EENotification

class EENotificationTest: XCTestCase {

    override func setUp() {
        super.setUp()

//        let application = UIApplication.shared
//        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (granted, _) in
//            if granted {
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            }
//        }
//
//        var nowNotification = NotificationRequest(group: "", identifier: "nowNotification", userInfo: [:], trigger: nil)
//        nowNotification.title = "test0"
//        nowNotification.body = "nowNotification"
//
//        NotificationManager.shared.addOrUpdateNotification(request: nowNotification)
//
//        var now1Notification1 = NotificationRequest(group: "", identifier: "now1Notification1", userInfo: [:], trigger: nil)
//        now1Notification1.title = "test1"
//        now1Notification1.body = "nowNotification"
//
//        NotificationManager.shared.addOrUpdateNotification(request: now1Notification1)
//
//        var nowNotification2 = NotificationRequest(group: "", identifier: "nowNotification2", userInfo: [:], trigger: nil)
//        nowNotification2.title = "test2"
//        nowNotification2.body = "nowNotification"
//
//        NotificationManager.shared.addOrUpdateNotification(request: nowNotification2)
//        var nowNotification3 = NotificationRequest(group: "", identifier: "nowNotification3", userInfo: [:], trigger: nil)
//        nowNotification3.title = "test3"
//        nowNotification3.body = "nowNotification"
//
//        NotificationManager.shared.addOrUpdateNotification(request: nowNotification3)
//
//        let notificationTrigger = NotificationTrigger(fireDate: Date(timeIntervalSinceNow: 5))
//        var triggerNotification = NotificationRequest(group: "", identifier: "triggerNotification", userInfo: [:], trigger: notificationTrigger)
//        triggerNotification.title = "test4"
//        triggerNotification.body = "triggerNotification"
//
//        NotificationManager.shared.addOrUpdateNotification(request: triggerNotification)

    }

    override func tearDown() {
//        NotificationManager.shared.removeAllNotifications()
    }

//    func testGetAllNotifications() {
//        let expectation = XCTestExpectation(description: "getAllNotifications")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            NotificationManager.shared.getAllNotifications { (notifications) in
//                XCTAssert(
//                    notifications.count == 1
//                )
//                if let first = notifications.first {
//                    XCTAssert(
//                        first.userInfo[NotificationUserInfoKey.identifier] as? String == "triggerNotification"
//                    )
//                }
//                expectation.fulfill()
//            }
//        }
//        wait(for: [expectation], timeout: 3)
//    }

//    func testGetDeliveredNotifications() {
//        let expectation = XCTestExpectation(description: "getDeliveredNotifications")
//        var nowNotification = NotificationRequest(group: "", identifier: "111", userInfo: [:], trigger: nil)
//        nowNotification.title = "test"
//        nowNotification.body = "nowNotification"
//
//        NotificationManager.shared.addOrUpdateNotification(request: nowNotification)
//
//        NotificationManager.shared.getDeliveredNotifications { (notifications) in
//            XCTAssert(
//                notifications.count == 4
//            )
//            if let first = notifications.first {
//                XCTAssert(
//                    first.userInfo[NotificationUserInfoKey.identifier] as? String == "nowNotification"
//                )
//            }
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 3)
//    }
//
//    func testGetPendingNotifications() {
//        let expectation = XCTestExpectation(description: "getPendingNotifications")
//        NotificationManager.shared.getPendingNotifications { (notifications) in
//            XCTAssert(
//                notifications.count == 0
//            )
//            if let first = notifications.first {
//                XCTAssert(
//                    first.userInfo[NotificationUserInfoKey.identifier] as? String == "triggerNotification"
//                )
//            }
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 3)
//    }
//
//    func testRemovePendingNotifications() {
//        let expectation = XCTestExpectation(description: "getPendingNotifications")
//
//        NotificationManager.shared.getPendingNotifications { (notifications) in
//            XCTAssert(
//                notifications.count == 0
//            )
//            if let first = notifications.first {
//                XCTAssert(
//                    first.userInfo[NotificationUserInfoKey.identifier] as? String == "111"
//                )
//            }
//        }
//
//        NotificationManager.shared.removePendingNotifications()
//
//        NotificationManager.shared.getPendingNotifications { (notifications) in
//            XCTAssert(
//                notifications.count == 0
//            )
//            expectation.fulfill()
//        }
//
//        wait(for: [expectation], timeout: 3)
//    }

}
