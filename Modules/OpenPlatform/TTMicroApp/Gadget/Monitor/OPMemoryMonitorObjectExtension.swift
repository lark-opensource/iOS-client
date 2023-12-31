//
//  OPMemoryMonitorObjectExtension.swift
//  TTMicroApp
//
//  Created by 尹清正 on 2021/3/29.
//

import Foundation
import OPFoundation

/// 定义TTMicroApp中各个对象OPMemoryMonitorObjectProtocol协议的实现
extension OPMicroAppJSRuntime: OPMemoryMonitorObjectProtocol {

    public static var overcountNumber: UInt {
        OPMemoryMonitorConfigProvider.jsRuntimeOvercountNumber
    }

}

extension BDPAppPage: OPMemoryMonitorObjectProtocol {

    public static var overcountNumber: UInt {
        OPMemoryMonitorConfigProvider.appPageOvercountNumber
    }

}

extension BDPTask: OPMemoryMonitorObjectProtocol {

    public static var overcountNumber: UInt {
        OPMemoryMonitorConfigProvider.taskOvercountNumber
    }

    public static var enableMemoryWaveDetect: Bool { true }

}

extension BDPAppController:OPMemoryMonitorObjectProtocol{
    public static var overcountNumber: UInt {
        OPMemoryMonitorConfigProvider.appPageControllerOvercountNumber
    }
}
