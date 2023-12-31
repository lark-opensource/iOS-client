//
// Created by liujianlong on 2022/11/15.
//

import Foundation
import ByteViewTracker

/*
// NOTE: 控制埋点上报浮点数精度
@propertyWrapper
struct Precision: Encodable {
    init(wrappedValue defaultValue: Float = 0.0, precision: Int) {
        self.precision = precision
        self.val = defaultValue
    }
    private let precision: Int
    private var val: Float
    var wrappedValue: Float {
        get {
            val
        }
        set {
            val = newValue
        }
    }

    func encode(to encoder: Encoder) throws {
        try String(format: "%0.\(precision)f", val).encode(to: encoder)
    }
}
*/

struct ProcessorBasicInfo {
    var cpuType: Int
    var cpuSubtype: Int
    var slotNum: Int
    var isMain: Bool
    var isRunning: Bool
}

extension ProcessorBasicInfo: CustomStringConvertible {
    var description: String {
        "(cpuType: \(cpuType), cpuSubtype: \(cpuSubtype), slotNum: \(slotNum), isMain: \(isMain), isRunning: \(isRunning))"
    }
}

struct CPUCoreAggregatedRecord {
    var avg: Float

    var minVal: Float

    var maxVal: Float
    var p50: Float

    var p75: Float

    var p95: Float
    var isMain: Bool
}

extension CPUCoreAggregatedRecord: CustomStringConvertible {
    // https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html
    var description: String {
        String(format: "(avg:%.2f%%, min:%.2f%%, max:%.2f%%, p50:%.2f%%, p75:%.2f%%, p95:%.2f%%)",
               avg * 100,
               minVal * 100,
               maxVal * 100,
               p50 * 100,
               p75 * 100,
               p95 * 100)
    }
}

extension CPUCoreAggregatedRecord {
    static func aggregate(cpuCoreUsages: [[Float]]) -> [CPUCoreAggregatedRecord] {
        guard !cpuCoreUsages.isEmpty else {
            return []
        }
        let sampleCount = cpuCoreUsages.count
        // disable-lint: magic number
        let p50Idx = min(Int(Float(sampleCount) * 0.5), sampleCount - 1)
        let p75Idx = min(Int(Float(sampleCount) * 0.75), sampleCount - 1)
        let p95Idx = min(Int(Float(sampleCount) * 0.95), sampleCount - 1)
        // enable-lint: magic number
        var coreStatistics: [CPUCoreAggregatedRecord] = []
        let processorCount = CPUCoreUsagesCollector.processorBasicInfos.count
        coreStatistics.reserveCapacity(processorCount)
        for coreIdx in 0..<processorCount {
            let sortedUsages = cpuCoreUsages.map { $0.count > coreIdx ? $0[coreIdx] : 0.0 }.sorted()
            let sum: Float = sortedUsages.reduce(0.0) {
                $0 + $1
            }
            coreStatistics.append(CPUCoreAggregatedRecord(avg: sum / Float(sampleCount),
                                                          minVal: sortedUsages.first!,
                                                          maxVal: sortedUsages.last!,
                                                          p50: sortedUsages[p50Idx],
                                                          p75: sortedUsages[p75Idx],
                                                          p95: sortedUsages[p95Idx],
                                                          isMain: CPUCoreUsagesCollector.processorBasicInfos[coreIdx].isMain))

        }
        return coreStatistics
    }
}

extension AggregateCoreCPUEvent {
    static func coreCPUEvent(cpuCoreUsages: [[Float]], ts: Int64, period: Int64, pCoreStartIdx: Int) -> AggregateCoreCPUEvent? {
        guard !cpuCoreUsages.isEmpty else {
            return nil
        }
        var records: [CPUCoreRecord] = []
        let processorCount = CPUCoreUsagesCollector.processorBasicInfos.count
        records.reserveCapacity(processorCount)
        var pValues = [Float]()
        var eValues = [Float]()
        var pCoresCnt = 0
        var eCoresCnt = 0
        for idx in 0..<processorCount {
            let usages = cpuCoreUsages.map { $0.count > idx ? $0[idx] : 0.0 }
            let isPCore = idx >= pCoreStartIdx && pCoreStartIdx > 0
            if isPCore {
                pValues.append(contentsOf: usages)
                pCoresCnt += 1
            } else {
                eValues.append(contentsOf: usages)
                eCoresCnt += 1
            }
            let record = CPUCoreRecord(index: idx, values: usages, isPCore: isPCore)
            records.append(record)
        }
        let pcores = CpuCoresAggRecord.record(coreCount: pCoresCnt, values: pValues)
        let ecores = CpuCoresAggRecord.record(coreCount: eCoresCnt, values: eValues)
        let event = AggregateCoreCPUEvent(sampleTs: ts,
                                          period: period,
                                          pCoreStartIdx: pCoreStartIdx,
                                          records: records,
                                          pcores: pcores,
                                          ecores: ecores)
        return event
    }
}

extension CpuCoresAggRecord {
    static func record(coreCount: Int, values: [Float]) -> CpuCoresAggRecord {
        if values.isEmpty {
            return CpuCoresAggRecord(coreCount: coreCount,
                                     sampleCount: 0,
                                     avg: 0.0,
                                     max: 0.0,
                                     min: 0.0,
                                     p50: 0.0,
                                     p75: 0.0,
                                     p95: 0.0)
        }
        let sampleCount = values.count
        // disable-lint: magic number
        let p50Idx = max(min(Int(Float(sampleCount) * 0.5), sampleCount - 1), 0)
        let p75Idx = max(min(Int(Float(sampleCount) * 0.75), sampleCount - 1), 0)
        let p95Idx = max(min(Int(Float(sampleCount) * 0.95), sampleCount - 1), 0)
        // enable-lint: magic number
        let sortedUsages = values.sorted()
        let sum: Float = sortedUsages.reduce(0.0) { $0 + $1 }
        let avg = sampleCount > 0 ? sum / Float(sampleCount) : 0.0
        let record = CpuCoresAggRecord(coreCount: coreCount,
                                       sampleCount: sampleCount,
                                       avg: avg,
                                       max: sortedUsages.last ?? 0.0,
                                       min: sortedUsages.first ?? 0.0,
                                       p50: sampleCount > 0 ? sortedUsages[p50Idx] : 0.0,
                                       p75: sampleCount > 0 ? sortedUsages[p75Idx] : 0.0,
                                       p95: sampleCount > 0 ? sortedUsages[p95Idx] : 0.0)
        return record
    }
}

class CPUCoreUsagesCollector {
    // swiftlint:disable large_tuple
    private typealias CPUTicks = (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)
    // swiftlint:enable large_tuple

    static let processorBasicInfos: [ProcessorBasicInfo] = {
        var processorCount: natural_t = 0
        var processorInfo = processor_info_array_t(bitPattern: 0)
        var processorInfoCount = mach_msg_type_number_t(0)

        let ret = host_processor_info(mach_host_self(), PROCESSOR_BASIC_INFO, &processorCount, &processorInfo, &processorInfoCount)
        if ret != KERN_SUCCESS {
            return []
        }
        defer {
            vm_deallocate(mach_task_self_, unsafeBitCast(processorInfo, to: vm_address_t.self), vm_size_t(processorInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        var cpuBasicInfos: [ProcessorBasicInfo] = []
        cpuBasicInfos.reserveCapacity(Int(processorCount))
        processorInfo?.withMemoryRebound(to: processor_basic_info.self, capacity: Int(processorCount)) { ptr in
            for i in 0..<Int(processorCount) {
                let info = ptr.advanced(by: i).pointee
                cpuBasicInfos.append(ProcessorBasicInfo(cpuType: Int(info.cpu_type),
                                                        cpuSubtype: Int(info.cpu_subtype),
                                                        slotNum: Int(info.slot_num),
                                                        isMain: info.is_main != 0,
                                                        isRunning: info.running != 0))
            }
        }
        return cpuBasicInfos
    }()

    static func canSampleHighLoad(pCoreIdx: Int) -> Bool {
        let processorCount = Self.processorBasicInfos.count
        let range = 1..<processorCount
        return range.contains(pCoreIdx)
    }

    private var previousTicks: [CPUTicks]?
    private let thread: ObjectIdentifier

    init() {
        self.thread = ObjectIdentifier(Thread.current)
        Logger.monitor.info("startCPUCoreMonitor, coreInfos \(Self.processorBasicInfos)")
    }
    func collect() -> [Float]? {
        assert(ObjectIdentifier(Thread.current) == self.thread)
        var cpuInfo = processor_info_array_t(bitPattern: 0)
        var cpuCount = natural_t(0)
        var size = mach_msg_type_number_t(0)
        let ret = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &cpuInfo, &size)
        if ret != KERN_SUCCESS {
            return nil
        }
        defer {
            vm_deallocate(mach_task_self_,
                          unsafeBitCast(cpuInfo, to: vm_address_t.self),
                          vm_size_t(size) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        var newTicks: [CPUTicks] = []
        newTicks.reserveCapacity(Int(cpuCount))
        cpuInfo?.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(cpuCount)) { ptr in
            for i in 0..<Int(cpuCount) {
                let ticks = ptr.advanced(by: i).pointee.cpu_ticks
                newTicks.append(ticks)
            }
        }
        defer {
            previousTicks = newTicks
        }

        if previousTicks == nil {
            return nil
        }
        var usages: [Float] = []
        usages.reserveCapacity(newTicks.count)
        for i in 0..<min(previousTicks!.count, newTicks.count) {
            let (user, system, idle, nice) = (
                newTicks[i].user &- previousTicks![i].user,
                newTicks[i].system &- previousTicks![i].system,
                newTicks[i].idle &- previousTicks![i].idle,
                newTicks[i].nice &- previousTicks![i].nice)

            let totalTicks = user &+ system &+ idle &+ nice
            if totalTicks == 0 {
                usages.append(0)
            } else {
                usages.append(Float(user &+ system &+ nice) / Float(totalTicks))
            }
        }
        return usages
    }
}
