//
//  OPMonitoredObjectProtocol.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/24.
//

import Foundation

public typealias OPMemoryMonitoredObjectType = NSObject & OPMemoryMonitorObjectProtocol

/// 所有需要接入性能检测机制的对象都需要遵循该协议
@objc public protocol OPMemoryMonitorObjectProtocol {

    /// 实例数量的最大值
    @objc optional static var overcountNumber: UInt { get }

    /// 是否允许内存波动检测
    @objc optional static var enableMemoryWaveDetect: Bool { get }

}

extension OPMemoryMonitorObjectProtocol {
    /// 给所有接入对象性能指标检测机制的类型提供一个typeIdentifier，值为其实际类型的名称
    public static var typeIdentifier: String {
        return "\(Self.self)"
    }
}
