//
//  Array+Lark.swift
//  Lark
//
//  Created by 齐鸿烨 on 2016/12/27.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible

public enum SequenceType: Int32 {
    case ascending
    case descending
}

public extension Sequence {
    /// deduplicate Element by same identity, keep order and first Element
    func lf_unique<T: Hashable>(by identity: (Element) throws -> T) rethrows -> [Element] {
        var saw = Set<T>(minimumCapacity: self.underestimatedCount)
        return try self.filter { saw.insert(try identity($0)).inserted }
    }
}

public extension Sequence where Element: Hashable {
    func lf_unique() -> [Element] { return lf_unique(by: { $0 }) }
}

public extension RangeReplaceableCollection {
    /// deduplicate Element by same identity, keep order and first Element
    mutating func lf_formUnique<T: Hashable>(by identity: (Element) throws -> T) rethrows {
        var saw = Set<T>(minimumCapacity: self.count)
        try removeAll { !saw.insert(try identity($0)).inserted }
    }
}

public extension RangeReplaceableCollection where Element: Hashable {
    mutating func lf_formUnique() { lf_formUnique(by: { $0 }) }
}

// swiftlint:disable cyclomatic_complexity function_body_length file_length
public extension Array {
    /**
     二分查找element所在位置（前提是已经按照某种规则排过顺序了）
     - parameters:
     - element: 要查找的元素
     - comparable: (a, b) -> Int 判定排列顺序的方法，相当于执行 a - b的结果
     - sequence: .ascending 升序 .descending 降序 default .ascending
     - Returns:
     (before: Int, after: Int) 返回所在的区间范围，
     比如：[1, 3].bsearch(2) -> (0, 1) 2不在原数组里，所以返回它应该在的区间
     比如：[1, 2, 3].bsearch(2) -> (1, 1)
     比如：[1, 1, 1].bsearch(1) -> (0, 2)
     */
    func lf_bsearch(
        _ element: Element,
        comparable: (Element, Element) -> Int,
        sequence: SequenceType = .ascending
    ) -> (before: Int, after: Int) {
        var before = 0
        var after = self.count - 1

        // 如果超出了range直接返回最开始活着最后面
        if self.isEmpty {
            return (0, 0)
        }

        var mid = 0
        var res = 0

        var compare: (Int) -> Int

        switch sequence {
        case .ascending:
            compare = { $0 }
        case .descending:
            compare = { $0 * -1 }
        }

        switch compare(comparable(self.first!, element)) {
        case 1 ..< Int.max:
            return (before - 1, before)
        case 0:
            return (before, lf_last(element, start: before, end: after, comparable: comparable) ?? before)
        default:
            break
        }

        switch compare(comparable(self.last!, element)) {
        case -Int.max ..< 0:
            return (after, after + 1)
        case 0:
            return (lf_first(element, end: after, comparable: comparable) ?? after, after)
        default:
            break
        }

        while after - before > 1 {
            mid = (before + after) >> 1
            res = compare(comparable(self[mid], element))
            if res == 0 {
                return (lf_first(element, start: before + 1, end: mid, comparable: comparable) ?? mid,
                        lf_last(element, start: mid + 1, end: after, comparable: comparable) ?? mid)
            } else if res < 0 {
                before = mid
            } else {
                after = mid
            }
        }

        if comparable(self[before], element) == 0 {
            return (before, before)
        }
        if comparable(self[after], element) == 0 {
            return (after, after)
        }

        return (before, after)
    }

    /// 查找从end到start找第一个element
    private func lf_first(
        _ element: Element,
        start: Int? = nil,
        end: Int? = nil,
        comparable: (Element, Element) -> Int) -> Int? {
        let start = start ?? 0
        var end = end ?? self.count - 1

        while start <= end && end > 0 {
            end -= 1
            if comparable(self[end], element) != 0 {
                return end + 1
            }
        }
        return nil
    }

    /// 查找从start到end找第一个element
    private func lf_last(
        _ element: Element,
        start: Int? = nil,
        end: Int? = nil,
        comparable: (Element, Element) -> Int) -> Int? {
        var start = start ?? 0
        let end = end ?? self.count

        while start < end {
            if comparable(self[start], element) != 0 {
                return start - 1
            }
            start += 1
        }
        return nil
    }

    /**
     merge有序数组
     - parameters:
     - array: 合并的数组
     - comparable: (a, b) -> Int 判定排列顺序的方法，相当于执行 a - b的结果
     - equitable: (a, b) -> Element? 如果Element?为nil，进入不相等逻辑。如果Element?非空则进入相等逻辑且使用Element到合并数组中。
     - sequence: .ascending 升序 .descending 降序，default .ascending
     - Returns:
     合并后的数组
     */
    func lf_mergeUnique(
        array: [Element],
        comparable: (Element, Element) -> Int,
        equitable: @escaping ((Element, Element) -> Element?),
        sequence: SequenceType = .ascending) -> [Element] {
        var output: [Element] = []
        func append(element: Element) {
            if let last = output.last, equitable(last, element) != nil {
                return
            }
            output.append(element)
        }

        let count1 = self.count
        let count2 = array.count

        if count1 == 0 {
            for element in array {
                append(element: element)
            }
            return output
        }
        if count2 == 0 {
            for element in self {
                append(element: element)
            }
            return output
        }

        var indexI = 0
        var indexJ = 0
        var compare: (Int) -> Int

        switch sequence {
        case .ascending:
            compare = { res -> Int in
                res
            }
        case .descending:
            compare = { res -> Int in
                res * -1
            }
        }

        while indexI < count1 && indexJ < count2 {
            if let value = equitable(self[indexI], array[indexJ]) {
                append(element: value)
                indexI += 1
                indexJ += 1
                continue
            }

            if compare(comparable(self[indexI], array[indexJ])) > 0 {
                append(element: array[indexJ])
                indexJ += 1
            } else {
                append(element: self[indexI])
                indexI += 1
            }
        }

        while indexI < count1 {
            append(element: self[indexI])
            indexI += 1
        }

        while indexJ < count2 {
            append(element: array[indexJ])
            indexJ += 1
        }

        return output
    }

    /**
     merge有序升序连续数组
     - parameters:
     - array: 合并的数组
     - comparable: (a, b) -> Int 判定排列顺序的方法，相当于执行 a - b的结果
     - Returns:
     合并后的数组
     */
    func lf_mergeUniqueContinuous(array: [Element], comparable: (Element, Element) -> Int) -> [Element] {
        let baseArr = self
        let newArr = array

        if baseArr.isEmpty {
            return array
        }
        if array.isEmpty {
            return baseArr
        }

        // messages在nowMessages里面
        if comparable(newArr.first!, baseArr.first!) >= 0 && comparable(baseArr.last!, newArr.last!) >= 0 {
            return baseArr
        } else if comparable(baseArr.first!, newArr.first!) >= 0 && comparable(newArr.last!, baseArr.last!) >= 0 {
            // nowMessages在messages里面
            return newArr
        }

        if comparable(baseArr.first!, array.first!) < 0 {
            // messages在nowMessages后面
            if comparable(baseArr.last!, array.first!) < 0 {
                return baseArr + newArr
            }
            var updateMessages: [Element] = []
            if newArr.count > baseArr.count {
                let index = baseArr.lf_bsearch(newArr.first!, comparable: comparable).after
                //                let index = baseArr.index(where: { $0 == newArr.first! }) ?? baseArr.count
                updateMessages = baseArr.prefix(index) + newArr
            } else {
                let index = newArr.lf_bsearch(baseArr.last!, comparable: comparable).after
                //                let index = newArr.index(where: { $0 == baseArr.last! }) ?? newArr.count
                updateMessages = baseArr + newArr.suffix(from: index + 1)
            }
            return updateMessages
        } else if comparable(newArr.last!, baseArr.last!) < 0 {
            // messages在nowMessages前面

            if comparable(newArr.last!, baseArr.first!) < 0 {
                return newArr + baseArr
            }

            var updateMessages: [Element] = []
            if newArr.count > baseArr.count {
                let index = baseArr.lf_bsearch(newArr.last!, comparable: comparable).after
                //                let index = baseArr.index(where: { $0 == newArr.last! }) ?? baseArr.count
                updateMessages = newArr + baseArr.suffix(from: index + 1)
            } else {
                let index = newArr.lf_bsearch(baseArr.first!, comparable: comparable).after
                //                let index = newArr.index(where: { $0 == baseArr.first! }) ?? newArr.count
                updateMessages = newArr.prefix(index) + baseArr
            }
            return updateMessages
        }

        return baseArr
    }

    // 按索引key排序
    func lf_sorted(by compare: (Element, Element) -> Bool,
                   getIndexKey: (Element) -> String) -> [(key: String, elements: [Element])] {
        var data: [String: [Element]] = [:]
        for index in 0 ..< self.count {
            let element = self[index]
            let indexKey = getIndexKey(element)
            var firstLettery = "#"
            if indexKey != "" {
                firstLettery = indexKey[..<indexKey.index(after: indexKey.startIndex)].uppercased()
                if firstLettery > "Z" || firstLettery < "A" {
                    firstLettery = "#"
                }
            }
            if data[firstLettery] != nil {
                data[firstLettery]!.append(element)
            } else {
                var tempArray: [Element] = []
                tempArray.append(element)
                data[firstLettery] = tempArray
            }
        }
        for (key, arr) in data {
            data[key] = arr.sorted(by: compare)
        }
        let keys = data.keys.sorted(by: <)
        return keys.map({ (key: $0, elements: data[$0] ?? []) })
    }

    func lf_toDictionary<T: Hashable>(_ selectKey: (Element) -> T) -> [T: Element] {
        var dict: [T: Element] = [:]
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }

    func lf_slice(_ fromIndex: Int, _ toIndex: Int) -> [Element] {
        let from = Swift.max(Swift.min(fromIndex, self.count), 0)
        let toValue = Swift.min(toIndex, self.count)

        if from >= toValue {
            return []
        }

        return Array(self[from ..< toValue])
    }
}

public extension Array where Element: Equatable {
    static func == (_ lhs: [Element], _ rhs: [Element]?) -> Bool {
        guard let rhs = rhs else {
            return false
        }
        if lhs.count != rhs.count {
            return false
        }

        for index in 0 ..< lhs.count where lhs[index] != rhs[index] {
            return false
        }

        return true
    }

    // Remove first collection element that is equal to the given `object`:
    mutating func lf_remove(object: Element) {
        guard let index = self.firstIndex(of: object) else {
            return
        }
        remove(at: index)
    }

    mutating func lf_removeObjectsInArray(_ array: [Element]) {
        array.forEach({ value in
            if let index = self.firstIndex(of: value) {
                self.remove(at: index)
            }
        })
    }

    mutating func lf_appendIfNotContains(_ object: Element) {
        if !self.contains(object) {
            self.append(object)
        }
    }

    mutating func lf_appendContentsIfNotContains(_ contents: [Element]) {
        contents.forEach { object in
            self.lf_appendIfNotContains(object)
        }
    }

    mutating func lf_removeDuplicateContents() {
        let temp = self
        self = []
        self.lf_appendContentsIfNotContains(temp)
    }

    // swiftlint:disable identifier_name
    @discardableResult
    mutating func lf_swap(_ i: Int, _ j: Int) -> [Element] {
        let temp = self[i]
        self[i] = self[j]
        self[j] = temp

        return self
    }

    func lf_top(
        n: Int,
        defaultElement: Element,
        comparable: @escaping (Element, Element) -> Bool) -> [Element] {
        // swiftlint:enable identifier_name
        func getLeftChild(_ heap: [Element], _ idx: Int, count: Int? = nil) -> (Element, Int)? {
            let leftIdx: Int = (idx << 1) + 1
            let count = count ?? heap.count
            if leftIdx >= count {
                return nil
            }
            return (value: heap[leftIdx], idx: leftIdx)
        }

        func getRightChild(_ heap: [Element], _ idx: Int, count: Int? = nil) -> (Element, Int)? {
            let rightIdx: Int = (idx << 1) + 2
            let count = count ?? heap.count
            if rightIdx >= count {
                return nil
            }
            return (value: heap[rightIdx], idx: rightIdx)
        }

        func heapIn(_ heap: inout [Element], _ element: Element, _ count: Int? = nil) {
            let length = count ?? heap.count
            let count = length / 2
            var idx = 0
            var lch: (Element, Int)?
            var rch: (Element, Int)?
            heap[idx] = element
            while idx < count {
                lch = getLeftChild(heap, idx, count: length)
                rch = getRightChild(heap, idx, count: length)
                if lch == nil && rch == nil {
                    break
                }
                if rch == nil {
                    if comparable(heap[idx], lch!.0) {
                        heap.lf_swap(idx, lch!.1)
                        idx = lch!.1
                    }
                    break
                }
                var nothingHappen = true
                if comparable(rch!.0, lch!.0) {
                    if comparable(heap[idx], lch!.0) {
                        heap.lf_swap(idx, lch!.1)
                        idx = lch!.1
                        nothingHappen = false
                    }
                } else {
                    if comparable(heap[idx], rch!.0) {
                        heap.lf_swap(idx, rch!.1)
                        idx = rch!.1
                        nothingHappen = false
                    }
                }

                if nothingHappen {
                    break
                }
            }
        }

        func heapOut(_ heap: inout [Element], _ count: Int) {
            if count > 1 {
                let lastIdx = count - 1
                heap.lf_swap(0, lastIdx)
                heapIn(&heap, heap.first!, lastIdx)
            }
        }

        var heap = [Element](repeating: defaultElement, count: n)

        for element in self {
            if comparable(element, heap.first!) {
                heapIn(&heap, element)
            }
        }

        for index in 0 ..< n {
            heapOut(&heap, n - index)
        }

        return heap
    }
}

// swiftlint:enable cyclomatic_complexity function_body_length file_length
