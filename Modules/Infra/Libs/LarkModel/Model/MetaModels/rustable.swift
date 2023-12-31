//
//  rustable.swift
//  Model
//
//  Created by qihongye on 2018/3/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import SwiftProtobuf

public protocol ModelProtocol {
    associatedtype PBModel: SwiftProtobuf.Message

    static func transform(pb: PBModel) -> Self
}

protocol AtomicExtra {
    associatedtype ExtraModel

    var atomicExtra: SafeAtomic<ExtraModel> { get }
}

struct SafeAtomic<T> {
    private var lock = os_unfair_lock_s()
    var unsafeValue: T
    var value: T {
        mutating get {
            os_unfair_lock_lock(&lock)
            defer {
                os_unfair_lock_unlock(&lock)
            }
            return unsafeValue
        }
        mutating set {
            os_unfair_lock_lock(&lock)
            unsafeValue = newValue
            os_unfair_lock_unlock(&lock)
        }
    }

    init(value: T) {
        self.unsafeValue = value
    }
}
