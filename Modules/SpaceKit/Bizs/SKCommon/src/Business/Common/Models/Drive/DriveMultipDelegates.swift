//
//  DriveMultipDelegates.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/3/31.
//

import Foundation
import SKFoundation

/// 多代理分发基类
open class DriveMultipDelegates {

    private var observers: NSHashTable<AnyObject> = NSHashTable(options: .weakMemory)

    /// 操作队列
    public let operateQueue = DispatchQueue(label: "com.drive.safeOperate")

    public init() {}

    open func addObserver(_ delegate: AnyObject) {
        operateQueue.async {
            self.observers.add(delegate)
            DocsLogger.info("added Observers", extraInfo: ["service": self,
                                                            "count": self.observers.allObjects.count])
        }
    }

    open func invoke<T>(_ invocation: @escaping (T) -> Void) {
        operateQueue.async {
            self.observers.allObjects.forEach { (obj) in
                if let value = obj as? T {
                    invocation(value)
                }
            }
        }
    }
}
