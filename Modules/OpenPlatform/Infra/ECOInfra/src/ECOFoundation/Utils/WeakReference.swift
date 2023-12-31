//
//  WeakReference.swift
//  OPSDK
//
//  Created by Limboy on 2020/11/10.
//

import Foundation

public final class WeakReference<T: AnyObject> {

    public weak var value: T?

    public init(value: T) {
        self.value = value
    }

    public func release() {
        value = nil
    }
}
