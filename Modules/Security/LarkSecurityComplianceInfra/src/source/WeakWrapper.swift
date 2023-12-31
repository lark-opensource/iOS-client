//
//  WeakWrapper.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/8/31.
//

import Foundation

public final class WeakWrapper<T: AnyObject> {
    public weak var value: T?
    public init(value: T) {
        self.value = value
    }
}
