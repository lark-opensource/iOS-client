//
//  DispatchSafeQueue.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/9/5.
//

import Foundation

/// 基于线程判断的调度队列
struct DispatchSafeQueue {

    init(label: String, qos: DispatchQoS = .unspecified, attributes: DispatchQueue.Attributes = [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) {
        let label = "\(label).\(UUID().uuidString)"
        self.label = label
        self.queue = DispatchQueue(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
        self.queue.setSpecific(key: Self.specificKey, value: label)
    }

    /// 私有调度队列
    private let queue: DispatchQueue

    /// 队列名称
    ///
    /// 会在传入的队列名称后添加自动生成的UUID，防止重名
    let label: String

    /// 特殊标记
    private static let specificKey = DispatchSpecificKey<String>()

    func sync<T>(execute work: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: Self.specificKey) == label {
            return try work()
        } else {
            return try queue.sync(execute: work)
        }
    }

    func async(group: DispatchGroup? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], execute work: @escaping @convention(block) () -> Void) {
        queue.async(group: group, qos: qos, flags: flags, execute: work)
    }

    func asyncAfter(deadline: DispatchTime, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], execute work: @escaping @convention(block) () -> Void) {
        queue.asyncAfter(deadline: deadline, qos: qos, flags: flags, execute: work)
    }
}
