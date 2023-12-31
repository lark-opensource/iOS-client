import Foundation

public struct LarkPerfAppInfo {
    public var cpuValue: Double = 0
    public var cpuTime: Double = 0
    public var memory: Int64 = 0
    public var deviceCpu:host_cpu_load_info_data_t = host_cpu_load_info_data_t()
    public init(cpuValue:Double = 0,cpuTime:Double = 0,memory:Int64 = 0,deviceCpu:host_cpu_load_info_data_t = host_cpu_load_info_data_t()) {
        self.cpuValue = cpuValue
        self.cpuTime = cpuTime
        self.memory = memory
        self.deviceCpu = deviceCpu
    }
}
    //获取当前app内存
let LarktaskVmInfoCount = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size

public class LarkPerfBase {
    
    public static func memoryUsage() -> Int64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(LarktaskVmInfoCount)
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: LarktaskVmInfoCount) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.phys_footprint)
        }
        return 0
    }
    
    public static func cpuUsegeClock() -> LarkPerfAppInfo {
        let task_cpu_time = Double(clock()) / (Double(CLOCKS_PER_SEC) * 0.001)
        let current_time = CACurrentMediaTime() * 1000
        let devic_cpu = lark_perfbase_device_cpu()
        return LarkPerfAppInfo(cpuValue:task_cpu_time,cpuTime:current_time,deviceCpu: devic_cpu)
    }
    
    public static func perfInfo() -> LarkPerfAppInfo {
        let task_cpu_time = Double(clock()) / (Double(CLOCKS_PER_SEC) * 0.001)
        let current_time = CACurrentMediaTime() * 1000
        let current_memory = LarkPerfBase.memoryUsage()
        let devic_cpu = LarkPerfBase.devicCpuUsageClock()
        return LarkPerfAppInfo(cpuValue:task_cpu_time,cpuTime:current_time,memory: current_memory,deviceCpu: devic_cpu)
    }
    
    public static func devicCpuUsageClock() -> host_cpu_load_info {
        return lark_perfbase_device_cpu()
    }
    
    public static func devicCpuUsage(begin:host_cpu_load_info,end:host_cpu_load_info) -> Double {
        return lark_perfbase_device_cpu_cal(begin, end)
    }
    
    public static func cpuNum() -> Int {
        return ProcessInfo.processInfo.activeProcessorCount
    }
    
    //获取瞬时CPU
    public static func larkPerfCpuUsage() -> Double {
        var arr: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let threadBasicInfoCount = MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size
        
        guard task_threads(mach_task_self_, &arr, &threadCount) == KERN_SUCCESS,
              let threads = arr else {
            return 0.0
        }
        
        defer {
            let size = MemoryLayout<thread_t>.size * Int(threadCount)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(size))
        }
        var cpuUsage = 0.0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(threadBasicInfoCount)
            let kerr = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: threadBasicInfoCount) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            guard kerr == KERN_SUCCESS else {
                return 0.0
            }
            if info.flags & TH_FLAGS_IDLE == 0 {
                cpuUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE)
            }
        }
        return cpuUsage
    }
}
