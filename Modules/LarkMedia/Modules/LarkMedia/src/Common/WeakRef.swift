//
//  WeakRef.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/3/29.
//

import Foundation

struct WeakRef<T: AnyObject> {

    private(set) weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}
