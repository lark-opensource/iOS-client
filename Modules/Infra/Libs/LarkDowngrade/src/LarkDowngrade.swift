//
//  LarkDowngrade.swift
//  Lark
//
//  Created by ByteDance on 2023/1/3.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import Heimdallr
import ThreadSafeDataStructure
import LKCommonsTracker
import LKCommonsLogging
import LarkPerfBase

public let DOWNGRADE_AB_KEY: String = "lark_ios_downgrade_ab_config"


//降级管理框架
public class LarkDowngradeService {
    static var logger = Logger.log(LarkDowngradeService.self)
    public var downgradeManager: LarkDownradeTaskManager//业务设置
    public static let shared = LarkDowngradeService() //单例
    public var deviceScore: Double = 100 //机型
    public static let isPad = UIDevice.current.userInterfaceIdiom == .pad  //是否是ipad
    public var config: LarkDowngradeConfig = LarkDowngradeConfig()//存储setting设置
    var appStatusTimer: Timer?
    var currentStatus: LarkDowngradeStatus = LarkDowngradeStatus()
    var currentPerfInfo: LarkPerfAppInfo = LarkPerfAppInfo(cpuValue: 0, cpuTime: 0, memory: 0, deviceCpu: host_cpu_load_info_data_t())
    private let timerQueue = DispatchQueue(label: "com.lark.downgradeOld")
    
    public lazy var abConfig: LarkDowngradeConfig = {
        //读取AB
        //demo
        if let configDic = Tracker.experimentValue(key: DOWNGRADE_AB_KEY, shouldExposure: true) as? [String: Any] {
            let config = LarkDowngradeConfig()
            config.updateWithDic(dictionary: configDic)
            return config
        }
        let config = LarkDowngradeConfig()
        config.updateWithDic(dictionary: [:])
        return config
    }()
    
    //静态降级
    /// static Downgrade
    /// - Parameters:
    ///   - key: 降级key，唯一标识
    ///   - indexes: 关注指标，默认不用填
    ///   - config: 个别业务关注指标需要自定义，默认不用填
    ///   - level: 降级级别,扩展用,默认不用填写
    ///   - doDowngrade: 降级处理
    ///   - doNormal: normal process
    public func Downgrade(key: String,
                           indexes: [LarkDowngradeIndex] = [],
                           config: LarkDowngradeConfig = LarkDowngradeConfig(isNormal: true),
                           level: LarkDowngradeLevel = .high,
                           doDowngrade: DowngradeAction,
                           doNormal: DowngradeAction)
    {
        var status = LarkDowngradeStatus()
        //整体开关
        if !self.config.enableDowngrade {
            doNormal(status)
            return
        }
        //用于关闭一些降级
        if self.config.getNormalLevel().contains(key) ||
            self.abConfig.getNormalLevel().contains(key) {
            doNormal(status)
            return
        }
        //
        //获取降级规则
        let taskConfig = config.isNormal ? self.config : config
        let rules = taskConfig.getRules(indexes: indexes, level: level)
        status = self.getAppStatus()
        let result = self.downgradeManager.normalTask.getDowngradeRuleListResult(status: status, rulelist: rules, onlyDowngrade: true)
        if result == .downgrade {
            status.downgradeStatus = true
        }

        if status.downgradeStatus {
            LarkDowngradeUtility.recordDowngradeDo(key: key, status: status, result: .downgrade)
            doDowngrade(status)
        } else {
            doNormal(status)
        }
    }

    //获取APP状态信息
    private func getAppStatus() -> LarkDowngradeStatus {
        var status = LarkDowngradeStatus()
        status.deviceValue = self.deviceScore
        //内存
        let currentMemory = Double(LarkPerfBase.memoryUsage()) / (1024*1024)
        let limitMemory = Double(hmd_getDeviceMemoryLimit()) / (1024*1024)
        let lastMemory = limitMemory - currentMemory
        status.memoryValue = lastMemory
        status.memoryCurrentValue = currentMemory
        //cpu
        let perfInfo = LarkPerfBase.perfInfo()
        let currentCpu = (perfInfo.cpuValue - self.currentPerfInfo.cpuValue)/(perfInfo.cpuTime - self.currentPerfInfo.cpuTime)
        status.cpuValue = Double(currentCpu) / Double(LarkPerfBase.cpuNum())

        //device cpu
        status.deviceCpuValue = Double(LarkPerfBase.devicCpuUsage(begin:self.currentPerfInfo.deviceCpu,end:perfInfo.deviceCpu))
        self.currentPerfInfo = perfInfo

        
        //低功耗模式
        //获取电量
        let batterylevle = Int(UIDevice.current.batteryLevel * 100)
        //获取充电状态
        let batterystatus = UIDevice.current.batteryState
        //获取温度情况
        let thermalstates = ProcessInfo.processInfo.thermalState
        //获取低功耗模式
        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if batterylevle < 30 && batterystatus != .charging
            && (thermalstates != .fair && thermalstates != .nominal) && isLowPower == true {
            status.isLowBattery = true
            status.downgradeStatus = true
        }
        self.currentStatus = status
        return status
    }

    //初始化
    public init(){
        //开启电池状态监听
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.currentPerfInfo = LarkPerfBase.perfInfo()
        self.config = LarkDowngradeConfig(isNormal: true)
        self.downgradeManager = LarkDownradeTaskManager(downgradeConfig: self.config)
    }

    //外部更新Config
    public func updateWithDic(dictionary: [String: Any]) {
        LarkDowngradeService.logger.info("LarkDowngrade_Config: \(String(describing: dictionary))")
        self.config.updateWithDic(dictionary: dictionary)
        self.downgradeManager.updateNormalConfig(downgradeConfig: self.config)
    }

    public func Start() {
        //监听
        //APP整体状态监听
        appStatusTimer = Timer.init(timeInterval: 2, repeats: true) { [weak self] (_) in
            guard let `self` = self else { return }
            self.timerQueue.async {
                if !self.config.enableDowngrade { return }
                let downgradeStatus = self.getAppStatus()
                LarkDowngradeService.logger.info("LarkDowngrade_Status: \(String(describing: downgradeStatus.toRecordDict()))")
                self.downgradeManager.downgrade(status: downgradeStatus)
                
            }
        }
        if let curTimer: Timer = appStatusTimer {
            RunLoop.main.add(curTimer, forMode: .common)
        }
    }

    public func addObserver(key: String,//降级key
                            indexes: [LarkDowngradeIndex] = [],//关注指标
                            config: LarkDowngradeConfig = LarkDowngradeConfig(isNormal: true), //个别业务关注指标需要自定义，默认不用填
                            level: LarkDowngradeLevel = .high,//降级级别,扩展用,默认不用填写
                            isAsyn: Bool = false, //是否为异步降级
                            doDowngrade: @escaping DowngradeAction,//降级处理
                            doCancel: @escaping DowngradeAction,//终止
                            doNormal: @escaping DowngradeAction) //恢复处理
    {
        if !self.config.enableDowngrade { return }
        if self.config.getNormalLevel().contains(key) || self.abConfig.getNormalLevel().contains(key) {
            return
        }
        let task = LarkDowngradeTask()
        task.key = key
        task.indexs = indexes
        task.downgradeConfig = config.isNormal ? self.config : config
        task.isNomal = config.isNormal
        task.isAsyn = isAsyn
        task.doNormal =  doNormal
        task.downgradeLevel = level
        task.doDowngrade = doDowngrade
        self.downgradeManager.addTask(task: task)
         
    }
    
    public func removeObserver(key: String) {
        self.downgradeManager.removeTask(key: key)
    }

    //监听事件执行前后 app状态
//    public func RecordAppStatus(key: String,hasStart: Bool = true,scene: String = "",type: String = "downgrade", action: () -> Void) {
//
//        if !self.config.enableDowngrade {
//            action()
//            return
//        }
//
//        let startMemory = hasStart ? LarkPerfBase.memoryUsage() : 0
//        let start_task_cpu_time = hasStart ? Double(clock()) / Double(CLOCKS_PER_SEC) :0
//        let start_time = CACurrentMediaTime()
//        action()
//        let endMemory = LarkPerfBase.memoryUsage() - startMemory
//        let end_task_cpu_time = hasStart ? Double(clock()) / Double(CLOCKS_PER_SEC) - start_task_cpu_time :0
//        let end_time = CACurrentMediaTime() - start_time
//        let cpu_used = end_task_cpu_time / end_time
//
//        let eventParams: [AnyHashable: Any] = [
//            "key": key ,
//            "memory": endMemory,
//            "cpuUsage": cpu_used,
//            "scene": scene,
//            "type": type
//        ]
//        //demo
//        let startEvent = TeaEvent("perf_downgrade_info_dev", params: eventParams)
//        Tracker.post(startEvent)
//    }
}
