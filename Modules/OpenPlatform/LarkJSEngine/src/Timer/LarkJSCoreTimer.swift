//
//  LarkJSCoreTimer.swift
//  LarkJSEngine
//
//  Created by Jiayun Huang on 2022/3/9.
//

import Foundation

class LarkJSCoreTimer: LarkJSTimerProtocol {
    private var timeoutFunctionIds: Set<NSInteger> = []
    
    private var timeoutTimerDic: [NSInteger: Timer] = [:]
    
    private var intervalFunctionIds: Set<NSInteger> = []
    
    private var intervalTimerDic: [NSInteger: Timer] = [:]
    
    private var intervalSourceTimerDic: [NSInteger: DispatchSourceTimer] = [:]
    
    // time 单位毫秒
    public func setTimeOut(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        timeoutFunctionIds.insert(functionID)
        let handler = { [weak self] in
            guard let self = self else {
                return
            }
            if self.timeoutFunctionIds.contains(functionID) {
                callback()
                self.timeoutFunctionIds.remove(functionID)
            }
        }
        (queue ?? DispatchQueue.main).asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(time), execute: handler)
    }
    
    // setTimeOut 平台实现，runloop方式，time 单位毫秒
    public func setTimeOut(functionID: NSInteger, time: NSInteger, runLoop: RunLoop, callback: @escaping () -> Void) {

        let timer = Timer(timeInterval: TimeInterval(Double(time) / 1000.0), repeats: false) { [weak self] timerInstance in
            self?.fireTimeout(functionID: functionID) { [weak self] in
                callback()
                self?.timeoutTimerDic.removeValue(forKey: functionID)
            }

        }
        timeoutTimerDic[functionID] = timer
        runLoop.add(timer, forMode: .default)
    }
    
    public func clearTimeout(functionID: NSInteger) {
        timeoutFunctionIds.remove(functionID)
        if let timer = timeoutTimerDic[functionID] {
            timer.invalidate()
            timeoutTimerDic.removeValue(forKey: functionID)
        }
    }

    // time 单位毫秒
    public func setInterval(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue ?? DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: DispatchTimeInterval.milliseconds(time), leeway: DispatchTimeInterval.milliseconds(50))
        timer.setEventHandler {
            callback()
        }
        intervalSourceTimerDic[functionID] = timer
        timer.activate()
    }
    
    // time 单位毫秒
    public func setInterval(functionID: NSInteger, time: NSInteger, runLoop: RunLoop, callback: @escaping () -> Void) {
        let timer = Timer(timeInterval: TimeInterval(Double(time) / 1000.0), repeats: true) { [weak self] timerInstance in
            self?.fireTimeout(functionID: functionID, callback: callback)
        }
        intervalTimerDic[functionID] = timer
        runLoop.add(timer, forMode: .default)
    }

    public func clearInterval(functionID: NSInteger) {
        if let timer = intervalTimerDic[functionID] {
            timer.invalidate()
            intervalTimerDic.removeValue(forKey: functionID)
        }
        if let sourceTimer = intervalSourceTimerDic[functionID] {
            sourceTimer.cancel()
            intervalSourceTimerDic.removeValue(forKey: functionID)
        }
    }
    
    deinit {
        // timeout
        timeoutFunctionIds.removeAll()
        for (timerKey, timerValue) in timeoutTimerDic {
            timerValue.invalidate()
        }
        timeoutTimerDic.removeAll()
        
        // interval
        for (timerKey, timerValue) in intervalTimerDic {
            timerValue.invalidate()
        }
        intervalTimerDic.removeAll()
        for (timerKey, timerValue) in intervalSourceTimerDic {
            timerValue.cancel()
        }
        intervalSourceTimerDic.removeAll()
    }

}

private extension LarkJSCoreTimer {
    @objc func fireTimeout(functionID: NSInteger, callback: (() -> Void)?) {
        if let callback = callback as? () -> Void {
            callback()
        }
    }

}
