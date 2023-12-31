//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import UGCoordinator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let mock = UGCoordinatorMock.shared

    var t1: Thread = Thread()
    var t2: Thread = Thread()
    let lock = NSLock()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        let ges = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        self.window?.rootViewController?.view.addGestureRecognizer(ges)

        t1 = Thread(target: self, selector: #selector(t1Action), object: nil)
        t2 = Thread(target: self, selector: #selector(t2Action), object: nil)

        onViewTapped()

        return true
    }

    @objc
    func onViewTapped() {
        testExample()
//        testMultiThread()
//        testAPI()
    }
    private func testAPI() {
        mock.testAPICase()
    }

    // ref: https://bytedance.feishu.cn/wiki/wikcntEHAElsx7QThIq7pDmkmGf
    private func testExample() {
        mock.testonScenarioTrigger() // 1, 3, 6
        mock.testConsumeBubble(reachPointIDs: ["1"]) // 1, 2
        mock.testConsumeBubble(reachPointIDs: ["2"]) // 1, 3, 6
        mock.testConsumeBubble(reachPointIDs: ["6"]) // 1, 3, 7
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}

extension AppDelegate {

    func testMultiThread() {
        t1.start()
        t2.start()
    }

    @objc func t1Action() {
        print("t1Action start ====================== current \(Thread.current) ")
        testExample()
        print("t1Action end ====================== current \(Thread.current) ")
    }

    @objc func t2Action() {
        print("t2Action start ====================== current \(Thread.current) ")
        testExample()
        print("t2Action end ======================  current \(Thread.current)")
    }

}
