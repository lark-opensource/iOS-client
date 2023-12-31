//
//  OPJSTimerModule.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/22.
//
// 给JS环境注入setTimeout的能力

import Foundation
import LKCommonsLogging
import LarkJSEngine
import LarkSetting

public final class OPJSTimerModule: NSObject, GeneralJSRuntimeModuleProtocol {
    static let logger = Logger.log(OPJSTimerModule.self, category: "OPJSEngine")
    public weak var jsRuntime: GeneralJSRuntime?
    private let enableSetTimerLog: Bool
    
    public override init() {
        enableSetTimerLog = FeatureGatingManager.shared.featureGatingValue(with: "openplatform.gadget.log_set_timer")
        super.init()
    }

    public func runtimeLoad() // js runtime初始化
    {
        appTimer = TMATimer()
        if let jsRuntime = self.jsRuntime, jsRuntime.isSeperateWorker, !jsRuntime.runtimeType.isVMSDK() {
            setupSeperateTimer()
        }
    }

    public func runtimeReady()
    {

    }

    var appTimer: TMATimer?


    public func clearTimer(message: BDPJSRuntimeSocketMessage) {
        clearTimer(type: message.timerType, functionID: message.timerId)
    }

    public func setTimer(message: BDPJSRuntimeSocketMessage) {
        setTimer(type: message.timerType, functionID: message.timerId, delay: message.time)
    }

    public func setTimer(type: String, functionID: Int, delay: Int) {
        if let isSocketDebug = self.jsRuntime?.isSocketDebug, !isSocketDebug {
            self.jsRuntime?.delegate?.bindCurrentThreadTracing?()
        }
        if(enableSetTimerLog) {
            Self.logger.info("setTimer, type=\(type), delay=\(delay)")
        }
        
        if type == "Timeout" {
            let callbackBlk: (() -> Void) = { [weak self] in
                self?.jsRuntime?.invokeJavaScriptModule(methodName: "nativeInvokeTimer", moduleName: nil, params: ["Timeout", NSNumber(value: functionID)])
            }
            if let dispatchQueue = self.jsRuntime?.dispatchQueue {
                jsRuntime?.setTimeOut(functionID: functionID, time: delay, runloop: dispatchQueue.thread.runLoop, callback: callbackBlk)
            } else {
                jsRuntime?.setTimeOut(functionID: functionID, time: delay, queue: nil, callback: callbackBlk)
            }
        }

        if type == "Interval" {
            let callbackBlk: (() -> Void) = { [weak self] in
                self?.jsRuntime?.invokeJavaScriptModule(methodName: "nativeInvokeTimer", moduleName: nil, params: ["Interval", NSNumber(value: functionID)])
            }
            if let dispatchQueue = self.jsRuntime?.dispatchQueue {
                jsRuntime?.setInterval(functionID: functionID, time: delay, runloop: dispatchQueue.thread.runLoop, callback: callbackBlk)
            } else {
                jsRuntime?.setInterval(functionID: functionID, time: delay, queue: nil, callback: callbackBlk)
            }
        }

    }

    public func clearTimer(type: String, functionID: Int) {
        if let isSocketDebug = self.jsRuntime?.isSocketDebug, !isSocketDebug {
            self.jsRuntime?.delegate?.bindCurrentThreadTracing?()
        }
        if type == "Timeout" {
            jsRuntime?.clearTimeout(functionID: functionID)
        } else if type == "Interval" {
            jsRuntime?.clearInterval(functionID: functionID)
        }
    }

    func setupSeperateTimer() {
        // setTimeout, setInterval
        let setTimeout: (@convention(block) (JSValue, Double) -> Any?) = { [weak self] (callback, timeout) in
            guard let `self` = self else {
                Self.logger.error("worker setTimeout fail, self is nil")
                return nil
            }

            let time = timeout / 1000.0
            let jsTimer = Timer(timeInterval: TimeInterval(time), repeats: false) { timer in
                callback.call(withArguments: [])
            }

            self.jsRuntime?.dispatchQueue?.thread.runLoop.add(jsTimer, forMode: .default)
            self.timerID = self.timerID + 1
            self.timerMap[self.timerID] = jsTimer
            return self.timerID
        }

        jsRuntime?.setObject(setTimeout,
                                forKeyedSubscript: "setTimeout" as NSString)


        let clearTimeout: (@convention(block) (Int) -> Any?) = { [weak self] (timerID) in
            guard let `self` = self else {
                Self.logger.error("worker clearTimeout fail, self is nil")
                return nil
            }
            if let timer = self.timerMap[timerID] {
                timer.invalidate()
                self.timerMap.removeValue(forKey: timerID)
            }
            return nil
        }
        jsRuntime?.setObject(clearTimeout,
                                forKeyedSubscript: "clearTimeout" as NSString)

        let setInterval: (@convention(block) (JSValue, Double) -> Any?) = { [weak self] (callback, timeout) in
            guard let `self` = self else {
                Self.logger.error("worker setInterval fail, self is nil")
                return nil
            }

            let time = timeout / 1000.0
            let jsTimer = Timer(timeInterval: TimeInterval(time), repeats: true) { timer in
                callback.call(withArguments: [])
            }
            self.jsRuntime?.dispatchQueue?.thread.runLoop.add(jsTimer, forMode: .default)
            self.timerID = self.timerID + 1
            self.timerMap[self.timerID] = jsTimer

            return self.timerID
        }

        jsRuntime?.setObject(setInterval,
                                forKeyedSubscript: "setInterval" as NSString)


        let clearInterval: (@convention(block) (Int) -> Any?) = { [weak self] (timerID) in
            guard let `self` = self else {
                Self.logger.error("worker clearInterval fail, self is nil")
                return nil
            }
            if let timer = self.timerMap[timerID] {
                timer.invalidate()
                self.timerMap.removeValue(forKey: timerID)
            }

            return nil
        }
        jsRuntime?.setObject(clearInterval,
                                forKeyedSubscript: "clearInterval" as NSString)

    }

    // setTimeout timer map
    var timerMap: [Int: Timer] = [:]
    var timerID: Int = 0

    deinit {
        for item in timerMap {
            if let timer = timerMap[item.key] {
                timer.invalidate()
            }
        }
        timerMap.removeAll()
    }
}
