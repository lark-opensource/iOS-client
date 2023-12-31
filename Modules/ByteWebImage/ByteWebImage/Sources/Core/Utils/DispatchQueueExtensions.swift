//
//  DispatchQueueExtensions.swift
//  ByteWebImage
//
//  Created by Nickyo on 2023/2/23.
//

import Foundation

enum DispatchImageQueue {

    private static let imageQueue = DispatchSafeQueue(label: "image.bytedance.queue", qos: .default, attributes: .concurrent)

    static var usePrivateImageQueue: Bool = false

    static func sync<T>(execute work: () throws -> T) rethrows -> T {
        if usePrivateImageQueue {
            return try imageQueue.sync(execute: work)
        } else {
            return try work()
        }
    }

    static func async(execute work: @escaping @convention(block) () -> Void) {
        imageQueue.async(execute: work)
    }
}

enum DispatchMainQueue {

    static func async(execute work: @escaping @convention(block) () -> Void) {
        if pthread_main_np() != 0 {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    static func asyncAfter(deadline: DispatchTime, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], execute work: @escaping @convention(block) () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: deadline, qos: qos, flags: flags, execute: work)
    }
}
