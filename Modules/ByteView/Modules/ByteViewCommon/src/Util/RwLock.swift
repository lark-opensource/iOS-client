//
//  RwLock.swift
//  ByteViewCommon
//
//  Created by kiri on 2022/1/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import EEAtomic

public final class RwLock {
    private var lock = EEAtomic.RWLock()

    public init() {}

    public func withRead<T>(_ block: () throws -> T) rethrows -> T {
        try lock.withRDLocking(action: block)
    }

    @discardableResult
    public func withWrite<T>(_ block: () throws -> T) rethrows -> T {
        try lock.withWRLocking(action: block)
    }
}
