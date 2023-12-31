//
//  LogFactoryStore.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2018/5/6.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation

final class LogFactoryStore {

    static let logQueue = DispatchQueue(label: "LKCommonsLogging.LogFactoryStore", qos: .background)

    var defaultFactory: LogFactoryBlock
    var store: [String: LogFactoryBlock] = [:]
    let semaphore = DispatchSemaphore(value: 1)

    init(_ factory: @escaping LogFactoryBlock) {
        defaultFactory = factory
    }

    func findLogFactory(for category: String) -> LogFactoryBlock {

        var components = category.components(separatedBy: ".")

        while !components.isEmpty {
            let key = components.joined(separator: ".")
            semaphore.wait()
            if let factory = store[key] {
                semaphore.signal()
                return factory
            }
            semaphore.signal()
            components.removeLast()
        }

        return defaultFactory
    }

    func setupLogFactory(for category: String, with block: @escaping LogFactoryBlock) {
        var key = category
        while key.last == "*" || key.last == "." {
            key.removeLast()
        }
        if key.isEmpty {
            defaultFactory = block
        } else {
            semaphore.wait()
            store[key] = block
            semaphore.signal()
        }

        SimpleFactory.setupLogFactory(for: key, with: block)
    }
}
