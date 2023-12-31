//
//  AppReciableSDKTask.swift
//  Lark
//
//  Created by qihongye on 2020/9/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppReciableSDK
import BootManager
import LarkPerf
import LKCommonsLogging
import LarkSDKInterface
import RxSwift
import AppContainer

struct AppReciablePrinterImpl: AppReciableSDKPrinter {
    private static let logger = Logger.log(AppReciableSDK.self)
    private let tag = "AppReciable"

    func info(logID: String, _ message: String, _ timestamp: TimeInterval?) {
        let time = timestamp ?? Date().timeIntervalSince1970
        Self.logger.log(logId: logID, message, tags: [tag], level: .info, time: time)
    }

    func error(logID: String, _ message: String, _ timestamp: TimeInterval?) {
        let time = timestamp ?? Date().timeIntervalSince1970
        Self.logger.log(logId: logID, message, tags: [tag], level: .error, time: time)
    }
}

final class AppReciableSDKInitTask: FlowBootTask, Identifiable {
    static var identify: TaskIdentify = "AppReciableSDKInitTask"
    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        AppReciableSDK.shared.setStartupTimeStamp(LarkProcessInfo.processStartTime() / 1000)
        AppReciableSDK.shared.setMaxNetStatus(6)
        AppReciableSDK.shared.setupPrinter(AppReciablePrinterImpl())
        /// 这个监听需要全局生命周期，不能disposed
        _ = BootLoader.container.pushCenter
            .observable(for: PushDynamicNetStatus.self)
            .subscribe(onNext: { (push) in
                AppReciableSDK.shared.setNetStatus(push.dynamicNetStatus.rawValue)
            }, onError: nil, onCompleted: nil, onDisposed: nil)
    }
}
