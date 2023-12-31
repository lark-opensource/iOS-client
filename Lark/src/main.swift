//
//  main.swift
//  ArchitectureDemo
//
//  Created by SolaWing on 2018/7/31.
//  Copyright © 2018年 SW. All rights reserved.
//

import Foundation
import AppContainer
import LarkPerf
import BootManager
import BootManagerDependency
import RunloopTools
import LarkFeatureSwitch
import LarkSafeMode
import LarkSDK
import LarkStorage
import LKLoadable
import Heimdallr
import BDFishhook
#if DEBUG
import LarkChat
#endif
#if canImport(FlameGraphTools)
import FlameGraphTools
import QuartzCore
#endif

private func larkMain() {

    //兜底安全模式
    guard LarkSafeMode.PureSafeModeEnable() else {
        LarkSafeMode.PureSafeModeSettingUpdate()
        let delegate: SafeModeAppDelegate.Type = NSClassFromString("TestAppDelegate") as? SafeModeAppDelegate.Type ?? SafeModeAppDelegate.self
        UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(delegate))
        return
    }

    ///火焰图工具，只在线下开启开关后才会执行
    #if canImport(FlameGraphTools)
    MethodTraceLogger.initShared()
    MethodTraceLogger.funcCost = 5
    MethodTraceLogger.startRecordAndStopForLaunch(deadLine: 15)
    #endif
    //记录main函数开始时间戳
    HMDStartDetector.markMainDate()
    LarkProcessInfo.mainStartTime = CACurrentMediaTime()
    LarkProcessInfo.doubleCheckPreWarm()
    ColdStartup.shared?.do(.main)
    LKLoadableManager.run(appMain)
    //开启慢函数
    #if ENABLE_EVIL_METHOD
    if KVPublic.FG.evilMethodOpen.value() {
        HMDEvilMethodTracer.sharedInstance().startTrace()
    }
    #endif
    //fix "Terminated due to signal 13"
    //https://juejin.im/post/5dc3805df265da4d1518efb4
    signal(SIGPIPE, SIG_IGN)
    //fix ttnet gcd crash
    open_bdfishhook()
    HMDProtectFixLibdispatch.sharedInstance().fixGCDCrash()
    #if DEBUG
    // Runloop 监测
    RunloopMonitor.shared.startRunLoopObserver()
    #endif
    NewBootManager.register(LarkMainAssembly.self)
    NewBootManager.register(AppReciableSDKInitTask.self)
    NewBootManager.register(LanguageManagerInitTask.self)
    NewBootManager.register(LarkSafeModeTask.self)
    NewBootManager.register(LarkSafeModeForemostTask.self)
    NewBootManager.register(LarkEnterSafeModeTask.self)
    NewBootManager.register(LarkRuntimeSafeModeTask.self)
    NewBootManager.register(InitIdleLoadTask.self)
    NewBootManager.shared.dependency = BootManagerDependency()

    let delegate: AppDelegate.Type = NSClassFromString("TestAppDelegate") as? AppDelegate.Type ?? AppDelegate.self

    let config = AppConfig(env: AppConfig.default.env)
    BootLoader.shared.start(delegate: delegate, config: config)

    #if ALPHA
        print("test")
    #endif
}

larkMain()
