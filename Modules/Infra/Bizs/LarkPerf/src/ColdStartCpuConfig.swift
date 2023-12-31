//
//  ColdStartCpuConfig.swift
//  LarkPerf
//
//  Created by huanglx on 2023/12/18.
//

import Foundation
import ThreadSafeDataStructure
import LarkStorage

/// cpu阈值类型
enum CpuConfigType: String {
    case appCpuWarnRate = "appCpuWarnRate"              //应用CPU异常阈值
    case deviceCpuWarnRate = "deviceCpuWarnRate"        //设备CPU异常阈值
    case appCpuNormalRate = "appCpuNormalRate"          //应用CPU正常阈值
    case deviceCpuNormalRate = "deviceCpuNormalRate"    //设备CPU正常阈值
}

///机型
enum DeviceClassify: String {
    case lowDevice = "lowDevice"        //低端机
    case middleDevice = "middleDevice"  //中端机
    case hightDevice = "hightDevice"    //高端机
}

public class ColdStartCpuConfig {
    
    //在settings获取之后注入
    public static var cpuConfig: SafeDictionary<String, Any> = [:] + .readWriteLock
        
    //设置默认数据
    static var configDefault: [String: [String: Double]] = [
        // disable-lint: magic number
        DeviceClassify.lowDevice.rawValue: [CpuConfigType.appCpuWarnRate.rawValue: 0.7, CpuConfigType.deviceCpuWarnRate.rawValue: 0.85, CpuConfigType.appCpuNormalRate.rawValue: 0.3, CpuConfigType.deviceCpuNormalRate.rawValue: 0.5],
        DeviceClassify.middleDevice.rawValue: [CpuConfigType.appCpuWarnRate.rawValue: 0.8, CpuConfigType.deviceCpuWarnRate.rawValue: 0.9, CpuConfigType.appCpuNormalRate.rawValue: 0.3, CpuConfigType.deviceCpuNormalRate.rawValue: 0.4],
        DeviceClassify.hightDevice.rawValue: [CpuConfigType.appCpuWarnRate.rawValue: 0.9, CpuConfigType.deviceCpuWarnRate.rawValue: 0.95, CpuConfigType.appCpuNormalRate.rawValue: 0.3, CpuConfigType.deviceCpuNormalRate.rawValue: 0.4]
        // enable-lint: magic number
    ]
    
    ///获取CPU数据
    ///configType：cpu类型
    static func getCurrentDeviceCpuConfig(configType: CpuConfigType) -> Double {
        //只有获取到评分才上报。否则返回0
        guard let deviceScore = KVPublic.Common.deviceScore.value(), deviceScore > 0 else {
            return 0
        }
        //获取settings配置的值，获取默认的值
        var config: Double?
        var defaultConfig: Double?
        //根据机型评分配置不同异常阈值。
        switch deviceScore {
        // disable-lint: magic number
        case 0...8:
            config = (cpuConfig[DeviceClassify.lowDevice.rawValue] as? [String: Double])?[configType.rawValue] as? Double
            defaultConfig = configDefault[DeviceClassify.lowDevice.rawValue]?[configType.rawValue]
        case 8...9.5:
            config = (cpuConfig[DeviceClassify.middleDevice.rawValue] as? [String: Double])?[configType.rawValue] as? Double
            defaultConfig = configDefault[DeviceClassify.middleDevice.rawValue]?[configType.rawValue]
        case 9.5...:
            config = (cpuConfig[DeviceClassify.hightDevice.rawValue] as? [String: Double])?[configType.rawValue] as? Double
            defaultConfig = configDefault[DeviceClassify.hightDevice.rawValue]?[configType.rawValue]
            default:
                break
        // enable-lint: magic number
        }
        //如果获取到了settings的值返回settings值
        if let config = config {
            return config
        } else {//没有获取到了setting的值，用默认的值，如果没有配置默认值返回0
            return defaultConfig ?? 0
        }
    }
    
    ///CPU持续平稳时间
    static func cpuIdleTime() -> Int {
        if let cpuIdleTime = cpuConfig["cpuIdleTime"] as? Int {
            return cpuIdleTime
        } else {
            // disable-lint: magic number
            return 5
            // enable-lint: magic number
        }
    }
    
    ///监听循环最大次数
    static func monitorCycleMaxCount() -> Int {
        if let monitorCycleMaxCount = cpuConfig["monitorCycleMaxCount"] as? Int {
            return monitorCycleMaxCount
        } else {
            // disable-lint: magic number
            return 30
            // enable-lint: magic number
        }
    }
}
