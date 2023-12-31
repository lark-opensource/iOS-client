//
//  WeakRef.swift
//  ByteView
//
//  Created by kiri on 2021/3/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct WeakRef<T: AnyObject>: Equatable {
    public static func == (lhs: WeakRef<T>, rhs: WeakRef<T>) -> Bool {
        lhs.ref === rhs.ref
    }

    public weak var ref: T?
    public init(_ obj: T) {
        self.ref = obj
    }
}

public struct AnyWeakRef {
    public weak var ref: AnyObject?
    public init(_ ref: AnyObject) {
        self.ref = ref
    }
}
