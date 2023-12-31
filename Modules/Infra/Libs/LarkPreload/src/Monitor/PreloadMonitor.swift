//
//  PreloadMonitor.swift
//  Lark
//
//  Created by huanglx on 2023/2/15.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import Heimdallr

///预处理性能监控
class PreloadMonitor {
    var monitorTimer: Timer?
    //防饿死机制是否开启-默认不开启
    var preventStarveIsOpen: Bool = false
    weak var reciever: MoinitorDelegate?
    
    //一次监听检查周期次数，判断是否触发防饿死机制
    var monitorCycleCount: Int = 0 {
        didSet {
            if monitorCycleCount > PreloadSettingsManager.preventStarveCycleCount(), PreloadSettingsManager.preventStarveCycleCount() > 0 { //超过n次监听周期都没有恢复，触发防饿死机制，移除监听，并且解除CPU和内存的限制，m秒后恢复限制。
                self.preventStarveIsOpen = true
                self.reciever?.trigggerPreventStarve(isOpen: self.preventStarveIsOpen)
                DispatchQueue.main.asyncAfter(deadline: .now() + PreloadSettingsManager.preventStarveOpenTime()) { [weak self] in
                    //关闭防饿死机制
                    self?.preventStarveIsOpen = false
                    self?.reciever?.trigggerPreventStarve(isOpen: false)
                }
            }
        }
    }
    
    //开始监听-2秒监听一次
    func startMonitor() {
        monitorTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(monitorCallback), userInfo: nil, repeats: true)
        if let curTimer: Timer = monitorTimer {
            RunLoop.main.add(curTimer, forMode: .common)
        }
    }
    
    //移除监听
    func removeMonitor() {
        if monitorTimer != nil {
            self.monitorCycleCount = 0
            monitorTimer?.invalidate()
            monitorTimer = nil
        }
    }
    
    //监听回调
    @objc
    func monitorCallback() {
        self.monitorCycleCount += 1
        self.reciever?.callbackMonitor()
        //防饿死机制开启-会移除监听。
        if self.preventStarveIsOpen {
            self.removeMonitor()
        }
    }
}
