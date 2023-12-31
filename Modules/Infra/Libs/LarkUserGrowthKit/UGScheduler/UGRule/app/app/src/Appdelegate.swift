//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import UGRule
import Swinject

// swiftlint:disable all
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    static let container = Container()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()

        UGRuleMockAssembly().assemble(container: AppDelegate.container)

//        testSingleRuleKeepClicking()
//        testSingleRuleShowTime()
//        testSingleRuleKeepTyping()

//        UGRuleMock.shared.testTriggerParentExpEvent(actionInfo: RuleActionInfo(ruleAction: .input, actionValue: "he"))
//        UGRuleMock.shared.testTriggerParentExpEvent(actionInfo: RuleActionInfo(ruleAction: .clickCount))
//        UGRuleMock.shared.testTriggerParentExpEvent(actionInfo: RuleActionInfo(ruleAction: .input, actionValue: "ll"))
//        UGRuleMock.shared.testTriggerParentExpEvent(actionInfo: RuleActionInfo(ruleAction: .clickCount))

        return true
    }

    // 点击多次
    func testSingleRuleKeepClicking() {
        let actionInfo = RuleActionInfo(ruleAction: .clickCount)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "3", expOperator: .lessOrEqual)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "1", expOperator: .lessOrEqual)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "3", expOperator: .lessOrEqual)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "5", expOperator: .lessOrEqual)
    }

    // 事件duration
    func testSingleRuleShowTime() {
        let actionInfo = RuleActionInfo(ruleAction: .showTime)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "1", expOperator: .greaterOrEqual)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "1", expOperator: .greaterOrEqual)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "3", expOperator: .greaterOrEqual)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo, thresholdValue: "5", expOperator: .lessThan)
    }

    // 点击多次
    func testSingleRuleKeepTyping() {
        let actionInfo1 = RuleActionInfo(ruleAction: .input, actionValue: "h")
        let actionInfo2 = RuleActionInfo(ruleAction: .input, actionValue: "e")
        let actionInfo3 = RuleActionInfo(ruleAction: .input, actionValue: "l")
        let actionInfo4 = RuleActionInfo(ruleAction: .input, actionValue: "h")

        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo1, thresholdValue: "hel", expOperator: .inside)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo2, thresholdValue: "hel", expOperator: .inside)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo3, thresholdValue: "hel", expOperator: .inside)
        UGRuleMock.shared.testTriggerSingleExpEvent(actionInfo: actionInfo4, thresholdValue: "hel", expOperator: .inside)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
