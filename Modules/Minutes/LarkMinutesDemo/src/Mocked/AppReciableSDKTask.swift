//
//  AppReciableSDKTask.swift
//  Lark
//
//  Created by qihongye on 2020/9/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import AppReciableSDK
import BootManager
import LarkPerf
import LKCommonsLogging
//import LarkSDKInterface
import RxSwift
import AppContainer
import OPFoundation

//struct AppReciablePrinterImpl: AppReciableSDKPrinter {
//    private static var logger = Logger.log(AppReciableSDK.self)
//    private let tag = "AppReciable"
//
//    func info(logID: String, _ message: String) {
//        AppReciablePrinterImpl.logger.info(logId: logID, message, params: nil, tags: [tag])
//    }
//
//    func error(logID: String, _ message: String) {
//        AppReciablePrinterImpl.logger.error(logId: logID, message, params: nil, tags: [tag])
//    }
//}
//
//class AppReciableSDKInitTask: FlowLaunchTask, Identifiable {
//    static var identify: TaskIdentify = "AppReciableSDKInitTask"
//
//    override var runOnlyOnce: Bool {
//        return true
//    }
//
//    override func execute(_ context: BootContext) {
//        AppReciableSDK.shared.setStartupTimeStamp(LarkProcessInfo.processStartTime / 1000)
//        AppReciableSDK.shared.setMaxNetStatus(6)
//        AppReciableSDK.shared.setupPrinter(AppReciablePrinterImpl())
//        /// 这个监听需要全局生命周期，不能disposed
//        _ = BootLoader.container.pushCenter
//            .observable(for: PushDynamicNetStatus.self)
//            .subscribe(onNext: { (push) in
//                AppReciableSDK.shared.setNetStatus(push.dynamicNetStatus.rawValue)
//            }, onError: nil, onCompleted: nil, onDisposed: nil)
//    }
//}
//
//class NewAppReciableSDKInitTask: FlowBootTask, Identifiable {
//    static var identify: TaskIdentify = "AppReciableSDKInitTask"
//
//    override var runOnlyOnce: Bool {
//        return true
//    }
//
//    override func execute(_ context: BootContext) {
//        AppReciableSDK.shared.setStartupTimeStamp(LarkProcessInfo.processStartTime / 1000)
//        AppReciableSDK.shared.setMaxNetStatus(6)
//        AppReciableSDK.shared.setupPrinter(AppReciablePrinterImpl())
//        /// 这个监听需要全局生命周期，不能disposed
//        _ = BootLoader.container.pushCenter
//            .observable(for: PushDynamicNetStatus.self)
//            .subscribe(onNext: { (push) in
//                AppReciableSDK.shared.setNetStatus(push.dynamicNetStatus.rawValue)
//            }, onError: nil, onCompleted: nil, onDisposed: nil)
//    }
//}
