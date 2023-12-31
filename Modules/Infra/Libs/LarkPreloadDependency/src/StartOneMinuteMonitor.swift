//
//  StartOneMinuteMonitor.swift
//  LarkPreload
//
//  Created by huanglx on 2023/11/28.
//

import Foundation
import LarkPreload

//启动后一分钟监听
class StartOneMinuteMonitor: MomentTriggerDelegate {
    var reciever: MomentTriggerCallBackDelegate?
    
    var isMonitorRegister: Bool = false
    
    //返回监听类型
    func momentTriggerType() -> PreloadMoment {
        return .startOneMinute
    }
    
    //开始监听
    func startMomentTriggerMonitor() {
        //启动后一分钟触发
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.reciever?.callbackMonent(moment: .startOneMinute)
        }
    }
    
    //移除监听
    func removeMomentTriggerMonitor() {
        
    }
}
