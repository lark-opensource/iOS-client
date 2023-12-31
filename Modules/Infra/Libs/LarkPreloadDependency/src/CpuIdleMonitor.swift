//
//  CpuIdleMonitor.swift
//  LarkPreload
//
//  Created by huanglx on 2023/11/28.
//

import Foundation
import LarkPreload

class CpuIdleMonitor: MomentTriggerDelegate {
    var reciever: MomentTriggerCallBackDelegate?
    var isMonitorRegister: Bool = false
    
    //返回监听类型
    func momentTriggerType() -> PreloadMoment {
        return .cpuIdle
    }
    
    //开始监听
    func startMomentTriggerMonitor() {
        
    }
    
    //移除监听
    func removeMomentTriggerMonitor() {
        
    }
}
