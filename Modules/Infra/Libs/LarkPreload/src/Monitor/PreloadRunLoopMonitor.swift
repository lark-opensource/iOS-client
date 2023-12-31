//
//  PreloadRunLoopMonitor.swift
//  Lark
//
//  Created by huanglx on 2023/1/31.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation

///监听runLoop
class PreloadRunLoopMonitor: MomentTriggerDelegate {
    var observer: CFRunLoopObserver?
    weak var reciever: MomentTriggerCallBackDelegate?
    var isMonitorRegister: Bool = false
    var runloop: CFRunLoop {
        return RunLoop.main.getCFRunLoop()
    }

    ///触发时机类型
    func momentTriggerType() -> PreloadMoment {
        return .runloopIdle
    }
    
    ///监听runloop空闲
    func startMomentTriggerMonitor() {
        guard self.observer == nil, !self.isMonitorRegister else { return }
        self.isMonitorRegister = true
         let activityToObserve: CFRunLoopActivity = [.beforeWaiting, .exit]
         let observer = CFRunLoopObserverCreateWithHandler(
             kCFAllocatorDefault,        // allocator
             activityToObserve.rawValue, // activities
             true,                       // repeats
             Int.max                     // order after CA transaction commits
         ) { [weak self] (_, _) in
             self?.reciever?.callbackMonent(moment: .runloopIdle)
         }
         self.observer = observer
         CFRunLoopAddObserver(runloop, observer, CFRunLoopMode.defaultMode)
     }
    
    ///移除Runloop监听
    func removeMomentTriggerMonitor() {
        guard let observer = self.observer, self.isMonitorRegister else { return }
        self.isMonitorRegister = false
        CFRunLoopRemoveObserver(runloop, observer, CFRunLoopMode.defaultMode)
        self.observer = nil
    }
}
