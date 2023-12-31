//
//  SynchronizedClosure.swift
//  SpaceKit
//
//  Created by zenghao on 2018/8/19.
//

import Foundation

@discardableResult
public func synchronized<T>(_ lock: AnyObject, _ closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)

    }
    return try closure()
}
