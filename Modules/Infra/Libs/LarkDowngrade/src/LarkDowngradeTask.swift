//
//  LarkDowngradeTask.swift
//  LarkDowngrade
//
//  Created by sniperYJ on 2023/9/1.
//

import Foundation

//降级任务
public class LarkDowngradeTask {
    public var downgradeConfig: LarkDowngradeConfig = LarkDowngradeConfig()  //业务特定配置
    public var isNomal: Bool = true
    public var isAsyn: Bool = false
    public var key: String = ""  //降级key
    public var status: LarkDowngradeTaskStatus = .normal
    public var doDowngrade: DowngradeAction = { status in } //降级逻辑
    public var doNormal: DowngradeAction = { status in }   //恢复逻辑
    public var indexs: [LarkDowngradeIndex] = [] //关注指标
    public var appStatus: LarkDowngradeAppStatues = LarkDowngradeAppStatues()
    public var funcTime: Double = 0 //升降的处理时间
    public var downgradeLevel: LarkDowngradeLevel = .high
    private var unfairLock = os_unfair_lock_s()

    init() {}

    //异步任务更新状态
    public func updateStatus(complete: Bool) {
        if complete {
            if self.status == .upgrading { self.status = .normal }
            if self.status == .downgrading { self.status = .downgraded }
        } else {
            if self.status == .upgrading { self.status = .downgraded }
            if self.status == .downgrading { self.status = .normal }
        }
    }

    //获取规则匹配后结果，onlyDowngrade 用于静态降级 只判断降级
    public func getDowngradeRuleListResult(status: LarkDowngradeStatus, rulelist: [LarkDowngradeRule], onlyDowngrade: Bool = false) -> LarkDowngradeRuleResult {
        var result = LarkDowngradeRuleResult.normal
        for rules in rulelist {
            //规则内部 先降级→终止→升级
            if self.status != .downgraded || onlyDowngrade {
                if let rulsInfo = rules.rules[.overload] {
                    for ruleDic in rulsInfo {
                        if  getDowngradeRuleListResult(status: status, rule: ruleDic, isDowngrade: true) {
                            //降级满足一个即降级
                            return .downgrade
                        }
                    }
                }
            } else {
                if self.status == .upgrading || self.status == .downgrading {
                    if let rulsInfo = rules.rules[.stop] {
                        for ruleDic in rulsInfo {
                            if !getDowngradeRuleListResult(status: status, rule: ruleDic, isDowngrade: false){
                                return .normal
                            }else{
                                result = .stop
                            }
                        }
                    }
                } else {
                    if self.status == .downgraded {
                        if let rulsInfo = rules.rules[.normal] {
                            for ruleDic in rulsInfo {
                                if !getDowngradeRuleListResult(status: status, rule: ruleDic, isDowngrade: false) {
                                    return .normal
                                }else{
                                    result = .upgrade
                                }
                                
                            }
                        }
                    }
                }
            }
        }
        
        return result
    }

    //判断是否符合规则
    public func getDowngradeRuleListResult(status: LarkDowngradeStatus, rule: LarkDowngradeRuleInfo, isDowngrade: Bool) -> Bool {
        os_unfair_lock_lock(&unfairLock); defer { os_unfair_lock_unlock(&unfairLock) }
        var match = true
        var matchRules = Array<Dictionary<String,Any>>()
        rule.ruleList.forEach({ (key: LarkDowngradeIndex, value: Double) in
            matchRules.append(["index":key.rawValue,
                               "limit":value,
                               "key":self.key,
                               "time":rule.time,
                               "type":isDowngrade ? LarkDowngradeRuleResult.downgrade.rawValue : LarkDowngradeRuleResult.upgrade.rawValue])
            switch key {
            case .lowDevice:
                if !isDowngrade { match = false }
                if status.deviceValue > value { match = false }
            case .unknow:
                break
            case .overCPU:
                let count = Int(ceil(rule.time/2))
                if count > self.appStatus.cpuRecorder.count {
                    match = false
                    break
                }
                for i in 0..<count {
                    let cpuValue = self.appStatus.cpuRecorder[i]
                    if isDowngrade {
                        if cpuValue < value { match = false }
                    } else {
                        if cpuValue > value { match = false }
                    }
                }
            case .overDeviceCPU:
                let count = Int(ceil(rule.time/2))
                if count > self.appStatus.deviceCpuRecorder.count {
                    match = false
                    break
                }
                for i in 0..<count {
                    let devicCpuValue = self.appStatus.deviceCpuRecorder[i]
                    if isDowngrade {
                        if devicCpuValue < value { match = false }
                    } else {
                        if devicCpuValue > value { match = false }
                    }
                }
            case .overMemory:
                if isDowngrade {
                    if status.memoryValue > value { match = false }
                } else {
                    if status.memoryValue < value { match = false }
                }
            case .overTemperature:
                let count = Int(ceil(rule.time/2))
                if count > self.appStatus.temperatureRecorder.count {
                    match = false
                    break
                }
                for i in 0..<count {
                    let temperaValue = self.appStatus.temperatureRecorder[i]
                    if isDowngrade {
                        if temperaValue < value { match = false }
                    } else {
                        if temperaValue >= value { match = false }
                    }
                }
            case .lowBattery:
                break
            }

        })
        //如果符合规则 把规则进行上报
        if match {
            for machRule in matchRules {
                LarkDowngradeUtility.recordRulesMach(eventParam: machRule)
            }
        }
        return match
    }

    public func doDowngrading(status: LarkDowngradeStatus) {
        self.doDowngrade(status)
        LarkDowngradeUtility.recordDowngradeDo(key: self.key, status: status, result: .downgrade)
        self.funcTime = CACurrentMediaTime()

        if self.isAsyn {
            self.status = .downgrading
        } else {
            self.status = .downgraded
        }
    }
    
    public func doUpgrading(status: LarkDowngradeStatus) {
        self.doNormal(status)
        LarkDowngradeUtility.recordDowngradeDo(key: self.key, status: status, result: .upgrade)
        self.funcTime = CACurrentMediaTime()

        if self.isAsyn {
            self.status = .upgrading
        } else {
            self.status = .normal
        }
    }
}
