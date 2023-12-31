//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LKMetric
import Logger

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        LogCenter.setup(config: [LKMetricLogCategory: [MetricAppenderImplement()]])
        LKMetric.log(domain: Root.passport.s(Passport.logout), type: .business, id: 0)
        LKMetric.log(domain: Root.passport.domain, type: .business, id: 1, emitType: .timer, emitValue: 233)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}

class MetricAppenderImplement: Appender {
    static func identifier() -> String {
        return "\(MetricAppenderImplement.self)"
    }

    static func persistentStatus() -> Bool {
        return true
    }

    func doAppend(_ event: LogEvent) {
        if let metricEvent = MetricEvent(time: event.time, logParams: event.params, error: event.error) {
            print(metricEvent)
        } else {
            print(event)
        }
    }

    func persistent(status: Bool) {
    }
}
