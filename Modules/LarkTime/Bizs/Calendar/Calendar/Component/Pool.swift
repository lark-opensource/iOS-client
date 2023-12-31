//
//  Pool.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/10.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation

protocol Poolable {
    init()
}

final class Pool<T: Poolable> {
    init() {
    }

    private var elements = [T]()
    func borrowObject() -> T {
        guard self.elements.isEmpty else {
            return self.elements.removeFirst()
        }
        let element = T()
        return element
    }

    func returnObject(_ element: T) {
        self.elements.append(element)
    }

}
