//
//  OPMemoryInfoUploader.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/9.
//

import Foundation

/// 负责发生内存泄漏之后，将相关的信息进行上报
@objcMembers
public final class OPMemoryInfoUploader: NSObject {

    // MARK: - static allocator register

    /// 每个事件对应的初始allocators
    private static var eventAllocators: [OPPerformanceMonitorEvent: [OPMemoryInfoAllocator]] = [:]

    /// 保护全局allocator注册逻辑的锁
    private static let registerSemaphore = DispatchSemaphore(value: 1)

    /// 将某个allocator作为特定事件的初始allocator注册进去
    public static func register(allocator: OPMemoryInfoAllocator, for events: [OPPerformanceMonitorEvent]) {
        registerSemaphore.wait()
        defer { registerSemaphore.signal() }

        for event in events {
            var allocatorList = eventAllocators[event] ?? []
            // 防止相同的allocator被多次注册进同一个event之内
            if allocatorList.contains(where: {$0.id == allocator.id}) {
                continue
            } else {
                allocatorList.append(allocator)
                eventAllocators[event] = allocatorList
            }
        }
    }

    /// 将某个allocator注册成为所有事件的初始allocator
    public static func registerForAllEvent(allocator: OPMemoryInfoAllocator) {
        register(allocator: allocator, for: OPPerformanceMonitorEvent.allCases)
    }

    // MARK: - instance logic

    /// 初始化方法
    init(with event: OPPerformanceMonitorEvent) {
        self.event = event
        super.init()

        // 检查外部是否有注册该事件的初始allocator，如果有就在初始化时注册到实例上去
        if let initialAllocators = Self.eventAllocators[event] {
            initialAllocators.forEach { self.registerInfoAllocator($0) }
        }
    }

    /// 所有的信息收集插件
    private var leakInfoAllocators: [String: OPMemoryInfoAllocator] = [:]
    /// 当前uploader所负责的事件
    private let event: OPPerformanceMonitorEvent
    /// 保护leakInfoAllocators写入的锁
    private let semaphore = DispatchSemaphore(value: 1)

    private var monitor: OPMonitor {
        OPMonitor(event.monitorCode)
            .setTime(Date().timeIntervalSince1970)
    }

    /// 触发内存性能监控事件，上传相关信息
    /// - Parameters:
    ///   - target: 导致此次事件发生的对象
    ///   - monitorUpdater: 在开始上传之前可以对monitor进行额外的操作
    func uploadLeakInfo(with target: NSObject, monitorUpdater: ((OPMonitor)->Void)? = nil) {
        let monitor = self.monitor
        semaphore.wait()
        for allocator in leakInfoAllocators.values {
            allocator.allocateMemoryInfo(with: target, monitor: monitor)
        }
        semaphore.signal()

        monitorUpdater?(monitor)

        monitor.flush()
    }

    /// 向OPLeakUploader中注册新的信息收集器
    public func registerInfoAllocator(_ allocator: OPMemoryInfoAllocator) {
        semaphore.wait()
        leakInfoAllocators[allocator.id] = allocator
        semaphore.signal()
    }

}

/// 内存泄漏信息收集器
/// 职责：当发生内存泄漏时收集与泄漏对象相关且必须的上下文信息并将信息设置进OPMonitor中
public protocol OPMemoryInfoAllocator {
    func allocateMemoryInfo(with target: NSObject, monitor: OPMonitor)
}

/// 为了防止allocator多次被注册，提供一个唯一的id
/// ID即为allocator的真正的类名
extension OPMemoryInfoAllocator {
    var id: String {
        return "\(Self.self)"
    }
}
