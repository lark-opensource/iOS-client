//
//  LarkDowngradeTaskManager.swift
//  LarkDowngrade
//
//  Created by ByteDance on 2023/3/2.
//

import Foundation
import Heimdallr
import ThreadSafeDataStructure
import LKCommonsTracker
import LKCommonsLogging

//降级处理
public typealias DowngradeAction = (LarkDowngradeStatus) -> Void
//异步降级结果通知
public let DOWNGRADE_COMPLETE_NOTIFY_KEY = Notification.Name("lark_iosDowngrade_Complete")
public let DOWNGRADE_CANCEL_NOTIFY_KEY = Notification.Name("lark_iosDowngrade_Cancel")

//扫描间隔
public let DowngradeInervalTime: Double = 2
//降级记录
var downgradedTasks: [String] = []

//关注指标
//TODO:是否需要调整为0x001
public enum LarkDowngradeIndex: String,CaseIterable {
    case unknow
    case lowDevice   //低端机
    case overCPU     //CPU
    case overDeviceCPU //设备CPU
    case overMemory  //内存
    case overTemperature //温度
    case lowBattery  //低电量
}

//降级等级
public enum LarkDowngradeLevel: String,CaseIterable {
    case unknow
    case normal //正常
    case middle //轻度降级
    case high  //重度降级
}

//机型分类
public enum LarkDowngradeClassify {
    case highMobile         //高端机
    case midMobile          //中端机
    case lowMobile          //低端机
    case unClassifyMobile   //未分类机型
}

//降级规则类型
public enum LarkDowngradeRuleType: String,CaseIterable {
    case overload
    case normal
    case stop
}

//规则处理结果
public enum LarkDowngradeRuleResult: String {
    case normal
    case downgrade
    case upgrade
    case stop
}

//降级任务状态
public enum LarkDowngradeTaskStatus {
    case normal //正常
    case downgrading  //降级中
    case downgraded   //已降级
    case upgrading  //升级中
}

//性能信息存储
public class LarkDowngradeAppStatues {
    public var cpuRecorder: SafeArray<Double> = SafeArray()
    public var deviceCpuRecorder: SafeArray<Double> = SafeArray()
    public var temperatureRecorder: SafeArray<Double> = SafeArray()
    public init() {}

    public func update(status:LarkDowngradeStatus) {
//        let limitCount = 30 * 60 * 4
//        if self.cpuRecorder.count >= limitCount {
//            self.cpuRecorder.remove(at: limitCount-1)
//            self.deviceCpuRecorder.remove(at: limitCount-1)
//            self.temperatureRecorder.remove(at: limitCount-1)
//        }
        self.cpuRecorder.insert(status.cpuValue, at: 0)
        self.deviceCpuRecorder.insert(status.deviceCpuValue, at: 0)
        self.temperatureRecorder.insert(Double(status.temperatureValue.rawValue), at: 0)
    }
}


//降级状态
public struct LarkDowngradeStatus {
    public var downgradeStatus: Bool = false //是否降级
    public var currentSataus: LarkDowngradeTaskStatus = .normal
    public var deviceValue: Double = 10 //设备等级
    public var deviceLevel: LarkDowngradeClassify  = .unClassifyMobile
    public var cpuValue: Double = 0   //前10s cpu均值
    public var cpuLevle: LarkDowngradeLevel = .unknow  //CPU降级等级
    public var memoryValue: Double = Double(hmd_getDeviceMemoryLimit()) / (1024*1024) //当前剩余内存
    public var memoryCurrentValue: Double = 0
    public var memoryLimit: Double = Double(hmd_getDeviceMemoryLimit()) / (1024*1024)
    public var memoryLevle: LarkDowngradeLevel = .unknow  //内存降级等级
    public var temperatureValue = ProcessInfo.ThermalState.nominal
    public var isLowBattery: Bool = false   //是否是低功耗模式
    public var deviceCpuValue: Double = 0
    
    public func toRecordDict() -> Dictionary<String, Any> {
        var record = Dictionary<String, Any>()
        record["cpuUsage"] = self.cpuValue
        record["memory"] = self.memoryValue
        record["device_cpu_usage"] = self.deviceCpuValue
        record["battery_temperature"] = self.temperatureValue.rawValue
        record["is_low_battery"] = self.isLowBattery ? "1" : "0"
        record["device_score"] = self.deviceValue
        return record
    }
}

//降级任务管理
public class LarkDownradeTaskManager {
    var downgradeList: [String] = []
    var downgradeTasks: [String: LarkDowngradeTask] = [:]
    var currentTask: LarkDowngradeTask = LarkDowngradeTask()
    var normalTask: LarkDowngradeTask = LarkDowngradeTask() //正常配置的降级情况
    public var MaxfuncTime: Double = 60 //升降级间隔最大时间

    //添加降级
    func addTask(task: LarkDowngradeTask) {
        self.downgradeList.append(task.key)
        self.downgradeTasks[task.key] = task
    }

    //移除降级
    func removeTask(key: String) {
        self.downgradeList.removeAll(where: {$0 != key})
        self.downgradeTasks.removeValue(forKey: key)
    }

    //初始化
    init(downgradeConfig: LarkDowngradeConfig) {
        self.normalTask = LarkDowngradeTask()
        self.normalTask.downgradeConfig = downgradeConfig
       
        //异步任务完成
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(taskComplete(notification:)),
                                               name: DOWNGRADE_COMPLETE_NOTIFY_KEY,
                                               object: self)
        //异步任务取消
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(taskCancel(notification:)),
                                               name: DOWNGRADE_CANCEL_NOTIFY_KEY,
                                               object: self)
        
    }

    public func updateNormalConfig(downgradeConfig: LarkDowngradeConfig) {
        self.normalTask.downgradeConfig = downgradeConfig
    }

    @objc
    private func taskComplete(notification: NSNotification) {
        guard let key = notification.object as? String else { return }
        if let task = self.downgradeTasks[key] {
            task.updateStatus(complete: true)
        }
    }

    @objc
    private func taskCancel(notification: NSNotification) {
        guard let key = notification.object as? String else { return }
        if let task = self.downgradeTasks[key] {
            task.updateStatus(complete: false)
        }
    }

    public func downgrade(status: LarkDowngradeStatus) {
        //更新各个task的数据
        self.normalTask.appStatus.update(status: status)
        for key in downgradeList {
            if let task = downgradeTasks[key] {
                task.appStatus.update(status: status)
            }
        }
        //处理降级
        let intervalTime = CACurrentMediaTime() - self.currentTask.funcTime
        //正在升降级 或者还没有到时间间隔 直接结束
        if intervalTime < self.MaxfuncTime {
            if (intervalTime < self.currentTask.downgradeConfig.normalInervalTime && self.currentTask.status == .upgrading) || (self.currentTask.status == .downgrading && intervalTime < self.currentTask.downgradeConfig.downgradeIntervalTime){
                return
            }
        }
        for key in downgradeList.reversed() {
            if let task = downgradeTasks[key] {
                let rules = task.downgradeConfig.getRules(indexes: task.indexs, level: task.downgradeLevel)
                let result = task.getDowngradeRuleListResult(status: status, rulelist: rules)
                var isContinue = true
                switch result {
                case .downgrade:
                    if task.status == .normal {
                        self.currentTask = task
                        self.currentTask.doDowngrading(status: status)
                        downgradedTasks.append(task.key)
                        isContinue = false
                        break
                    }
                case .normal:
                    break
                case .upgrade:
                    if task.status == .downgraded {
                        self.currentTask = task
                        self.currentTask.doUpgrading(status: status)
                        isContinue = false
                        break
                    }
                case .stop:
                    break
                }
                if !isContinue { break }
            }
        }
    }
}
