//
//  AppContainerTest.swift
//  AppContainerDevEEUnitTest
//
//  Created by CharlieSu on 3/19/20.
//

import UIKit
import Foundation
import XCTest
@testable import AppContainer
import Swinject

class AppContainerTest: XCTestCase {

    var appDelegate: AppDelegate!
    var demoApplicationDelegate: DemoApplicationDelegate!

    override func setUp() {
        BootLoader.shared = BootLoader()
        BootLoader.shared.context = AppInnerContext(config: .default, container: Container())
        BootLoader.shared.context?.registerApplication(config: DemoApplicationDelegate.config,
                                                       delegate: DemoApplicationDelegate.self)

        appDelegate = AppDelegate()
        demoApplicationDelegate = DemoApplicationDelegate(context: appDelegate.context)
    }

    override func tearDown() {
        appDelegate = nil
    }

    func test_did_become_active_message_dispached() {
        _ = appDelegate.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: DidBecomeActive.self))
    }

    func test_will_resign_active_message_dispached() {
        _ = appDelegate.applicationWillResignActive(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: WillResignActive.self))
    }

    func test_did_enter_background_message_dispached() {
        _ = appDelegate.applicationDidEnterBackground(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: DidEnterBackground.self))
    }

    func test_will_enter_foreground_message_dispached() {
        _ = appDelegate.applicationWillEnterForeground(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: WillEnterForeground.self))
    }

    func test_will_terminate_message_dispached() {
        _ = appDelegate.applicationWillTerminate(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: WillTerminate.self))
    }

    func test_did_receive_memory_warning_message_dispached() {
        _ = appDelegate.applicationDidReceiveMemoryWarning(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: DidReceiveMemoryWarning.self))
    }

    func test_did_register_for_remote_notifications_message_dispached() {
        _ = appDelegate.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: Data())
        XCTAssert(demoApplicationDelegate.messageInvoked(message: DidRegisterForRemoteNotifications.self))
    }

    func test_did_fail_to_register_for_remote_notifications_message_dispached() {
        _ = appDelegate.application(UIApplication.shared, didFailToRegisterForRemoteNotificationsWithError: TestError())
        XCTAssert(demoApplicationDelegate.messageInvoked(message: DidFailToRegisterForRemoteNotifications.self))
    }

    func test_significant_time_change_message_dispached() {
        _ = appDelegate.applicationSignificantTimeChange(UIApplication.shared)
        XCTAssert(demoApplicationDelegate.messageInvoked(message: SignificantTimeChange.self))
    }

    func test_open_url_message_dispached() {
        _ = appDelegate.application(UIApplication.shared, open: URL(string: "abc")!, options: [:])
        XCTAssert(demoApplicationDelegate.messageInvoked(message: OpenURL.self))
    }

    func test_perform_fetch_message_dispached() {
        _ = appDelegate.application(UIApplication.shared, performFetchWithCompletionHandler: { _ in })
        XCTAssert(demoApplicationDelegate.messageInvoked(message: PerformFetch.self))
    }

    func test_perform_action_message_dispached() {
        _ = appDelegate.application(UIApplication.shared,
                                    performActionFor: UIApplicationShortcutItem(type: "", localizedTitle: ""),
                                    completionHandler: { _ in })
        XCTAssert(demoApplicationDelegate.messageInvoked(message: PerformAction.self))
    }

    func test_continue_user_activity_message_dispached() {
        _ = appDelegate.application(UIApplication.shared,
                                    continue: NSUserActivity(activityType: "test"),
                                    restorationHandler: { _ in })
        XCTAssert(demoApplicationDelegate.messageInvoked(message: ContinueUserActivity.self))
    }
}

struct TestError: Error { }

class DemoApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "Demo", daemon: true)

    var messageHasInvokeDic: [String: Bool] = [:]

    required init(context: AppContext) {

        context.dispatcher.add(observer: self) { [weak self] (_, message: DidBecomeActive) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: WillResignActive) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: DidEnterBackground) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: WillEnterForeground) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: WillTerminate) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: DidReceiveMemoryWarning) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: DidRegisterForRemoteNotifications) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: DidFailToRegisterForRemoteNotifications) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: SignificantTimeChange) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: OpenURL) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: PerformFetch) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: PerformAction) in
            self?.handleMessage(message: message)
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message: ContinueUserActivity) in
            self?.handleMessage(message: message)
        }
    }

    private func handleMessage<T: Message>(message: T) {
        messageHasInvokeDic[String(describing: T.self)] = true
    }

    func messageInvoked<T: Message>(message: T.Type) -> Bool {
        messageHasInvokeDic[String(describing: message)] ?? false
    }
}
