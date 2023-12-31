//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import UIKit
import LarkSecurityAudit
import LKCommonsLogging

// TODO: db is locked
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let logger = Logger.log(AppDelegate.self, category: "SecurityAudit.AppDelegate")

    let securityAudit = SecurityAudit()

    var window: UIWindow?

    // swiftlint:disable function_body_length
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self.window = UIWindow()
        self.window?.rootViewController = UIViewController(nibName: nil, bundle: nil)
        // swiftlint:disable init_color_with_token
        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        // swiftlint:enable init_color_with_token

        self.window?.makeKeyAndVisible()
        let config = Config(
            hostProvider: {
//            return "10.227.16.205:8338"
                return "internal-api-lark-api.feishu-staging.cn"
            },
            deviceId: "13241341234123432",
            session: "XxXXXX"
        )
        SecurityAuditManager.shared.initSDK(config)
        SecurityAuditManager.shared.start()
        SecurityAuditManager.sidecar = "#lark.staging.lianggang.lark3"
        var event = Event()
        event.module = .moduleBitable
        event.env.did = "13241341234123432"
        securityAudit.sharedParams = event
        Self.logger.info("start up")

        var evt = Event()
        evt.operation = .operationComment
        evt.operator = OperatorEntity()
        evt.operator.type = .entityBitableID
        evt.operator.value = .declaredDatatype
        var opType = SecurityEvent_ObjectEntity()
        opType.type = .entityBitableID
        opType.value = .declaredDatatype

        evt.objects = [opType]
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
        securityAudit.auditEvent(evt)
//        let auto = securityAudit.checkAuthority(permType: .fileAppOpen)
        return true
    }
    // swiftlint:enable function_body_length

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}
