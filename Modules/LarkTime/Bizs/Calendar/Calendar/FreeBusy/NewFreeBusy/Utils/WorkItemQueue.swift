//
//  WorkItemQueue.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging
import CalendarFoundation

final class WorkItemQueue {
    var queue: SafeArray = [(DispatchWorkItem, Int)]() + .readWriteLock

    let maxCount: Int

    init(maxCount: Int) {
        self.maxCount = maxCount
    }

    func add(_ item: (DispatchWorkItem, Int)) {
        queue.safeWrite { innerArray in
            innerArray = innerArray.filter { (arg) -> Bool in
                let (workItem, index) = arg
                if index == item.1 {
                    // cancel重复刷新的index，保留最近一次的刷新
                    workItem.cancel()
                    return false
                }
                return true
            }
        }

        if queue.count < maxCount {
            queue.insert(item, at: 0)
            return
        }
        removeLestImportant(with: item.1)
        queue.insert(item, at: 0)
    }

    private func removeLestImportant(with newIndex: Int) {
        queue.safeWrite { (innerArray) in
            var indexShouldRemove = 0
            var itemShouldRemove = innerArray.last
            var maxDiff = Int.min
            for i in 0 ..< innerArray.count {
                let item = innerArray[i]
                let diff = abs(newIndex - item.1)
                if diff > maxDiff {
                    maxDiff = diff
                    itemShouldRemove = item
                    indexShouldRemove = i
                }
            }
            innerArray.remove(at: indexShouldRemove)
            itemShouldRemove?.0.cancel()
            operationLog(message: "...did remove panel index: \(String(describing: itemShouldRemove?.1))")

        }
    }
    func remove(_ item: DispatchWorkItem) {
        queue.safeWrite { innerArray in
            if let index = innerArray.firstIndex(where: { $0.0 === item }) {
                innerArray.remove(at: index)
            }
        }
    }

}
