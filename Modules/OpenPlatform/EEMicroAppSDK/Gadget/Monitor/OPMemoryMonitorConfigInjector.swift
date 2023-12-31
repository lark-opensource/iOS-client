//
//  OPMemoryMonitorConfigInjector.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/30.
//

import Foundation

/// 该类负责将EMA模块中获取配置的能力注入到TTMicroApp中
@objcMembers
public final class OPMemoryMonitorConfigInjector: NSObject {

    /// 是否已经进行过了注入(只能注入一次)
    static var configInjected = false

    public static func inject() {
        guard !configInjected else {
            configInjected = true
            return
        }

        guard let config = EMAAppEngine.current()?.onlineConfig else {
            return
        }
        
        OPMemoryMonitorConfigProvider.jsRuntimeOvercountNumber = config.jsRuntimeOvercountNumber()
        OPMemoryMonitorConfigProvider.taskOvercountNumber = config.taskOvercountNumber()
        OPMemoryMonitorConfigProvider.appPageOvercountNumber = config.appPageOvercountNumber()
    }
}
