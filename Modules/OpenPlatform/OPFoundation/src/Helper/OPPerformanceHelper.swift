//
//  OPPerformanceHelper.swift
//  OPFoundation
//
//  Created by liuyou on 2021/4/22.
//

import Foundation

@objcMembers
public final class OPPerformanceHelper: NSObject {
    public static var usedMemoryInMB: Float {
        return OPPerformanceUtil.usedMemoryInMB()
    }

    public static var cpuUsage: Float {
        return OPPerformanceUtil.cpuUsage()
    }

    public static var fps: Float {
        OPPerformanceUtil.runFPSMonitor()
        return OPPerformanceUtil.fps()
    }
    
    public static var availableMemory: Float{
        return OPPerformanceUtil.availableMemory()
    }


}
