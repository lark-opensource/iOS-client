//
//  WeakManager.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/10/13.
//

import Foundation

final class Weak<T: AnyObject> {
    weak var value: T?
    init(value: T) {
        self.value = value
    }
}

final class WeakManager<T> {
    var weakObjects = [Weak<AnyObject>]()

    func register(object: AnyObject) {
        let isContain = weakObjects.contains(where: { obj in
            return obj.value === object
        })
        if !isContain {
            weakObjects.append(Weak(value: object))
        }
    }

    func remove(object: AnyObject) {
        weakObjects.removeAll(where: {
            guard let value = $0.value else {
                return true
            }
            return value === object
        })
    }
}
