//
//  MinutesCPUMonitor.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/13.
//

import Foundation

public struct ThreadCPUUsage {
    let index: Int
    let usage: Double
    let threadID: UInt64
    let threadName: String
}

public struct CPUUsage {
    public private(set) var process: Double = 0.0
    public private(set) var system: Double = 0.0
    public private(set) var threadInfo: [ThreadCPUUsage] = []
    private let topN: Int

    init(_ topN: Int) {
        self.topN = topN
    }

    mutating func update(_ system: Double) {
        self.system = system
    }

    mutating func update(_ usage: ThreadCPUUsage) {
        self.process = self.process + usage.usage

        let index = self.threadInfo.firstIndex { info in
            info.usage < usage.usage
        }

        if let i = index {
            self.threadInfo.insert(usage, at: i)
        } else if self.threadInfo.count < topN {
            self.threadInfo.append(usage)
        }

        if self.threadInfo.count > topN {
            let k = self.threadInfo.count - topN
            self.threadInfo.removeLast(k)
        }
    }

    mutating func adjust(for cores: Int) {
        self.process = self.process / Double(cores)
    }

}

public final class CPUMonitor {

    lazy var previousInfo: host_cpu_load_info = host_cpu_load_info()
    var topN: Int = 5

    func cpuCount() -> Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    func getThreadName(_ thread: thread_inspect_t) -> String? {
        var threadInfo = thread_extended_info()
        var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
        let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                thread_info(thread, thread_flavor_t(THREAD_EXTENDED_INFO), $0, &threadInfoCount)
            }
        }

        guard infoResult == KERN_SUCCESS else {
            return nil
        }
        // disable-lint: magic number
        let threadName = withUnsafePointer(to: threadInfo.pth_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: 64) {
                String(cString: $0)
            }
        }
        // enable-lint: magic number
        return threadName
    }

    func cpuUsage() -> CPUUsage {
        var cpuUsage: CPUUsage = CPUUsage(topN)

        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let thread = threadsList[Int(index)]
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(thread, thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }

                guard infoResult == KERN_SUCCESS else {
                    continue
                }

                guard threadInfo.flags & TH_FLAGS_IDLE == 0 else {
                    continue
                }

                var usage = Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                var pid: UInt64 = 0
                var threadName = "<NULL>"

                if let pthread = pthread_from_mach_thread_np(thread) {
                    let result = pthread_threadid_np(pthread, &pid)
                }

                if index == 0 {
                    threadName = "main"
                } else if let name = getThreadName(thread) {
                    threadName = name
                }

                let threadUsage = ThreadCPUUsage(index: Int(index), usage: usage, threadID: pid, threadName: threadName)
                cpuUsage.update(threadUsage)
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))

        let cores = self.cpuCount()
        cpuUsage.adjust(for: cores)

        let system = systemCPUUsage()
        cpuUsage.update(system)

        return cpuUsage
    }

    func systemCPUUsage() -> Double {

        let maxHostCpuLoadInfoSize = MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(maxHostCpuLoadInfoSize)
        var info = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: maxHostCpuLoadInfoSize) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        let userDiff = Double(info.cpu_ticks.0 - previousInfo.cpu_ticks.0)
        let sysDiff = Double(info.cpu_ticks.1 - previousInfo.cpu_ticks.1)
        let idleDiff = Double(info.cpu_ticks.2 - previousInfo.cpu_ticks.2)
        let niceDiff = Double(info.cpu_ticks.3 - previousInfo.cpu_ticks.3)

        let totalTicks = sysDiff + userDiff + niceDiff + idleDiff

        let sys = sysDiff / totalTicks * 100.0
        let user = userDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0

        let used = user + nice + sys

        return used
    }

}
