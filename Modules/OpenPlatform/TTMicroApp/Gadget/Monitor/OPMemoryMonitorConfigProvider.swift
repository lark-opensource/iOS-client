//
//  OPMemoryMonitorConfigProvider.swift
//  TTMicroApp
//
//  Created by 尹清正 on 2021/3/30.
//

import Foundation

/// BDPJSRuntime对象在内存中的最大数量默认值
fileprivate let DefaultJSRuntimeOvercountNumber: UInt = 6
/// BDPTask对象在内存中的最大数量默认值
fileprivate let DefaultTaskRuntimeOvercountNumber: UInt = 8
/// BDPAppPage对象在内存中的最大数量默认值
fileprivate let DefaultAppPageRuntimeOvercountNumber: UInt = 50
/// BDPAppController 对象在内存中的最大数量默认值
fileprivate let DefaultAppPageControllerRuntimeOvercountNumber: UInt = 50

/// 提供与开放平台内存性能监控指标相关的一些配置获取的能力
public final class OPMemoryMonitorConfigProvider {
    /// BDPJSRuntime对象在内存中的最大数量，不得为0
    private static var _jsRuntimeOvercountNumber = DefaultJSRuntimeOvercountNumber
    public static var jsRuntimeOvercountNumber: UInt {
        get { return _jsRuntimeOvercountNumber }
        set {
            guard newValue != 0 else { return }
            _jsRuntimeOvercountNumber = newValue
        }
    }

    /// BDPTask对象在内存中的最大数量默认值，不得为0
    private static var _taskOvercountNumber = DefaultTaskRuntimeOvercountNumber
    public static var taskOvercountNumber: UInt {
        get { return _taskOvercountNumber }
        set {
            guard newValue != 0 else { return }
            _taskOvercountNumber = newValue
        }
    }

    /// BDPAppPage对象在内存中的最大数量默认值，不得为0
    private static var _appPageOvercountNumber = DefaultAppPageRuntimeOvercountNumber
    public static var appPageOvercountNumber: UInt {
        get { return _appPageOvercountNumber }
        set {
            guard newValue != 0 else { return }
            _appPageOvercountNumber = newValue
        }
    }
    
    /// BDPAppPage对象在内存中的最大数量默认值，不得为0
    private static var _appPageControllerOvercountNumber = DefaultAppPageRuntimeOvercountNumber
    public static var appPageControllerOvercountNumber: UInt {
        get { return _appPageControllerOvercountNumber }
        set {
            guard newValue != 0 else { return }
            _appPageControllerOvercountNumber = newValue
        }
    }

}
