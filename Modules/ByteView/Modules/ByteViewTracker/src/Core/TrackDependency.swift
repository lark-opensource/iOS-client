//
//  TrackDependency.swift
//  ByteViewTracker
//
//  Created by kiri on 2023/7/3.
//

import Foundation

public protocol TrackDependency {
    /// 记录一次Exception
    func trackUserException(_ exceptionType: String)
    /// 记录一次头像有关数据
    func trackAvatar()
    /// 获取当前内存使用
    func getCurrentMemoryUsage() -> MemoryUsage?

    func dumpMemoryGraph()
}

public struct MemoryUsage: Equatable {
    public let appUsageBytes: UInt64
    public let systemUsageBytes: UInt64
    public let availableUsageBytes: UInt64

    public init(appUsageBytes: UInt64, systemUsageBytes: UInt64, availableUsageBytes: UInt64) {
        self.appUsageBytes = appUsageBytes
        self.systemUsageBytes = systemUsageBytes
        self.availableUsageBytes = availableUsageBytes
    }
}

private extension VCTracker {
    static var dependency: TrackDependency?
}

public extension VCTracker {
    static func setupDependency(_ dependency: TrackDependency) {
        self.dependency = dependency
    }

    /// 记录一次Exception
    func trackUserException(_ exceptionType: String) {
        Self.dependency?.trackUserException(exceptionType)
    }

    /// 记录一次头像有关数据
    func trackAvatar() {
        Self.dependency?.trackAvatar()
    }

    /// 获取当前内存使用
    /// - note: 系统API"host_statistics64"在iOS11系统上会卡1s左右，iOS11主线程单次runloop请勿频繁调用
    func getCurrentMemoryUsage() -> MemoryUsage? {
        Self.dependency?.getCurrentMemoryUsage()
    }

    func dumpMemoryGraph() {
        Self.dependency?.dumpMemoryGraph()
    }
}
