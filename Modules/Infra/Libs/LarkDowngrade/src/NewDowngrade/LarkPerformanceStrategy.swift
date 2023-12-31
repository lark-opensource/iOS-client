//
//  LarkPerformanceStrategy.swift
//  DowngradeTest
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation
import Heimdallr
import LarkPerfBase
import LKCommonsLogging
import ThreadSafeDataStructure

infix operator |&| : AdditionPrecedence
infix operator ||| : AdditionPrecedence
public enum LarkPerformanceStrategyType {
    static var logger = Logger.log(LarkPerformanceStrategyType.self)
    case lowDevice(Double? = nil)   //低端机
    case overCPU(Double? = nil, Double? = nil, Double? = nil) //CPU
    case overDeviceCPU(Double? = nil, Double? = nil, Double? = nil) //设备CPU
    case overMemory(Double? = nil, Double? = nil)  //内存
    case overBattery(Double, Double) //电量
    case overTemperature(Double? = nil, Double? = nil, Double? = nil) //温度

    public func getKey() -> String {
        switch self {
        case .lowDevice(_):
            return "lowDevice"
        case .overCPU(_, _, _):
            return "overCPU"
        case .overDeviceCPU(_, _, _):
            return "overDeviceCPU"
        case .overMemory(_, _):
            return "overMemory"
        case .overBattery(_, _):
            return "overBattery"
        case .overTemperature(_, _, _):
            return "overTemperature"
        }
    }

    public func getPerformanceRule() -> LarkUniversalDowngradeRule {
        switch self {
        case let .lowDevice(deviceValue):
            return LarkPerformanceLowDeviceRule(deviceValue: deviceValue)
        case let .overCPU(downgradeValue, upgradeValue, times):
            return LarkPerformanceCPURule(cpuDowngradeValue: downgradeValue, cpuUpgradeValue: upgradeValue, times: times)
        case let .overDeviceCPU(downgradeValue, upgradeValue, times):
            return LarkPerformanceDeviceCPURule(deviceDowngradeCpuValue: downgradeValue, deviceUpgradeCpuValue: upgradeValue, times: times)
        case let .overMemory(downgradeValue, upgradeValue):
            return LarkPerformanceMemoryRule(downgradeValue: downgradeValue, upgradeValue: upgradeValue)
        case let .overBattery(downgradeValue, upgradeValue):
            return LarkPerformanceBatteryRule(downgradeValue: downgradeValue, upgradeValue: upgradeValue)
        case let .overTemperature(downgradeValue, upgradeValue, times):
            return LarkPerformanceTemperatureRule(temperatureDowngradeValue: downgradeValue, temperatureUpgradeValue: upgradeValue, times: times)
        }
    }
    
    public static func |&| (operand1: LarkPerformanceStrategyType, operand2: LarkPerformanceStrategyType) -> [String: LarkPerformanceStrategyType] {
        if operand1.getKey() == operand2.getKey() {
            assertionFailure("LarkPerformacenStrategy add same rules \(operand1.getKey())")
            LarkPerformanceStrategyType.logger.error("LarkPerformacenStrategy add same rules \(operand1.getKey())")
        }
        var result = [operand1.getKey(): operand1]
        result[operand2.getKey()] = operand2
        return result
    }

    public static func |&| (operand1: [String: LarkPerformanceStrategyType], operand2: LarkPerformanceStrategyType) -> [String: LarkPerformanceStrategyType] {
        if let v = operand1[operand2.getKey()] {
            assertionFailure("LarkPerformacenStrategy add same rules \(v.getKey())")
            LarkPerformanceStrategyType.logger.error("LarkPerformacenStrategy add same rules \(v.getKey())")
        }
        var result = operand1
        result[operand2.getKey()] = operand2
        return result
    }
    
    public static func ||| (operand1: LarkPerformanceStrategyType, operand2: LarkPerformanceStrategyType) -> [LarkPerformanceStrategyType] {
        return [operand1, operand2]
    }

    public static func ||| (operand1: [LarkPerformanceStrategyType], operand2: LarkPerformanceStrategyType) -> [LarkPerformanceStrategyType] {
        var result = operand1
        result.append(operand2)
        return result
    }
}


//降级状态
public struct LarkPerformanceStatus {
    public var deviceValue: Double = 10 //设备等级
    public var cpuValue: Double = 0   //前10s cpu均值
    public var memoryValue: Double = Double(hmd_getDeviceMemoryLimit()) / (1024*1024) //当前剩余内存
    public var memoryCurrentValue: Double = 0
    public var memoryLimit: Double = Double(hmd_getDeviceMemoryLimit()) / (1024*1024)
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

public class LarkPerformanceMemoryRule: LarkUniversalDowngradeRule {
    static var logger = Logger.log(LarkPerformanceMemoryRule.self)
    public var ruleKey: String = "LarkPerformanceMemoryRule"
    public var downgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverMemoryConfig().downgradeValue
    public var upgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverMemoryConfig().upgradeValue
    
    public init(downgradeValue: Double?, upgradeValue: Double?) {
        if let dowgrade = downgradeValue {
            self.downgradeValue = dowgrade
        }
        
        if let upgrade = upgradeValue {
            self.upgradeValue = upgrade
        }
    }
    
    public func shouldDowngrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            return status.remainMemory < downgradeValue
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceMemoryRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
    
    public func shouldUpgrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            return status.remainMemory > upgradeValue
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceMemoryRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
}

public class LarkPerformanceBatteryRule: LarkUniversalDowngradeRule {
    static var logger = Logger.log(LarkPerformanceBatteryRule.self)
    public var ruleKey: String = "LarkPerformanceBatteryRule"
    public var downgradeValue: Double
    public var upgradeValue: Double

    public init(downgradeValue: Double, upgradeValue: Double) {
        self.downgradeValue = downgradeValue
        self.upgradeValue = upgradeValue
    }

    public func shouldDowngrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            return status.currentBattery < downgradeValue
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceBatteryRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }

    public func shouldUpgrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            return status.currentBattery > upgradeValue
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceBatteryRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
}

public class LarkPerformanceCPURule: LarkUniversalDowngradeRule {
    static var logger = Logger.log(LarkPerformanceCPURule.self)
    public var ruleKey: String = "LarkPerformanceCPURule"
    public var downgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverCPUConfig().downgradeValue
    public var upgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverCPUConfig().upgradeValue
    public var times: Double = LarkUniversalDowngradeService.shared.config.getOverCPUConfig().times

    public init(cpuDowngradeValue: Double?, cpuUpgradeValue: Double?, times: Double?) {
        if let cpu = cpuDowngradeValue {
            self.downgradeValue = cpu
        }

        if let cpu = cpuUpgradeValue {
            self.upgradeValue = cpu
        }

        if let times = times {
            self.times = times
        }
    }

    public func shouldDowngrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            let count = Int(self.times)
            if count > status.cpuRecorder.count {
                return false
            }
            for i in 0..<count {
                let devicCpuValue = status.cpuRecorder[i]
                if devicCpuValue < downgradeValue {
                    return false
                }
            }
            return true
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceCPURule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }

    public func shouldUpgrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            let count = Int(self.times)
            if count > status.cpuRecorder.count {
                return false
            }
            for i in 0..<count {
                let devicCpuValue = status.cpuRecorder[i]
                if devicCpuValue > upgradeValue {
                    return false
                }
            }
            return true
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceCPURule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
}

public class LarkPerformanceDeviceCPURule: LarkUniversalDowngradeRule {
    static var logger = Logger.log(LarkPerformanceDeviceCPURule.self)
    public var ruleKey: String = "LarkPerformanceDeviceCPURule"
    public var downgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverDeviceCPUConfig().downgradeValue
    public var upgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverDeviceCPUConfig().upgradeValue
    public var times: Double = LarkUniversalDowngradeService.shared.config.getOverDeviceCPUConfig().times

    public init(deviceDowngradeCpuValue: Double?, deviceUpgradeCpuValue: Double?, times: Double?) {
        if let deviceCpu = deviceDowngradeCpuValue {
            self.downgradeValue = deviceCpu
        }

        if let deviceCpu = deviceUpgradeCpuValue {
            self.upgradeValue = deviceCpu
        }

        if let times = times {
            self.times = times
        }
    }

    public func shouldDowngrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            let count = Int(self.times)
            if count > status.deviceCpuRecorder.count {
                return false
            }
            for i in 0..<count {
                let devicCpuValue = status.deviceCpuRecorder[i]
                if devicCpuValue < downgradeValue {
                    return false
                }
            }
            return true
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceDeviceCPURule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }

    public func shouldUpgrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            let count = Int(self.times)
            if count > status.deviceCpuRecorder.count {
                return false
            }
            for i in 0..<count {
                let devicCpuValue = status.deviceCpuRecorder[i]
                if devicCpuValue > upgradeValue {
                    return false
                }
            }
            return true
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceDeviceCPURule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
}

public class LarkPerformanceLowDeviceRule: LarkUniversalDowngradeRule {
    static var logger = Logger.log(LarkPerformanceLowDeviceRule.self)
    public var ruleKey: String = "LarkPerformanceLowDeviceRule"
    public var value: Double = LarkUniversalDowngradeService.shared.config.getLowDeviceConfig().downgradeValue

    public init(deviceValue: Double?) {
        if let device = deviceValue {
            self.value = device
        }
    }

    public func shouldDowngrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            return status.deviceScore < value
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceLowDeviceRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
    
    public func shouldUpgrade(context: Any?) -> Bool {
        return false
    }
}

public class LarkPerformanceTemperatureRule: LarkUniversalDowngradeRule {
    static var logger = Logger.log(LarkPerformanceTemperatureRule.self)
    public var ruleKey: String = "LarkPerformanceTemperatureRule"
    public var downgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverTemperatureConfig().downgradeValue
    public var upgradeValue: Double = LarkUniversalDowngradeService.shared.config.getOverTemperatureConfig().upgradeValue
    public var times: Double = LarkUniversalDowngradeService.shared.config.getOverTemperatureConfig().times

    public init(temperatureDowngradeValue: Double?, temperatureUpgradeValue: Double?, times: Double?) {
        if let temperature = temperatureDowngradeValue {
            self.downgradeValue = temperature
        }

        if let temperature = temperatureUpgradeValue {
            self.upgradeValue = temperature
        }

        if let times = times {
            self.times = times
        }
    }

    public func shouldDowngrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            let count = Int(self.times)
            if count > status.temperatureRecorder.count {
                return false
            }
            for i in 0..<count {
                let temperaValue = status.temperatureRecorder[i]
                if temperaValue < downgradeValue {
                    return false
                }
            }
            return true
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceTemperatureRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }

    public func shouldUpgrade(context: Any?) -> Bool {
        if let status = context as? LarkPerformanceAppStatues {
            let count = Int(self.times)
            if count > status.temperatureRecorder.count {
                return false
            }
            for i in 0..<count {
                let temperaValue = status.temperatureRecorder[i]
                if temperaValue > upgradeValue {
                    return false
                }
            }
            return true
        }
        assertionFailure("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        LarkPerformanceTemperatureRule.logger.error("\(String(describing: type(of: context))) context is not LarkPerformanceAppstatues type")
        return false
    }
}

public class LarkPerformanceAppStatues {
    static var logger = Logger.log(LarkPerformanceAppStatues.self)
    public var cpuRecorder: SafeArray<Double> = SafeArray()
    public var deviceCpuRecorder: SafeArray<Double> = SafeArray()
    public var temperatureRecorder: SafeArray<Double> = SafeArray()
    public var deviceScore: Double = 10
    public var remainMemory: Double = 0
    public var currentBattery: Double = 0
    public static let shared = LarkPerformanceAppStatues()
    private let collectAppPerformanceQueue: DispatchQueue = DispatchQueue(label: "com.lark.collect.performance")
    private let batterylevleMin: Double = 30
    private var timer: DispatchSourceTimer?
    private var currentPerfInfo: LarkPerfAppInfo = LarkPerfAppInfo(cpuValue: 0, cpuTime: 0, memory: 0, deviceCpu: host_cpu_load_info_data_t())

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.currentPerfInfo = LarkPerfBase.perfInfo()
    }

    public func startCollectData() {
        timer = DispatchSource.makeTimerSource(queue: collectAppPerformanceQueue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [weak self] in
            self?.updateStatus()
        }
        timer?.resume()
    }

    public func updateStatus() {
        let status = getPerformanceStatus()
        update(status: status)
        LarkPerformanceAppStatues.logger.info("LarkAppPerformance: \(String(describing: status.toRecordDict()))")
    }

    private func update(status: LarkPerformanceStatus) {
        let limitCount = 30 * 60 * 4
        if self.cpuRecorder.count >= limitCount {
            self.cpuRecorder.remove(at: limitCount - 1)
            self.deviceCpuRecorder.remove(at: limitCount - 1)
            self.temperatureRecorder.remove(at: limitCount - 1)
        }
        self.cpuRecorder.insert(status.cpuValue, at: 0)
        self.deviceCpuRecorder.insert(status.deviceCpuValue, at: 0)
        self.temperatureRecorder.insert(Double(status.temperatureValue.rawValue), at: 0)
        self.deviceScore = status.deviceValue
        self.remainMemory = status.memoryValue
    }

    //获取APP状态信息
    private func getPerformanceStatus() -> LarkPerformanceStatus {
        var status = LarkPerformanceStatus()
        status.deviceValue = LarkUniversalDowngradeService.shared.deviceScore
        //内存
        let currentMemory = Double(LarkPerfBase.memoryUsage()) / (1024 * 1024)
        let limitMemory = Double(hmd_getDeviceMemoryLimit()) / (1024 * 1024)
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
        self.currentBattery = Double(UIDevice.current.batteryLevel * 100)
        //获取充电状态
        let batterystatus = UIDevice.current.batteryState
        //获取温度情况
        let thermalstates = ProcessInfo.processInfo.thermalState
        //获取低功耗模式
        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

        if currentBattery < batterylevleMin && batterystatus != .charging
            && (thermalstates != .fair && thermalstates != .nominal) && isLowPower == true {
            status.isLowBattery = true
        }
        return status
    }
}

public class LarkPerformanceStrategy: LarkUniversalDowngradeStrategy {

    public var allMeetStrategys: [LarkUniversalDowngradeRule]?

    public var oneOfMeetStrategys: [LarkUniversalDowngradeRule]?

    public var strategyKey: String

    private var appStatues = LarkPerformanceAppStatues.shared
    
    private var privateStatus: LarkPerformanceAppStatues?

    convenience public init(strategyKey: String, strategys: [LarkUniversalDowngradeRule], needPrivateData: Bool = false) {
        self.init(key: strategyKey)
        self.oneOfMeetStrategys = strategys
        if needPrivateData {
            privateStatus = LarkPerformanceAppStatues()
        }
    }

    convenience public init(strategyKey: String, strategys: [String: LarkUniversalDowngradeRule], needPrivateData: Bool = false) {
        self.init(key: strategyKey)
        self.allMeetStrategys = []
        for value in strategys.values {
            self.allMeetStrategys?.append(value)
        }
        if needPrivateData {
            privateStatus = LarkPerformanceAppStatues()
        }
    }

    private init(key: String) {
        self.strategyKey = key
    }

    public func updatePrivateDataIfNeeded() {
        if (privateStatus != nil) {
            if let value = appStatues.cpuRecorder.first {
                privateStatus?.cpuRecorder.insert(value, at: 0)
            }
            if let value = appStatues.deviceCpuRecorder.first {
                privateStatus?.deviceCpuRecorder.insert(value, at: 0)
            }
            if let value = appStatues.temperatureRecorder.first {
                privateStatus?.temperatureRecorder.insert(value, at: 0)
            }
        }
    }

    public func clearPrivateDataIfNeeded() {
        if (privateStatus != nil) {
            privateStatus?.cpuRecorder.removeAll()
            privateStatus?.deviceCpuRecorder.removeAll()
            privateStatus?.temperatureRecorder.removeAll()
        }
    }

    public func getData() -> Any? {
        return (privateStatus != nil) ? privateStatus: appStatues
    }
}
