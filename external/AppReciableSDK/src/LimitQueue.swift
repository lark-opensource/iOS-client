//
//  LimitQueue.swift
//  AppReciableSDK
//
//  Created by qihongye on 2020/12/29.
//

import Foundation

struct LimitQueue<Element> {
    private(set) var array: [Element] = []

    var startIndex: Int = 0
    var endIndex: Int = 0
    var count: Int {
        return array.count
    }
    var capacity: Int

    var last: Element? {
        guard endIndex < array.count, endIndex > 0 else {
            return nil
        }
        return array[endIndex]
    }

    init(capacity: Int) {
        array.reserveCapacity(capacity)
        self.capacity = capacity
        startIndex = 0
        endIndex = 0
    }

    mutating func push(_ element: Element) {
        if array.count < capacity {
            endIndex = array.count
            self.array.append(element)
            return
        }
        self.endIndex = startIndex
        self.array[self.endIndex] = element
        self.startIndex = (startIndex + 1) % capacity
    }

    func forEach(_ body: (Element) -> Bool) {
        if array.isEmpty {
            return
        }
        if endIndex < startIndex {
            for i in startIndex..<array.count {
                if !body(array[i]) {
                    break
                }
            }
            for i in 0...endIndex {
                if !body(array[i]) {
                    break
                }
            }
            return
        }
        for i in startIndex...endIndex {
            if !body(array[i]) {
                break
            }
        }
    }

    func map<O>(_ body: (Element) -> O) -> [O] {
        var output: [O] = []
        output.reserveCapacity(capacity)
        forEach { (i) in
            output.append(body(i))
            return true
        }
        return output
    }
}
