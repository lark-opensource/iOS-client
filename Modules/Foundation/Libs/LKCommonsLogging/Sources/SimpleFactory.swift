//
//  LKCommonsLoggingSimpleFactory.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2018/3/25.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation

struct SimpleFactory: LogFactory {
    static var proxies: [String: LoggingProxy] = [:]
    static let semaphore = DispatchSemaphore(value: 1)

    static func createLog(_ type: Any, category: String) -> Log {
        let key = category
        semaphore.wait()
        let proxy = proxies[key] ?? LoggingProxy(type, category: key)
        proxies[key] = proxy
        semaphore.signal()
        return proxy
    }

    static func setupLogFactory(for category: String, with block: LogFactoryBlock) {
        semaphore.wait()
        let fixedProxies = category.isEmpty ? proxies : proxies.filter { $0.key.hasPrefix(category) }
        semaphore.signal()
        fixedProxies.forEach { $0.value.setupLogFactory(block) }
    }
}
