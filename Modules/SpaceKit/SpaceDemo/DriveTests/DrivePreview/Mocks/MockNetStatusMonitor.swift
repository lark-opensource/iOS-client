//
//  MockNetStatusMonitor.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import UIKit
@testable import SpaceKit

private var managerKey: Void?
class MockNetStatusMonitor: SKNetStatusService {
    public var observers: NSHashTable<AnyObject> = NSHashTable(options: .weakMemory)

    var accessType: NetworkType = .wifi
    var isReachable: Bool {
        return accessType != .notReachable

    }
    func addObserver(_ observer: AnyObject, _ block: @escaping NetStatusCallback) {
        objc_setAssociatedObject(observer,
                                 &managerKey, block,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.observers.add(observer)
        block(self.accessType, self.isReachable)
    }
    func changeAccessType(_ type: NetworkType) {
        accessType = type
        let observers = self.observers.allObjects
        for observer in observers {
            let block = objc_getAssociatedObject(observer, &managerKey)
            guard let callback = block as? NetStatusCallback else { return }
            callback(self.accessType, self.isReachable)
        }
    }

    static func noNetMonitor() -> SKNetStatusService {
        let net = MockNetStatusMonitor()
        net.changeAccessType(.notReachable)
        return net
    }
}
